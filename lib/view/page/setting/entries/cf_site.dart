part of '../entry.dart';

/// The CF-Server-Monitor site the CF pages read: where it is, whether reading
/// it needs a login, and the one login the app keeps for it.
///
/// Its own page rather than rows in the server group's settings, because what
/// it configures is not this app but another one — a site this build talks to.
/// The URL is saved as it is submitted; the credentials are saved as they are
/// submitted too, and the same submit logs in, because an API instance can
/// only carry a token it minted itself. The connection test does both again
/// and adds the one read that says the site answers.
final class CfSiteSettingsPage extends ConsumerStatefulWidget {
  const CfSiteSettingsPage({super.key});

  @override
  ConsumerState<CfSiteSettingsPage> createState() =>
      _CfSiteSettingsPageState();
}

final class _CfSiteSettingsPageState extends ConsumerState<CfSiteSettingsPage> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  // Masked by the controller rather than by `obscureText`, which is what
  // raises the secure keyboard — see [MaskedInput].
  final _pwdCtrl = MaskedTextEditingController();
  final _expiryDaysCtrl = TextEditingController();

  /// Re-entry guard for the test below: a slow site and an impatient finger
  /// would otherwise stack two logins and two reads.
  bool _testing = false;

  /// The same guard for [checkNow]: the check is a network round trip too.
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = Stores.setting.cfSiteUrl.fetch();
    // The credentials are read from the keystore asynchronously. What comes
    // back is put into the fields so a re-test does not need re-typing;
    // whatever is already there — the user typed faster than the keystore
    // answered — is left alone.
    final credentials = ref.read(cfCredentialsProvider);
    unawaited(_fill(credentials.username, _userCtrl));
    unawaited(_fill(credentials.password, _pwdCtrl));
  }

  Future<void> _fill(Future<String?> stored, TextEditingController ctrl) async {
    final value = await stored;
    if (value != null && value.isNotEmpty && ctrl.text.isEmpty) {
      ctrl.text = value;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _pwdCtrl.dispose();
    _expiryDaysCtrl.dispose();
    super.dispose();
  }

  /// Saves the address, refusing one the login must not be posted to.
  ///
  /// The password goes out on this connection, so a plaintext address is not
  /// a preference to honour: `http://` puts it on the wire in the clear, and
  /// the WebSocket that follows carries the token the same way. The widget
  /// side has always refused this (`WidgetApi.get` throws on a non-HTTPS
  /// URL); this is the same rule on the app's own path, which is where the
  /// password is typed.
  ///
  /// Loopback is allowed through — `isSecureRemoteEndpoint` says so, and a
  /// site being developed on this machine is reached over HTTP. Nothing is
  /// stored on a refusal, so the previously good address stays in effect.
  void _saveUrl(String raw) {
    final url = raw.trim();
    if (url == Stores.setting.cfSiteUrl.fetch()) return;

    final uri = Uri.tryParse(url);
    if (uri == null || !isSecureRemoteEndpoint(uri)) {
      context.showErrDialog(l10n.cfSiteHttpsRequired);
      return;
    }

    // The provider holding the API listens for exactly this, and rebuilds
    // its client — nothing else to notify here.
    Stores.setting.cfSiteUrl.put(url);
  }

  /// Log in as needed, then read the node list once, and say which happened.
  ///
  /// This is also where typed credentials are persisted *with* their token:
  /// [CfApi.performLogin] returns it, and the set is complete only with one —
  /// which is why [_saveCredentials] logs in as well when it stores the pair
  /// alone.
  Future<void> _test() async {
    if (_testing) return;
    setState(() => _testing = true);
    try {
      final api = ref.read(cfApiProvider);
      if (Stores.setting.cfAuthEnabled.fetch()) {
        final username = _userCtrl.text.trim();
        final password = _pwdCtrl.text;
        if (username.isNotEmpty && password.isNotEmpty) {
          final token = await api.performLogin(username, password);
          await ref
              .read(cfCredentialsProvider)
              .save(username: username, password: password, token: token);
        }
        // Either field empty: whatever is stored — possibly nothing — is what
        // the read below is tested with, and its answer says so.
      }
      final snapshot = await api.fetchServers();
      if (!mounted) return;
      await context.showRoundDialog(
        title: libL10n.success,
        child: Text(l10n.cfTestOk(snapshot.servers.length)),
      );
    } catch (e, s) {
      Loggers.app.warning('CF connection test failed', e, s);
      if (!mounted) return;
      await context.showRoundDialog(title: l10n.cfTestFail, child: Text('$e'));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  /// Runs one alert check now and says what it found.
  ///
  /// The periodic worker's slot can be fifteen minutes away, and an alert
  /// whose threshold is not met yet posts nothing at all — so without this,
  /// "configured correctly" and "never going to fire" are indistinguishable
  /// to the user who just set a threshold.
  ///
  /// The check is native, and it is the same one the worker runs: running a
  /// second implementation here would let the button report one thing while
  /// the background job did another.
  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);

    // Cleared as soon as the answer is in, not when the dialog closes: the
    // spinner belongs to the check, and leaving it turning under a dialog that
    // already holds the result reads as a check still running.
    Map<String, Object?>? result;
    try {
      result = await MethodChans.checkAlertsNow();
    } catch (e, s) {
      Loggers.app.warning('Alert check failed', e, s);
      result = null;
    } finally {
      if (mounted) setState(() => _checking = false);
    }

    if (!mounted) return;
    if (result == null) {
      await context.showRoundDialog(
        title: l10n.cfAlertCheckNow,
        child: Text(l10n.cfAlertCheckNetwork),
      );
      return;
    }
    if (result['ok'] != true) {
      await context.showRoundDialog(
        title: l10n.cfAlertCheckNow,
        child: Text(_checkFailureText('${result['reason']}')),
      );
      return;
    }

    // Three different answers, and `notified` alone cannot tell them apart:
    // zero means either "nothing qualified" or "already sent today", and a
    // user pressing the button twice is owed the difference. The suppressed
    // list is what separates them, and its contents are the alert that would
    // have been sent — shown so the second press explains itself rather than
    // reading as a check that did nothing.
    final count = result['checked'] as int? ?? 0;
    final notified = result['notified'] as int? ?? 0;
    final suppressed = _suppressedOf(result);
    await context.showRoundDialog(
      title: l10n.cfAlertCheckNow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch ((notified, suppressed.isEmpty)) {
              // Sent: say how many.
              (final n, _) when n > 0 => l10n.cfAlertCheckOk(count, n),
              // Nothing sent, but something qualified and was held back:
              // the reminder already went out today.
              (_, false) => l10n.cfAlertCheckSuppressed(count),
              // Nothing qualified at all — the ordinary, reassuring answer.
              _ => l10n.cfAlertCheckClear(count),
            },
          ),
          for (final (title, text) in suppressed) ...[
            const SizedBox(height: 9),
            Text(title, style: UIs.text13Bold),
            Text(text, style: UIs.text13Grey),
          ],
        ],
      ),
    );
  }

  /// The `[[title, text], ...]` the native side reports, defensively read.
  ///
  /// The value crosses a method channel, so its shape is the other side's
  /// promise and not a type the compiler checks here; anything unexpected is
  /// dropped rather than thrown, because losing a line of detail is a better
  /// outcome than a dialog that never opens.
  List<(String, String)> _suppressedOf(Map<String, Object?> result) {
    final raw = result['suppressed'];
    if (raw is! List) return const [];
    final out = <(String, String)>[];
    for (final entry in raw) {
      if (entry is List && entry.length >= 2) {
        final title = entry[0];
        final text = entry[1];
        if (title is String && text is String) out.add((title, text));
      }
    }
    return out;
  }

  /// The sentence for one of [MethodChans.checkAlertsNow]'s failure codes.
  ///
  /// The codes are built natively, where the l10n files are not reachable, so
  /// the mapping lives here; an unrecognised one falls back to the network
  /// wording rather than showing a raw identifier.
  String _checkFailureText(String reason) => switch (reason) {
        'no_site' => l10n.cfAlertCheckNoSite,
        'no_token' => l10n.cfAlertCheckNoToken,
        'auth' => l10n.cfAlertCheckAuth,
        _ => l10n.cfAlertCheckNetwork,
      };

  /// Persists the typed credentials as they are submitted, and logs in with
  /// them when nothing has yet: a stored pair alone becomes a session only
  /// through a login — the same one the launch restore runs — so saving it
  /// without minting a token would leave this session reading anonymously
  /// (and failing, on a private site) until the app restarted.
  ///
  /// A refused login is logged and otherwise swallowed: the credentials are
  /// kept regardless — a site that is down this minute is not a reason to
  /// make anyone retype a password — and the connection test is where a
  /// failure is said out loud.
  Future<void> _saveCredentials(String _) async {
    final username = _userCtrl.text.trim();
    final password = _pwdCtrl.text;
    if (!Stores.setting.cfAuthEnabled.fetch() ||
        username.isEmpty ||
        password.isEmpty) {
      return;
    }
    try {
      final credentials = ref.read(cfCredentialsProvider);
      await credentials.saveCredentials(username: username, password: password);
      final token = await ref
          .read(cfApiProvider)
          .performLogin(username, password);
      await credentials.saveToken(token);
    } catch (e, s) {
      Loggers.app.warning('CF credential submit failed', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(13),
        children: [
          CardX(
            child: Input(
              controller: _urlCtrl,
              label: l10n.cfSite,
              hint: l10n.cfSiteUrlHint,
              icon: Icons.link,
              // Suggestions are left on, and the keyboard type is left to
              // inference. Suppressing suggestions on a text field makes the
              // engine ask for `TYPE_TEXT_VARIATION_VISIBLE_PASSWORD` (0x90),
              // whose low byte is the password bit — the same one the secure
              // keyboard is raised for. `suggestion: false` here was the whole
              // reason this field, which is not a password field, brought up
              // the secure keyboard.
              onSubmitted: _saveUrl,
            ),
          ),
          CardX(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.cfAuth),
              trailing: StoreSwitch(prop: Stores.setting.cfAuthEnabled),
            ),
          ),
          ValBuilder(
            listenable: Stores.setting.cfAuthEnabled.listenable(),
            builder: (on) => on
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardX(
                        child: Input(
                          controller: _userCtrl,
                          label: l10n.cfUsername,
                          icon: Icons.person_outline,
                          onSubmitted: _saveCredentials,
                        ),
                      ),
                      CardX(
                        child: MaskedInput(
                          controller: _pwdCtrl,
                          label: l10n.cfPassword,
                          icon: Icons.password_outlined,
                          onSubmitted: _saveCredentials,
                        ),
                      ),
                    ],
                  )
                : UIs.placeholder,
          ),
          CardX(
            child: ListTile(
              leading: const Icon(Icons.network_check),
              title: Text(l10n.cfTestConnection),
              trailing: _testing
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right, size: 18),
              onTap: _test,
            ),
          ),
          if (isAndroid) ...[
            const SizedBox(height: 12),
            CardX(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: TipText(l10n.cfAlerts, l10n.cfAlertsTip),
                    trailing: StoreSwitch(
                      prop: Stores.setting.cfAlertsEnabled,
                      validator: (on) async {
                        if (on) {
                          final allowed = await MethodChans.notificationsAllowed();
                          if (!allowed && mounted) {
                            await MethodChans.openNotificationSettings();
                          }
                        }
                        return true;
                      },
                    ),
                  ),
                  ValBuilder(
                    listenable: Stores.setting.cfAlertsEnabled.listenable(),
                    builder: (on) => on
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.data_usage),
                                title: Text(l10n.cfAlertTrafficPct),
                                trailing: ValBuilder(
                                  listenable: Stores.setting.cfAlertTrafficPct.listenable(),
                                  builder: (pct) => Text('$pct%', style: UIs.text15),
                                ),
                                onTap: () async {
                                  final selected = await context.showPickSingleDialog<int>(
                                    title: l10n.cfAlertTrafficPct,
                                    items: const [80, 90, 95],
                                    display: (p0) => '$p0%',
                                    initial: Stores.setting.cfAlertTrafficPct.fetch(),
                                  );
                                  if (selected != null) {
                                    Stores.setting.cfAlertTrafficPct.put(selected);
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.calendar_today_outlined),
                                title: Text(l10n.cfAlertExpiryDays),
                                trailing: ValBuilder(
                                  listenable: Stores.setting.cfAlertExpiryDays.listenable(),
                                  builder: (days) => Text(
                                    l10n.cfAlertDaysFmt(days),
                                    style: UIs.text15,
                                  ),
                                ),
                                onTap: () {
                                  _expiryDaysCtrl.text = Stores.setting.cfAlertExpiryDays.fetch().toString();
                                  context.showRoundDialog(
                                    title: l10n.cfAlertExpiryDays,
                                    child: Input(
                                      controller: _expiryDaysCtrl,
                                      autoFocus: true,
                                      type: TextInputType.number,
                                      icon: Icons.calendar_today_outlined,
                                      suggestion: false,
                                      onSubmitted: (s) {
                                        final days = int.tryParse(s.trim());
                                        if (days != null && days > 0) {
                                          Stores.setting.cfAlertExpiryDays.put(days);
                                        }
                                        context.popDialog();
                                      },
                                    ),
                                    actions: Btn.ok(onTap: () {
                                      final days = int.tryParse(_expiryDaysCtrl.text.trim());
                                      if (days != null && days > 0) {
                                        Stores.setting.cfAlertExpiryDays.put(days);
                                      }
                                      context.popDialog();
                                    }).toList,
                                  );
                                },
                              ),
                              // The resource rules are the alert system's third
                              // kind, and like the other two they are only read
                              // on Android — the worker that evaluates them is
                              // native. The row lives inside the same
                              // `isAndroid` block for that reason.
                              ListTile(
                                leading: const Icon(Icons.speed_outlined),
                                title: Text(l10n.cfResourceAlerts),
                                subtitle: Text(
                                  l10n.cfResourceAlertsTip,
                                  style: UIs.text12Grey,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ValBuilder(
                                      listenable: Stores.setting.cfResourceAlertRules.listenable(),
                                      builder: (rules) => Text(
                                        '${rules.length}',
                                        style: UIs.text15,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18),
                                  ],
                                ),
                                onTap: () => CfResourceAlertsPage.route.go(context),
                              ),
                              ListTile(
                                leading: const Icon(Icons.play_circle_outline),
                                title: Text(l10n.cfAlertCheckNow),
                                trailing: _checking
                                    ? const SizedBox.square(
                                        dimension: 15,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.chevron_right, size: 18),
                                onTap: _checkNow,
                              ),
                            ],
                          )
                        : UIs.placeholder,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
