import 'dart:convert';

import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/theme.dart';
import 'package:server_box/data/model/app/diagnostics_level.dart';
import 'package:server_box/data/model/app/motion.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/data/res/default.dart';
import 'package:server_box/data/store/field_prop.dart';

List<String> _virtKeyNames(Object? raw) =>
    raw is List ? raw.whereType<String>().toList() : const [];

class SettingStore extends SqliteStore with ThemeSettings {
  SettingStore([super.storeName = 'setting']);

  static final instance = SettingStore();

  /// Timeout for server connections and related operations.
  late final timeout = propertyDefault('timeOut', 5);

  /// Whether to remember previously opened SFTP paths.
  late final recordHistory = propertyDefault('recordHistory', true);

  /// UI scale factor. `1.0` means 100%.
  ///
  /// Large values may cause layout issues.
  late final textFactor = propertyDefault('textFactor', 1.0);

  late final serverStatusUpdateInterval = propertyDefault(
    'serverStatusUpdateInterval',
    Defaults.updateInterval,
  );

  /// The CF-Server-Monitor site the CF pages read, see
  /// `lib/data/provider/server/cf/`. Empty means none is configured.
  late final cfSiteUrl = propertyDefault(
    'cfSiteUrl',
    '',
  );

  /// Seconds between two polls of that site's node list.
  late final cfUpdateInterval = propertyDefault('cfUpdateInterval', 10);

  /// Whether that site needs a login, i.e. its read endpoints are private.
  ///
  /// The credentials themselves are not a setting: this store is SQLite in
  /// plaintext, so they live in `CfCredentials` — the platform keystore —
  /// instead.
  late final cfAuthEnabled = propertyDefault('cfAuthEnabled', false);

  /// Local alerts for CF-Server-Monitor nodes (traffic threshold + expiration).
  late final cfAlertsEnabled = propertyDefault('cfAlertsEnabled', false);

  /// Traffic threshold percentage for alerts (80, 90, or 95).
  late final cfAlertTrafficPct = propertyDefault('cfAlertTrafficPct', 90);

  /// Advance notice days before expiration to alert.
  late final cfAlertExpiryDays = propertyDefault('cfAlertExpiryDays', 7);

  // Maximum number of server connection retries.
  late final maxRetryCount = propertyDefault('maxRetryCount', 2);

  /// Whether the app moves less than it would, over what the device asks —
  /// see [MotionPref]. Full motion unless the user turns it down here: the
  /// app's own transitions are its design, whatever the device asks.
  late final motionPref = propertyDefault(
    'motionPref',
    MotionPref.full,
    fromObj: MotionPref.parse,
    toObj: (pref) => pref?.name,
  );

  // Path to the terminal font file.
  late final fontPath = propertyDefault('fontPath', '');

  // Whether the app may continue running in the background on Android.
  late final bgRun = propertyDefault('bgRun', isAndroid);

  /// Whether closing the desktop window leaves the app running in the tray.
  ///
  /// On by default, because it is what makes the status icon worth having: an
  /// icon that goes away with the window says nothing at the moment anybody
  /// would look at it. Off restores what every desktop build did before —
  /// closing the window ends the app.
  late final trayKeepRunning = propertyDefault('trayKeepRunning', isDesktop);

  late final trayMetrics = listProperty<String>(
    'trayMetrics',
    defaultValue: ['cpu', 'mem'],
  );

  late final trayChart = propertyDefault('trayChart', 'cpu');

  late final trayCompact = propertyDefault('trayCompact', false);

  // Server order
  late final serverOrder = listProperty<String>('serverOrder');

  late final snippetOrder = listProperty<String>('snippetOrder');

  // Disabled detail cards (for persistence when toggling visibility)
  late final detailCardDisabled = listProperty<String>('detailCardDisabled');

  /// Virtual keys the user has hidden, by [VirtKey.name] — see [sshVirtKeys]
  /// for why not by index.
  late final sshVirtKeysDisabled = listProperty<String>(
    'sshVirtKeysDisabled',
    fromObj: _virtKeyNames,
  );

  // SSH term font size
  late final termFontSize = propertyDefault('termFontSize', 13.0);

  // Locale
  late final locale = propertyDefault('locale', '');

  // SSH virtual key (ctrl | alt) auto turn off
  late final sshVirtualKeyAutoOff = propertyDefault(
    'sshVirtualKeyAutoOff',
    true,
  );

  late final editorFontSize = propertyDefault('editorFontSize', 12.5);

  late final editorFontFamily = propertyDefault('editorFontFamily', '');

  /// Trusted SSH host key fingerprints keyed by `serverId::keyType`.
  late final sshKnownHostFingerprints = propertyDefault<Map<String, String>>(
    'sshKnownHostFingerprints',
    const {},
    fromObj: (raw) {
      if (raw is Map) {
        return raw.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
      return <String, String>{};
    },
  );

  /// Which profile a terminal opens in, by `LinuxProfile.id`.
  ///
  /// Empty until something is chosen; the platform layer reads that as "the
  /// first one installed". A profile and not a distribution, because two of the
  /// same distribution can be installed side by side.
  late final linuxProfile = propertyDefault('linuxProfile', '');

  late final linuxDistro = propertyDefault(
    'linuxDistro',
    'alpine',
  );

  late final linuxMirrors = propertyDefault<Map<String, String>>(
    'linuxMirrors',
    const {},
    fromObj: (raw) {
      if (raw is Map) {
        return raw.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
      return <String, String>{};
    },
  );

  /// The resolvers written into the guest's `/etc/resolv.conf`.
  ///
  /// Not per distribution: this is the network the device is on. Read through
  /// `linuxNameservers()`, which is also what decides what counts as an address
  /// in it.
  late final linuxDns = propertyDefault('linuxDns', Defaults.linuxDns);

  // Editor theme
  late final editorTheme = propertyDefault('editorTheme', Defaults.editorTheme);

  late final editorDarkTheme = propertyDefault(
    'editorDarkTheme',
    Defaults.editorDarkTheme,
  );

  late final fullScreen = propertyDefault('fullScreen', false);

  late final fullScreenJitter = propertyDefault('fullScreenJitter', true);

  late final sshVirtKeys = listProperty<String>(
    'sshVirtKeys',
    defaultValue: const [],
    fromObj: _virtKeyNames,
  );

  // Only valid on iOS
  late final autoUpdateHomeWidget = propertyDefault(
    'autoUpdateHomeWidget',
    isIOS,
  );

  /// Hide the app's content once it leaves the foreground, so the app
  /// switcher's card does not leave server names or terminal output readable.
  /// Mobile only.
  ///
  /// iOS blurs the window; Android sets `FLAG_SECURE`, which blanks the recents
  /// thumbnail instead — Flutter draws into a `SurfaceView` that no in-process
  /// blur can reach, and a cover that has to render a frame races the system's
  /// capture.
  ///
  /// The native side keeps its own copy — a cold launch can reach the switcher
  /// before Dart has pushed anything — so a change here has to go through
  /// [MethodChans.setPrivacyBlur], and every launch re-pushes.
  late final privacyBlur = propertyDefault('privacyBlur', false);

  /// Whether this app may put a Live Activity on the lock screen at all.
  ///
  /// iOS only, and one switch for every kind rather than one per kind: the user
  /// question is whether this app appears on the lock screen, not which of its
  /// features does. What is behind it today is the terminal session activity;
  /// the monitor status one will sit behind the same switch.
  ///
  /// **Off by default, which is a change of behaviour.** A Live Activity used
  /// to appear whenever a terminal connected, with nothing to stop it. It shows
  /// a server's name and the state of a connection to it, on a screen that is
  /// readable without unlocking the phone, and that is not something to opt
  /// somebody into — least of all silently, on a device they hand to other
  /// people. An install that wants it turns it on once.
  ///
  /// Independent of iOS' own per-app Live Activity permission, which can also
  /// be off: this says whether the app *asks*.
  late final liveActivity = propertyDefault('liveActivity', false);

  /// Servers the watch app may show, by [Spi.id], in display order.
  ///
  /// The watch used to be configured by a list of URLs living only inside the
  /// WCSession application context — invisible to backup and sync, lost on
  /// reinstall, and unrelated to the server list the user actually maintains.
  /// Keeping the selection here makes the app the source of truth and the
  /// context merely the transport. iOS only.
  ///
  /// Read only by the v15 -> v16 migration now, which turns whatever is in it
  /// into [watchExcludedServerIds]. Every monitor server syncs by default.
  ///
  /// TODO: drop with `WatchSelectionToExclusionMigration`.
  late final watchServerIds = listProperty<String>('watchServerIds');

  /// Servers held back from the watch, by [Spi.id].
  ///
  /// The inverse of what came before, and the inversion is the feature: a
  /// server the user adds is on their watch without a second step, which is
  /// what "sync automatically" has to mean. An opt-*in* list is a place to
  /// forget a server, and forgetting one looks exactly like the watch being
  /// broken.
  ///
  /// It exists at all because syncing a server means minting a credential for
  /// it and putting that on a second device. That is worth being able to
  /// refuse per server — the default is what changed, not whether there is a
  /// choice. iOS only.
  late final watchExcludedServerIds = listProperty<String>(
    'watchExcludedServerIds',
  );

  /// Raw Go-compat `/status` URLs typed by hand in builds before the watch
  /// could read a server record.
  ///
  /// Read only by [LegacyStatusUrlsMigration], which empties it and arranges
  /// for the user to be told — a bare address cannot reach the authenticated
  /// API, so there is nothing to convert it into.
  ///
  /// TODO: drop with `LegacyStatusUrlsMigration`.
  late final watchLegacyUrls = listProperty<String>('watchLegacyUrls');

  /// Whether this install still has to be told that its hand-typed `/status`
  /// URLs stopped working.
  ///
  /// Set by [LegacyStatusUrlsMigration] and cleared by the dialog. Persisted
  /// rather than shown from the migration itself, because a migration runs
  /// before there is a screen to show anything on — and a message about a
  /// feature that has gone must not be lost to whichever launch happened to
  /// run the migration.
  late final legacyStatusNoticePending = propertyDefault(
    'legacyStatusNoticePending',
    false,
  );

  /// The timestamp of the most recent `ApplicationExitInfo` already reported.
  ///
  /// Android hands back the same record on every launch until another one
  /// replaces it, and the records carry no id — the timestamp is the only thing
  /// telling two apart. Without this, one crash would raise the prompt on every
  /// launch after it, forever.
  /// Device-local twice over, which takes both the prefix and the flag.
  ///
  /// `updateLastModified: false` because a crash is not an edit: stamping the
  /// sync clock for one would make a phone that merely crashed claim the newer
  /// copy of every setting at the next merge.
  ///
  /// The internal-key prefix because the value must not travel. It is compared
  /// against *this* device's `ApplicationExitInfo.timestamp`, so another
  /// device's — which is simply a different clock reading — arriving here
  /// would silently discard every crash older than it, permanently.
  late final lastExitInfoTs = propertyDefault(
    '${StoreDefaults.prefixKey}lastExitInfoTs',
    0,
    updateLastModified: false,
  );

  /// How much of a crash is uploaded — see `DiagnosticsLevel`.
  ///
  /// Stored by name, never by index: an index changes meaning the moment a
  /// case is inserted, and this value outlives the build that wrote it.
  ///
  /// The default is `defaultDiagnosticsLevel`: `none` on Android, `basic`
  /// everywhere else. The split is about F-Droid, which distributes only the
  /// Android build and requires collection to be off by default — see that
  /// getter for why it is decided at runtime rather than by a compile-time
  /// flag.
  ///
  /// Either way nothing is uploaded until the user has been shown the intro
  /// page that explains the three levels. That ordering is what makes this
  /// "asked before it happens" rather than collection by surprise.
  late final diagnosticsLevel = propertyDefault(
    'diagnosticsLevel',
    defaultDiagnosticsLevel.name,
  );

  /// The revision of the crash-collection notice this install has seen.
  ///
  /// Its own counter rather than `introVer`, which is set to the *build
  /// number* when an intro completes — so every key in `_builders` is
  /// permanently below it for anyone who has ever seen one, and a newly added
  /// page could never appear. Bumping `kDiagnosticsConsentVer` shows this again,
  /// which is what a change to what is collected would need.
  late final diagnosticsConsentVer = propertyDefault(
    'diagnosticsConsentVer',
    0,
  );

  /// The revision of the feature pages in the intro this install has seen.
  ///
  /// Its own counter for `diagnosticsConsentVer`'s reason: `introVer` holds a
  /// build number, which is above any small constant, so a page keyed on it
  /// could never appear for anyone who has finished an intro. Each page names
  /// the revision it arrived in, and completing the intro records the latest.
  late final featureIntroVer = propertyDefault('featureIntroVer', 0);

  late final autoCheckAppUpdate = propertyDefault('autoCheckAppUpdate', true);

  /// Width of the list column, wherever one shares the window with what it
  /// opens: the server list, the terminal and file rails, the agent's
  /// history. One width for all of them, so the columns line up between
  /// tabs.
  ///
  /// Remembered because it is a working preference, not a one-off: someone who
  /// widens it to read long server names wants it that way tomorrow too.
  ///
  /// The default is what dragging used to bottom out at. Only new installs see
  /// it — anyone who has dragged a divider has a number of their own stored,
  /// and moving that under them would undo the choice this exists to keep.
  late final paneListWidth = propertyDefault('paneListWidth', 220.0);

  /// Whether that column is folded away entirely.
  ///
  /// Shared with [paneListWidth] for the same reason: one answer for every
  /// list-beside-content layout, so folding the column on one tab does not
  /// leave the next tab looking like it forgot.
  ///
  /// Separate from the width rather than a width of zero. Zero is not a width
  /// any drag can produce, so storing it there would mean every reader had to
  /// know that one value means something else — and unfolding would have
  /// nowhere to find the width to go back to.
  late final paneListCollapsed = propertyDefault('paneListCollapsed', false);

  /// Whether use `rm -r` to delete directory on SFTP
  late final sftpRmrDir = propertyDefault('sftpRmrDir', false);

  /// Only valid on iOS / Android / Windows
  late final useBioAuth = propertyDefault('useBioAuth', false);

  /// Delay to lock the App with BioAuth, in seconds.
  /// Set to `0` to disable this feature.
  late final delayBioAuthLock = propertyDefault('delayBioAuthLock', 0);

  /// The performance of highlight is bad
  late final editorHighlight = propertyDefault('editorHighlight', true);

  /// Open SFTP with last viewed path
  late final sftpOpenLastPath = propertyDefault('sftpOpenLastPath', true);

  /// Whether the SFTP browser lists directories before files.
  late final sftpShowFoldersFirst = propertyDefault(
    'sftpShowFoldersFirst',
    true,
  );

  /// List entries whose name starts with a dot.
  ///
  /// Off, because the common case is looking for something you put there. Not
  /// per-backend: someone who wants to see `.ssh` on a server wants to see
  /// `.config` on this device too.
  late final showHiddenFiles = propertyDefault('showHiddenFiles', false);

  /// Whether to show the warning before suspending a process.
  late final showSuspendTip = propertyDefault('showSuspendTip', true);

  /// Whether collapse UI items by default
  late final collapseUIDefault = propertyDefault('collapseUIDefault', true);

  /// Whether a command the Agent proposes may run on a *server* without being
  /// asked, when it is clearly read-only — see `AskAiCommand.canAutoRun`.
  /// Running on this device is [agentLocalExec], and never runs unasked.
  late final agentAutoRunSafe = propertyDefault('agentAutoRunSafe', false);

  /// Whether the Agent may run commands on this device.
  ///
  /// Off until asked for, unlike a configured server. A server was added
  /// deliberately and is somewhere else; this machine is where the app's own
  /// stores, private keys and keychain live, and nobody opted into a model
  /// touching those by adding a server.
  ///
  /// Auto-running stays off here whatever [agentAutoRunSafe] says — that
  /// setting is about servers. See `AskAiCommand.canAutoRun`.
  ///
  /// Device-local — see [deviceLocalKeys]: this is what the app will let a
  /// model do to this machine, and a restore should not carry it.
  late final agentLocalExec = propertyDefault('agentLocalExec', false);

  /// Settings that describe *this device* rather than a preference worth
  /// carrying to another one, so a backup neither exports nor restores them.
  ///
  /// Both are answers to "what may this machine do", and a backup file does not
  /// know which machine it is being read on.
  ///
  /// [agentLocalExec]'s doc says a restore of a provider configuration must not
  /// carry it, and until this existed it did: the key is an ordinary settings
  /// row, so exporting on a machine where the Agent had been let loose and
  /// restoring on a phone turned it on there with nothing said.
  ///
  /// [liveActivity] the same, one screen out. It decides whether a server's
  /// name and the state of a connection to it are readable without unlocking,
  /// so restoring a phone's backup onto a second phone would start putting
  /// them on that phone's lock screen without anyone deciding it. It is also
  /// iOS-only, which makes the other direction wrong too: a backup taken on
  /// Android carries the untouched default and would switch it off on an iPhone
  /// that had it on.
  ///
  /// Handled beside the internal keys rather than by giving them internal
  /// names, so an install that has already answered the question keeps its
  /// answer instead of being quietly reset by a rename.
  static const deviceLocalKeys = {
    'agentLocalExec',
    'liveActivity',
    // TODO(appearance): package image bytes when backups can carry theme assets.
    'appBackgroundPath',
    'appCustomBackgroundPath',
    // TODO(appearance): include installed theme/font assets in backup packages.
    'appThemePackage',
    'appImportedFontPath',
    'themeStoreCache',
    // What this device's themes directory holds, like `appThemePackage`.
    'bundledThemesSeeded',
  };

  /// The floating Agent's placement and size, as one row.
  ///
  /// Eight keys before this. See [FloatShellConfig] for the nesting and
  /// [FloatShellProps] for the [FieldProp]s onto it.
  late final serverFuncBtns = listProperty<String>(
    'serverBtns',
    defaultValue: const [],
  );

  /// Whether container commands use Podman instead of Docker.
  late final usePodman = propertyDefault('usePodman', false);

  /// Whether to try `sudo` when running container commands.
  late final containerTrySudo = propertyDefault('containerTrySudo', true);

  /// Whether to retain the previous server status after a refresh error.
  late final keepStatusWhenErr = propertyDefault('keepStatusWhenErr', false);

  /// Whether to collect container resource statistics.
  late final containerParseStat = propertyDefault('containerParseStat', true);

  /// Whether to refresh container status automatically.
  late final containerAutoRefresh = propertyDefault(
    'containerAutoRefresh',
    true,
  );

  /// Whether the strip above the server list is shown: the overview over the
  /// grid, and the row of servers it turns into over an open one.
  late final serverOverview = propertyDefault('serverOverview', true);

  /// Remerber pwd in memory
  /// Used for [DialogX.showPwdDialog]
  late final rememberPwdInMem = propertyDefault('rememberPwdInMem', true);

  /// SSH Term Theme
  /// 0: follow app theme, 1: light, 2: dark
  late final termTheme = propertyDefault('termTheme', 0);

  late final lastVer = propertyDefault('lastVer', 0);

  /// Layout version of this device's local storage — see [SchemaVersion].
  ///
  /// Defaults to 2, not 0: storage that predates versioning is, by definition,
  /// whatever the last unversioned release wrote, and that is v2 (Spi with a
  /// flat SSH layout plus `monitorHttp`). A fresh install overwrites this with
  /// [SchemaVersion.current] before any migration runs.
  ///
  /// An **internal** key, so `getAllMap` leaves it out of a backup and `clear`
  /// leaves it alone. Under a plain key it travelled: restoring a backup taken
  /// on a device still on the previous release wrote that device's version
  /// back, and the next launch found a version with no migration registered for
  /// it and threw `SchemaTooNewException`'s counterpart — a `StateError` that
  /// nothing catches.
  ///
  /// Being internal also means it never stamps `lastUpdateTs`, which it must
  /// not: it describes this device's storage, so counting a migration writing
  /// it as a user edit would make a device that has only just upgraded claim
  /// the newer copy of everything at the next sync.
  ///
  /// TODO: drop `schemaVersion` from `removeRetiredKeys` once no install can
  /// still carry the plain-key copy this replaced.
  late final schemaVersion = propertyDefault(
    '${StoreDefaults.prefixKey}schemaVersion',
    2,
    updateLastModified: false,
  );

  /// Hide title bar on desktop
  late final hideTitleBar = propertyDefault('hideTitleBar', isDesktop);

  late final editorSoftWrap = propertyDefault('editorSoftWrap', isIOS);

  late final sshTermHelpShown = propertyDefault('sshTermHelpShown', false);

  /// Whether the walkthrough over the virtual keys has run.
  ///
  /// Separate from [sshTermHelpShown], which gates a dialog about the terminal
  /// body and is the only guidance a desktop gets — there are no virtual keys
  /// there to walk through.
  late final virtKeyIntroShown = propertyDefault('virtKeyIntroShown', false);

  /// How many rows of virtual keys the terminal shows at once, 0 for all.
  ///
  /// Rows past that go on a page of their own, swiped sideways. It replaced a
  /// switch meaning "one row, scrolled sideways", which is this set to 1 —
  /// with the difference that a swipe now lands on whole rows rather than
  /// leaving the row halfway between two keys. See [VirtKeyRowsMigration].
  late final virtKeyRows = propertyDefault('virtKeyRows', 0);

  /// general wake lock
  late final generalWakeLock = propertyDefault('generalWakeLock', false);

  /// ssh page
  late final sshWakeLock = propertyDefault('sshWakeLock', true);
  late final sshBgImage = propertyDefault('sshBgImage', '');
  late final sshBgOpacity = propertyDefault('sshBgOpacity', 0.3);
  late final sshBlurRadius = propertyDefault('sshBlurRadius', 0.0);

  /// fmt: https://example.com/{DIST}-{BRIGHT}.png
  late final serverLogoUrl = propertyDefault('serverLogoUrl', '');

  late final betaTest = propertyDefault('betaTest', false);

  /// The build number the App Store build last mentioned the DMG one for.
  ///
  /// `-1` means never again. Only the sandboxed macOS build reads it — see
  /// `DmgNotice`, which is where the once-per-version rule lives.
  late final dmgTipBuild = propertyDefault('dmgTipBuild', 0);

  /// For desktop only.
  /// Record the position and size of the window.
  /// Stored as an object, not as a string holding one.
  ///
  /// `SqliteStore.set` encodes whatever `toObj` returns, so returning an
  /// already-encoded string got it encoded a second time and the `value`
  /// column held `"{\"size\":{\"width\":1324.0,...}}"`. Twice the bytes, and
  /// the raw settings editor could only show it as one escaped line instead of
  /// a value with fields.
  ///
  /// No migration: `WindowStateListener` writes on every move and resize, so
  /// the row rewrites itself the first time the window is touched. The string
  /// branch below is what reads it until then.
  late final windowState = property<WindowState>(
    'windowState',
    fromObj: (raw) => switch (raw) {
      // TODO: delete the string branch once no install can still hold one.
      final String s => WindowState.fromJson(
        jsonDecode(s) as Map<String, dynamic>,
      ),
      final Map m => WindowState.fromJson(Map<String, dynamic>.from(m)),
      _ => null,
    },
    toObj: (state) => state?.toJson(),
  );

  late final introVer = propertyDefault('introVer', 0);

  late final letterCache = propertyDefault('letterCache', false);

  /// Remote editor command used in the SSH terminal, such as `$EDITOR` or
  /// `vim`. Leave empty to use the local GUI editor.
  late final sftpEditor = propertyDefault('sftpEditor', '');

  // `fgService` was here: a second switch for the Android foreground service,
  // whose tile was commented out of the settings page long before that page
  // was deleted. It defaulted to false, nothing could turn it on, and it gated
  // Android service updates — so the app never asked for the service it needs
  // to survive being backgrounded. [bgRun] is the one switch now.
  //
  // TODO: the stale `fgService` row in `kv` is harmless and is left to be swept
  // with the next settings migration.

  /// Close the editor after saving
  late final closeAfterSave = propertyDefault('closeAfterSave', false);

  /// The backup password
  late final backupPassword = SecureProp('bakPasswd');

  /// Whether to read SSH config from ~/.ssh/config on first time
  late final firstTimeReadSSHCfg = propertyDefault('firstTimeReadSSHCfg', true);

  /// Tabs at home page
  ///
  /// [AppTab.defaultOrder] rather than `AppTab.values`: the two differ, and
  /// the difference is which tab the bar has room for.
  late final homeTabs = listProperty(
    'homeTabs',
    defaultValue: AppTab.defaultOrder,
    fromObj: AppTab.parseAppTabsFromObj,
    toObj: (val) {
      return val?.map((e) => e.name).toList() ?? [];
    },
  );

  /// What `{DIST}` expands to, for a distribution whose file is named
  /// something else wherever the marks are hosted.
  ///
  /// Keyed by `Dist`'s own case name, which is the value `{DIST}` carries by
  /// default. Absent means "use the case name", so this holds only the
  /// disagreements — an empty map is the normal state.
  ///
  /// It exists because there is no correct table to ship. The names belong to
  /// whichever collection the user pointed at: font-logos calls Arch
  /// `archlinux` and RHEL `redhat`, another set will call them something else,
  /// and a table baked in here would be right for one of them and wrong for
  /// the rest. Edited by hand in the settings' key-value editor.
  late final distNameMap = propertyDefault<Map<String, String>>(
    'distNameMap',
    const {},
    fromObj: (raw) {
      if (raw is Map) {
        return raw.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
      return <String, String>{};
    },
  );

  /// Where the small mark beside a server's name is fetched from.
  ///
  /// Separate from [serverLogoUrl], which is the large image on a server's own
  /// page, because the two are different pictures: artwork that reads at full
  /// width is a smudge at 20px, and an icon that works at 20px is lost on a
  /// detail page. Both take `{DIST}` and `{BRIGHT}`.
  ///
  /// Empty means the marks shipped with the app are used where there are any,
  /// and the fallback icon everywhere else. See [showDistMark] for the switch
  /// that governs whether any of it is drawn at all.
  late final serverMarkUrl = propertyDefault('serverMarkUrl', '');

  /// Whether to draw a mark beside a server's name at all.
  ///
  /// **Off by default.** Five distributions' logos ship with the app and the
  /// rest fall back to an icon, so this is the difference between a column of
  /// marks and no column — not, as an earlier version of it was, a second gate
  /// over an address that was already blank. Turning it on shows the terms
  /// first; turning it off is agreement to nothing and asks nothing.
  ///
  /// Off means *nothing*, not a blank of the same size: the callers ask for
  /// `distIcon(...)`, which answers null, and leave the slot out entirely.
  ///
  /// A new key rather than the old `showDistIcon`, which defaulted to on and
  /// would have carried that answer past the terms for anyone who had it
  /// stored. TODO: the old key sits unread in the `setting` table on installs
  /// that wrote it; nothing looks at it.
  late final showDistMark = propertyDefault('showDistMark', false);

  /// Hide port forward beta warning
  late final portForwardBetaWarned = propertyDefault(
    'portForwardBetaWarned',
    false,
  );

  /// Whether the one-off guide over the tab strip has been shown.
  ///
  /// The bulk actions there open on a long press or a right-click, and neither
  /// leaves a mark on screen — nothing about the strip says the menu exists.
  /// A version flag would show it again after every update; what is wanted is
  /// once per install, so this is set the first time it is dismissed and never
  /// read again.
  late final navTabMenuGuided = propertyDefault('navTabMenuGuided', false);

  /// The highest rootfs-manifest serial this device has accepted.
  ///
  /// A signature stays valid for as long as the key does, so verifying one
  /// does not make it current. Refusing a serial below this is what stops an
  /// old signed manifest being replayed to pin a device to a rootfs whose
  /// problems are known.
  ///
  /// Device-local bookkeeping, so it does not stamp the sync clock: which
  /// manifest a phone has seen is not an edit anyone made.
  late final rootfsManifestSerial = propertyDefault(
    'rootfsManifestSerial',
    0,
    updateLastModified: false,
  );

  /// The last manifest that verified, and its signature, base64.
  ///
  /// Both, because the cache is re-verified when it is read rather than
  /// trusted for having once been verified — it sits in app storage, and
  /// re-checking 64 bytes costs nothing next to believing whatever is there.
  late final rootfsManifestCache = propertyDefault(
    'rootfsManifestCache',
    '',
    updateLastModified: false,
  );
  late final rootfsManifestCacheSig = propertyDefault(
    'rootfsManifestCacheSig',
    '',
    updateLastModified: false,
  );

  /// Hide the Linux beta warning, which is asked before an install.
  ///
  /// Separate from [portForwardBetaWarned] rather than one flag for every beta
  /// feature: dismissing the warning on one says nothing about having read the
  /// other, and the two are not the same risk.
  late final linuxBetaWarned = propertyDefault('linuxBetaWarned', false);

  late final sshPageSortBy = propertyDefault('sshPageSortBy', 0);
  late final sshPageSortAsc = propertyDefault('sshPageSortAsc', true);

  /// The remote desktop server picker has the terminal picker's four orders,
  /// but keeps its own choice so changing tabs does not change the ordering.
  late final remoteDesktopSortBy = propertyDefault('remoteDesktopSortBy', 0);
  late final remoteDesktopSortAsc = propertyDefault(
    'remoteDesktopSortAsc',
    true,
  );

  /// How the server list is ordered, as an index into `_SortField` and a
  /// direction — the same pair, stored the same way, as the two above.
  ///
  /// The defaults are the first field ascending, which is the order the user
  /// arranged in the settings. Sorting the list some other way is a view of
  /// it, and this is where that view is remembered; [serverOrder] stays the
  /// arrangement itself.
  late final serverPageSortBy = propertyDefault<String>(
    'serverPageSortBy',
    'manual',
  );
  late final serverPageSortAsc = propertyDefault('serverPageSortAsc', true);

  /// Whether to automatically start/attach tmux on SSH connect.
  late final tmuxAuto = propertyDefault('tmuxAuto', false);

  /// Whether to show the tmux session selector dialog on connect.
  late final tmuxShowSelector = propertyDefault('tmuxShowSelector', true);

  /// Default tmux session name. Empty string means use 'server_box'.
  late final tmuxSessionName = propertyDefault('tmuxSessionName', '');

  /// Which reading each server's card draws in full, by server id.
  ///
  /// Per server because the answer is: a database is watched for its disk and
  /// a build box for its CPU. Carried into the detail page as well, so picking
  /// a row on the card and picking one on the page are the same choice — which
  /// is the whole reason the card and the page are one structure.
  ///
  /// A kind's `name`, never its index: a case inserted into
  /// `ServerMetricKind` would silently repoint every stored choice.
  late final serverCardMetric = propertyDefault<Map<String, String>>(
    'serverCardMetric',
    const {},
    fromObj: (obj) => Map<String, String>.from(obj as Map),
  );

  /// Whether a server's card has its rows unfolded, for the servers somebody
  /// has said so about, by [Spi.id].
  ///
  /// A card with no entry rests at what [collapseUIDefault] says, which is
  /// what makes that setting a default rather than a starting value: a server
  /// added tomorrow follows it without anything being written, and so does
  /// every card nobody has touched when the setting is changed.
  ///
  /// Per server for the reason [serverCardMetric] is: the two machines worth
  /// keeping open on a page of forty are not the same two for everybody.
  late final serverCardExpandedOverride = propertyDefault<Map<String, bool>>(
    'serverCardExpandedOverride',
    const {},
    fromObj: (obj) => Map<String, bool>.from(obj as Map),
  );

  /// How much of each server the list shows, by tag.
  ///
  /// Per tag because a tag is a set of machines: `#prod` with forty in it and
  /// `#local` with two want different answers. The empty key is "all", which
  /// is the set the app opens on.
  ///
  /// A [ServerListDensity]'s `name`, and absent means `auto` — so an install
  /// that has never chosen follows the count rather than a stored guess.
  late final serverListDensity = propertyDefault<Map<String, String>>(
    'serverListDensity',
    const {},
    fromObj: (obj) => Map<String, String>.from(obj as Map),
  );

  /// How the list is ordered, by tag — the same shape, and the same empty key
  /// for "all", as [serverListDensity].
  ///
  /// Per tag for the reason the density is: `#prod` with forty in it wants to
  /// be read busiest-first, and `#local` with two wants the arrangement it was
  /// given. One field and one direction, written `<field>:<asc|desc>` — a bare
  /// field name reads as ascending, which is what the pair below used to be
  /// stored as.
  ///
  /// TODO: [serverPageSortBy] and [serverPageSortAsc] are only still read as
  /// this map's empty-key default, for installs that chose before it existed.
  /// Delete both, and the fallback in `ServerSortOrder.of`, a few releases on.
  late final serverListSort = propertyDefault<Map<String, String>>(
    'serverListSort',
    const {},
    fromObj: (obj) => Map<String, String>.from(obj as Map),
  );

  /// Whether the list is cut into sections, by tag.
  ///
  /// A string rather than a bool because what it names is what the sections
  /// are cut by: `tag` today, and absent is one list. A second answer — by
  /// status, say — is then a value rather than a second setting.
  ///
  /// Only ever means anything under the empty key: inside `#prod` every
  /// machine is in `#prod`, so grouping by tag there is one section. It is
  /// stored per tag anyway, because a setting that is remembered in one place
  /// and forgotten in another is the harder thing to explain.
  late final serverListGroup = propertyDefault<Map<String, String>>(
    'serverListGroup',
    const {},
    fromObj: (obj) => Map<String, String>.from(obj as Map),
  );

  /// Whether the globe exists at all.
  ///
  /// On by default, and off is a real off: no button in the server tab, no
  /// asset read, no name resolved, no request made. That is worth stating
  /// because the two things below it are separate switches and neither of them
  /// is what turns the feature off.
  late final globeEnabled = propertyDefault('globeEnabled', true);

  /// Whether the server tab is currently showing the globe.
  ///
  /// A view over the list, stored the same way the sort order is and for the
  /// same reason: reopening the app on the grid after having chosen the globe
  /// reads as the choice not having taken. Distinct from [globeEnabled], which
  /// is whether the choice exists.
  late final serverPageGlobe = propertyDefault('serverPageGlobe', false);

  // `geoShards`, `geoShardEndpoint` and `geoCacheLimit` were all here and are
  // all retired below. Each existed because the data was fetched a shard at a
  // time: a switch to consent to those requests, an endpoint to send them
  // somewhere else, and a cap on what they could accumulate. One download
  // answers all three — having the file is the consent, there is nothing an
  // endpoint could improve about a request that discloses nothing, and one
  // copy that replaces itself cannot accumulate.

  /// Whether the guide pointing at the globe button has been shown.
  ///
  /// Once per install, like [navTabMenuGuided] — the globe is a way of viewing
  /// a list that already looks finished, so nothing on the server tab suggests
  /// the button changes anything until it is pressed.
  late final globeGuided = propertyDefault('globeGuided', false);

  /// Whether the remote desktop viewer's walkthrough has been shown.
  ///
  /// Once per install. On a touch screen the canvas is a touchpad — one
  /// finger moves the pointer rather than clicking where it lands — and
  /// nothing on screen says so, nor that two fingers right-click and scroll.
  late final remoteDesktopGuided = propertyDefault(
    'remoteDesktopGuided',
    false,
  );

  /// How long a remote session stays connected once it is off screen, in
  /// seconds; 0, the default, keeps it until it is closed. See
  /// `SessionKeepAlive`.
  ///
  /// Seconds rather than an index into the choices the settings row offers,
  /// so that changing those choices never changes what a stored value means.
  late final remoteSessionIdleTimeout = propertyDefault(
    'remoteSessionIdleTimeout',
    0,
    fromObj: (obj) => obj is int && obj >= 0 ? obj : null,
  );

  /// Removes settings for UI choices that no longer exist. Idempotent so old
  /// installs are cleaned without another migration flag becoming permanent
  /// state of its own.
  Future<void> removeRetiredKeys() async {
    for (final key in const [
      'moveOutServerTabFuncBtns',
      'forceSinglePane',
      'fgService',
      'noNotiPerm',
      'showDistIcon',
      'appIconPreset',
      'detailCardOrder',
      'schemaVersion',
      'geoShards',
      'geoShardEndpoint',
      'geoCacheLimit',
      'netViewType',
      'serverTabPreferDiskAmount',
      'doubleColumnServersPage',
      'cpuViewAsProgress',
      'displayCpuIndex',
      'sshConnectionMode',
      'desktopSshAutoCopyPassword',
      'desktopTerminal',
    ]) {
      remove(key, updateLastUpdateTsOnRemove: false);
    }
  }
}
