import 'dart:async';

import 'package:dio/dio.dart';
import 'package:server_box/data/model/cf/cf_history.dart';
import 'package:server_box/data/model/cf/cf_server.dart';

/// Talks to one CF-Server-Monitor site
/// (https://github.com/huilang-me/CF-Server-Monitor, API.md is the contract).
///
/// Public sites need no auth at all. Private sites authenticate once via
/// [login] — `POST /admin/api {"action":"login",...}` for a JWT — and carry
/// it as `Authorization: Bearer` on every read. When the token expires
/// mid-session the server answers 401/403; if the credentials of the last
/// [login] are known, one silent re-login replays the request once, which is
/// what keeps the "log in once, forever" experience. The WebSocket layer
/// (which cannot set headers) reads the current token through [token].
class CfApi {
  CfApi({required String baseUrl, String? Function()? tokenProvider})
    : _tokenProvider = tokenProvider {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = this.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          final status = err.response?.statusCode;
          final request = err.requestOptions;
          // The auth POST itself is never re-login material: a refused
          // re-login would re-enter here while the credentials are still
          // set, recursing without bound. The flag below already bounds the
          // data-request path to one replay.
          final isAuthPost = request.path == _loginPath;
          if ((status == 401 || status == 403) &&
              !isAuthPost &&
              request.extra[_retriedKey] != true &&
              _canRelogin) {
            try {
              final token = await performLogin(_username!, _password!);
              request.extra[_retriedKey] = true;
              request.headers['Authorization'] = 'Bearer $token';
              handler.resolve(await _dio.fetch<dynamic>(request));
            } catch (_) {
              // The re-login itself failed (the password probably changed
              // server-side, so performLogin has forgotten the credentials).
              // Surface the original 401 — that is the state the caller has
              // to act on: ask the user for fresh credentials.
              handler.next(err);
            }
            return;
          }
          handler.next(err);
        },
      ),
    );
  }

  static const _connectTimeout = Duration(seconds: 8);
  static const _receiveTimeout = Duration(seconds: 15);
  static const _retriedKey = 'cf_relogin_retried';
  static const _loginPath = '/admin/api';

  late final Dio _dio;
  final String? Function()? _tokenProvider;
  String? _token;
  String? _username;
  String? _password;

  /// Set by [attachRestore] when the provider that constructed this instance
  /// launches its restore login; null on the public path, where there is no
  /// session to wait for.
  Completer<void>? _restoreGate;

  /// Completes when the restore login this instance started at construction
  /// has settled — immediately when it has none. The first read awaits this
  /// rather than racing the login with a tokenless request, which the site
  /// would answer with a 401 the page then pins as its state.
  Future<void> get ready => _restoreGate?.future ?? Future.value();

  /// Hands over the future of the launch restore, so a first read can wait
  /// it out through [ready]. The future runs on regardless; nothing here is
  /// what starts it.
  void attachRestore(Future<void> restore) {
    final gate = Completer<void>();
    _restoreGate = gate;
    unawaited(restore.whenComplete(gate.complete));
  }

  /// The current token: what an injected provider supplies, else what the
  /// last [login] / silent re-login obtained. `null` on the public path.
  String? get token => _tokenProvider?.call() ?? _token;

  bool get _canRelogin => _username != null && _password != null;

  /// POSTs the admin login, keeps the returned JWT (and the credentials, so
  /// a later 401 can re-login silently) and returns it.
  ///
  /// Transport failures propagate as `DioException`; a refusal by the site
  /// itself surfaces as [CfApiException] carrying the server's error key.
  Future<void> login(String username, String password) async {
    await performLogin(username, password);
  }

  /// [login] that also hands back the token — the seam the credentials store
  /// (`cf_credentials.dart`) wires its silent re-login through.
  ///
  /// A refusal by the site itself (API.md §3.2: `401 invalidCredentials`,
  /// `403 verificationFailed`, …) throws [CfApiException] carrying the
  /// server's error key; transport failures propagate as `DioException`.
  Future<String> performLogin(String username, String password) async {
    Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        _loginPath,
        data: {'action': 'login', 'username': username, 'password': password},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final error = data is Map && data['error'] is String ? data['error'] as String : null;
      if (error == null) rethrow;
      // Refused credentials will be refused again — forget them so the 401
      // path above cannot keep trying them, and the UI re-prompts instead.
      _username = null;
      _password = null;
      throw CfApiException(code: e.response?.statusCode, message: error);
    }
    final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
    final token = data?['token'];
    if (data?['success'] != true || token is! String || token.isEmpty) {
      throw CfApiException(
        code: res.statusCode,
        message: data?['error'] is String ? data!['error'] as String : 'loginFailed',
      );
    }
    _token = token;
    _username = username;
    _password = password;
    return token;
  }

  /// The node list the home page renders, with the site-wide counters.
  Future<CfServersSnapshot> fetchServers() async =>
      CfServersSnapshot.fromJson(await _getMap('/api/servers'));

  /// The detail endpoint's untouched Server object, for the page that needs
  /// the fields the snapshot does not carry.
  Future<Map<String, dynamic>> fetchServerRaw(String id) =>
      _getMap('/api/server', query: {'id': id});

  /// `hours` must be one of the ranges API.md enumerates (0.167, 0.5, 1, 6,
  /// 12, 24, 48, 96, 168); the server rejects anything else.
  Future<List<CfHistoryRow>> fetchHistory({
    required String id,
    required double hours,
  }) async {
    final res = await _dio.get<dynamic>(
      '/api/history/all',
      queryParameters: {'id': id, 'hours': hours},
    );
    final data = res.data;
    return [
      if (data is List)
        for (final e in data)
          if (e is Map) CfHistoryRow.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get<dynamic>(path, queryParameters: query);
    final data = res.data;
    if (data is! Map) throw CfApiException(message: 'unexpected response from $path');
    return Map<String, dynamic>.from(data);
  }

  void close() => _dio.close();
}

/// The site answered, but not with what the adapter can use: a refused
/// login, or a response shape the parser does not recognise. Transport
/// failures are `DioException`s and stay untouched.
class CfApiException implements Exception {
  final int? code;
  final String message;

  const CfApiException({this.code, required this.message});

  @override
  String toString() => 'CfApiException($code): $message';
}
