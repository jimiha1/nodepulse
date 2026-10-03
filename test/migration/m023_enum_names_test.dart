import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/app/menu/server_func.dart';
import 'package:server_box/data/model/app/server_sort.dart';
import 'package:server_box/data/store/migrations/all.dart';
import 'package:server_box/data/store/migrations/m023_enum_names.dart';
import 'package:server_box/data/store/schema.dart';
import 'package:server_box/data/store/setting.dart';

import '../helpers/test_db.dart';

/// Two settings held an enum as `Enum.index`. An index means whatever the
/// build reading it says it means, and cases have been removed from
/// `ServerFuncBtn` — each removal shifting every value after it, silently,
/// because every index still resolves to some valid case.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the step', () {
    late SettingStore store;

    setUp(() {
      SqliteDb.openInMemory();
      store = SettingStore.instance;
    });

    tearDown(closeTestDb);

    test('is registered as the step after the current schema', () {
      final migration = EnumNamesMigration();
      expect(migration.from, 23);
      expect(SchemaVersion.current, greaterThan(migration.from));
      // Missing from the list throws `Missing schema migration from v23` at
      // launch on a device that has one, and nothing here would say so.
      expect(kSchemaMigrations.any((m) => m is EnumNamesMigration), isTrue);
      expect(
        kSchemaMigrations.last.from,
        SchemaVersion.current - 1,
        reason: 'the chain has to reach the current version',
      );
    });

    test('converts a stored button row to names', () {
      // 2 is `container` and 8 `power` in the nine-entry pre-m021 layout,
      // which is what an untagged row of small indexes falls back to — see
      // `legacyIndexNamesBeforeM021`. The ints are written as literals: they
      // name positions in that historical layout, not in today's enum, which
      // the trim has since shortened. 0 named `terminal` there, and an entry
      // the build no longer knows is dropped rather than resolved.
      store.set(EnumNamesMigration.btnsKey, [
        0,
        2,
        8,
      ], updateLastUpdateTsOnSet: false);

      EnumNamesMigration().applySync();

      expect(store.get<Object>(EnumNamesMigration.btnsKey), {
        'layout': 'current',
        'values': ['container', 'power'],
      });
    });

    test('converts the sort field', () {
      store.set(
        EnumNamesMigration.sortKey,
        ServerSortField.status.index,
        updateLastUpdateTsOnSet: false,
      );

      EnumNamesMigration().applySync();

      expect(store.get<Object>(EnumNamesMigration.sortKey), 'status');
    });

    test('an entry no case answers to is dropped, not shifted', () {
      // What a row written by a build with more cases looks like here. The
      // first two named `terminal` and `files`, both gone from the enum; the
      // third is an index past the end of today's values. None of the three
      // may name whatever sits at another's position, so all of them go.
      store.set(EnumNamesMigration.btnsKey, [
        'terminal',
        'files',
        ServerFuncBtn.values.length + 5,
      ], updateLastUpdateTsOnSet: false);

      EnumNamesMigration().applySync();

      expect(store.get<Object>(EnumNamesMigration.btnsKey), {
        'layout': 'current',
        'values': <String>[],
      });
    });

    test(
      'settings decoding keeps a tagged current-layout row as names',
      () {
        store.set(EnumNamesMigration.btnsKey, {
          'layout': 'current',
          'values': [
            ServerFuncBtn.users.name,
            ServerFuncBtn.scheduledTasks.name,
          ],
        });

        expect(store.serverFuncBtns.fetch(), [
          ServerFuncBtn.users.name,
          ServerFuncBtn.scheduledTasks.name,
        ]);
      },
    );

    test('writes a current layout marker for synchronized rows', () {
      store.serverFuncBtns.put([
        ServerFuncBtn.users.name,
        ServerFuncBtn.scheduledTasks.name,
      ]);

      expect(store.get<Object>(EnumNamesMigration.btnsKey), {
        'layout': 'current',
        'values': [
          ServerFuncBtn.users.name,
          ServerFuncBtn.scheduledTasks.name,
        ],
      });
    });

    test('runs twice without changing what it wrote', () {
      store.set(EnumNamesMigration.btnsKey, [
        ServerFuncBtn.container.index,
      ], updateLastUpdateTsOnSet: false);

      EnumNamesMigration().applySync();
      final once = store.get<Object>(EnumNamesMigration.btnsKey);
      EnumNamesMigration().applySync();

      expect(store.get<Object>(EnumNamesMigration.btnsKey), once);
    });

    test('leaves a store that holds nothing alone', () {
      EnumNamesMigration().applySync();

      expect(store.get<Object>(EnumNamesMigration.btnsKey), isNull);
      expect(store.get<Object>(EnumNamesMigration.sortKey), isNull);
    });
  });

  group('reading either shape', () {
    test('a name and an index both resolve', () {
      // `terminal` was an entry once; a row naming it now resolves to
      // nothing, the same way a misspelt one does.
      expect(ServerFuncBtn.byStored('terminal'), isNull);
      expect(ServerFuncBtn.byStored('container'), ServerFuncBtn.container);
      expect(
        ServerFuncBtn.byStored(ServerFuncBtn.power.index),
        ServerFuncBtn.power,
      );
      expect(
        ServerFuncBtn.byStored(
          ServerFuncBtn.scheduledTasks.index,
          legacyIntegerNames: ServerFuncBtn.legacyIndexNamesBeforeM021,
        ),
        isNull,
        reason: 'that position names `iperf` in the legacy layout, which is '
            'gone — and an entry gone from the enum resolves to nothing',
      );
      expect(
        ServerFuncBtn.namesFromStored({
          'layout': 'preM021',
          'values': [5, 6, 7, 8],
        }),
        // `iperf` and `portForward` sat at 5 and 7 there; both are gone, so
        // only what is left resolves.
        ['systemd', 'power'],
      );
      expect(
        ServerFuncBtn.namesFromStored({
          'layout': 'current',
          'values': [5, 6, 7, 8],
        }),
        ['scheduledTasks', 'firewall'],
      );
      expect(ServerFuncBtn.byStored('nothing-of-the-sort'), isNull);
      expect(ServerFuncBtn.byStored(ServerFuncBtn.values.length), isNull);
      expect(ServerFuncBtn.byStored(-1), isNull);
    });

    test('the sort field falls back rather than throwing', () {
      expect(ServerSortField.fromStored('status'), ServerSortField.status);
      expect(
        ServerSortField.fromStored(ServerSortField.name.index),
        ServerSortField.name,
      );
      expect(ServerSortField.fromStored('gone'), ServerSortField.manual);
      expect(ServerSortField.fromStored(null), ServerSortField.manual);
      expect(ServerSortField.fromStored(99), ServerSortField.manual);
    });
  });
}
