import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/theme.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/data/model/app/tab.dart';
import 'package:nodepulse/data/res/store.dart';
import 'package:nodepulse/view/page/server/cf_tab.dart';
import 'package:nodepulse/view/widget/marked_title.dart';
import 'package:nodepulse/view/widget/nav_rail.dart';

extension AppTabViewX on AppTab {
  Widget get page {
    return switch (this) {
      AppTab.server => const CfHomePage(),
    };
  }

  Widget get icon {
    return _AppTabIcon(tab: this, selected: false);
  }

  Widget get selectedIcon {
    return _AppTabIcon(tab: this, selected: true);
  }

  String get label {
    return switch (this) {
      AppTab.server => libL10n.server,
    };
  }

  bool get beta => false;

  /// The mark a tab carries, where the tab is *listed* — the settings page
  /// that arranges them, and the sheet the bar opens for the ones it cannot
  /// hold — and after its name in the open rail ([navRailItem]). The bottom
  /// bar, whose label is mostly hidden, carries it on the pill's corner while
  /// the tab is selected.
  Widget? get mark => beta ? const BetaTag() : null;

  /// [label] with [mark], for a row that lists the tab rather than opening it.
  Widget get listTitle {
    final mark_ = mark;
    if (mark_ == null) return Text(label);
    return MarkedTitle(label, mark: mark_);
  }

  Widget titleWithMark({bool selected = false}) {
    final mark_ = beta ? const BetaTag() : null;
    return MarkedTitle(label, mark: mark_);
  }

  NavRailItem navRailItem({ContextMenuOpener? onMenu}) {
    return NavRailItem(
      icon: _railIcon(icon),
      selectedIcon: _railIcon(selectedIcon),
      label: label,
      badge: null,
      mark: beta ? (opacity) => BetaTag(opacity: opacity) : null,
      onMenu: onMenu,
    );
  }

  Widget _railIcon(Widget icon) => icon;
}

class _AppTabIcon extends StatelessWidget {
  const _AppTabIcon({required this.tab, required this.selected});

  final AppTab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Stores.setting.appIconStyle.listenable(),
        ThemePackages.preview,
      ]),
      builder: (context, _) {
        final mingcute =
            (ThemePackages.preview.value?.iconStyle ??
                Stores.setting.appIconStyle.fetch()) ==
            IconStyle.mingcute;
        final icon = mingcute
            ? switch (tab) {
                AppTab.server =>
                  selected ? MingCute.server_fill : MingCute.server_line,
              }
            : switch (tab) {
                AppTab.server =>
                  selected ? BoxIcons.bxs_server : BoxIcons.bx_server,
              };
        return ThemeIconAsset(
          keyName: ThemeIcons.tabKey(tab.name, selected: selected),
          fallback: Icon(icon),
        );
      },
    );
  }
}
