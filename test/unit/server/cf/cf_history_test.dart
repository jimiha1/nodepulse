import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/data/model/cf/cf_history.dart';
import 'package:nodepulse/view/page/server/cf_detail/charts.dart';

void main() {
  group('CfHistoryRange', () {
    test('maps to CF accepted hours', () {
      expect(CfHistoryRange.live.hours, isNull);
      expect(CfHistoryRange.m30.hours, 0.5);
      expect(CfHistoryRange.h1.hours, 1.0);
      expect(CfHistoryRange.h6.hours, 6.0);
      expect(CfHistoryRange.d1.hours, 24.0);
      expect(CfHistoryRange.d2.hours, 48.0);
      expect(CfHistoryRange.d7.hours, 168.0);
    });
  });

  group('rowsToSeries transformation', () {
    final sampleRows = [
      const CfHistoryRow(
        timestamp: 1000,
        cpu: 10.0,
        ramUsed: 2000,
        ramTotal: 8000,
        diskUsed: 40000,
        diskTotal: 100000,
        netInSpeed: 1024,
        netOutSpeed: 2048,
        tcpConn: 50,
        udpConn: 20,
        processes: 120,
        diskReadBps: 512,
        diskWriteBps: 1024,
        swapUsed: 100,
        swapTotal: 2000,
        loadAvg: '0.15 0.20 0.25',
        pingCt: 30.0,
        pingCu: 40.0,
        pingCm: null,
        lossCt: 0.0,
        lossCu: 1.5,
        lossCm: null,
      ),
      const CfHistoryRow(
        timestamp: 2000,
        cpu: 25.0,
        ramUsed: 2500,
        ramTotal: 8000,
        diskUsed: 40000,
        diskTotal: 100000,
        netInSpeed: 4096,
        netOutSpeed: 8192,
        tcpConn: 55,
        udpConn: 22,
        processes: 125,
        diskReadBps: 1024,
        diskWriteBps: 2048,
        swapUsed: 100,
        swapTotal: 2000,
        loadAvg: '0.30 0.25 0.22',
        pingCt: 32.0,
        pingCu: null,
        pingCm: 45.0,
        lossCt: 0.0,
        lossCu: null,
        lossCm: 0.0,
      ),
    ];

    test('builds CPU series', () {
      final series = rowsToCpuSeries(sampleRows);
      expect(series.length, 1);
      expect(series[0].label, 'CPU');
      expect(series[0].values, [10.0, 25.0]);
    });

    test('builds Network dual-series (In / Out)', () {
      final series = rowsToNetSeries(sampleRows);
      expect(series.length, 2);
      expect(series[0].label, contains('In'));
      expect(series[0].values, [1024.0, 4096.0]);
      expect(series[1].label, contains('Out'));
      expect(series[1].values, [2048.0, 8192.0]);
    });

    test('builds Memory + Swap series', () {
      final series = rowsToMemSeries(sampleRows);
      expect(series.length, 2);
      expect(series[0].label, contains('RAM'));
      // In MB or bytes as defined; ramUsed is in MB: 2000, 2500
      expect(series[0].values, [2000.0, 2500.0]);
      expect(series[1].label, contains('Swap'));
      expect(series[1].values, [100.0, 100.0]);
    });

    test('builds Disk series', () {
      final series = rowsToDiskSeries(sampleRows);
      expect(series.length, 1);
      expect(series[0].values, [40000.0, 40000.0]);
    });

    test('builds Disk IO dual-series', () {
      final series = rowsToDiskIoSeries(sampleRows);
      expect(series.length, 2);
      expect(series[0].values, [512.0, 1024.0]);
      expect(series[1].values, [1024.0, 2048.0]);
    });

    test('builds System Load 3-series', () {
      final series = rowsToLoadSeries(sampleRows);
      expect(series.length, 3);
      expect(series[0].values, [0.15, 0.30]);
      expect(series[1].values, [0.20, 0.25]);
      expect(series[2].values, [0.25, 0.22]);
    });

    test('builds Connections dual-series', () {
      final series = rowsToConnSeries(sampleRows);
      expect(series.length, 2);
      expect(series[0].values, [50.0, 55.0]);
      expect(series[1].values, [20.0, 22.0]);
    });

    test('builds Processes series', () {
      final series = rowsToProcessSeries(sampleRows);
      expect(series.length, 1);
      expect(series[0].values, [120.0, 125.0]);
    });

    test('builds Ping 3-series preserving nulls for missing samples', () {
      final series = rowsToPingSeries(sampleRows);
      expect(series.length, 3);
      // CT: 30.0, 32.0
      expect(series[0].values, [30.0, 32.0]);
      // CU: 40.0, null
      expect(series[1].values, [40.0, null]);
      // CM: null, 45.0
      expect(series[2].values, [null, 45.0]);
    });

    test('detects whether node has any ping data across rows', () {
      expect(hasAnyPing(sampleRows), isTrue);

      const noPingRows = [
        CfHistoryRow(
          timestamp: 1000,
          cpu: 10,
          ramUsed: 0,
          ramTotal: 0,
          diskUsed: 0,
          diskTotal: 0,
          netInSpeed: 0,
          netOutSpeed: 0,
          tcpConn: 0,
          udpConn: 0,
          processes: 0,
          diskReadBps: 0,
          diskWriteBps: 0,
          swapUsed: 0,
          swapTotal: 0,
          loadAvg: '',
          pingCt: null,
          pingCu: null,
          pingCm: null,
        ),
      ];
      expect(hasAnyPing(noPingRows), isFalse);
    });
  });
}
