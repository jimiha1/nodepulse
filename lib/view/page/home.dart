import 'dart:async';
import 'dart:math' as math;

import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/core/chan.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/core/utils/desktop_shortcuts.dart';
import 'package:server_box/data/model/app/app_link.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/data/provider/server/cf/cf_servers_provider.dart';
import 'package:server_box/data/res/build_data.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/data/res/url.dart';
import 'package:server_box/view/page/home_tab.dart';
import 'package:server_box/view/page/server/cf_detail/charts.dart';
import 'package:server_box/view/page/server/cf_detail/view.dart';
import 'package:server_box/view/page/setting/entry.dart';
import 'package:server_box/view/widget/nav_rail.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'home/lifecycle.dart';
part 'home/nav.dart';
part 'home/settings.dart';
part 'home/tabs.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();

  static const route = AppRouteNoArg(page: HomePage.new, path: '/');
}

class _HomePageState extends ConsumerState<HomePage>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin {
  late final PageController _pageController;

  final _selectIndex = ValueNotifier(0);

  DateTime? _pausedTime;
  bool _shouldAuth = false;

  var _serverRefreshCycle = 0;
  bool _switchingPage = false;
  bool? _lastFullscreenMode;

  final _lastTab = Stores.setting.propertyDefault('lastHomeTab', '');

  var _consumingPending = false;
  Future<void>? _authed;

  late final _notifier = ref.read(cfServersProvider.notifier);

  late List<AppTab> _barTabs = Stores.setting.homeTabs.fetch();
  late List<AppTab> _tabs = _barTabs;

  final _navKey = GlobalKey();
  bool _narrow = false;
  bool _settingsOpen = false;
  final _settingsNavKey = GlobalKey<NavigatorState>();

  late final _settingsCtrl = AnimationController(
    vsync: this,
    duration: Durations.medium2,
  );
  late final _settingsAnim = CurvedAnimation(
    parent: _settingsCtrl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool _settingsSeen = false;
  bool _navGuideHandled = false;

  @override
  void dispose() {
    _stopServerRefreshCycle();
    if (isMobile) {
      SystemUIs.switchStatusBar(hide: false);
    }
    WidgetsBinding.instance.removeObserver(this);
    Stores.setting.homeTabs.listenable().removeListener(_handleHomeTabsChanged);
    _pageController.dispose();
    WakelockPlus.disable();

    _selectIndex.dispose();
    _settingsAnim.dispose();
    _settingsCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemUIs.switchStatusBar(hide: false);
    WidgetsBinding.instance.addObserver(this);
    MethodChans.onOpened(() => unawaited(_consumePending()));

    if (_selectIndex.value >= _tabs.length || _selectIndex.value < 0) {
      _selectIndex.value = 0;
    }
    _pageController = PageController(initialPage: _selectIndex.value);
    if (Stores.setting.generalWakeLock.fetch()) {
      WakelockPlus.enable();
    }

    Stores.setting.homeTabs.listenable().addListener(_handleHomeTabsChanged);

    _settingsCtrl.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.completed || AnimationStatus.dismissed:
          if (mounted) setState(() {});
        case _:
          break;
      }
    });
  }

  void _handleHomeTabsChanged() {
    final newBar = Stores.setting.homeTabs.fetch();
    final newTabs = newBar;
    if (!mounted || newBar.equals(_barTabs)) return;

    final previousIndex = _selectIndex.value;
    final previousTab = previousIndex >= 0 && previousIndex < _tabs.length
        ? _tabs[previousIndex]
        : null;
    final moved = previousTab == null ? -1 : newTabs.indexOf(previousTab);
    final nextIndex = moved >= 0
        ? moved
        : (newTabs.isEmpty ? 0 : previousIndex.clamp(0, newTabs.length - 1));

    setState(() {
      _barTabs = newBar;
      _tabs = newTabs;
      _selectIndex.value = nextIndex;
      _rememberTab(nextIndex);
    });

    if (nextIndex != previousIndex && _pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_pageController.hasClients) return;
        _pageController.jumpToPage(nextIndex);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      unawaited(_consumePending());
    }

    if (isDesktop) return;
    _handleMobileLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _syncFullscreenSystemUi();

    Widget mainContent(bool narrow) => ListenableBuilder(
      listenable: _selectIndex,
      builder: (_, _) => Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                if (_hasRail(narrow))
                  const SafeArea(
                    top: false,
                    bottom: false,
                    right: false,
                    child: SizedBox(width: _kRailWidth),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      _buildTabPages(),
                      if (_settingsSeen) _buildSettingsPane(),
                    ],
                  ),
                ),
              ],
            ),
            if (_hasRail(narrow))
              PositionedDirectional(
                top: 0,
                bottom: 0,
                start: 0,
                child: _buildRailBar(),
              ),
          ],
        ),
        bottomNavigationBar: null,
      ),
    );

    final scaffold = LayoutBuilder(
      builder: (context, cons) {
        _narrow = cons.maxWidth < 600;
        return mainContent(_narrow);
      },
    );

    final withBack = PopScope(
      canPop: !_settingsOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _closeSettings();
      },
      child: scaffold,
    );

    if (!isDesktop) return withBack;

    return CallbackShortcuts(
      bindings: desktopShortcuts(
        tabCount: _tabs.length,
        onTab: _onDestinationSelected,
        onSettings: _openSettings,
      ),
      child: Focus(autofocus: true, skipTraversal: true, child: withBack),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    final saved = _savedTabIndex();
    if (saved != null) {
      _selectIndex.value = saved;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(saved);
      }
    }
    final authed = _authed = _goAuth(showGuide: false);

    if (Stores.setting.autoCheckAppUpdate.fetch()) {
      unawaited(
        AppUpdateIface.doUpdate(
          build: BuildData.build,
          githubReleasesUrl: Urls.githubReleasesApi,
          storeUrl: Urls.appStore,
          context: context,
        ),
      );
    }

    await _showLaunchNotices(authed);
  }
}
