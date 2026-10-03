import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/server/port_forward.dart';
import 'package:server_box/data/model/server/server_private_info.dart';
import 'package:server_box/data/model/server/ssh_credential.dart';
import 'package:server_box/data/store/port_forward.dart';
import 'package:server_box/data/store/server.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../helpers/test_db.dart';

void main() {
  late ServerStore servers;
  late PortForwardStore forwards;

  const original = Spi(
    id: 'server-old',
    name: 'production',
    ssh: SshCredential(ip: '10.0.0.1'),
  );
  const jumpOwner = Spi(
    id: 'jump-owner',
    name: 'through-production',
    ssh: SshCredential(ip: '10.0.0.2', jumpIds: ['server-old']),
  );
  const forward = PortForwardConfig(
    id: 'forward-1',
    serverId: 'server-old',
    name: 'postgres',
    type: PortForwardType.local,
    localPort: 15432,
  );

  setUp(() async {
    await openTestDb();
    forwards = PortForwardStore();
    servers = ServerStore(portForwards: forwards);
    servers.put(original);
    servers.put(jumpOwner);
    forwards.put(forward);
    SqliteDb.instance.execute(
      'INSERT INTO known_host (server_id, key_type, fingerprint) VALUES (?, ?, ?);',
      [original.id, 'ssh-ed25519', 'SHA256:old'],
    );
    SqliteDb.instance.execute('INSERT INTO container_host VALUES (?, ?, ?);', [
      original.id,
      'docker',
      'tcp://docker:2375',
    ]);
    SqliteDb.instance.execute('INSERT INTO container_runtime VALUES (?, ?);', [
      original.id,
      'podman',
    ]);
    SqliteDb.instance.execute(
      'INSERT INTO server_dist (server_id, dist, updated_at) VALUES (?, ?, ?);',
      [original.id, 'ubuntu', 1],
    );
    SqliteDb.instance.execute(
      'INSERT INTO conn_stat '
      '(id, server_id, server_name, timestamp, result, duration_ms) '
      'VALUES (?, ?, ?, ?, ?, ?);',
      ['stat-1', original.id, original.name, 1, 'success', 5],
    );
  });

  tearDown(closeTestDb);

  test('renaming moves every dependent row in one committed state', () async {
    // Prime the caches that a raw foreign-key update used to leave stale.
    expect(forwards.fetch().single.serverId, original.id);
    final forwardChanged = forwards.watch().first;

    final oldForwardRev =
        SqliteDb.instance.select('SELECT rev FROM port_forward WHERE id = ?;', [
              forward.id,
            ]).single['rev']
            as int;
    final oldOwnerRev =
        SqliteDb.instance.select('SELECT rev FROM server WHERE id = ?;', [
              jumpOwner.id,
            ]).single['rev']
            as int;

    final replacement = original.copyWith(id: 'server-new');
    servers.rename(original, replacement);
    await forwardChanged.timeout(const Duration(seconds: 1));

    expect(servers.fetchOneRaw(original.id), isNull);
    expect(servers.fetchOneRaw(replacement.id), replacement);
    expect(
      {
        for (final row in SqliteDb.instance.select(
          'SELECT key_type, fingerprint FROM known_host WHERE server_id = ?;',
          [replacement.id],
        ))
          row['key_type']: row['fingerprint'],
      },
      {'ssh-ed25519': 'SHA256:old'},
    );
    expect(forwards.fetch().single.serverId, replacement.id);
    expect(
      SqliteDb.instance
          .select('SELECT server_id FROM container_host;')
          .single['server_id'],
      replacement.id,
    );
    expect(
      SqliteDb.instance
          .select('SELECT server_id FROM container_runtime;')
          .single['server_id'],
      replacement.id,
    );
    expect(
      SqliteDb.instance
          .select('SELECT server_id FROM conn_stat;')
          .single['server_id'],
      replacement.id,
    );
    expect(
      SqliteDb.instance
          .select('SELECT server_id FROM server_dist;')
          .single['server_id'],
      replacement.id,
    );
    expect(servers.fetchOneRaw(jumpOwner.id)?.ssh?.jumpIds, [replacement.id]);

    expect(
      SqliteDb.instance.select('SELECT rev FROM port_forward WHERE id = ?;', [
        forward.id,
      ]).single['rev'],
      greaterThan(oldForwardRev),
    );
    expect(
      SqliteDb.instance.select('SELECT rev FROM server WHERE id = ?;', [
        jumpOwner.id,
      ]).single['rev'],
      greaterThan(oldOwnerRev),
    );
    expect(
      SqliteDb.instance.select(
        'SELECT count(*) AS n FROM tombstone WHERE tbl = ? AND row_id = ?;',
        ['server', original.id],
      ).single['n'],
      1,
    );
  });

  test('a failed replacement rolls the original graph back', () {
    // A carried table whose write alone is refused: the failure comes after
    // the rename's other writes, which have to be undone with it.
    SqliteDb.instance.execute('''
      CREATE TRIGGER refuse_conn_stat BEFORE UPDATE ON conn_stat
      BEGIN SELECT RAISE(ABORT, 'refused'); END;
    ''');

    expect(
      () => servers.rename(original, original.copyWith(id: 'server-new')),
      throwsA(isA<SqliteException>()),
    );

    servers.dropCache();
    expect(servers.fetchOneRaw(original.id), original);
    expect(forwards.fetchForServer(original.id), [forward]);
    expect({
      for (final row in SqliteDb.instance.select(
        'SELECT key_type, fingerprint FROM known_host WHERE server_id = ?;',
        [original.id],
      ))
        row['key_type']: row['fingerprint'],
    }, isNotEmpty);
    expect(
      SqliteDb.instance.select(
        'SELECT count(*) AS n FROM server WHERE id = ?;',
        ['server-new'],
      ).single['n'],
      0,
    );
  });

  test(
    'direct deletion invalidates child caches and stamps removed links',
    () async {
      expect(forwards.fetch(), [forward]);
      final forwardChanged = forwards.watch().first;

      servers.deleteById(original.id);
      await forwardChanged.timeout(const Duration(seconds: 1));

      expect(forwards.fetch(), isEmpty);
      expect(
        SqliteDb.instance.select(
          'SELECT count(*) AS n FROM tombstone '
          "WHERE tbl = 'port_forward' AND row_id = ?;",
          [forward.id],
        ).single['n'],
        1,
      );
      expect(
        servers.fetchOneRaw(jumpOwner.id)?.ssh?.jumpIds,
        anyOf(isNull, isEmpty),
      );
    },
  );
}
