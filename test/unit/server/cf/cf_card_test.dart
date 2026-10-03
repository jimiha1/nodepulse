import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/cf/cf_server.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/data/store/setting.dart';
import 'package:server_box/view/page/server/cf_card.dart';

import '../../../helpers/test_db.dart';

/// One node with everything the card can show, built directly: the JSON
/// fixtures are [cf_server_test.dart]'s business, this one is about what the
/// widget does with the parsed model.
const _node = CfServer(
  id: 'n1',
  name: '日本节点',
  group: '家宽',
  region: 'jp',
  os: 'Ubuntu 22.04',
  online: true,
  cpu: 3.2,
  cpuCores: 4,
  ramUsed: 1024,
  ramTotal: 4096,
  swapUsed: 0,
  swapTotal: 0,
  diskUsed: 20480,
  diskTotal: 40960,
  load1: 0.42,
  load5: 0.3,
  load15: 0.2,
  netInSpeed: 1048576,
  netOutSpeed: 262144,
        netRxMonthly: 3221225472,
        netTxMonthly: 1073741824,
        netRx: 0,
        netTx: 0,
        tcpConn: 12,
        udpConn: 3,
        processes: 118,
        pingCt: 165,
        pingCm: 190,
  bootTime: 1750000000,
  expireDate: '2027-01-01',
  price: '5.0',
  trafficLimit: '500GB',
  trafficCalcType: 'total',
);

Future<void> _pump(
  WidgetTester tester, {
  bool showExpire = true,
  bool showPrice = true,
  CfServer node = _node,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CfServerCard(
          node: node,
          showExpire: showExpire,
          showPrice: showPrice,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() async {
    // The card reads `showDistMark` through the distro-icon seam, so the
    // setting store has to exist — in memory, per the helper's contract.
    await openTestDb();
    getIt.registerSingleton<SettingStore>(SettingStore('setting_test'));
  });

  tearDown(() async {
    await getIt.reset();
    await closeTestDb();
  });

  testWidgets('renders the fields a node carries', (tester) async {
    await _pump(tester);

    expect(find.text('日本节点'), findsOneWidget);
    expect(find.text('家宽'), findsOneWidget);
    // CPU as the brief's fixture says.
    expect(find.text('3.2%'), findsOneWidget);
    // Only the pings that exist get a line: CU is null here.
    expect(find.text('电信 165ms'), findsOneWidget);
    expect(find.text('移动 190ms'), findsOneWidget);
    expect(find.text('联通 --'), findsNothing);
    // Expiry, with the price beside it.
    expect(find.text('2027-01-01'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    // The node has a traffic limit, so what is left of it is shown — the
    // label is a span of a rich text, hence the containment match.
    expect(find.textContaining(l10n.cfTrafficRemaining), findsOneWidget);
  });

  testWidgets('hides what the site says not to show and what is absent', (
    tester,
  ) async {
    await _pump(
      tester,
      showExpire: false,
      showPrice: false,
      node: const CfServer(
        id: 'n1',
        name: '日本节点',
        group: '家宽',
        region: 'jp',
        os: 'Ubuntu 22.04',
        online: true,
        cpu: 3.2,
        ramUsed: 1024,
        ramTotal: 4096,
        swapUsed: 0,
        swapTotal: 0,
        diskUsed: 20480,
        diskTotal: 40960,
        load1: 0.42,
        load5: 0.3,
        load15: 0.2,
        netInSpeed: 1048576,
        netOutSpeed: 262144,
        netRxMonthly: 3221225472,
        netTxMonthly: 1073741824,
        netRx: 0,
        netTx: 0,
        tcpConn: 12,
        udpConn: 3,
        processes: 118,
      ),
    );

    expect(find.text('2027-01-01'), findsNothing);
    expect(find.text('5.0'), findsNothing);
  });

  testWidgets('an offline node carries no ping lines at all', (tester) async {
    await _pump(
      tester,
      node: const CfServer(
        id: 'n2',
        name: '离线节点',
        online: false,
        cpu: 0,
        ramUsed: 0,
        ramTotal: 0,
        swapUsed: 0,
        swapTotal: 0,
        diskUsed: 0,
        diskTotal: 0,
        load1: 0,
        load5: 0,
        load15: 0,
        netInSpeed: 0,
        netOutSpeed: 0,
        netRxMonthly: 0,
        netTxMonthly: 0,
        netRx: 0,
        netTx: 0,
        tcpConn: 0,
        udpConn: 0,
        processes: 0,
      ),
    );

    expect(find.text('离线节点'), findsOneWidget);
    expect(find.text('CT 165ms'), findsNothing);
    expect(find.text('CU --'), findsNothing);
    expect(find.text('CM 190ms'), findsNothing);
  });

  testWidgets('renders progress indicators and loss metrics for cf server', (tester) async {
    const server = CfServer(
      id: 's1',
      name: 'Tokyo Node',
      region: 'JP',
      group: 'Edge',
      os: 'Ubuntu 22.04',
      online: true,
      cpu: 45.0,
      cpuCores: 4,
      ramUsed: 4096,
      ramTotal: 8192,
      swapUsed: 0,
      swapTotal: 2048,
      diskUsed: 51200,
      diskTotal: 102400,
      load1: 0.15,
      load5: 0.20,
      load15: 0.18,
      netInSpeed: 1024000,
      netOutSpeed: 512000,
      netRxMonthly: 1000000000,
      netTxMonthly: 2000000000,
      netRx: 1000000000,
      netTx: 2000000000,
      tcpConn: 85,
      udpConn: 12,
      processes: 120,
      pingCt: 45.0,
      pingCu: 38.0,
      pingCm: 60.0,
      lossCt: 0.0,
      lossCu: 1.0,
      lossCm: 0.0,
      bootTime: 1750000000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CfServerCard(node: server),
        ),
      ),
    );

    expect(find.text('Tokyo Node'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    expect(find.textContaining('电信 45ms'), findsOneWidget);
    expect(find.textContaining('联通 38ms'), findsOneWidget);
    expect(find.textContaining('移动 60ms'), findsOneWidget);
    expect(find.text('0%'), findsNWidgets(2));
    expect(find.text('1%'), findsOneWidget);
  });
}
