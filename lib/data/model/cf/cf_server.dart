import 'dart:convert';

/// One GPU of a node, parsed from the loosely typed `gpu_info` field.
///
/// API.md §5.1: REST usually delivers it as a JSON *string* of
/// `[{"id":..,"name":..,"info":..}]`, WebSocket/upstream may deliver a real
/// array, and the live site also sends `""`. `info` is the utilisation and
/// can be a number; optional keys (`mem_used`, `sm_clock`, …) are ignored.
class CfGpu {
  final String id;
  final String name;
  final String? info;

  const CfGpu({required this.id, required this.name, this.info});

  static CfGpu fromJson(Map<String, dynamic> j) => CfGpu(
        id: _str(j['id']) ?? '',
        name: _str(j['name']) ?? '',
        info: switch (j['info']) {
          null => null,
          final String s => s.isEmpty ? null : s,
          final Object v => '$v',
        },
      );
}

/// One node of `GET /api/servers`, hand-parsed rather than codegen'd: the
/// payload is a third-party API with loose types (`false` in place of
/// numbers, numbers as strings, empty strings in place of unset), and a
/// fault-tolerant read is shorter than a schema for it.
class CfServer {
  final String id, name;
  final String? group, region, os, arch, price, billingCycle, expireDate, trafficLimit;
  final String? trafficCalcType; // dl/down / ul/up / total/sum / min, unknown → the larger side
  final bool online; // derived from last_updated, see [_isOnline]
  final double cpu; // %
  final int? cpuCores;
  final String? cpuInfo;
  final int ramUsed, ramTotal, swapUsed, swapTotal, diskUsed, diskTotal; // MB
  final double load1, load5, load15; // parsed from load_avg, 0 when unreadable
  final int netInSpeed, netOutSpeed; // B/s
  final int netRxMonthly, netTxMonthly, netRx, netTx; // bytes
  final int tcpConn, udpConn, processes;
  final double? pingCt, pingCu, pingCm; // ms; null = timeout or not configured
  final double? lossCt, lossCu, lossCm; // %
  final int? bootTime; // seconds; uptime = now - bootTime
  final List<CfGpu> gpus;

  const CfServer({
    required this.id,
    required this.name,
    this.group,
    this.region,
    this.os,
    this.arch,
    this.price,
    this.billingCycle,
    this.expireDate,
    this.trafficLimit,
    this.trafficCalcType,
    required this.online,
    required this.cpu,
    this.cpuCores,
    this.cpuInfo,
    required this.ramUsed,
    required this.ramTotal,
    required this.swapUsed,
    required this.swapTotal,
    required this.diskUsed,
    required this.diskTotal,
    required this.load1,
    required this.load5,
    required this.load15,
    required this.netInSpeed,
    required this.netOutSpeed,
    required this.netRxMonthly,
    required this.netTxMonthly,
    required this.netRx,
    required this.netTx,
    required this.tcpConn,
    required this.udpConn,
    required this.processes,
    this.pingCt,
    this.pingCu,
    this.pingCm,
    this.lossCt,
    this.lossCu,
    this.lossCm,
    this.bootTime,
    this.gpus = const [],
  });

  static CfServer fromJson(Map<String, dynamic> j) {
    final loads = _loads(j['load_avg']);
    return CfServer(
      id: _str(j['id']) ?? '',
      name: _str(j['name']) ?? '',
      group: _str(j['server_group']),
      region: _str(j['region']),
      os: _str(j['os']),
      arch: _str(j['arch']),
      price: _str(j['price']),
      billingCycle: _str(j['billing_cycle']),
      expireDate: _str(j['expire_date']),
      trafficLimit: _str(j['traffic_limit']),
      trafficCalcType: _str(j['traffic_calc_type']),
      online: _isOnline(j),
      cpu: _dbl(j['cpu']) ?? 0,
      cpuCores: _intOpt(j['cpu_cores']),
      cpuInfo: _str(j['cpu_info']),
      ramUsed: _int(j['ram_used']),
      ramTotal: _int(j['ram_total']),
      swapUsed: _int(j['swap_used']),
      swapTotal: _int(j['swap_total']),
      diskUsed: _int(j['disk_used']),
      diskTotal: _int(j['disk_total']),
      load1: loads[0],
      load5: loads[1],
      load15: loads[2],
      netInSpeed: _int(j['net_in_speed']),
      netOutSpeed: _int(j['net_out_speed']),
      netRxMonthly: _int(j['net_rx_monthly']),
      netTxMonthly: _int(j['net_tx_monthly']),
      netRx: _int(j['net_rx']),
      netTx: _int(j['net_tx']),
      tcpConn: _int(j['tcp_conn']),
      udpConn: _int(j['udp_conn']),
      processes: _int(j['processes']),
      pingCt: _dbl(j['ping_ct']),
      pingCu: _dbl(j['ping_cu']),
      pingCm: _dbl(j['ping_cm']),
      lossCt: _dbl(j['loss_ct']),
      lossCu: _dbl(j['loss_cu']),
      lossCm: _dbl(j['loss_cm']),
      bootTime: _bootSeconds(j['boot_time']),
      gpus: _gpus(j['gpu_info']),
    );
  }

  /// Returns a copy of this server with incremental dynamic metric fields
  /// replaced by values in [data] (e.g. from WebSocket batchUpdate samples).
  /// Fields not present in [data] keep their existing values.
  CfServer copyWithMetrics(Map<String, dynamic> data) {
    final loads = data.containsKey('load_avg') ? _loads(data['load_avg']) : null;
    return CfServer(
      id: id,
      name: name,
      group: group,
      region: region,
      os: os,
      arch: arch,
      price: price,
      billingCycle: billingCycle,
      expireDate: expireDate,
      trafficLimit: trafficLimit,
      trafficCalcType: trafficCalcType,
      online: data.containsKey('last_updated') ? _isOnline(data) : online,
      cpu: data.containsKey('cpu') ? (_dbl(data['cpu']) ?? cpu) : cpu,
      cpuCores: data.containsKey('cpu_cores') ? _intOpt(data['cpu_cores']) : cpuCores,
      cpuInfo: data.containsKey('cpu_info') ? _str(data['cpu_info']) : cpuInfo,
      ramUsed: data.containsKey('ram_used') ? _int(data['ram_used'], ramUsed) : ramUsed,
      ramTotal: data.containsKey('ram_total') ? _int(data['ram_total'], ramTotal) : ramTotal,
      swapUsed: data.containsKey('swap_used') ? _int(data['swap_used'], swapUsed) : swapUsed,
      swapTotal: data.containsKey('swap_total') ? _int(data['swap_total'], swapTotal) : swapTotal,
      diskUsed: data.containsKey('disk_used') ? _int(data['disk_used'], diskUsed) : diskUsed,
      diskTotal: data.containsKey('disk_total') ? _int(data['disk_total'], diskTotal) : diskTotal,
      load1: loads != null ? loads[0] : load1,
      load5: loads != null ? loads[1] : load5,
      load15: loads != null ? loads[2] : load15,
      netInSpeed: data.containsKey('net_in_speed') ? _int(data['net_in_speed'], netInSpeed) : netInSpeed,
      netOutSpeed: data.containsKey('net_out_speed') ? _int(data['net_out_speed'], netOutSpeed) : netOutSpeed,
      netRxMonthly: data.containsKey('net_rx_monthly') ? _int(data['net_rx_monthly'], netRxMonthly) : netRxMonthly,
      netTxMonthly: data.containsKey('net_tx_monthly') ? _int(data['net_tx_monthly'], netTxMonthly) : netTxMonthly,
      netRx: data.containsKey('net_rx') ? _int(data['net_rx'], netRx) : netRx,
      netTx: data.containsKey('net_tx') ? _int(data['net_tx'], netTx) : netTx,
      tcpConn: data.containsKey('tcp_conn') ? _int(data['tcp_conn'], tcpConn) : tcpConn,
      udpConn: data.containsKey('udp_conn') ? _int(data['udp_conn'], udpConn) : udpConn,
      processes: data.containsKey('processes') ? _int(data['processes'], processes) : processes,
      pingCt: data.containsKey('ping_ct') ? _dbl(data['ping_ct']) : pingCt,
      pingCu: data.containsKey('ping_cu') ? _dbl(data['ping_cu']) : pingCu,
      pingCm: data.containsKey('ping_cm') ? _dbl(data['ping_cm']) : pingCm,
      lossCt: data.containsKey('loss_ct') ? _dbl(data['loss_ct']) : lossCt,
      lossCu: data.containsKey('loss_cu') ? _dbl(data['loss_cu']) : lossCu,
      lossCm: data.containsKey('loss_cm') ? _dbl(data['loss_cm']) : lossCm,
      bootTime: data.containsKey('boot_time') ? _bootSeconds(data['boot_time']) : bootTime,
      gpus: data.containsKey('gpu_info') ? _gpus(data['gpu_info']) : gpus,
    );
  }

  /// Used share of the monthly traffic quota: 0..1, or -1 when the node has
  /// no limit. Which counter counts follows CF-Server-Monitor's own frontend
  /// (`traffic_calc_type`): `dl`/`down` → received, `ul`/`up` → sent,
  /// `total`/`sum` → both, `min` → the smaller one, anything else → the
  /// larger one.
  double get trafficUsedRatio {
    final limitBytes = _limitToBytes(trafficLimit);
    if (limitBytes <= 0) return -1;
    final used = _usedBytes(trafficCalcType, netRxMonthly, netTxMonthly);
    return (used / limitBytes).clamp(0.0, 1.0);
  }

  /// The monthly quota in bytes, 0 when the node has none — the parsed form
  /// of the free-text `trafficLimit`, for a reader that shows what is left
  /// rather than the share [trafficUsedRatio] answers.
  int get trafficLimitBytes => _limitToBytes(trafficLimit);

  /// What this node has counted against [trafficLimitBytes] this month, by
  /// the same rule [trafficUsedRatio] follows.
  int get trafficUsedBytes =>
      _usedBytes(trafficCalcType, netRxMonthly, netTxMonthly);

  static bool _isOnline(Map<String, dynamic> j) =>
      DateTime.now().millisecondsSinceEpoch - _int(j['last_updated']) < 90_000;

  static List<CfGpu> _gpus(Object? v) {
    Object? raw = v;
    if (raw is String) {
      if (raw.isEmpty) return const [];
      try {
        raw = jsonDecode(raw);
      } on FormatException {
        return const [];
      }
    }
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) CfGpu.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  /// `load_avg` is `"x x x"` per API.md; some deployments pipe-separate it.
  static List<double> _loads(Object? v) {
    if (v is! String) return const [0, 0, 0];
    final parts = v
        .split('|')
        .join(' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    double at(int i) => i < parts.length ? double.tryParse(parts[i]) ?? 0 : 0;
    return [at(0), at(1), at(2)];
  }

  /// API.md: `boot_time` is a millisecond epoch *string*. Older producers
  /// may already send seconds — anything ≥ 1e11 can only be milliseconds
  /// (1e11 s would be the year 5138). Normalised to seconds so the
  /// interface's `uptime = now - bootTime` holds.
  static int? _bootSeconds(Object? v) {
    final n = switch (v) {
      final num n => n,
      final String s => int.tryParse(s) ?? double.tryParse(s),
      _ => null,
    };
    if (n == null) return null;
    return (n >= 1e11 ? n / 1000 : n).round();
  }

  /// Parses the free-text `traffic_limit` the way CF's own frontend does:
  /// unitless numbers are GB, a known suffix is binary (1024^n), and
  /// anything else falls back to raw bytes, defaulting to 0 (unlimited).
  static int _limitToBytes(Object? v) {
    switch (v) {
      case final num n:
        return n.isFinite ? (n * 1024 * 1024 * 1024).round() : 0;
      case final String s:
        final m = _limitUnit.firstMatch(s.trim());
        if (m == null) return double.tryParse(s.trim())?.round() ?? 0;
        final n = double.tryParse(m.group(1) ?? '') ?? 0;
        final unit = (m.group(2) ?? 'gb').toLowerCase();
        return (n * (_unitBytes[unit] ?? _unitBytes['gb']!)).round();
      default:
        return 0;
    }
  }

  static int _usedBytes(String? calcType, int rxMonthly, int txMonthly) {
    switch ((calcType ?? '').trim().toLowerCase()) {
      case 'ul' || 'up':
        return txMonthly;
      case 'dl' || 'down':
        return rxMonthly;
      case 'total' || 'sum':
        return rxMonthly + txMonthly;
      case 'min':
        return rxMonthly < txMonthly ? rxMonthly : txMonthly;
      default:
        return rxMonthly > txMonthly ? rxMonthly : txMonthly;
    }
  }
}

const _unitBytes = {
  'b': 1,
  'kb': 1024,
  'mb': 1024 * 1024,
  'gb': 1024 * 1024 * 1024,
  'tb': 1024 * 1024 * 1024 * 1024,
  'pb': 1024 * 1024 * 1024 * 1024 * 1024,
};

final _limitUnit = RegExp(r'^([\d.]+)\s*(b|kb|mb|gb|tb|pb)?$', caseSensitive: false);

/// The fields the interface models are numbers that the API may deliver as
/// `null`, `false` (CF's marker for "not configured"), or numeric strings —
/// these readers fold all of that into the fallbacks the interface pins.

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

int _int(Object? v, [int fallback = 0]) => switch (v) {
      final int n => n,
      final num n => n.round(),
      final String s => int.tryParse(s) ?? double.tryParse(s)?.round() ?? fallback,
      _ => fallback,
    };

int? _intOpt(Object? v) => v == null ? null : _int(v);

double? _dbl(Object? v) => switch (v) {
      // `false` is CF's "not configured"; it renders like a timeout, i.e. null.
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };

/// Top level of `GET /api/servers`: the node list plus site-wide counters.
class CfServersSnapshot {
  final List<CfServer> servers;
  final int total, online;
  final double globalSpeedIn, globalSpeedOut; // B/s
  final int globalNetRx, globalNetTx; // bytes
  final bool showExpire, showPrice;

  const CfServersSnapshot({
    required this.servers,
    required this.total,
    required this.online,
    required this.globalSpeedIn,
    required this.globalSpeedOut,
    required this.globalNetRx,
    required this.globalNetTx,
    required this.showExpire,
    required this.showPrice,
  });

  static CfServersSnapshot fromJson(Map<String, dynamic> j) {
    final stats = _map(j['stats']);
    final sys = _map(j['sysConfig']);
    return CfServersSnapshot(
      servers: [
        for (final e in j['servers'] as List? ?? const [])
          if (e is Map) CfServer.fromJson(Map<String, dynamic>.from(e)),
      ],
      total: _int(stats['total']),
      online: _int(stats['online']),
      globalSpeedIn: _dbl(stats['globalSpeedIn']) ?? 0,
      globalSpeedOut: _dbl(stats['globalSpeedOut']) ?? 0,
      globalNetRx: _int(stats['globalNetRx']),
      globalNetTx: _int(stats['globalNetTx']),
      showExpire: _bool(sys['show_expire']),
      showPrice: _bool(sys['show_price']),
    );
  }
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

bool _bool(Object? v) => switch (v) {
      final bool b => b,
      final String s => s == 'true' || s == '1',
      _ => false,
    };
