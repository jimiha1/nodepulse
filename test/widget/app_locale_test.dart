import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/app.dart';
import 'package:nodepulse/data/res/store.dart';
import 'package:nodepulse/data/store/setting.dart';

import '../helpers/test_db.dart';

/// Changing the language setting has to reach the page already on screen.
///
/// A fresh install lands on the CF home, whose strings are read in widgets
/// that the framework may reuse rather than rebuild — a `const` widget whose
/// text comes from the module-level `l10n` is canonicalized to one instance,
/// so `Element.updateChild` sees nothing new and skips it. The screen would
/// then keep the language it first built in until something else rebuilt it.
/// This is the test that says the setting reaches the page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingStore setting;

  setUp(() async {
    // The tables, not only a connection: the CF page reads the store.
    await openTestDb();
    setting = SettingStore('setting_test');
    getIt.registerSingleton<SettingStore>(setting);
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
    await closeTestDb();
  });

  testWidgets('the language setting reaches the page already on screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // A site is not configured, so the home says where to set one.
    expect(find.text('No monitor site yet'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).locale, isNull);

    setting.locale.put('zh');
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('zh'),
    );
    expect(find.text('No monitor site yet'), findsNothing);
    expect(find.text('还没有监控站点'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
