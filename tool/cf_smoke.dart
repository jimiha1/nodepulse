// Smoke test against the real CF-Server-Monitor site. Manual, not CI:
//
//   dart run tool/cf_smoke.dart [baseUrl]
//
// Verifies the field assumptions of the CF adapter against live data — the
// public site needs no credentials, so plain reads prove the whole path.
import 'dart:io';

import 'package:nodepulse/data/provider/server/cf/cf_api.dart';

Future<void> main(List<String> args) async {
  final base = args.isEmpty ? 'https://monitor.example.com' : args.first;
  final api = CfApi(baseUrl: base);
  try {
    final snap = await api.fetchServers();
    stdout.writeln(
      'snapshot: total=${snap.total} online=${snap.online} '
      'speedIn=${snap.globalSpeedIn}B/s speedOut=${snap.globalSpeedOut}B/s '
      'showPrice=${snap.showPrice} showExpire=${snap.showExpire}',
    );
    for (final n in snap.servers) {
      final uptime = n.bootTime == null
          ? null
          : DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(n.bootTime! * 1000),
            );
      stdout.writeln(
        'node ${n.name} (${n.region}, ${n.os}): '
        'cpu=${n.cpu.toStringAsFixed(1)}%/${n.cpuCores}c '
        'ram=${n.ramUsed}/${n.ramTotal}MB disk=${n.diskUsed}/${n.diskTotal}MB '
        'load=${n.load1}/${n.load5}/${n.load15} '
        'net=${n.netInSpeed}/${n.netOutSpeed}B/s tcp=${n.tcpConn} udp=${n.udpConn} '
        'ping=${n.pingCt ?? '-'}/${n.pingCu ?? '-'}/${n.pingCm ?? '-'}ms '
        'online=${n.online} uptime=${uptime == null ? '-' : uptime.inHours}h '
        'quota=${n.trafficUsedRatio < 0 ? '-' : (n.trafficUsedRatio * 100).toStringAsFixed(1) + '%'} '
        'expire=${n.expireDate ?? '-'}',
      );
    }

    final first = snap.servers.firstOrNull;
    if (first == null) return;

    final raw = await api.fetchServerRaw(first.id);
    stdout.writeln('detail: keys=${raw.length} cpu=${raw['cpu']} '
        'gpu_info=${raw['gpu_info']}');

    final rows = await api.fetchHistory(id: first.id, hours: 0.5);
    stdout.writeln('history: ${rows.length} rows over 0.5h');
    if (rows.isNotEmpty) {
      final last = rows.last;
      stdout.writeln(
        'last row: cpu=${last.cpu.toStringAsFixed(1)}% '
        'ram=${last.ramUsed}/${last.ramTotal}MB '
        'diskW=${last.diskWriteBps}B/s conn=${last.tcpConn}/${last.udpConn} '
        'ping=${last.pingCt ?? '-'}/${last.pingCu ?? '-'}/${last.pingCm ?? '-'}ms',
      );
    }
  } finally {
    api.close();
  }
}
