import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/data/model/cf/cf_server.dart';
import 'package:nodepulse/data/provider/server/cf/cf_api.dart';
import 'package:nodepulse/data/provider/server/cf/cf_servers_provider.dart';
import 'package:nodepulse/data/res/store.dart';

/// A minimal slice of the live `GET /api/servers` response, enough for one
/// parsed node — the same fixture shape `cf_api_test.dart` uses.
const _serversRaw = '''
{"servers":[{"id":"a","name":"n1","cpu":3.2,"last_updated":1759410000000}],
 "stats":{"total":1,"online":0},"sysConfig":{}}''';

/// `CfApi` is concrete and its constructor only builds a `Dio` — no interface
/// worth extracting for one method, so the fake extends it and overrides the
/// one call the provider makes.
class _FakeCfApi extends CfApi {
  _FakeCfApi() : super(baseUrl: 'http://localhost');

  CfServersSnapshot? snapshot;
  Object? error;
  int fetches = 0;

  @override
  Future<CfServersSnapshot> fetchServers() async {
    fetches++;
    final error = this.error;
    if (error != null) throw error;
    return snapshot!;
  }
}

CfServersSnapshot _snapshotOf(String raw) =>
    CfServersSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sbm-cf-servers-');
    Paths.doc = tempDir.path;
  });

  tearDownAll(() async => tempDir.delete(recursive: true));

  setUp(() async {
    SqliteDb.openInMemory();
    await Stores.init();
    // Every test here is about a site that *is* configured: what the provider
    // does with it is the subject. Without one the provider answers `empty`
    // and sends nothing — see [hasCfSite] — which is a different behaviour and
    // has its own test below.
    Stores.setting.cfSiteUrl.put('https://status.example.com');
  });

  tearDown(() async {
    await getIt.reset();
    await SqliteDb.close();
  });

  test('refresh parses the snapshot and stores it', () async {
    final api = _FakeCfApi()..snapshot = _snapshotOf(_serversRaw);
    final container = ProviderContainer(
      overrides: [cfApiProvider.overrideWith((ref) => api)],
    );
    addTearDown(container.dispose);

    await container.read(cfServersProvider.notifier).refresh();

    final state = container.read(cfServersProvider);
    expect(state.value?.servers, hasLength(1));
    expect(state.value?.servers.single.name, 'n1');
    expect(state.value?.total, 1);
    expect(api.fetches, greaterThanOrEqualTo(1));
  });

  test('a failed fetch surfaces as an error state, not a thrown one', () async {
    final api = _FakeCfApi()
      ..snapshot = _snapshotOf(_serversRaw)
      ..error = const CfApiException(message: 'boom');
    final container = ProviderContainer(
      overrides: [cfApiProvider.overrideWith((ref) => api)],
    );
    addTearDown(container.dispose);

    await container.read(cfServersProvider.notifier).refresh();

    final state = container.read(cfServersProvider);
    expect(state.hasError, true);
    expect(state.error, isA<CfApiException>());
  });

  test('startAutoRefresh polls on the stored interval and stops when disposed',
      () {
    fakeAsync((async) {
      Stores.setting.cfUpdateInterval.put(1);
      final api = _FakeCfApi()..snapshot = _snapshotOf(_serversRaw);
      final container = ProviderContainer(
        overrides: [cfApiProvider.overrideWith((ref) => api)],
      );

      container.read(cfServersProvider.notifier).startAutoRefresh();
      final initial = api.fetches;

      async.elapse(const Duration(milliseconds: 2500));
      expect(api.fetches, greaterThanOrEqualTo(initial + 2));

      container.dispose();
      final atDispose = api.fetches;
      async.elapse(const Duration(seconds: 3));
      expect(api.fetches, atDispose);
    });
  });

  test('a rebuilt api is what the state watches, not one cached in build',
      () async {
    var api = _FakeCfApi()..snapshot = _snapshotOf(_serversRaw);
    final container = ProviderContainer(
      overrides: [cfApiProvider.overrideWith((ref) => api)],
    );
    addTearDown(container.dispose);

    await container.read(cfServersProvider.notifier).refresh();
    expect(container.read(cfServersProvider).value?.servers.single.name, 'n1');

    // Standing in for the rebuild a changed site URL produces: the api
    // provider is built anew, and this state — which watches it — must
    // follow, rather than keep the snapshot of the site it left.
    api = _FakeCfApi()
      ..snapshot = _snapshotOf('''
{"servers":[{"id":"b","name":"n2"}],"stats":{"total":1,"online":0},"sysConfig":{}}''');
    container.invalidate(cfApiProvider);

    await container.read(cfServersProvider.future);
    expect(container.read(cfServersProvider).value?.servers.single.name, 'n2');
  });

  group('no site configured', () {
    setUp(() => Stores.setting.cfSiteUrl.put(''));

    test('build answers empty without asking the api at all', () async {
      final api = _FakeCfApi()..snapshot = _snapshotOf(_serversRaw);
      final container = ProviderContainer(
        overrides: [cfApiProvider.overrideWith((ref) => api)],
      );
      addTearDown(container.dispose);

      final snap = await container.read(cfServersProvider.future);

      // The point is the missing request, not the empty list: an address that
      // is not configured used to be requested anyway, and the failure that
      // came back was retried by Riverpod into a ~38-second spinner.
      expect(api.fetches, 0);
      expect(snap.servers, isEmpty);
      expect(container.read(cfServersProvider).hasError, isFalse);
    });

    test('refresh stays empty rather than surfacing an error', () async {
      final api = _FakeCfApi()
        ..snapshot = _snapshotOf(_serversRaw)
        ..error = const CfApiException(message: 'should not be reached');
      final container = ProviderContainer(
        overrides: [cfApiProvider.overrideWith((ref) => api)],
      );
      addTearDown(container.dispose);

      await container.read(cfServersProvider.future);
      await container.read(cfServersProvider.notifier).refresh();

      final state = container.read(cfServersProvider);
      expect(api.fetches, 0);
      expect(state.hasError, isFalse);
      expect(state.value?.servers, isEmpty);
    });

    test('configuring a site afterwards makes the next poll read it', () async {
      final api = _FakeCfApi()..snapshot = _snapshotOf(_serversRaw);
      final container = ProviderContainer(
        overrides: [cfApiProvider.overrideWith((ref) => api)],
      );
      addTearDown(container.dispose);

      expect((await container.read(cfServersProvider.future)).servers, isEmpty);
      expect(api.fetches, 0);

      // What the settings page writes when an address is entered.
      Stores.setting.cfSiteUrl.put('https://status.example.com');

      // Coming back to the home page runs this — the resume path and the
      // auto-refresh timer both do. It is also the state's own guard being
      // re-read: the site is configured now, so the request goes out where it
      // was skipped a moment ago.
      await container.read(cfServersProvider.notifier).refresh();

      expect(api.fetches, greaterThanOrEqualTo(1));
      expect(
        container.read(cfServersProvider).value?.servers.single.name,
        'n1',
      );
    });
  });
}
