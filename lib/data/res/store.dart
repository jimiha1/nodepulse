import 'package:fl_lib/fl_lib.dart';
import 'package:get_it/get_it.dart';
import 'package:server_box/data/store/server_dist.dart';
import 'package:server_box/data/store/setting.dart';

final GetIt getIt = GetIt.instance;

extension SyncSqlitePropWrite<T extends Object> on StoreProp<T> {
  void putSync(T value) {
    final sqlite = store;
    if (sqlite is! SqliteStore ||
        !sqlite.set(
          key,
          value,
          toObj: toObj,
          updateLastUpdateTsOnSet: updateLastUpdateTsOnSet,
        )) {
      throw StateError('failed to persist "$key"');
    }
  }
}

abstract final class Stores {
  static SettingStore get setting => getIt<SettingStore>();
  static ServerDistStore get serverDist => getIt<ServerDistStore>();

  static Future<void> init() async {
    getIt.registerLazySingleton<SettingStore>(() => SettingStore.instance);
    getIt.registerLazySingleton<ServerDistStore>(
      () => ServerDistStore.instance,
    );

    await SqliteStore.openDatabase();
    serverDist.dropCache();

    await setting.init();
    await setting.removeRetiredKeys();
  }
}
