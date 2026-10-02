import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/core/service/widget_sync.dart';
import 'package:server_box/data/model/cf/cf_server.dart';

void main() {
  group('WidgetSync payloadFrom', () {
    test('builds payload matching CF contract', () {
      final nodes = [
        const CfServer(
          id: 'node-2',
          name: '香港节点',
          region: 'HK',
          online: true,
          cpu: 10.0,
          ramUsed: 1024,
          ramTotal: 4096,
          swapUsed: 0,
          swapTotal: 0,
          diskUsed: 20480,
          diskTotal: 102400,
          load1: 0.1,
          load5: 0.2,
          load15: 0.3,
          netInSpeed: 1000,
          netOutSpeed: 2000,
          netRxMonthly: 0,
          netTxMonthly: 0,
          netRx: 0,
          netTx: 0,
          tcpConn: 10,
          udpConn: 5,
          processes: 50,
          gpus: [],
        ),
        const CfServer(
          id: 'node-1',
          name: '东京节点',
          region: 'JP',
          online: true,
          cpu: 5.0,
          ramUsed: 2048,
          ramTotal: 4096,
          swapUsed: 0,
          swapTotal: 0,
          diskUsed: 20480,
          diskTotal: 102400,
          load1: 0.1,
          load5: 0.2,
          load15: 0.3,
          netInSpeed: 500,
          netOutSpeed: 1000,
          netRxMonthly: 0,
          netTxMonthly: 0,
          netRx: 0,
          netTx: 0,
          tcpConn: 10,
          udpConn: 5,
          processes: 50,
          gpus: [],
        ),
      ];

      final payload = WidgetSync.payloadFrom(
        siteUrl: 'https://monitor.example.com',
        token: 'test-jwt',
        tokenExpiresAt: 1759410000000,
        nodes: nodes,
      );

      expect(payload['siteUrl'], 'https://monitor.example.com');
      expect(payload['token'], 'test-jwt');
      expect(payload['tokenExpiresAt'], 1759410000000);

      final outNodes = payload['nodes'] as List<Map<String, dynamic>>;
      expect(outNodes.length, 2);
      // Sorted alphabetically by name: 东京节点 before 香港节点
      expect(outNodes[0]['id'], 'node-1');
      expect(outNodes[0]['name'], '东京节点');
      expect(outNodes[0]['region'], 'JP');
      expect(outNodes[1]['id'], 'node-2');
      expect(outNodes[1]['name'], '香港节点');
      expect(outNodes[1]['region'], 'HK');
    });

    test('handles empty or null token correctly', () {
      final payload = WidgetSync.payloadFrom(
        siteUrl: 'http://monitor.local',
        token: null,
        tokenExpiresAt: 0,
        nodes: [],
      );

      expect(payload['siteUrl'], 'http://monitor.local');
      expect(payload['token'], isNull);
      expect(payload['tokenExpiresAt'], 0);
      expect(payload['nodes'], isEmpty);
    });
  });
}
