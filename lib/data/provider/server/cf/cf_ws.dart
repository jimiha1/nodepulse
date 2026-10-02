import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_lib/fl_lib.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket connection manager for CF-Server-Monitor (`/api/ws`).
///
/// Features:
/// - Connects to `{wsScheme}://{host}/api/ws` with optional `?token=$token`.
/// - Sends `{"type":"subscribe","scope":"all"}` on connection open.
/// - 30s heartbeat ping (`{"type":"ping"}`) expecting exact `{"type":"pong"}` within 10s.
/// - Exponential backoff reconnect (1s, 2s, 4s, 8s ... max 60s) on error/close.
/// - Parses `batchUpdate` messages and invokes `onSample(serverId, sample.data)`.
/// - Notifies on connection status changes via `onConnected` / `onDisconnected`.
class CfWs {
  CfWs._({
    required this.url,
    this.token,
    required this.onSample,
    this.onConnected,
    this.onDisconnected,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final String url;
  final String? token;
  final void Function(String serverId, Map<String, dynamic> data) onSample;
  final void Function()? onConnected;
  final void Function()? onDisconnected;
  final WebSocketChannel Function(Uri uri) _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;

  static const String subscribeMessage = '{"type":"subscribe","scope":"all"}';
  static const String pingMessage = '{"type":"ping"}';
  static const String pongMessage = '{"type":"pong"}';

  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration pongTimeoutDuration = Duration(seconds: 10);
  static const Duration maxReconnectDelay = Duration(seconds: 60);

  /// Connects to the CF-Server-Monitor WebSocket endpoint.
  static CfWs connect({
    required String url,
    String? token,
    required void Function(String serverId, Map<String, dynamic> data) onSample,
    void Function()? onConnected,
    void Function()? onDisconnected,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) {
    final client = CfWs._(
      url: url,
      token: token,
      onSample: onSample,
      onConnected: onConnected,
      onDisconnected: onDisconnected,
      channelFactory: channelFactory,
    );
    client._startConnect();
    return client;
  }

  /// Converts an http/https/ws/wss URL to a valid WebSocket URL with `/api/ws` path
  /// and optional `?token=...` parameter.
  static String buildWsUrl(String rawUrl, {String? token}) {
    final uri = Uri.parse(rawUrl);

    String wsScheme;
    if (uri.scheme == 'https' || uri.scheme == 'wss') {
      wsScheme = 'wss';
    } else {
      wsScheme = 'ws';
    }

    var path = uri.path;
    if (path.isEmpty || path == '/') {
      path = '/api/ws';
    } else if (path.endsWith('/api/ws') || path.endsWith('/ws')) {
      // already a ws path
    } else if (path.endsWith('/')) {
      path = '${path}api/ws';
    } else {
      path = '$path/api/ws';
    }

    final queryParams = Map<String, String>.from(uri.queryParameters);
    if (token != null && token.isNotEmpty) {
      queryParams['token'] = token;
    }

    final wsUri = Uri(
      scheme: wsScheme,
      userInfo: uri.userInfo.isNotEmpty ? uri.userInfo : null,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return wsUri.toString();
  }

  /// Parses incoming raw message text and invokes `onSample` on batch updates.
  static void handleRawMessage(
    String raw,
    void Function(String serverId, Map<String, dynamic> data) onSample,
  ) {
    Map<String, dynamic> msg;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      msg = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    final type = msg['type'];
    if (type == 'batchUpdate') {
      final updates = msg['updates'];
      if (updates is! List) return;
      for (final u in updates) {
        if (u is! Map) continue;
        final serverId = u['serverId'];
        if (serverId is! String || serverId.isEmpty) continue;
        final samples = u['samples'];
        if (samples is! List) continue;
        for (final s in samples) {
          if (s is! Map) continue;
          final data = s['data'];
          if (data is Map) {
            onSample(serverId, Map<String, dynamic>.from(data));
          }
        }
      }
    }
  }

  void _startConnect() {
    if (_isDisposed) return;
    _cleanConnection();

    try {
      final fullUrl = buildWsUrl(url, token: token);
      final uri = Uri.parse(fullUrl);
      final channel = _channelFactory(uri);
      _channel = channel;

      _channelSub = channel.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      // Connected: reset backoff, send subscription, notify, start heartbeat
      _reconnectAttempts = 0;
      _send(subscribeMessage);
      onConnected?.call();
      _startHeartbeat();
    } catch (e, s) {
      Loggers.app.warning('CfWs connection attempt failed', e, s);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    if (raw == pongMessage) {
      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = null;
      return;
    }

    handleRawMessage(raw, onSample);
  }

  void _send(String msg) {
    try {
      _channel?.sink.add(msg);
    } catch (e, s) {
      Loggers.app.warning('CfWs send failed', e, s);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _sendPing();
    });
  }

  void _sendPing() {
    _pongTimeoutTimer?.cancel();
    _send(pingMessage);
    _pongTimeoutTimer = Timer(pongTimeoutDuration, () {
      Loggers.app.warning('CfWs pong timed out (10s), reconnecting');
      _triggerReconnect();
    });
  }

  void _onError(dynamic error) {
    Loggers.app.warning('CfWs stream error: $error');
    _triggerReconnect();
  }

  void _onDone() {
    Loggers.app.info('CfWs stream closed');
    _triggerReconnect();
  }

  void _triggerReconnect() {
    if (_isDisposed) return;
    _cleanConnection();
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s ... max 60s
    final delaySeconds = min(
      pow(2, _reconnectAttempts).toInt(),
      maxReconnectDelay.inSeconds,
    );
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed) {
        _startConnect();
      }
    });
  }

  void _cleanConnection() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _channelSub?.cancel();
    _channelSub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Closes the connection and stops all reconnect / heartbeat timers permanently.
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanConnection();
    onDisconnected?.call();
  }
}
