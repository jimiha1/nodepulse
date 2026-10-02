/// One row of `GET /api/history/all`.
///
/// API.md §5.3 fixes the column list; every column is optional as far as this
/// parser is concerned, so a schema change or a partial row degrades to
/// zeroes/nulls instead of a broken chart.
class CfHistoryRow {
  final int timestamp; // ms
  final double cpu; // %
  final int ramUsed, ramTotal, diskUsed, diskTotal; // MB
  final int netInSpeed, netOutSpeed; // B/s
  final int tcpConn, udpConn, processes;
  final int diskReadBps, diskWriteBps; // B/s
  final int swapUsed, swapTotal; // MB
  final String loadAvg; // raw "x x x"; charts split it themselves
  final double? pingCt, pingCu, pingCm; // ms; null = timeout / not sampled
  final double? lossCt, lossCu, lossCm; // %

  const CfHistoryRow({
    required this.timestamp,
    required this.cpu,
    required this.ramUsed,
    required this.ramTotal,
    required this.diskUsed,
    required this.diskTotal,
    required this.netInSpeed,
    required this.netOutSpeed,
    required this.tcpConn,
    required this.udpConn,
    required this.processes,
    required this.diskReadBps,
    required this.diskWriteBps,
    required this.swapUsed,
    required this.swapTotal,
    required this.loadAvg,
    this.pingCt,
    this.pingCu,
    this.pingCm,
    this.lossCt,
    this.lossCu,
    this.lossCm,
  });

  static CfHistoryRow fromJson(Map<String, dynamic> j) => CfHistoryRow(
        timestamp: _int(j['timestamp']),
        cpu: _dbl(j['cpu']) ?? 0,
        ramUsed: _int(j['ram_used']),
        ramTotal: _int(j['ram_total']),
        diskUsed: _int(j['disk_used']),
        diskTotal: _int(j['disk_total']),
        netInSpeed: _int(j['net_in_speed']),
        netOutSpeed: _int(j['net_out_speed']),
        tcpConn: _int(j['tcp_conn']),
        udpConn: _int(j['udp_conn']),
        processes: _int(j['processes']),
        diskReadBps: _int(j['disk_read_bps']),
        diskWriteBps: _int(j['disk_write_bps']),
        swapUsed: _int(j['swap_used']),
        swapTotal: _int(j['swap_total']),
        loadAvg: j['load_avg'] is String ? j['load_avg'] as String : '',
        pingCt: _dbl(j['ping_ct']),
        pingCu: _dbl(j['ping_cu']),
        pingCm: _dbl(j['ping_cm']),
        lossCt: _dbl(j['loss_ct']),
        lossCu: _dbl(j['loss_cu']),
        lossCm: _dbl(j['loss_cm']),
      );
}

/// The same loose-typed readers as `cf_server.dart`, local to this file:
/// numbers may arrive as `null`, `false` (CF's "not configured"), or strings.

int _int(Object? v, [int fallback = 0]) => switch (v) {
      final int n => n,
      final num n => n.round(),
      final String s => int.tryParse(s) ?? double.tryParse(s)?.round() ?? fallback,
      _ => fallback,
    };

double? _dbl(Object? v) => switch (v) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };
