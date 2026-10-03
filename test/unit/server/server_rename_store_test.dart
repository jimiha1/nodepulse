import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/server/server_private_info.dart';
import 'package:server_box/data/model/server/ssh_credential.dart';
import 'package:server_box/data/store/server.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../helpers/test_db.dart';

void main() {
  late ServerStore servers;

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

  /// A child row of the `port_forward` table, seeded by hand: the store that
  /// owned these rows is gone with the terminal-and-files trim, but the table
  /// and the rename-and-delete cascades that maintain it stay, and this is
  /// the one test holding them to it.
  void seedForward({
    String id = 'forward-1',
    String serverId = 'server-old',
  }) {
    SqliteDb.instance.execute(
      'INSERT INTO port_forward '
      '(id, server_id, name, type, local_host, local_port, remote_host, '
      'remote_port, updated_at, rev) '
      "VALUES (?, ?, 'postgres', 'local', NULL, 15432, NULL, NULL, 0, 0);",
      [id, serverId],
    );
  }

  setUp(() async {
    await openTestDb();
    servers = ServerStore();
    servers.put(original);
    servers.put(jumpOwner);
    seedForward();
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

  int forwardRev(String id) =>
      SqliteDb.instance.select('SELECT rev FROM port_forward WHERE id = ?;', [
        id,
      ]).single['rev']
          as int;

  test('renaming moves every dependent row in one committed state', () async {
    final oldForwardRev = forwardRev('forward-1');
    final oldOwnerRev =
        SqliteDb.instance.select('SELECT rev FROM server WHERE id = ?;', [
              jumpOwner.id,
            ]).single['rev']
            as int;

    final replacement = original.copyWith(id: 'server-new');
    servers.rename(original, replacement);

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
    expect(
      SqliteDb.instance
          .select('SELECT server_id FROM port_forward;')
          .single['server_id'],
      replacement.id,
    );
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
      forwardRev('forward-1'),
      greaterThan(oldForwardRev),
      reason: 'the carried row is stamped, so sync hears about the move',
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
    expect(
      SqliteDb.instance.select('SELECT count(*) AS n FROM port_forward;')
          .single['n'],
      1,
    );
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
    'direct deletion stamps removed child rows and drops the links',
    () async {
      servers.deleteById(original.id);

      expect(
        SqliteDb.instance.select('SELECT count(*) AS n FROM port_forward;')
            .single['n'],
        0,
      );
      expect(
        SqliteDb.instance.select(
          'SELECT count(*) AS n FROM tombstone '
          "WHERE tbl = 'port_forward' AND row_id = ?;",
          ['forward-1'],
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
