import 'dart:async';
import 'dart:convert';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/chan.dart';
import 'package:server_box/data/model/cf/cf_server.dart';
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

  /// The credential the last push actually sent, so a poll that changed
  /// nothing but the numbers does not push again — see [bindContainer].
  String? _pushedToken;

  bool get _supported => isAndroid;

  Future<void> init([ProviderContainer? container]) async {
    if (!_supported) return;
    if (container != null) {
      bindContainer(container);
    }
    Stores.setting.cfAlertsEnabled.listenable().addListener(_schedulePush);
    Stores.setting.cfAlertTrafficPct.listenable().addListener(_schedulePush);
    Stores.setting.cfAlertExpiryDays.listenable().addListener(_schedulePush);
    Stores.setting.cfResourceAlertRules.listenable().addListener(_schedulePush);
    Stores.setting.cfSiteUrl.listenable().addListener(_schedulePush);
    Stores.setting.cfAuthEnabled.listenable().addListener(_schedulePush);
    await push();
  }

  /// Binds the container, and re-pushes when the site's credential changes.
  ///
  /// The [init] push runs before the restore login has landed, so at that
  /// moment [CfApi.token] is still null and the native side is handed nothing
  /// to authenticate with — its worker then reads 401 on every run, for ever,
  /// because a background worker has no way to log in by itself.
  ///
  /// Watching [cfServersProvider] is what closes that window. Its first value
  /// is built only after `CfApi.ready`, i.e. after the login, so by then the
  /// token is there; the same listener also catches a later silent re-login,
  /// which mints a new token the native side would otherwise never see.
  ///
  /// Gated on the token changing rather than pushing on every value: the
  /// provider emits on each poll, ten seconds apart, and every push writes the
  /// native settings and re-enqueues the worker. Those are not things to do
  /// 8,640 times a day to say what has not changed. A settings change still
  /// pushes on its own — see the listeners [init] registers.
  void bindContainer(ProviderContainer container) {
    _container = container;
    container.listen<AsyncValue<CfServersSnapshot>>(
      cfServersProvider,
      (previous, next) {
        // Loading carries no snapshot, and therefore no credential to read.
        if (!next.hasValue) return;
        final token = _currentToken();
        if (token == _pushedToken) return;
        _pushedToken = token;
        _schedulePush();
      },
      fireImmediately: true,
    );
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

  /// The credential a push would send right now.
  ///
  /// The API's own token wins over [updateToken]'s, because the API is the
  /// thing that logs in: it holds a token this app never saw, and only it
  /// knows when a silent re-login replaced the last one.
  ///
  /// A failure to read it is logged rather than swallowed. That `catch` used
  /// to be empty, and it hid the whole reason the native side was left
  /// unauthenticated: a push that could not read a token looked exactly like
  /// one that read `null` on purpose.
  String? _currentToken() {
    final container = _container;
    if (container == null) return _latestToken;
    try {
      final apiToken = container.read(cfApiProvider).token;
      if (apiToken != null && apiToken.isNotEmpty) return apiToken;
    } catch (e, s) {
      Loggers.app.warning('Read the CF token for alerts', e, s);
    }
    return _latestToken;
  }

  Future<void> _pushOnce() async {
    final enabled = Stores.setting.cfAlertsEnabled.fetch();
    final trafficPct = Stores.setting.cfAlertTrafficPct.fetch();
    final expiryDays = Stores.setting.cfAlertExpiryDays.fetch();
    final resourceRules = Stores.setting.cfResourceAlertRules.fetch();
    final siteUrl = Stores.setting.cfSiteUrl.fetch().trim();

    final token = _currentToken();
    var tokenExpiresAt = _latestTokenExpiresAt ?? 0;
    if (token != null) {
      final exp = CfCredentials.expiryOf(token);
      if (exp != null) tokenExpiresAt = exp.millisecondsSinceEpoch;
    }

    final payload = {
      'enabled': enabled,
      'trafficPct': trafficPct,
      'expiryDays': expiryDays,
      'resourceRules': [for (final rule in resourceRules) rule.toJson()],
      'siteUrl': siteUrl,
      'token': token,
      'tokenExpiresAt': tokenExpiresAt,
    };

    try {
      await MethodChans.publishAlertSettings(jsonEncode(payload));
      // What was actually sent, not what was intended — the difference is the
      // whole bug this field guards against.
      _pushedToken = token;
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
