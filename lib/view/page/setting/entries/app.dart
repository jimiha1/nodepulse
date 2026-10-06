part of '../entry.dart';

extension _App on _AppSettingsPageState {
  List<SettingsGroup> _buildApp() {
    return [
      SettingsGroup(libL10n.general, [_buildLocale(), _buildCollapseUI()]),
      SettingsGroup(libL10n.update, [_buildCheckUpdate(), _buildBeta()]),
      // Everything about the machine the app happens to be on, which is why
      // every row in it is behind a platform test. It is also where the rows
      // that used to be behind a tile called "More" ended up: a group with a
      // name is what that tile was standing in for.
      SettingsGroup(libL10n.system, [
        if (_bioAuthAvail == true) ...[_buildBioAuth(), _buildBioAuthDelay()],
        if (isMobile) _buildWakeLock(),
        if (isAndroid) _buildBgRun(),
        if (isDesktop) _buildHideTitleBar(),
        _buildMotion(),
      ]),
    ];
  }

  /// What the app looks like, in two groups.
  ///
  /// Theme and font were two pages, each holding a group the other's name
  /// would have covered: the theme page opened on a group called "Appearance"
  /// and the font page was one group called "Font". The page is the appearance
  /// and the groups are the two halves of it — which is also what puts the
  /// font beside the theme it is part of, rather than a tap away.
  List<SettingsGroup> _buildAppearance() {
    // The rows themselves are shared with the other apps on fl_lib; which page
    // they are on, and the groups they are read in, are this app's.
    final appearance = ThemeAppearance(
      context,
      setStateSafe,
      storeTarget: _SettingsWidth.pageTarget(context),
    );
    SettingsRow row(ThemeSettingRow r) =>
        SettingsRow(r.label, r.build, keywords: r.keywords);
    return [
      SettingsGroup(libL10n.theme, appearance.themeRows().map(row).toList()),
      SettingsGroup(libL10n.font, appearance.fontRows().map(row).toList()),
    ];
  }

  SettingsRow _buildBioAuth() {
    return SettingsRow(libL10n.bioAuth, PlatformPublicSettings.buildBioAuth);
  }

  SettingsRow _buildBioAuthDelay() {
    return SettingsRow(
      PlatformPublicSettings.bioAuthDelayLabel,
      PlatformPublicSettings.buildBioAuthDelay,
      keywords: libL10n.bioAuth,
    );
  }

  SettingsRow _buildBgRun() {
    final label = l10n.bgRun;
    return SettingsRow(
      label,
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: TipText(label, l10n.bgRunTip),
            trailing: StoreSwitch(prop: Stores.setting.bgRun),
          ),
          _buildBgRunPermission(),
        ],
      ),
      keywords: l10n.bgRunTip,
    );
  }

  /// Says so when the switch above cannot do what it says.
  ///
  /// Running in the background means holding a foreground service, and a
  /// foreground service means a notification — so an app whose notifications
  /// are turned off is frozen the moment it leaves the screen, and every
  /// connection dies with nothing on screen explaining it (#1287). Shown only
  /// in that case: a row saying "this is fine" on every other device is noise.
  Widget _buildBgRunPermission() {
    return FutureWidget(
      future: MethodChans.notificationsAllowed(),
      loading: UIs.placeholder,
      error: (_, _) => UIs.placeholder,
      success: (allowed) {
        if (allowed != false) return UIs.placeholder;
        return ListTile(
          leading: Icon(Icons.notifications_off, color: UIs.primaryColor),
          title: TipText(libL10n.permission, l10n.bgRunNeedsNotification),
          trailing: const Icon(Icons.keyboard_arrow_right),
          onTap: () async {
            await MethodChans.openNotificationSettings();
            // Read again on the way back: the point of sending someone there
            // is that they change it, and a row still saying it is off would
            // make them wonder whether it took.
            setStateSafe(() {});
          },
        );
      },
    );
  }

  SettingsRow _buildCheckUpdate() {
    final label = libL10n.checkUpdate;
    return SettingsRow(
      label,
      () => _checkUpdateTile(
        context,
        trailing: StoreSwitch(prop: _setting.autoCheckAppUpdate),
      ),
      keywords: 'v${BuildData.build}',
    );
  }

  /// Over the device's own "reduce motion", in either direction — see
  /// `AppMotion`.
  SettingsRow _buildMotion() {
    final label = l10n.reduceMotion;
    String name(MotionPref pref) => switch (pref) {
      MotionPref.system => libL10n.followSystem,
      MotionPref.reduce => libL10n.enabled,
      MotionPref.full => libL10n.disabled,
    };
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(Icons.animation),
        title: Text(label),
        onTap: () async {
          final selected = await context.showPickSingleDialog(
            title: label,
            items: MotionPref.values,
            display: name,
            initial: _setting.motionPref.fetch(),
          );
          if (selected != null) _setting.motionPref.put(selected);
        },
        trailing: ValBuilder(
          listenable: _setting.motionPref.listenable(),
          builder: (pref) => Text(name(pref), style: UIs.text15),
        ),
      ),
      keywords: 'animation',
    );
  }

  SettingsRow _buildLocale() {
    final label = libL10n.language;
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(IonIcons.language),
        title: Text(label),
        onTap: () async {
          final selected = await context.showPickSingleDialog(
            title: label,
            items: AppLocalizations.supportedLocales,
            display: (p0) => p0.nativeName,
            initial: _setting.locale.fetch().toLocale,
          );
          if (selected != null) {
            _setting.locale.put(selected.code);
            // No `pop`: the picker has already closed — that is what `await`
            // returning a selection means — so popping here closed the settings
            // page behind it. `notify` is what makes the new language take
            // effect; nothing has to be dismissed for that.
            unawaited(RNodes.app.notify());
          }
        },
        trailing: ListenBuilder(
          listenable: _setting.locale.listenable(),
          builder: () => Text(context.localeNativeName, style: UIs.text15),
        ),
      ),
    );
  }

  /// Its own page rather than two rows under the app's own settings, because
  /// what it decides is not the same kind of thing as the rows it sat among.
  ///
  /// A page can also be reached — from the intro that first asks the question,
  /// from a release note, from an answer to someone asking what is collected —
  /// and a row buried in a collapsed tile cannot.
  List<SettingsGroup> _buildPrivacy() {
    return [
      // Only where a report could actually be sent. A control that cannot do
      // anything is worse than one that is not offered, and a build with no
      // DSN in it can do nothing here. See [DiagnosticsUpload].
      //
      // Uncarded: the picker is a list of cards already.
      if (DiagnosticsUpload.availableInBuild)
        SettingsGroup(l10n.crashCollect, [
          _buildDiagnosticsUpload(),
        ], carded: false),
      // Not behind `availableInBuild` — a build with no upload endpoint is
      // exactly the one where handing the log over by hand is the only way a
      // crash gets reported at all. Absent when nothing crashed: a row reading
      // "no crash report" would be on the page for the whole life of every
      // healthy install, while a row that appears is itself the news.
      if (_savedCrashReport != null)
        SettingsGroup(libL10n.log, [_buildLastCrashReport()]),
      SettingsGroup(l10n.privacy, [
        // The policy describes what is kept on the device as well as what is
        // sent, so it has something to say in a build that uploads nothing.
        _buildPrivacyPolicy(),
        // Last, after everything about what leaves the device. It is the one
        // control here that acts on this moment instead — who can read the
        // screen.
        ?PlatformPublicSettings.privacyBlur?.row,
      ]),
    ];
  }

  /// Where the choice made on the intro page can be revisited.
  ///
  /// The same widget the intro puts the question with, so the answer reads the
  /// same in both places. It replaced a row whose trailing text named the
  /// current level and whose tap opened a picker of three bare labels: the
  /// sentence saying what a level actually sends existed only on the intro,
  /// which is the one screen a user sees once and cannot go back to.
  SettingsRow _buildDiagnosticsUpload() {
    return SettingsRow(
      l10n.crashCollect,
      () => DiagnosticsLevelPicker(
        // Applied now rather than at the next launch: turning it down has to
        // take the sink out immediately, not eventually.
        onPicked: () => unawaited(DiagnosticsUpload.sync()),
      ),
    );
  }

  /// The previous run's log, when there is one.
  ///
  /// Whether one exists is a file on disk, read once when the page opens —
  /// see [_AppSettingsPageState.initState]. Read here through a builder it
  /// flickered out and back on every unrelated rebuild, and the group it is in
  /// could not know whether to exist at all.
  SettingsRow _buildLastCrashReport() {
    final label = l10n.crashReportTitle;
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(label),
        subtitle: Text(l10n.crashLastRunFailed, style: UIs.textGrey),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final report = _savedCrashReport;
          if (report == null) return;
          final kept = await CrashReportDialog.show(context, report);
          // The row goes when the report does.
          if (kept) return;
          _savedCrashReport = null;
          refresh();
        },
      ),
    );
  }

  /// Beside the level, not inside the picker.
  ///
  /// The dialog that picks a level is a list of three options and has nowhere
  /// to put a link; and the policy is worth reaching without first opening the
  /// control that changes a setting.
  SettingsRow _buildPrivacyPolicy() {
    final label = l10n.privacyPolicy;
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(Icons.policy_outlined),
        title: Text(label),
        trailing: const Icon(Icons.open_in_new, size: 17),
        onTap: Urls.privacyPolicy.launchUrl,
      ),
    );
  }

  SettingsRow _buildBeta() {
    final label = l10n.preReleaseUpdates;
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(Icons.science_outlined),
        title: Text(label),
        trailing: StoreSwitch(prop: _setting.betaTest),
      ),
    );
  }

  SettingsRow _buildWakeLock() {
    final label = l10n.wakeLock;
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(MingCute.lock_fill),
        title: Text(label),
        trailing: StoreSwitch(prop: _setting.generalWakeLock),
      ),
    );
  }

  SettingsRow _buildCollapseUI() {
    final label = 'UI ${libL10n.fold}';
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(Icons.unfold_less),
        title: TipText(label, l10n.collapseUITip),
        trailing: StoreSwitch(prop: _setting.collapseUIDefault),
      ),
      keywords: l10n.collapseUITip,
    );
  }

  SettingsRow _buildHideTitleBar() {
    final label = libL10n.hideTitleBar;
    return SettingsRow(
      label,
      () => ListTile(
        leading: const Icon(Icons.web_asset),
        title: Text(label),
        trailing: StoreSwitch(
          prop: _setting.hideTitleBar,
          callback: (value) async {
            await SystemUIs.updateTitleBarStyle(hideTitleBar: value);
          },
        ),
      ),
    );
  }
}
