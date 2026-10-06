import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/data/model/cf/cf_history.dart';
import 'package:nodepulse/data/model/cf/cf_server.dart';

/// A minimal representative slice of the real `GET /api/servers` response of
/// <https://monitor.example.com> — field names and shapes per
/// CF-Server-Monitor `API.md` §5.1 and the live site: `load_avg` is
/// space-separated, `ram_used` is fractional MB, `boot_time` is a
/// millisecond-epoch *string*, and traffic quota fields arrive as loose text.
const _raw = '''
{"servers":[{
  "id":"fd978320-c32c-474d-857a-3412a7526a7b","name":"日本节点","server_group":"Default",
  "region":"JP","os":"Debian GNU/Linux 13 (trixie)","arch":"arm64","cpu_info":"arm64 (x2)",
  "cpu":3.23,"cpu_cores":2,"load_avg":"0.22 0.17 0.17",
  "ram_total":12268,"ram_used":4987.9,"swap_total":0,"swap_used":0,
  "disk_total":100454,"disk_used":54886,
  "net_in_speed":13200,"net_out_speed":2980,"net_rx":3160000000,"net_tx":4500000000,
  "net_rx_monthly":3160000000,"net_tx_monthly":4500000000,
  "tcp_conn":34,"udp_conn":8,"processes":347,
  "ping_ct":165,"ping_cu":78,"ping_cm":310,"loss_ct":0,"loss_cu":0,"loss_cm":0,
  "boot_time":"1756000000000","expire_date":"2027-10-02","price":"39.90","billing_cycle":"year",
  "traffic_limit":"10TB","traffic_calc_type":"down","last_updated":1759410000000
}],
"stats":{"total":1,"online":1,"globalSpeedIn":13200,"globalSpeedOut":2980,
 "globalNetRx":3160000000,"globalNetTx":4500000000},
"sysConfig":{"show_price":true,"show_expire":true,"show_tf":true}}''';

/// Builds a single-node snapshot the way the endpoint wraps it.
CfServersSnapshot snapshotOf(Map<String, dynamic> node) =>
    CfServersSnapshot.fromJson({
      'servers': [node],
      'stats': const <String, dynamic>{},
      'sysConfig': const <String, dynamic>{},
    });

void main() {
  test('parses a CF server node', () {
    final s = CfServersSnapshot.fromJson(jsonDecode(_raw) as Map<String, dynamic>);
    final n = s.servers.single;
    expect(n.id, 'fd978320-c32c-474d-857a-3412a7526a7b');
    expect(n.name, '日本节点');
    expect(n.group, 'Default');
    expect(n.region, 'JP');
    expect(n.cpu, 3.23);
    expect(n.cpuCores, 2);
    expect(n.load1, 0.22);
    expect(n.load5, 0.17);
    expect(n.load15, 0.17);
    // The live site reports fractional MB; the interface carries whole MB.
    expect(n.ramUsed, 4988);
    expect(n.ramTotal, 12268);
    expect(n.netInSpeed, 13200);
    expect(n.netRxMonthly, 3160000000);
    expect(n.tcpConn, 34);
    expect(n.processes, 347);
    expect(n.pingCt, 165.0);
    expect(n.pingCm, 310.0);
    expect(n.lossCt, 0.0);
    // API.md delivers boot_time as a millisecond string; the interface
    // carries whole seconds so uptime is `now - bootTime`.
    expect(n.bootTime, 1756000000);
    expect(n.trafficUsedRatio, closeTo(3160000000 / 10995116277760, 1e-9));
    expect(n.expireDate, '2027-10-02');
    expect(n.billingCycle, 'year');
    expect(n.price, '39.90');
    expect(s.total, 1);
    expect(s.online, 1);
    expect(s.globalSpeedIn, 13200.0);
    expect(s.globalNetRx, 3160000000);
    expect(s.showPrice, isTrue);
    expect(s.showExpire, isTrue);
  });

  test('tolerates missing and false fields', () {
    final j = jsonDecode('{"servers":[{"id":"x","name":"n","ping_ct":false,"loss_cu":null,'
            '"traffic_limit":"500GB","traffic_calc_type":"total","net_rx_monthly":1000000000,'
            '"net_tx_monthly":2000000000,"expire_date":"","price":"","ram_used":123.4,'
            '"boot_time":"1788081803813",'
            '"gpu_info":"[{\\"id\\":\\"0\\",\\"name\\":\\"I9\\",\\"info\\":12.5}]"}],'
            '"stats":{},"sysConfig":{}}')
        as Map<String, dynamic>;
    final n = CfServersSnapshot.fromJson(j).servers.single;
    expect(n.pingCt, isNull);
    expect(n.lossCu, isNull);
    // `total` counts rx + tx towards the quota.
    expect(n.trafficUsedRatio, closeTo(3e9 / (500 * 1024 * 1024 * 1024.0), 1e-9));
    // An empty string is the site's way of saying "unset", same as absent.
    expect(n.expireDate, isNull);
    expect(n.price, isNull);
    expect(n.ramUsed, 123);
    expect(n.bootTime, 1788081804);
    expect(n.gpus.single.name, 'I9');
    expect(n.gpus.single.info, '12.5');
  });

  test('quota side and unitless limits follow the CF frontend', () {
    CfServer node(Map<String, dynamic> fields) =>
        snapshotOf(Map<String, dynamic>.from(fields)
          ..['id'] = 'x'
          ..['name'] = 'n'
          ..['net_rx_monthly'] = 3000000000
          ..['net_tx_monthly'] = 1000000000).servers.single;

    // The live site sends unitless numbers — its frontend reads those as GB.
    expect(
      node({'traffic_limit': '10000.0', 'traffic_calc_type': 'dl'}).trafficUsedRatio,
      closeTo(3000000000 / (10000 * 1024 * 1024 * 1024.0), 1e-9),
      reason: 'dl/down counts received bytes only',
    );
    expect(
      node({'traffic_limit': '1TB', 'traffic_calc_type': 'ul'}).trafficUsedRatio,
      closeTo(1000000000 / (1024 * 1024 * 1024 * 1024.0), 1e-9),
      reason: 'ul/up counts sent bytes only',
    );
    expect(
      node({'traffic_limit': '10TB', 'traffic_calc_type': 'weird'}).trafficUsedRatio,
      closeTo(3000000000 / (10 * 1024 * 1024 * 1024 * 1024.0), 1e-9),
      reason: 'unknown calc types take the larger of rx/tx, like the CF frontend',
    );
    expect(
      node({'traffic_limit': '10TB', 'traffic_calc_type': 'min'}).trafficUsedRatio,
      closeTo(1000000000 / (10 * 1024 * 1024 * 1024 * 1024.0), 1e-9),
    );
    expect(
      node({'traffic_calc_type': 'total'}).trafficUsedRatio,
      -1,
      reason: 'no limit means unlimited, shown as -1',
    );
    expect(
      node({'traffic_limit': '0', 'traffic_calc_type': 'total'}).trafficUsedRatio,
      -1,
      reason: 'a zero limit is unlimited too',
    );
  });

  test('online is derived from last_updated', () {
    final fresh = snapshotOf({'last_updated': DateTime.now().millisecondsSinceEpoch});
    expect(fresh.servers.single.online, isTrue);
    expect(fresh.online, 0, reason: 'stats.online counts what the server counted');
    final stale = snapshotOf({'last_updated': 1759410000000});
    expect(stale.servers.single.online, isFalse);
    expect(snapshotOf(const {}).servers.single.online, isFalse);
  });

  test('parses a history row with the fixed column list', () {
    // Shape of a real row of `GET /api/history/all` on the live site (§5.3).
    final j = jsonDecode('{"timestamp":1790927096022,"cpu":6.51,"gpu_info":"",'
            '"ram_total":11943,"ram_used":4912.875,"disk_total":100475,"disk_used":54846,'
            '"disk_read_bps":0,"disk_write_bps":117927,"processes":348,'
            '"net_in_speed":16115,"net_out_speed":9632,"tcp_conn":34,"udp_conn":7,'
            '"ping_ct":174,"ping_cu":82,"ping_cm":314,"ping_bd":false,'
            '"loss_ct":0,"loss_cu":0,"loss_cm":0,'
            '"swap_total":0,"swap_used":0,"load_avg":"0.04 0.12 0.15","region":"JP"}')
        as Map<String, dynamic>;
    final row = CfHistoryRow.fromJson(j);
    expect(row.timestamp, 1790927096022);
    expect(row.cpu, 6.51);
    expect(row.ramUsed, 4913);
    expect(row.ramTotal, 11943);
    expect(row.diskUsed, 54846);
    expect(row.diskWriteBps, 117927);
    expect(row.netInSpeed, 16115);
    expect(row.netOutSpeed, 9632);
    expect(row.tcpConn, 34);
    expect(row.udpConn, 7);
    expect(row.processes, 348);
    expect(row.swapUsed, 0);
    expect(row.swapTotal, 0);
    expect(row.loadAvg, '0.04 0.12 0.15');
    expect(row.pingCt, 174.0);
    expect(row.pingCu, 82.0);
    expect(row.pingCm, 314.0);
    expect(row.lossCt, 0.0);
    expect(row.lossCm, 0.0);
  });

  test('history rows survive missing and false columns', () {
    final row = CfHistoryRow.fromJson(
      jsonDecode('{"timestamp":42,"cpu":false,"ping_ct":false,"loss_cu":null}')
          as Map<String, dynamic>,
    );
    expect(row.timestamp, 42);
    expect(row.cpu, 0.0, reason: 'a false reading charts as no data, i.e. zero');
    expect(row.pingCt, isNull);
    expect(row.lossCu, isNull);
    expect(row.ramTotal, 0);
    expect(row.diskWriteBps, 0);
    expect(row.loadAvg, '');
  });
}
