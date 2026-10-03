part of 'entry.dart';

List<SettingsNode> _buildNodes() {
  return [
    SettingsNode.branch(
      id: 'app',
      title: libL10n.app,
      icon: Icons.tune,
      children: [
        SettingsNode.leaf(
          id: 'app.setting',
          title: libL10n.general,
          icon: Icons.settings_outlined,
          page: () => const AppSettingsPage(section: SettingsSection.app),
        ),
        SettingsNode.leaf(
          id: 'app.appearance',
          title: libL10n.appearanceSettings,
          icon: Icons.style_outlined,
          page: () => const AppSettingsPage(section: SettingsSection.appearance),
        ),
        SettingsNode.leaf(
          id: 'app.privacy',
          title: l10n.privacy,
          icon: Icons.privacy_tip_outlined,
          page: () => const AppSettingsPage(section: SettingsSection.privacy),
        ),
        SettingsNode.leaf(
          id: 'app.homeTabs',
          title: l10n.homeTabs,
          icon: Icons.tab_outlined,
          page: () => const HomeTabsConfigPage(embedded: true),
        ),
        if (isMobile)
          SettingsNode.leaf(
            id: 'app.fullScreen',
            title: l10n.fullScreen,
            icon: Icons.fullscreen,
            page: () =>
                const AppSettingsPage(section: SettingsSection.fullScreen),
          ),
      ],
    ),
    SettingsNode.leaf(
      id: 'cfSite',
      title: l10n.cfSite,
      icon: Icons.monitor_heart_outlined,
      page: () => const CfSiteSettingsPage(),
    ),
    SettingsNode.leaf(
      id: 'about',
      title: libL10n.about,
      icon: Icons.info_outline,
      page: () => const _AppAboutPage(),
    ),
  ];
}
