part of '../home.dart';

const _kRailWidth = NavRailMetrics.width;

@visibleForTesting
const railWidth = _kRailWidth;

const _kRailChromeHeight = NavRailMetrics.chromeHeight;

@visibleForTesting
const railDestinationExtent = NavRailMetrics.itemExtent;

@visibleForTesting
int railCapacity({required double height, required double destinationExtent}) {
  if (destinationExtent <= 0) return 2;
  final room = height - _kRailChromeHeight;
  return math.max(2, room ~/ destinationExtent);
}

@visibleForTesting
int railShownCount({
  required int wanted,
  required int total,
  required int capacity,
}) {
  if (wanted >= total && wanted <= capacity) return wanted;
  return math.max(1, math.min(wanted, capacity - 1));
}

extension _HomePageStrip on _HomePageState {
  bool _hasRail(bool narrow) => !narrow;

  Future<void> _showMoreSheet(int shownCount) async {
    final overflow = _tabs.skip(shownCount).toList();
    final selected = _selectIndex.value;

    await showRowsSheet<void>(
      context,
      rows: (ctx) => [
        for (final tab in overflow)
          ListTile(
            leading: tab.icon,
            title: tab.listTitle,
            selected: _tabs.indexOf(tab) == selected,
            onTap: () {
              Navigator.of(ctx).pop();
              _onDestinationSelected(_tabs.indexOf(tab));
            },
          ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(libL10n.setting),
          onTap: () {
            Navigator.of(ctx).pop();
            _openSettings();
          },
        ),
      ],
    );
  }

  Widget _buildRailBar() {
    return SafeArea(
      right: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final capacity = railCapacity(
            height: constraints.maxHeight,
            destinationExtent: railDestinationExtent,
          );
          final shown = railShownCount(
            wanted: _barTabs.length,
            total: _tabs.length,
            capacity: capacity,
          );
          return _buildRail(shown: shown);
        },
      ),
    );
  }

  Widget _buildRail({required int shown}) {
    final more = shown < _tabs.length;
    return ListenableBuilder(
      listenable: _selectIndex,
      builder: (context, _) {
        if (_isServerFullscreenMode) return UIs.placeholder;
        return AppNavRail(
          key: _navKey,
          selectedIndex: _settingsOpen
              ? -1
              : (_selectIndex.value < shown ? _selectIndex.value : shown),
          items: [
            for (final tab in _tabs.take(shown))
              tab.navRailItem(onMenu: _navMenuFor(tab)),
            if (more)
              NavRailItem(
                icon: const ThemedIcon(Icons.more_horiz),
                selectedIcon: const ThemedIcon(Icons.more_horiz),
                label: libL10n.more,
              ),
          ],
          onSelected: (index) {
            if (index < shown) return _onDestinationSelected(index);
            unawaited(_showMoreSheet(shown));
          },
          footer: NavRailItem(
            icon: const ThemedIcon(Icons.settings_outlined),
            selectedIcon: const ThemedIcon(Icons.settings),
            label: libL10n.setting,
          ),
          onFooterTap: _openSettings,
          footerSelected: _settingsOpen,
        );
      },
    );
  }
}

extension _HomePageNav on _HomePageState {
  ContextMenuOpener? _navMenuFor(AppTab tab) {
    return null;
  }

  Future<void> _maybeShowNavGuide() async {
    if (_navGuideHandled) return;
    final flag = Stores.setting.navTabMenuGuided;
    if (flag.fetch()) return;
    if (!mounted) return;
    if (ref.read(cfServersProvider).value?.servers.isEmpty ?? true) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final spot = rectInOverlay(_navKey.currentContext, overlay);
    if (spot == null) return;

    _navGuideHandled = true;
    await GuideOverlay.show(context, [
      GuideStep(body: context.l10n.navTabMenuTip, spot: spot),
    ]);
    Stores.setting.navTabMenuGuided.put(true);
  }
}
