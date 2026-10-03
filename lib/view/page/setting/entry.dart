import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/theme.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/core/chan.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/core/service/crash_report.dart';
import 'package:server_box/core/service/diagnostics_upload.dart';
import 'package:server_box/data/model/app/motion.dart';
import 'package:server_box/data/provider/server/cf/cf_servers_provider.dart';
import 'package:server_box/data/res/build_data.dart';
import 'package:server_box/data/res/github_id.dart';
import 'package:server_box/data/res/store.dart';
import 'package:server_box/data/res/url.dart';
import 'package:server_box/generated/l10n/l10n.dart';
import 'package:server_box/view/page/setting/entries/home_tabs.dart';
import 'package:server_box/view/page/setting/platform/platform_pub.dart';
import 'package:server_box/view/widget/crash_debug.dart';
import 'package:server_box/view/widget/crash_report_dialog.dart';
import 'package:server_box/view/widget/diagnostics_level_picker.dart';
import 'package:server_box/view/widget/edge_fade_scroll.dart';
import 'package:server_box/view/widget/group_title.dart';
import 'package:server_box/view/widget/marked_title.dart';
import 'package:server_box/view/widget/pane_settings.dart';

part 'about.dart';
part 'app_page.dart';
part 'entries/app.dart';
part 'entries/cf_site.dart';
part 'entries/full_screen.dart';
part 'group.dart';
part 'layout.dart';
part 'level.dart';
part 'menu.dart';
part 'nodes.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const route = AppRouteNoArg(page: SettingsPage.new, path: '/settings');

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

/// How wide the content beside that menu is allowed to get.
final _kContentMaxWidth = PageColumns.widthFor(
  2,
  padding: _kGridPadding,
  spacing: _kGridSpacing,
);

const _kGridPadding = EdgeInsets.all(13);
const _kGridSpacing = 9.0;

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _path = <SettingsNode>[];
  String? _selectedId;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  bool get _searching => _query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedId = _buildNodes().firstOrNull?.firstLeaf?.id;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _clearAllSettings() async {
    try {
      if (!await Stores.setting.clear()) {
        Toast.error(libL10n.fail);
        return;
      }
      unawaited(RNodes.app.notify());
      Toast.success(libL10n.success);
    } catch (e, s) {
      Loggers.app.warning('Failed to clear settings', e, s);
      Toast.error(libL10n.fail);
    }
  }

  void _onSelect(SettingsNode node) {
    _dropPushedPages();
    setState(() => _selectedId = node.id);
  }

  void _onMenuTap(SettingsNode node) {
    final leaf = node.firstLeaf;
    if (leaf != null) _onSelect(leaf);
  }

  void _onSearch(String value) {
    final query = value.trim();
    if (query == _query) return;
    setState(() {
      _query = query;
      if (query.isNotEmpty) _path.clear();
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearch('');
  }

  List<SettingsHit> _hits(List<SettingsNode> nodes) {
    final needle = _query.toLowerCase();
    bool matches(SettingsNode leaf, SettingsNode? parent) =>
        leaf.title.toLowerCase().contains(needle) ||
        leaf.id.toLowerCase().contains(needle) ||
        (leaf.beta && 'beta'.contains(needle)) ||
        (parent?.title.toLowerCase().contains(needle) ?? false);

    final hits = <SettingsHit>[];
    for (final node in nodes) {
      if (node.isLeaf) {
        if (matches(node, null)) hits.add(SettingsHit(leaf: node));
        continue;
      }
      for (final child in node.children) {
        if (child.isLeaf && matches(child, node)) {
          hits.add(SettingsHit(leaf: child, parent: node));
        }
      }
    }
    return hits;
  }

  void _onHit(SettingsHit hit) {
    _dropPushedPages();
    setState(() {
      _searchCtrl.clear();
      _query = '';
      _selectedId = hit.leaf.id;
      _path
        ..clear()
        ..add(hit.parent ?? hit.leaf);
    });
  }

  final _contentNav = GlobalKey<NavigatorState>();

  void _dropPushedPages() {
    final nav = _contentNav.currentState;
    if (nav == null) return;
    nav.popUntil((route) => route.settings is Page);
  }

  void _onTab(SettingsNode node) {
    _dropPushedPages();
    setState(() {
      if (node.isLeaf && _path.isNotEmpty) {
        _selectedId = node.id;
        return;
      }
      _path.add(node);
      final leaf = node.firstLeaf;
      if (leaf != null) _selectedId = leaf.id;
    });
  }

  void _onTabBack() {
    if (_path.isEmpty) return;
    _dropPushedPages();
    setState(_path.removeLast);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _buildNodes();
    final leaves = [
      for (final node in nodes) ...node.flattened.where((e) => e.isLeaf),
    ];
    final selected =
        leaves.firstWhereOrNull((e) => e.id == _selectedId) ?? leaves.first;

    final hits = _searching ? _hits(nodes) : const <SettingsHit>[];

    final menu = _SettingsMenu(
      nodes: nodes,
      selectedId: selected.id,
      onSelect: _onMenuTap,
      search: _buildSearchField(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AdaptivePanes.kSplitWidth;
        return _SettingsWidth(
          wide: wide,
          child: _buildScaffold(
            wide: wide,
            menu: menu,
            nodes: nodes,
            selected: selected,
            hits: hits,
          ),
        );
      },
    );
  }
}
