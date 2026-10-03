import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/data/store/migrations/all.dart';
import 'package:server_box/data/store/migrations/m021_home_tabs_bar.dart';
import 'package:server_box/data/store/schema.dart';
import 'package:server_box/data/store/setting.dart';

import '../helpers/test_db.dart';

void main() {
  late SettingStore store;
  late HomeTabsBarMigration migration;

  setUp(() {
    SqliteDb.openInMemory();
    store = SettingStore.instance;
    migration = HomeTabsBarMigration();
  });

  tearDown(closeTestDb);

  test('is registered as the step after the current schema', () {
    expect(migration.from, 21);
    // Relative, not absolute: pinning this as the newest step fails the day
    // another is added. See `m013_virt_key_names_test.dart`.
    expect(SchemaVersion.current, greaterThan(migration.from));
    expect(
      kSchemaMigrations.where((m) => m.from == migration.from),
      hasLength(1),
    );
  });

  test('moves the last item from the old all-tabs arrangement', () async {
    // A record written when the setting held every tab: it names tabs the
    // deleted domains took away, which no longer parse and are dropped before
    // the legacy set is recognized.
    store.set('homeTabs', [
      AppTab.server.name,
      'ssh',
      'file',
      'agent',
      'snippet',
    ]);

    await migration.apply();

    expect(store.get<List>('homeTabs'), [
      AppTab.server.name,
      'ssh',
    ]);
  });

  test('preserves the stored order while moving its last item', () async {
    store.set('homeTabs', [
      AppTab.server.name,
      'snippet',
      'file',
      'agent',
      'ssh',
    ]);

    await migration.apply();

    expect(store.get<List>('homeTabs'), [
      AppTab.server.name,
      'file',
    ]);
  });

  test('does not change a custom arrangement', () async {
    final custom = [AppTab.server.name, 'ssh'];
    store.set('homeTabs', custom);
    await migration.apply();
    expect(store.get<List>('homeTabs'), custom);

    final namesUnknown = ['unknown', AppTab.server.name, 'ssh'];
    store.set('homeTabs', namesUnknown);
    await migration.apply();
    expect(store.get<List>('homeTabs'), namesUnknown);
  });

  test('is idempotent', () async {
    store.set('homeTabs', [
      AppTab.server.name,
      'ssh',
      'file',
      'agent',
      'snippet',
    ]);

    await migration.apply();
    await migration.apply();

    expect(store.get<List>('homeTabs'), [
      AppTab.server.name,
      'ssh',
    ]);
  });
}
