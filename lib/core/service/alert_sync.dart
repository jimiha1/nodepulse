import 'dart:async';
import 'dart:convert';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/chan.dart';
import 'package:server_box/data/provider/server/cf/cf_credentials.dart';
import 'package:server_box/data/provider/server/cf/cf_servers_provider.dart';
import 'package:server_box/data/res/store.dart';

/// Keeps the native alert scheduler (Android WorkManager) in sync with
/// alert settings, site URL, and auth credentials.
final class AlertSync {
  AlertSync._();

  static final instance = AlertSync._();

  static const _pushDebounce = Duration(milliseconds: 500);

  Timer? _pushDebouncer;
  Future<void>? _pushing;
  bool _pushDirty = false;
  ProviderContainer? _container;

  String? _latestToken;
  int? _latestTokenExpiresAt;

  bool get _supported => isAndroid;

  Future<void> init([ProviderContainer? container]) async {
    if (!_supported) return;
    if (container != null) {
      bindContainer(container);
    }
    Stores.setting.cfAlertsEnabled.listenable().addListener(_schedulePush);
    Stores.setting.cfAlertTrafficPct.listenable().addListener(_schedulePush);
    Stores.setting.cfAlertExpiryDays.listenable().addListener(_schedulePush);
    Stores.setting.cfSiteUrl.listenable().addListener(_schedulePush);
    Stores.setting.cfAuthEnabled.listenable().addListener(_schedulePush);
    await push();
  }

  void bindContainer(ProviderContainer container) {
    _container = container;
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
    final enabled = Stores.setting.cfAlertsEnabled.fetch();
    final trafficPct = Stores.setting.cfAlertTrafficPct.fetch();
    final expiryDays = Stores.setting.cfAlertExpiryDays.fetch();
    final siteUrl = Stores.setting.cfSiteUrl.fetch().trim();

    String? token = _latestToken;
    int tokenExpiresAt = _latestTokenExpiresAt ?? 0;

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

    final payload = {
      'enabled': enabled,
      'trafficPct': trafficPct,
      'expiryDays': expiryDays,
      'siteUrl': siteUrl,
      'token': token,
      'tokenExpiresAt': tokenExpiresAt,
    };

    try {
      await MethodChans.publishAlertSettings(jsonEncode(payload));
    } catch (e, s) {
      Loggers.app.warning('Publish alert settings failed', e, s);
    }
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
