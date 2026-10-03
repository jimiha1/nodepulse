import 'dart:async';

import 'package:fl_lib/fl_lib.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:server_box/data/model/cf/cf_history.dart';
import 'package:server_box/data/model/cf/cf_server.dart';
import 'package:server_box/data/provider/server/cf/cf_api.dart';
import 'package:server_box/data/provider/server/cf/cf_credentials.dart';
import 'package:server_box/data/provider/server/cf/cf_ws.dart';
import 'package:server_box/data/res/store.dart';

part 'cf_servers_provider.g.dart';

@Riverpod(keepAlive: true)
CfCredentials cfCredentials(Ref ref) {
  return CfCredentials(
    // The seam [CfCredentials.token] refreshes a stale token through: a real
    // login, so the fresh token it hands back is one the API itself holds —
    // see [cfApi]. Read, not watch: this runs at refresh time, which is
    // never during this provider's own build.
    login: (username, password) =>
        ref.read(cfApiProvider).performLogin(username, password),
  );
}

@Riverpod(keepAlive: true)
CfApi cfApi(Ref ref) {
  final url = Stores.setting.cfSiteUrl;
  final auth = Stores.setting.cfAuthEnabled;
  final api = CfApi(baseUrl: url.fetch());
  ref.onDispose(api.close);

  // The Dio inside carries the base URL, so a changed site is a new client —
  // and a new session, because the restore below runs again for it. The
  // switch saying whether the site needs a login governs whether there is a
  // session at all, so it rebuilds the client the same way.
  void rebuild() => ref.invalidateSelf();
  final urlListenable = url.listenable();
  final authListenable = auth.listenable();
  urlListenable.addListener(rebuild);
  authListenable.addListener(rebuild);
  ref.onDispose(() {
    urlListenable.removeListener(rebuild);
    authListenable.removeListener(rebuild);
  });

  final credentials = ref.watch(cfCredentialsProvider);

  // One login per launch, with the credentials stored by the site settings:
  // the API can only carry a token it minted itself, so a stored one that is
  // still fresh cannot simply be handed to it. Best-effort — a refused login
  // (a password rotated server-side, say) leaves the anonymous path, and the
  // first poll surfaces whatever a read without a session gets.
  //
  // The future is handed to the API as it starts ([CfApi.ready]), so the
  // first fetch waits it out instead of racing it: without that, a read sent
  // before the login landed goes out tokenless and comes back a 401 that
  // pins the page as an error for a whole interval.
  if (auth.fetch()) {
    api.attachRestore(_restore(api, credentials));
  }
  return api;
}

Future<void> _restore(CfApi api, CfCredentials credentials) async {
  try {
    final username = await credentials.username;
    final password = await credentials.password;
    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return;
    }
    await api.login(username, password);
  } catch (e, s) {
    Loggers.app.warning('CF session restore failed', e, s);
  }
}

/// The node list of the CF site, polled; the state the CF pages read.
@Riverpod(keepAlive: true)
class CfServers extends _$CfServers {
  Timer? _timer;
  CfWs? _ws;
  StreamController<void>? _wsStreamController;

  /// One up per [startAutoRefresh], so a restarted one cannot add a second
  /// timer beside the first: the ticks of a generation whose number the
  /// counter has passed simply reschedule nothing.
  int _generation = 0;

  @override
  Future<CfServersSnapshot> build() async {
    ref.onDispose(() {
      _stopAutoRefresh();
      _stopWs();
    });
    final api = ref.watch(cfApiProvider);
    // A private site's restore login starts the moment the API exists, and
    // this first fetch is the read it must not race — see [CfApi.ready].
    await api.ready;
    // Watched, not read: a changed site URL rebuilds the API, and this state
    // must then become the new site's, not keep the old one's snapshot.
    final snapshot = await api.fetchServers();
    _pushLiveBuffer(snapshot);
    return snapshot;
  }

  /// Pulls once, now. A failure is state, not an exception: the poll also
  /// runs on a timer nobody is awaiting, and an error a reader can render is
  /// worth more than a log line.
  Future<void> refresh() async {
    final api = ref.read(cfApiProvider);
    await api.ready;
    final snapshot = await AsyncValue.guard(api.fetchServers);
    if (!ref.mounted) return;
    if (snapshot.value case final data?) {
      _pushLiveBuffer(data);
    }
    state = snapshot;
  }

  /// Polls every `Stores.setting.cfUpdateInterval.fetch()` seconds — read
  /// again per tick, so a changed interval takes effect on the next one.
  ///
  /// The recursive-schedule shape of [ServersNotifier.startAutoRefresh]: the
  /// next tick is armed only after the previous fetch settled, so a slow
  /// site cannot stack polls, and a restarted one abandons the generation
  /// still in flight.
  void startAutoRefresh() {
    _stopAutoRefresh();
    final generation = ++_generation;

    void schedule() {
      if (generation != _generation) return;
      _timer = Timer(_interval, () async {
        try {
          await refresh();
        } catch (e, s) {
          Loggers.app.warning('CF auto refresh failed', e, s);
        } finally {
          if (generation == _generation) schedule();
        }
      });
    }

    schedule();
  }

  /// Initializes or re-initializes the WebSocket connection.
  void _initWs() {
    _stopWs();

    final siteUrl = Stores.setting.cfSiteUrl.fetch();
    if (siteUrl.isEmpty) return;

    final api = ref.read(cfApiProvider);
    _wsStreamController = StreamController<void>.broadcast();

    _ws = CfWs.connect(
      url: siteUrl,
      token: api.token,
      onConnected: () {
        Loggers.app.info('CfWs connected, pausing polling timer');
        _stopAutoRefresh();
      },
      onDisconnected: () {
        Loggers.app.info('CfWs disconnected, resuming polling timer');
        startAutoRefresh();
      },
      onSample: (serverId, data) {
        _applySample(serverId, data);
        _wsStreamController?.add(null);
      },
    );
  }

  void _applySample(String serverId, Map<String, dynamic> data) {
    final current = state.value;
    if (current == null) return;

    final index = current.servers.indexWhere((s) => s.id == serverId);
    if (index == -1) return;

    final oldServer = current.servers[index];
    final updatedServer = oldServer.copyWithMetrics(data);

    final updatedServers = List<CfServer>.from(current.servers);
    updatedServers[index] = updatedServer;

    _pushSingleServerLiveBuffer(updatedServer);

    // Compute updated snapshot
    state = AsyncValue.data(
      CfServersSnapshot(
        servers: updatedServers,
        total: current.total,
        online: updatedServers.where((s) => s.online).length,
        // Recompute fleet speed sums from updated servers so header reflects live spikes
        globalSpeedIn: updatedServers.fold<double>(0, (sum, s) => sum + s.netInSpeed),
        globalSpeedOut: updatedServers.fold<double>(0, (sum, s) => sum + s.netOutSpeed),
        globalNetRx: current.globalNetRx,
        globalNetTx: current.globalNetTx,
        showExpire: current.showExpire,
        showPrice: current.showPrice,
      ),
    );
  }

  void _pushSingleServerLiveBuffer(CfServer s) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = _liveBuffers.putIfAbsent(s.id, () => []);
    list.add(
      CfHistoryRow(
        timestamp: now,
        cpu: s.cpu,
        ramUsed: s.ramUsed,
        ramTotal: s.ramTotal,
        diskUsed: s.diskUsed,
        diskTotal: s.diskTotal,
        netInSpeed: s.netInSpeed,
        netOutSpeed: s.netOutSpeed,
        tcpConn: s.tcpConn,
        udpConn: s.udpConn,
        processes: s.processes,
        diskReadBps: 0,
        diskWriteBps: 0,
        swapUsed: s.swapUsed,
        swapTotal: s.swapTotal,
        loadAvg: '${s.load1} ${s.load5} ${s.load15}',
        pingCt: s.pingCt,
        pingCu: s.pingCu,
        pingCm: s.pingCm,
        lossCt: s.lossCt,
        lossCu: s.lossCu,
        lossCm: s.lossCm,
      ),
    );
    if (list.length > 120) {
      list.removeAt(0);
    }
  }

  void _stopWs() {
    _ws?.dispose();
    _ws = null;
    _wsStreamController?.close();
    _wsStreamController = null;
  }

  /// The WebSocket feed stream subscription.
  StreamSubscription<void> watchWs() {
    if (_ws == null) {
      _initWs();
    }
    return (_wsStreamController?.stream ?? const Stream<void>.empty())
        .listen((_) {});
  }

  /// Rolling live history buffer per server id (in-memory, up to ~120 samples).
  final Map<String, List<CfHistoryRow>> _liveBuffers = {};

  List<CfHistoryRow> getLiveBuffer(String serverId) =>
      _liveBuffers[serverId] ?? const [];

  void _pushLiveBuffer(CfServersSnapshot snapshot) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final s in snapshot.servers) {
      final list = _liveBuffers.putIfAbsent(s.id, () => []);
      list.add(
        CfHistoryRow(
          timestamp: now,
          cpu: s.cpu,
          ramUsed: s.ramUsed,
          ramTotal: s.ramTotal,
          diskUsed: s.diskUsed,
          diskTotal: s.diskTotal,
          netInSpeed: s.netInSpeed,
          netOutSpeed: s.netOutSpeed,
          tcpConn: s.tcpConn,
          udpConn: s.udpConn,
          processes: s.processes,
          diskReadBps: 0,
          diskWriteBps: 0,
          swapUsed: s.swapUsed,
          swapTotal: s.swapTotal,
          loadAvg: '${s.load1} ${s.load5} ${s.load15}',
          pingCt: s.pingCt,
          pingCu: s.pingCu,
          pingCm: s.pingCm,
          lossCt: s.lossCt,
          lossCu: s.lossCu,
          lossCm: s.lossCm,
        ),
      );
      if (list.length > 120) {
        list.removeAt(0);
      }
    }
  }

  void stopAutoRefresh() {
    _stopAutoRefresh();
  }

  void _stopAutoRefresh() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  /// No UI writes the interval yet, but a zero or negative that found its way
  /// into the store would turn the poll into a hot loop — the default is the
  /// floor.
  Duration get _interval {
    final seconds = Stores.setting.cfUpdateInterval.fetch();
    if (seconds <= 0) return const Duration(seconds: 10);
    return Duration(seconds: seconds);
  }
}

/// Fetches history rows for [id] over [hours].
@riverpod
Future<List<CfHistoryRow>> cfHistory(
  Ref ref, {
  required String id,
  required double hours,
}) async {
  final api = ref.watch(cfApiProvider);
  await api.ready;
  return api.fetchHistory(id: id, hours: hours);
}

