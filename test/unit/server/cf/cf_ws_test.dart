import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/data/model/cf/cf_server.dart';
import 'package:nodepulse/data/provider/server/cf/cf_ws.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketSink implements WebSocketSink {
  final void Function(dynamic data)? onAdd;
  final void Function()? onClose;

  _FakeWebSocketSink({this.onAdd, this.onClose});

  @override
  void add(dynamic data) => onAdd?.call(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future close([int? closeCode, String? closeReason]) async {
    onClose?.call();
  }

  @override
  Future get done => Future.value();
}

class _FakeWebSocketChannel extends StreamChannelMixin implements WebSocketChannel {
  final StreamController<dynamic> _streamController;
  final _FakeWebSocketSink _sink;

  _FakeWebSocketChannel({
    required StreamController<dynamic> streamController,
    required void Function(dynamic data) onSend,
    void Function()? onClose,
  })  : _streamController = streamController,
        _sink = _FakeWebSocketSink(onAdd: onSend, onClose: onClose);

  @override
  Stream get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();
}

void main() {
  group('CfServer.copyWithMetrics', () {
    test('sample updates metrics while leaving static fields unchanged', () {
      const server = CfServer(
        id: 's1',
        name: 'Node Alpha',
        group: 'Default',
        region: 'US',
        os: 'Ubuntu 22.04',
        arch: 'x86_64',
        price: '5.00',
        billingCycle: 'month',
        expireDate: '2027-01-01',
        trafficLimit: '1000GB',
        trafficCalcType: 'down',
        online: false,
        cpu: 10.0,
        cpuCores: 4,
        cpuInfo: 'Intel Xeon',
        ramUsed: 1000,
        ramTotal: 8000,
        swapUsed: 100,
        swapTotal: 2000,
        diskUsed: 20000,
        diskTotal: 100000,
        load1: 0.1,
        load5: 0.2,
        load15: 0.3,
        netInSpeed: 500,
        netOutSpeed: 600,
        netRxMonthly: 10000,
        netTxMonthly: 20000,
        netRx: 50000,
        netTx: 60000,
        tcpConn: 15,
        udpConn: 5,
        processes: 120,
        pingCt: 50.0,
        pingCu: 45.0,
        pingCm: 60.0,
        lossCt: 0.0,
        lossCu: 0.0,
        lossCm: 0.0,
        bootTime: 1700000000,
      );

      final sample = {
        'cpu': 55.5,
        'net_in_speed': 100,
        'net_out_speed': 250,
        'ram_used': 2048.5,
        'disk_used': 30000,
        'tcp_conn': 20,
        'udp_conn': 8,
        'load_avg': '1.5 1.2 0.8',
        'ping_ct': 42.0,
        'loss_ct': 2.5,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      };

      final updated = server.copyWithMetrics(sample);

      // Changed fields
      expect(updated.cpu, 55.5);
      expect(updated.netInSpeed, 100);
      expect(updated.netOutSpeed, 250);
      expect(updated.ramUsed, 2049); // rounded to int
      expect(updated.diskUsed, 30000);
      expect(updated.tcpConn, 20);
      expect(updated.udpConn, 8);
      expect(updated.load1, 1.5);
      expect(updated.load5, 1.2);
      expect(updated.load15, 0.8);
      expect(updated.pingCt, 42.0);
      expect(updated.lossCt, 2.5);
      expect(updated.online, isTrue);

      // Unmentioned fields remain identical
      expect(updated.id, 's1');
      expect(updated.name, 'Node Alpha');
      expect(updated.group, 'Default');
      expect(updated.region, 'US');
      expect(updated.os, 'Ubuntu 22.04');
      expect(updated.arch, 'x86_64');
      expect(updated.cpuCores, 4);
      expect(updated.cpuInfo, 'Intel Xeon');
      expect(updated.ramTotal, 8000);
      expect(updated.diskTotal, 100000);
      expect(updated.swapTotal, 2000);
      expect(updated.swapUsed, 100);
      expect(updated.netRxMonthly, 10000);
      expect(updated.netTxMonthly, 20000);
      expect(updated.trafficLimit, '1000GB');
      expect(updated.price, '5.00');
      expect(updated.expireDate, '2027-01-01');
      expect(updated.pingCu, 45.0);
      expect(updated.pingCm, 60.0);
      expect(updated.lossCu, 0.0);
      expect(updated.lossCm, 0.0);
      expect(updated.bootTime, 1700000000);
    });
  });

  group('CfWs message parsing and lifecycle', () {
    test('parses batchUpdate and invokes onSample for each update and sample', () {
      final samples = <(String, Map<String, dynamic>)>[];

      void onSample(String serverId, Map<String, dynamic> data) {
        samples.add((serverId, data));
      }

      final payload = jsonEncode({
        'type': 'batchUpdate',
        'ts': 1759410000000,
        'updates': [
          {
            'serverId': 'srv-1',
            'samples': [
              {
                'ts': 1759410000000,
                'data': {'cpu': 12.3, 'ram_used': 500}
              },
              {
                'ts': 1759410001000,
                'data': {'cpu': 15.0, 'ram_used': 520}
              }
            ]
          },
          {
            'serverId': 'srv-2',
            'samples': [
              {
                'ts': 1759410000000,
                'data': {'cpu': 88.0}
              }
            ]
          }
        ]
      });

      CfWs.handleRawMessage(payload, onSample);

      expect(samples.length, 3);
      expect(samples[0].$1, 'srv-1');
      expect(samples[0].$2['cpu'], 12.3);
      expect(samples[1].$1, 'srv-1');
      expect(samples[1].$2['cpu'], 15.0);
      expect(samples[2].$1, 'srv-2');
      expect(samples[2].$2['cpu'], 88.0);
    });

    test('ignores non-batchUpdate or unrecognized messages', () {
      final samples = <(String, Map<String, dynamic>)>[];
      void onSample(String serverId, Map<String, dynamic> data) {
        samples.add((serverId, data));
      }

      CfWs.handleRawMessage(jsonEncode({'type': 'hello', 'version': '1.0'}), onSample);
      CfWs.handleRawMessage(jsonEncode({'type': 'subscribed', 'scope': 'all'}), onSample);
      CfWs.handleRawMessage(jsonEncode({'type': 'pong'}), onSample);
      CfWs.handleRawMessage('not valid json', onSample);

      expect(samples, isEmpty);
    });

    test('formats websocket url with scheme conversion and token param', () {
      expect(
        CfWs.buildWsUrl('https://example.com'),
        'wss://example.com/api/ws',
      );
      expect(
        CfWs.buildWsUrl('http://example.com/'),
        'ws://example.com/api/ws',
      );
      expect(
        CfWs.buildWsUrl('https://example.com', token: 'my-jwt-token'),
        'wss://example.com/api/ws?token=my-jwt-token',
      );
      expect(
        CfWs.buildWsUrl('wss://example.com/custom/ws', token: 'abc'),
        'wss://example.com/custom/ws?token=abc',
      );
    });

    test('subscribe and ping message serialization', () {
      expect(CfWs.subscribeMessage, '{"type":"subscribe","scope":"all"}');
      expect(CfWs.pingMessage, '{"type":"ping"}');
      expect(CfWs.pongMessage, '{"type":"pong"}');
    });

    test('reconnect backoff and heartbeat ping-pong flow', () async {
      final outgoingMessages = <dynamic>[];
      final incomingController = StreamController<dynamic>();
      var isClosed = false;

      final fakeChannel = _FakeWebSocketChannel(
        streamController: incomingController,
        onSend: (msg) => outgoingMessages.add(msg),
        onClose: () => isClosed = true,
      );

      var connected = false;
      var disconnected = false;
      final samples = <(String, Map<String, dynamic>)>[];

      final ws = CfWs.connect(
        url: 'https://example.com',
        token: 'secret',
        channelFactory: (uri) => fakeChannel,
        onConnected: () => connected = true,
        onDisconnected: () => disconnected = true,
        onSample: (id, data) => samples.add((id, data)),
      );

      expect(connected, isTrue);
      expect(outgoingMessages, contains(CfWs.subscribeMessage));

      // Simulate incoming batch update
      incomingController.add(jsonEncode({
        'type': 'batchUpdate',
        'ts': 1000,
        'updates': [
          {
            'serverId': 'srv-1',
            'samples': [
              {
                'ts': 1000,
                'data': {'cpu': 33.3}
              }
            ]
          }
        ]
      }));

      // Let microtasks run
      await pumpEventQueue();

      expect(samples.length, 1);
      expect(samples.first.$1, 'srv-1');
      expect(samples.first.$2['cpu'], 33.3);

      ws.dispose();
      expect(disconnected, isTrue);
      expect(isClosed, isTrue);
    });
  });
}
