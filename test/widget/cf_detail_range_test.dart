/// Which range a [CfDetailPage] opens on.
///
/// The page is reached two ways and they want different things. The card in
/// the server list wants the freshest reading, and live is what that page did
/// before the range was a parameter. A tap from the home-screen widget wants
/// to see how the node has been — and live is only the buffer this app session
/// has collected, which for an app that very tap just launched is nothing.
library;

import 'package:fl_lib/fl_lib.dart';
// Prefixed: the page is built from `package:flutter/material.dart`, and its
// `ChoiceChip` is that library's type. This file's unprefixed `ChoiceChip`
// name would otherwise resolve to `material_ui`'s unrelated one, and the
// finder would match nothing.
import 'package:flutter/material.dart' as legacy;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/core/extension/context/locale.dart';
import 'package:nodepulse/data/model/cf/cf_history.dart';
import 'package:nodepulse/data/model/cf/cf_server.dart';
import 'package:nodepulse/data/provider/server/cf/cf_servers_provider.dart';
import 'package:nodepulse/data/res/store.dart';
import 'package:nodepulse/data/store/setting.dart';
import 'package:nodepulse/generated/l10n/l10n.dart';
import 'package:nodepulse/generated/l10n/l10n_zh.dart';
import 'package:nodepulse/view/page/server/cf_detail/charts.dart';
import 'package:nodepulse/view/page/server/cf_detail/view.dart';

import '../helpers/test_db.dart';

const _node = CfServer(
  id: 'n1',
  name: 'Osaka',
  online: true,
  cpu: 8,
  ramUsed: 1024,
  ramTotal: 2048,
  swapUsed: 0,
  swapTotal: 0,
  diskUsed: 1024,
  diskTotal: 4096,
  load1: 0.1,
  load5: 0.1,
  load15: 0.1,
  netInSpeed: 0,
  netOutSpeed: 0,
  netRxMonthly: 0,
  netTxMonthly: 0,
  netRx: 0,
  netTx: 0,
  tcpConn: 1,
  udpConn: 0,
  processes: 1,
);

/// Answers both providers from memory: this test is about which range the page
/// *asks for*, and a real fetch would only add a network error to read past.
class _FakeServers extends CfServers {
  @override
  Future<CfServersSnapshot> build() async => const CfServersSnapshot(
    servers: [_node],
    total: 1,
    online: 1,
    globalSpeedIn: 0,
    globalSpeedOut: 0,
    globalNetRx: 0,
    globalNetTx: 0,
    showExpire: true,
    showPrice: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await openTestDb();
    getIt.registerSingleton<SettingStore>(SettingStore('setting_test'));
  });
  tearDown(() async {
    await getIt.reset();
    await closeTestDb();
  });

  /// The ranges the page actually requested, in order.
  ///
  /// Recorded rather than asserted through the provider: the point is which
  /// hours went out on the wire, and the chip being selected is only the
  /// visible half of that.
  late List<double> asked;

  Future<void> pump(WidgetTester tester, {CfHistoryRange? range}) async {
    asked = [];
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cfServersProvider.overrideWith(_FakeServers.new),
          cfHistoryProvider.overrideWith((ref, arg) async {
            asked.add(arg.hours);
            return const <CfHistoryRow>[];
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Builder(
            builder: (ctx) {
              ctx.setLibL10n();
              l10n = AppLocalizationsZh();
              // The page is built from `package:flutter/material.dart` — its
              // `ChoiceChip` resolves Flutter's own `MaterialLocalizations`,
              // which is not what `material_ui`'s delegates provide. This is
              // the same bridge `app.dart` wraps the real tree in.
              // ignore: deprecated_member_use
              return MaterialUiCompatibilityBridge(
                child: CfDetailPage(
                  args: CfDetailArgs(id: 'n1', name: 'Osaka', range: range),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a widget tap opens on the hour, not live', (tester) async {
    await pump(tester, range: CfHistoryRange.h1);

    // The hour's data is what went out on the wire: 1.0 is what `h1` sends as
    // `hours`, and live sends nothing at all.
    expect(asked, contains(1.0));
    expect(asked, isNot(contains(0.0)));
    expect(_selectedChipLabel(tester), l10n.cfRangeH1);
  });

  testWidgets('the server list card still opens on live', (tester) async {
    // No range in the args is the card's call, and live is what it has always
    // meant — the fetch is the live buffer, so nothing goes out as history.
    await pump(tester);

    expect(asked, isEmpty);
    expect(_selectedChipLabel(tester), l10n.cfRangeLive);
  });
}

/// Which range chip is on.
///
/// Matched by predicate rather than by type: the page is built from
/// `package:flutter/material.dart`, so its `ChoiceChip` is Flutter's, while
/// this file's `ChoiceChip` name resolves to `material_ui`'s — two unrelated
/// types, and `find.byType` would match none of them. The row also scrolls
/// horizontally, so a label finder would miss the chips past the right edge.
String _selectedChipLabel(WidgetTester tester) {
  final chips = tester
      .widgetList(find.byWidgetPredicate((w) => w is legacy.ChoiceChip))
      .cast<legacy.ChoiceChip>()
      .where((c) => c.selected)
      .toList();
  expect(chips, hasLength(1), reason: 'exactly one range is selected');
  return ((chips.single.label) as Text).data!;
}
