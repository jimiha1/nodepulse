import 'package:fl_lib/fl_lib.dart';

/// Opens a fresh in-memory database.
Future<void> openTestDb() async {
  SqliteDb.openInMemory();
  SqliteDb.instance.execute('PRAGMA foreign_keys = ON;');
}

Future<void> closeTestDb() async {
  await Future<void>.delayed(Duration.zero);
  await SqliteDb.close();
}
