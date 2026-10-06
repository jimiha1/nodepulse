import 'dart:async';
import 'dart:convert';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nodepulse/core/chan.dart';
import 'package:nodepulse/data/model/cf/cf_server.dart';
import 'package:nodepulse/data/provider/server/cf/cf_credentials.dart';
import 'package:nodepulse/data/provider/server/cf/cf_servers_provider.dart';
import 'package:nodepulse/data/res/store.dart';

/// Keeps the home-screen widgets in sync with the CF-Server-Monitor site,
/// its access token, and available nodes.
///
/// Published JSON payload contract:
/// ```json
/// {
///   "siteUrl": "https://monitor.example.com",
///   "token": "jwt-or-null",
///   "tokenExpiresAt": 1759410000000,
///   "nodes": [
///     {"id": "uuid", "name": "Node name", "region": "JP"}
///   ]
/// }
/// ```
final class WidgetSync {
  WidgetSync._();

  static final instance = WidgetSync._();

  static const _pushDebounce = Duration(milliseconds: 500);

  Timer? _pushDebouncer;
  Future<void>? _pushing;
  bool _pushDirty = false;
  ProviderContainer? _container;

  List<CfServer> _latestNodes = [];
  String? _latestToken;
  int? _latestTokenExpiresAt;

  bool get _supported => isIOS || isAndroid;

  Future<void> init([ProviderContainer? container]) async {
    if (!_supported) return;
    if (container != null) {
      bindContainer(container);
    }
    Stores.setting.cfSiteUrl.listenable().addListener(_schedulePush);
    Stores.setting.cfAuthEnabled.listenable().addListener(_schedulePush);
    await push();
  }

  /// Binds the Riverpod container to listen for CF server updates.
  void bindContainer(ProviderContainer container) {
    _container = container;
    container.listen<AsyncValue<CfServersSnapshot>>(
      cfServersProvider,
      (previous, next) {
        if (next.value case final snapshot?) {
          updateSnapshot(snapshot);
        }
      },
      fireImmediately: true,
    );
  }

  void updateSnapshot(CfServersSnapshot snapshot) {
    _latestNodes = snapshot.servers;
    _schedulePush();
  }

  void updateToken(String? token, [int? expiresAt]) {
    _latestToken = token;
    _latestTokenExpiresAt = expiresAt;
    _schedulePush();
  }

  Future<void> push() {
    if (!_supported) return Future.value();
    _pushDirty = true;
    return _pushing ??= _drainPush();
  }

  Future<void> _drainPush() async {
    try {
      while (_pushDirty) {
        _pushDirty = false;
        await _pushOnce();
      }
    } finally {
      _pushing = null;
      if (_pushDirty) _pushing = _drainPush();
    }
  }

  Future<void> _pushOnce() async {
    final siteUrl = Stores.setting.cfSiteUrl.fetch().trim();
    if (siteUrl.isEmpty) {
      try {
        await MethodChans.publishWidgetServers(
          jsonEncode({
            'siteUrl': '',
            'token': null,
            'tokenExpiresAt': 0,
            'nodes': [],
          }),
        );
      } catch (e, s) {
        Loggers.app.warning('Publish empty widget servers', e, s);
      }
      return;
    }

    String? token = _latestToken;
    int tokenExpiresAt = _latestTokenExpiresAt ?? 0;

    // If container available, attempt to resolve token from cfApi or cfCredentials
    if (_container != null) {
      try {
        final apiToken = _container!.read(cfApiProvider).token;
        if (apiToken != null && apiToken.isNotEmpty) {
          token = apiToken;
          final exp = CfCredentials.expiryOf(apiToken);
          if (exp != null) {
            tokenExpiresAt = exp.millisecondsSinceEpoch;
          }
        }
      } catch (_) {}
    }

    final payload = payloadFrom(
      siteUrl: siteUrl,
      token: token,
      tokenExpiresAt: tokenExpiresAt,
      nodes: _latestNodes,
    );

    try {
      await MethodChans.publishWidgetServers(jsonEncode(payload));
    } catch (e, s) {
      Loggers.app.warning('Publish widget servers', e, s);
    }
  }

  @visibleForTesting
  static Map<String, dynamic> payloadFrom({
    required String siteUrl,
    required String? token,
    required int tokenExpiresAt,
    required List<CfServer> nodes,
  }) {
    final ordered = [...nodes]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return {
      'siteUrl': siteUrl,
      'token': token,
      'tokenExpiresAt': tokenExpiresAt,
      'nodes': [
        for (final node in ordered)
          {
            'id': node.id,
            'name': node.name,
            if (node.region != null && node.region!.isNotEmpty)
              'region': node.region,
          },
      ],
    };
  }

  void _schedulePush() {
    _pushDebouncer?.cancel();
    _pushDebouncer = Timer(_pushDebounce, () => unawaited(push()));
  }

  void dispose() {
    _pushDebouncer?.cancel();
    _pushDebouncer = null;
    _pushDirty = false;
  }
}
