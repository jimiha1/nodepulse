part of '../entry.dart';

/// The CF-Server-Monitor site the CF pages read: where it is, whether reading
/// it needs a login, and the one login the app keeps for it.
///
/// Its own page rather than rows in the server group's settings, because what
/// it configures is not this app but another one — a site this build talks to.
/// The URL is saved as it is submitted; the credentials are not saved as they
/// are typed but with the connection test, which is the only moment a token
/// exists to store beside them.
final class CfSiteSettingsPage extends ConsumerStatefulWidget {
  const CfSiteSettingsPage({super.key});

  @override
  ConsumerState<CfSiteSettingsPage> createState() =>
      _CfSiteSettingsPageState();
}

final class _CfSiteSettingsPageState extends ConsumerState<CfSiteSettingsPage> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  /// Re-entry guard for the test below: a slow site and an impatient finger
  /// would otherwise stack two logins and two reads.
  bool _testing = false;

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
    super.dispose();
  }

  void _saveUrl(String raw) {
    final url = raw.trim();
    if (url == Stores.setting.cfSiteUrl.fetch()) return;
    // The provider holding the API listens for exactly this, and rebuilds
    // its client — nothing else to notify here.
    Stores.setting.cfSiteUrl.put(url);
  }

  /// Log in as needed, then read the node list once, and say which happened.
  ///
  /// This is also where typed credentials are persisted: [CfApi.performLogin]
  /// returns the token, and only with one does the credentials store have a
  /// complete set to keep — which is why the inputs above are not saved as
  /// they are typed.
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
              suggestion: false,
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
                        ),
                      ),
                      CardX(
                        child: Input(
                          controller: _pwdCtrl,
                          label: l10n.cfPassword,
                          icon: Icons.password_outlined,
                          obscureText: true,
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
        ],
      ),
    );
  }
}
