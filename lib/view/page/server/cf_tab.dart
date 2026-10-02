import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/cf/cf_server.dart';
import 'package:server_box/data/provider/server/cf/cf_servers_provider.dart';
import 'package:server_box/view/page/server/cf_card.dart';
import 'package:server_box/view/page/server/cf_detail/view.dart';

/// The CF site's home: the fleet in one line, then one card per node.
///
/// The tab the app opens on, reading the CF site instead of the SSH fleet —
/// the old server tab stays in the tree, unreferenced, until the trim's last
/// task takes it out.
class CfHomePage extends ConsumerStatefulWidget {
  const CfHomePage({super.key});

  @override
  ConsumerState<CfHomePage> createState() => _CfHomePageState();

  static const route = AppRouteNoArg(page: CfHomePage.new, path: '/cf');
}

class _CfHomePageState extends ConsumerState<CfHomePage> {
  @override
  void initState() {
    super.initState();
    // Reading the notifier builds the provider, whose first build waits out
    // the launch-restore login before it fetches — so a private site's first
    // read goes out with the token, not with the 401 of one sent while the
    // login was still in flight. The timer this arms polls from the next
    // interval on, and re-arming here cannot stack a second one beside it.
    ref.read(cfServersProvider.notifier).startAutoRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cfServersProvider);
    return Scaffold(
      body: async.when(
        loading: () => UIs.centerLoading,
        error: (e, s) => _error(e),
        data: (snap) => _list(context, snap),
      ),
    );
  }

  /// An error is one poll's answer, not the page's end: the timer keeps
  /// polling underneath, and the button is the way to ask again right now.
  Widget _error(Object e) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text('$e', textAlign: TextAlign.center, style: UIs.text13Grey),
          ),
          const SizedBox(height: 13),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(cfServersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(libL10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, CfServersSnapshot snap) {
    return RefreshIndicator(
      onRefresh: () => ref.read(cfServersProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 25),
        children: [
          _overview(context, snap),
          const SizedBox(height: 4),
          if (snap.servers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text(libL10n.empty, style: UIs.text13Grey)),
            )
          else
            for (final node in snap.servers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CfServerCard(
                  node: node,
                  showExpire: snap.showExpire,
                  showPrice: snap.showPrice,
                  onTap: () =>
                      CfDetailPage.route.go(context, CfDetailArgs(id: node.id, name: node.name)),
                ),
              ),
        ],
      ),
    );
  }

  /// The fleet in one line: how many are up, what all of them are moving
  /// right now, and what they have moved this month.
  Widget _overview(BuildContext context, CfServersSnapshot snap) {
    return CardX(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: _overviewCol(
                l10n.cfOverviewOnline,
                ['${snap.online} / ${snap.total}'],
              ),
            ),
            _overviewDivider(context),
            Expanded(
              child: _overviewCol(l10n.cfOverviewBandwidth, [
                '↓ ${snap.globalSpeedIn.bytes2Str}/s',
                '↑ ${snap.globalSpeedOut.bytes2Str}/s',
              ]),
            ),
            _overviewDivider(context),
            Expanded(
              child: _overviewCol(libL10n.traffic, [
                '↓ ${snap.globalNetRx.bytes2Str}',
                '↑ ${snap.globalNetTx.bytes2Str}',
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewCol(String label, List<String> lines) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: UIs.text12Grey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        for (final line in lines)
          Text(
            line,
            style: UIs.text13Bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _overviewDivider(BuildContext context) => VerticalDivider(
    width: 21,
    thickness: Hairline.thickness,
    color: Hairline.color(context),
  );
}
