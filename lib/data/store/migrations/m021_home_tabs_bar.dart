import 'package:server_box/data/store/schema.dart';
import 'package:server_box/data/store/setting.dart';

/// Moves the last tab out of the five-button home bar used by older builds.
///
/// The setting used to contain every tab available to the home page. The
/// current setting contains only the tabs shown in the bar, with the rest
/// reached through "more", so the old five-item default has to be converted
/// once. A custom order is preserved; only the old set of five tabs is
/// recognized, which keeps this migration from changing a newer arrangement.
class HomeTabsBarMigration implements SchemaMigration {
  const HomeTabsBarMigration();


  static const appliedAt = 21;
  static const key = 'homeTabs';

  /// The default bar this migration converts, in the order a stored list held
  /// it. Named as the strings older builds wrote: the terminal and file tabs
  /// have since been removed from `AppTab`, so their entries here can no
  /// longer resolve against the enum and are matched against this list
  /// instead.
  static const legacyTabs = ['server', 'ssh', 'file'];

  @override
  int get from => appliedAt;

  @override
  Future<void> apply() async => applySync();

  void applySync() {
    final store = SettingStore.instance;
    final raw = store.get<Object>(key);
    if (raw is! List) return;

    // What each element named when this migration shipped: the tab name a
    // newer build stored, or the tab its index pointed at in the enum's
    // declaration order of the day. Unresolvable elements are dropped, and a
    // repeat is counted once — the same shape `AppTab.parseAppTabsFromObj`
    // gives a stored list.
    final names = <String>{};
    for (final e in raw) {
      final name = switch (e) {
        final String name => name,
        final int index when index >= 0 && index < legacyTabs.length =>
          legacyTabs[index],
        _ => null,
      };
      if (name != null) names.add(name);
    }
    if (names.length != legacyTabs.length ||
        !names.containsAll(legacyTabs.toSet())) {
      return;
    }

    final ok = store.set(
      key,
      names.take(names.length - 1).toList(),
      updateLastUpdateTsOnSet: false,
    );
    if (!ok) throw StateError('m021: writing "$key" failed');
  }
}
