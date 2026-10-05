/// What the CF home page shows when a poll failed, and the way out of it.
///
/// The page is the app's first screen and on a phone its bottom bar — the one
/// other route into the settings — is what an error replaces. So the two
/// things this has to keep saying are that retrying is possible and that the
/// settings are reachable; a site that started requiring a login is only
/// fixable in the second, and the raw `DioException` never says so.
library;

import 'package:dio/dio.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/data/store/setting.dart';
import 'package:server_box/generated/l10n/l10n.dart';
import 'package:server_box/generated/l10n/l10n_zh.dart';
import 'package:server_box/view/page/server/cf_tab.dart';

import '../helpers/test_db.dart';

/// The error the app actually gets from a tokenless read: Dio's status check
/// throws before any of the CF code parses a body.
DioException _statusError(int code) => DioException(
  requestOptions: RequestOptions(path: '/api/servers'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/servers'),
    statusCode: code,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await openTestDb();
    // The settings page the last test opens reads the store for its pane
    // width and its switches, so it has to exist. Registered here rather than
    // in that one test because `getIt.reset()` in the teardown is shared.
    getIt.registerSingleton<SettingStore>(SettingStore('setting_test'));
  });
  tearDown(() async {
    await getIt.reset();
    await closeTestDb();
  });

  /// Pumps the view with the strings resolved the way a launch resolves them.
  ///
  /// Two globals have to be filled, not one, and they are in different
  /// libraries: `l10n` is the app's, which `app.dart` assigns from
  /// `AppLocalizations.of`, and `libL10n` reads fl_lib's own — set through
  /// `setLibL10n`, which is the same call the app makes. A bare `pumpWidget`
  /// does neither; the delegates only serve `AppLocalizations.of(context)`.
  Future<void> pump(WidgetTester tester, Object error) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(
        builder: (ctx) {
          ctx.setLibL10n();
          l10n = AppLocalizationsZh();
          return Scaffold(
            body: CfErrorView(error: error, onRetry: () {}),
          );
        },
      ),
    ),
  );

  testWidgets('a 401 says a login is needed, not the raw Dio text', (
    tester,
  ) async {
    await pump(tester, _statusError(401));

    expect(find.text('该站点需要登录'), findsOneWidget);
    // The text this replaced talked about status codes and Mozilla's
    // documentation, and never once said the site wanted credentials.
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.textContaining('developer.mozilla.org'), findsNothing);
  });

  testWidgets('the settings button is offered, and is the way out', (
    tester,
  ) async {
    await pump(tester, _statusError(401));

    // By text, not by type: `FilledButton.tonalIcon` builds a private
    // subclass, which `find.byType(FilledButton)` does not match.
    expect(find.text('打开设置'), findsOneWidget);
    // Both ways on: retrying the same failure is still there, because the
    // site may simply have been down.
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('a failure that is not the site refusing still shows itself', (
    tester,
  ) async {
    // A 500 is not something a reader can fix in the settings, so it is not
    // translated into advice — the error is shown as it is. The settings
    // button is still there, because a wrong address is the other thing this
    // page fails on and it is fixed in exactly one place.
    await pump(tester, _statusError(500));

    expect(find.textContaining('DioException'), findsOneWidget);
    expect(find.text('该站点需要登录'), findsNothing);
    expect(find.text('打开设置'), findsOneWidget);
  });

  testWidgets('the button opens the settings page', (tester) async {
    await pump(tester, _statusError(401));

    await tester.tap(find.text('打开设置'));
    await tester.pumpAndSettle();

    // Reached the settings rather than merely drawing a button: the CF site
    // entry is the page this whole change exists to make reachable.
    expect(find.text('CF 监控站点'), findsWidgets);
  });
}
