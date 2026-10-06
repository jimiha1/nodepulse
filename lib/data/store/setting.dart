import 'dart:convert';

import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/theme.dart';
import 'package:nodepulse/data/model/app/diagnostics_level.dart';
import 'package:nodepulse/data/model/app/motion.dart';
import 'package:nodepulse/data/model/app/tab.dart';
import 'package:nodepulse/data/model/cf/cf_resource_alert.dart';

class SettingStore extends SqliteStore with ThemeSettings {
  SettingStore([super.storeName = 'setting']);

  static final instance = SettingStore();

  /// Timeout for server connections and related operations.
  late final timeout = propertyDefault('timeOut', 5);

  /// UI scale factor. `1.0` means 100%.
  ///
  /// Large values may cause layout issues.
  late final textFactor = propertyDefault('textFactor', 1.0);

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

  /// User-authored resource rules the native alert worker evaluates on its
  /// periodic run: which node, which metric, over what window, and how the
  /// window is judged. See [CfResourceAlertRule].
  ///
  /// One row holding a JSON array rather than a row per rule: the rules are
  /// only ever read and written whole — the settings page loads the list,
  /// edits it, and puts it back — and a row per rule would need its own id
  /// bookkeeping for no reader that wants one rule on its own.
  late final cfResourceAlertRules = listProperty<CfResourceAlertRule>(
    'cfResourceAlertRules',
    fromObj: CfResourceAlertRule.parseList,
    toObj: CfResourceAlertRule.toObjList,
  );

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

  // Locale
  late final locale = propertyDefault('locale', '');

  late final fullScreen = propertyDefault('fullScreen', false);

  late final fullScreenJitter = propertyDefault('fullScreenJitter', true);

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

  /// Whether collapse UI items by default
  late final collapseUIDefault = propertyDefault('collapseUIDefault', true);

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

  /// Whether to collect container resource statistics.
  late final containerParseStat = propertyDefault('containerParseStat', true);

  late final lastVer = propertyDefault('lastVer', 0);

  /// Hide title bar on desktop
  late final hideTitleBar = propertyDefault('hideTitleBar', isDesktop);

  /// general wake lock
  late final generalWakeLock = propertyDefault('generalWakeLock', false);

  /// fmt: https://example.com/{DIST}-{BRIGHT}.png
  late final serverLogoUrl = propertyDefault('serverLogoUrl', '');

  late final betaTest = propertyDefault('betaTest', false);

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

  /// Whether the one-off guide over the tab strip has been shown.
  ///
  /// The bulk actions there open on a long press or a right-click, and neither
  /// leaves a mark on screen — nothing about the strip says the menu exists.
  /// A version flag would show it again after every update; what is wanted is
  /// once per install, so this is set the first time it is dismissed and never
  /// read again.
  late final navTabMenuGuided = propertyDefault('navTabMenuGuided', false);

  // `geoShards`, `geoShardEndpoint` and `geoCacheLimit` were all here and are
  // all retired below. Each existed because the data was fetched a shard at a
  // time: a switch to consent to those requests, an endpoint to send them
  // somewhere else, and a cap on what they could accumulate. One download
  // answers all three — having the file is the consent, there is nothing an
  // endpoint could improve about a request that discloses nothing, and one
  // copy that replaces itself cannot accumulate.

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
