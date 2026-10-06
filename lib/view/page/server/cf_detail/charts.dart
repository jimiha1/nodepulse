import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:nodepulse/core/extension/context/locale.dart';
import 'package:nodepulse/data/model/cf/cf_history.dart';
import 'package:nodepulse/view/page/server/chart.dart';

/// The 7 time ranges supported by CF history endpoints and live buffer.
enum CfHistoryRange {
  live,
  m30,
  h1,
  h6,
  d1,
  d2,
  d7,
}

extension CfHistoryRangeX on CfHistoryRange {
  /// The hours query parameter for `GET /api/history/all`.
  /// Null for [live].
  double? get hours => switch (this) {
        CfHistoryRange.live => null,
        CfHistoryRange.m30 => 0.5,
        CfHistoryRange.h1 => 1.0,
        CfHistoryRange.h6 => 6.0,
        CfHistoryRange.d1 => 24.0,
        CfHistoryRange.d2 => 48.0,
        CfHistoryRange.d7 => 168.0,
      };

  String get label => switch (this) {
        CfHistoryRange.live => l10n.cfRangeLive,
        CfHistoryRange.m30 => l10n.cfRangeM30,
        CfHistoryRange.h1 => l10n.cfRangeH1,
        CfHistoryRange.h6 => l10n.cfRangeH6,
        CfHistoryRange.d1 => l10n.cfRangeD1,
        CfHistoryRange.d2 => l10n.cfRangeD2,
        CfHistoryRange.d7 => l10n.cfRangeD7,
      };
}

/// Helper functions transforming [CfHistoryRow] list to [HistorySeries]

List<HistorySeries> rowsToCpuSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'CPU',
      Colors.blue,
      [for (final r in rows) r.cpu],
    ),
  ];
}

List<HistorySeries> rowsToNetSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'In',
      Colors.green,
      [for (final r in rows) r.netInSpeed.toDouble()],
    ),
    HistorySeries(
      'Out',
      Colors.blue,
      [for (final r in rows) r.netOutSpeed.toDouble()],
    ),
  ];
}

List<HistorySeries> rowsToMemSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'RAM',
      Colors.orange,
      [for (final r in rows) r.ramUsed.toDouble()],
    ),
    HistorySeries(
      'Swap',
      Colors.purple,
      [for (final r in rows) r.swapUsed.toDouble()],
    ),
  ];
}

List<HistorySeries> rowsToDiskSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'Disk',
      Colors.teal,
      [for (final r in rows) r.diskUsed.toDouble()],
    ),
  ];
}

List<HistorySeries> rowsToDiskIoSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'Read',
      Colors.green,
      [for (final r in rows) r.diskReadBps.toDouble()],
    ),
    HistorySeries(
      'Write',
      Colors.deepOrange,
      [for (final r in rows) r.diskWriteBps.toDouble()],
    ),
  ];
}

List<HistorySeries> rowsToLoadSeries(List<CfHistoryRow> rows) {
  final l1 = <double?>[];
  final l5 = <double?>[];
  final l15 = <double?>[];

  for (final r in rows) {
    final parts = r.loadAvg
        .split('|')
        .join(' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    double? at(int i) =>
        i < parts.length ? double.tryParse(parts[i]) : null;
    l1.add(at(0) ?? 0);
    l5.add(at(1) ?? 0);
    l15.add(at(2) ?? 0);
  }

  return [
    HistorySeries('1m', Colors.cyan, l1),
    HistorySeries('5m', Colors.amber, l5),
    HistorySeries('15m', Colors.indigoAccent, l15),
  ];
}

List<HistorySeries> rowsToConnSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'TCP',
      Colors.teal,
      [for (final r in rows) r.tcpConn.toDouble()],
    ),
    HistorySeries(
      'UDP',
      Colors.indigo,
      [for (final r in rows) r.udpConn.toDouble()],
    ),
  ];
}

List<HistorySeries> rowsToProcessSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      'Processes',
      Colors.purpleAccent,
      [for (final r in rows) r.processes.toDouble()],
    ),
  ];
}

List<HistorySeries> rowsToPingSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      '电信',
      Colors.blue,
      [for (final r in rows) r.pingCt],
    ),
    HistorySeries(
      '联通',
      Colors.green,
      [for (final r in rows) r.pingCu],
    ),
    HistorySeries(
      '移动',
      Colors.deepOrange,
      [for (final r in rows) r.pingCm],
    ),
  ];
}

List<HistorySeries> rowsToLossSeries(List<CfHistoryRow> rows) {
  return [
    HistorySeries(
      '电信',
      Colors.blue,
      [for (final r in rows) r.lossCt],
    ),
    HistorySeries(
      '联通',
      Colors.green,
      [for (final r in rows) r.lossCu],
    ),
    HistorySeries(
      '移动',
      Colors.deepOrange,
      [for (final r in rows) r.lossCm],
    ),
  ];
}

bool hasAnyLoss(List<CfHistoryRow> rows) {
  return rows.any(
    (r) => r.lossCt != null || r.lossCu != null || r.lossCm != null,
  );
}

bool hasAnyPing(List<CfHistoryRow> rows) {
  return rows.any(
    (r) => r.pingCt != null || r.pingCu != null || r.pingCm != null,
  );
}

/// A clean card container wrapping a title, optional subtitle/stats, and [MetricChart].
class CfChartCard extends StatelessWidget {
  const CfChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.series,
    required this.times,
    required this.format,
    this.binaryScale = false,
  });

  final String title;
  final String? subtitle;
  final List<HistorySeries> series;
  final List<int> times;
  final String Function(double) format;
  final bool binaryScale;

  @override
  Widget build(BuildContext context) {
    final spec = MetricChartSpec(
      series: series,
      times: times,
      format: format,
      binaryScale: binaryScale,
      height: 120,
      axis: 1,
    );

    return CardX(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: UIs.text15Bold),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: UIs.text12Grey),
              ],
            ),
            MetricChart(spec),
          ],
        ),
      ),
    );
  }
}
