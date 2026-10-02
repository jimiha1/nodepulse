import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/cf/cf_history.dart';
import 'package:server_box/data/model/cf/cf_server.dart';
import 'package:server_box/data/provider/server/cf/cf_servers_provider.dart';
import 'package:server_box/view/page/server/cf_detail/charts.dart';

/// Which node a [CfDetailPage] opens: its id on the site, and the name the
/// list already had for the bar.
final class CfDetailArgs {
  const CfDetailArgs({required this.id, required this.name});

  final String id;
  final String name;
}

/// The page a CF node's card opens: Info Card + Range Selector + 8 Charts + Ping Chart.
class CfDetailPage extends ConsumerStatefulWidget {
  const CfDetailPage({super.key, required this.args});

  final CfDetailArgs args;

  static const route = AppRouteArg(page: CfDetailPage.new, path: '/cf/detail');

  @override
  ConsumerState<CfDetailPage> createState() => _CfDetailPageState();
}

class _CfDetailPageState extends ConsumerState<CfDetailPage> {
  CfHistoryRange _selectedRange = CfHistoryRange.live;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(cfServersProvider);
    final snapshot = snapshotAsync.value;
    final node = snapshot?.servers.firstWhere(
      (s) => s.id == widget.args.id,
      orElse: () => _fallbackNode(),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(node?.name ?? widget.args.name),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 25),
        children: [
          if (node != null) ...[
            _buildInfoCard(
              context,
              node,
              showExpire: snapshot?.showExpire ?? true,
              showPrice: snapshot?.showPrice ?? true,
            ),
            const SizedBox(height: 11),
          ],
          _buildRangeSelector(context),
          const SizedBox(height: 11),
          _buildChartsSection(context, node),
        ],
      ),
    );
  }

  CfServer _fallbackNode() {
    return CfServer(
      id: widget.args.id,
      name: widget.args.name,
      online: false,
      cpu: 0,
      ramUsed: 0,
      ramTotal: 0,
      swapUsed: 0,
      swapTotal: 0,
      diskUsed: 0,
      diskTotal: 0,
      load1: 0,
      load5: 0,
      load15: 0,
      netInSpeed: 0,
      netOutSpeed: 0,
      netRxMonthly: 0,
      netTxMonthly: 0,
      netRx: 0,
      netTx: 0,
      tcpConn: 0,
      udpConn: 0,
      processes: 0,
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    CfServer node, {
    required bool showExpire,
    required bool showPrice,
  }) {
    final rows = <({String k, String v})>[
      // Arch + OS
      (
        k: 'OS / Arch',
        v: [node.os ?? '—', if (node.arch != null) node.arch!].join(' / '),
      ),
      // GPU
      (
        k: 'GPU',
        v: node.gpus.isNotEmpty
            ? node.gpus
                .map((g) => g.info != null ? '${g.name} (${g.info})' : g.name)
                .join(', ')
            : '—',
      ),
      // Memory + Swap
      (
        k: libL10n.memory,
        v: '${_mb(node.ramUsed)} / ${_mb(node.ramTotal)}',
      ),
      (
        k: 'Swap',
        v: node.swapTotal > 0
            ? '${_mb(node.swapUsed)} / ${_mb(node.swapTotal)}'
            : (libL10n.none),
      ),
      // Disk
      (
        k: libL10n.disk,
        v: '${_mb(node.diskUsed)} / ${_mb(node.diskTotal)}',
      ),
      // System Load
      (
        k: l10n.cfLoad,
        v: '${node.load1.toStringAsFixed(2)} / ${node.load5.toStringAsFixed(2)} / ${node.load15.toStringAsFixed(2)}',
      ),
      // Uptime
      if (node.bootTime != null)
        (k: libL10n.uptime, v: _uptime(node.bootTime!)),
      // Realtime network
      (
        k: l10n.cfOverviewBandwidth,
        v: '↓ ${node.netInSpeed.bytes2Str}/s  ↑ ${node.netOutSpeed.bytes2Str}/s',
      ),
      // Total traffic
      (
        k: libL10n.traffic,
        v: '↓ ${node.netRxMonthly.bytes2Str}  ↑ ${node.netTxMonthly.bytes2Str}',
      ),
      // Remaining traffic
      if (node.trafficUsedRatio >= 0)
        (
          k: l10n.cfTrafficRemaining,
          v: (node.trafficLimitBytes - node.trafficUsedBytes)
              .clamp(0, 1 << 62)
              .bytes2Str,
        ),
      // Expiry & Price
      if (showExpire && node.expireDate != null)
        (
          k: l10n.cfExpire,
          v: [
            node.expireDate!,
            if (showPrice && node.price != null && node.price!.isNotEmpty)
              node.price!,
          ].join('  ·  '),
        ),
    ];

    return CardX(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, node),
            const Divider(height: 19),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(row.k, style: UIs.text12Grey),
                    ),
                    Expanded(
                      child: Text(
                        row.v,
                        style: UIs.text13,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, CfServer node) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: node.online ? Colors.lightGreen : Colors.grey,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            node.name,
            style: UIs.text15Bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (node.region case final region?) _regionBadge(context, region),
        if (node.group case final group?) ...[
          const SizedBox(width: 5),
          Text(group, style: UIs.text12Grey),
        ],
      ],
    );
  }

  Widget _regionBadge(BuildContext context, String region) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(region.toUpperCase(), style: UIs.text12),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final range in CfHistoryRange.values) ...[
            ChoiceChip(
              label: Text(range.label),
              selected: _selectedRange == range,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedRange = range);
                }
              },
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, CfServer? node) {
    if (_selectedRange == CfHistoryRange.live) {
      final liveRows = ref
          .read(cfServersProvider.notifier)
          .getLiveBuffer(widget.args.id);
      final rows = liveRows.isNotEmpty
          ? liveRows
          : (node != null ? [_nodeToRow(node)] : const <CfHistoryRow>[]);
      return _renderCharts(context, rows);
    }

    final hours = _selectedRange.hours!;
    final historyAsync = ref.watch(
      cfHistoryProvider(id: widget.args.id, hours: hours),
    );

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Text('$e', textAlign: TextAlign.center, style: UIs.text13Grey),
            ),
            FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(
                cfHistoryProvider(id: widget.args.id, hours: hours),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(libL10n.retry),
            ),
          ],
        ),
      ),
      data: (rows) => _renderCharts(context, rows),
    );
  }

  Widget _renderCharts(BuildContext context, List<CfHistoryRow> rows) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text(libL10n.empty, style: UIs.text13Grey)),
      );
    }

    final times = [for (final r in rows) r.timestamp];

    // Compute average ping losses if available
    String? pingSubtitle;
    if (hasAnyPing(rows)) {
      final lossCts = [for (final r in rows) if (r.lossCt != null) r.lossCt!];
      final lossCus = [for (final r in rows) if (r.lossCu != null) r.lossCu!];
      final lossCms = [for (final r in rows) if (r.lossCm != null) r.lossCm!];

      double avg(List<double> list) =>
          list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

      final pings = <String>[];
      if (lossCts.isNotEmpty) pings.add('CT: ${avg(lossCts).toStringAsFixed(1)}%');
      if (lossCus.isNotEmpty) pings.add('CU: ${avg(lossCus).toStringAsFixed(1)}%');
      if (lossCms.isNotEmpty) pings.add('CM: ${avg(lossCms).toStringAsFixed(1)}%');
      if (pings.isNotEmpty) {
        pingSubtitle = 'Loss: ${pings.join(' ')}';
      }
    }

    return Column(
      children: [
        // 1. CPU usage
        CfChartCard(
          title: l10n.cfChartCpu,
          series: rowsToCpuSeries(rows),
          times: times,
          format: (v) => '${v.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 11),
        // 2. Memory & Swap
        CfChartCard(
          title: l10n.cfChartMem,
          series: rowsToMemSeries(rows),
          times: times,
          format: (v) => (v * 1024 * 1024).bytes2Str,
          binaryScale: true,
        ),
        const SizedBox(height: 11),
        // 3. Disk used
        CfChartCard(
          title: l10n.cfChartDisk,
          series: rowsToDiskSeries(rows),
          times: times,
          format: (v) => (v * 1024 * 1024).bytes2Str,
          binaryScale: true,
        ),
        const SizedBox(height: 11),
        // 4. Network Speed (In / Out)
        CfChartCard(
          title: l10n.cfChartNet,
          series: rowsToNetSeries(rows),
          times: times,
          format: (v) => '${v.bytes2Str}/s',
          binaryScale: true,
        ),
        const SizedBox(height: 11),
        // 5. System Load
        CfChartCard(
          title: l10n.cfChartLoad,
          series: rowsToLoadSeries(rows),
          times: times,
          format: (v) => v.toStringAsFixed(2),
        ),
        const SizedBox(height: 11),
        // 6. Disk IO
        CfChartCard(
          title: l10n.cfChartDiskIo,
          series: rowsToDiskIoSeries(rows),
          times: times,
          format: (v) => '${v.bytes2Str}/s',
          binaryScale: true,
        ),
        const SizedBox(height: 11),
        // 7. Connections
        CfChartCard(
          title: l10n.cfChartConn,
          series: rowsToConnSeries(rows),
          times: times,
          format: (v) => v.toInt().toString(),
        ),
        const SizedBox(height: 11),
        // 8. Processes
        CfChartCard(
          title: l10n.cfChartProcess,
          series: rowsToProcessSeries(rows),
          times: times,
          format: (v) => v.toInt().toString(),
        ),
        if (hasAnyPing(rows)) ...[
          const SizedBox(height: 11),
          // 9. Ping Latency (CT/CU/CM)
          CfChartCard(
            title: l10n.cfChartPing,
            subtitle: pingSubtitle,
            series: rowsToPingSeries(rows),
            times: times,
            format: (v) => '${v.toStringAsFixed(0)}ms',
          ),
        ],
      ],
    );
  }

  static CfHistoryRow _nodeToRow(CfServer s) {
    return CfHistoryRow(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      cpu: s.cpu,
      ramUsed: s.ramUsed,
      ramTotal: s.ramTotal,
      diskUsed: s.diskUsed,
      diskTotal: s.diskTotal,
      netInSpeed: s.netInSpeed,
      netOutSpeed: s.netOutSpeed,
      tcpConn: s.tcpConn,
      udpConn: s.udpConn,
      processes: s.processes,
      diskReadBps: 0,
      diskWriteBps: 0,
      swapUsed: s.swapUsed,
      swapTotal: s.swapTotal,
      loadAvg: '${s.load1} ${s.load5} ${s.load15}',
      pingCt: s.pingCt,
      pingCu: s.pingCu,
      pingCm: s.pingCm,
      lossCt: s.lossCt,
      lossCu: s.lossCu,
      lossCm: s.lossCm,
    );
  }

  static String _mb(int mb) => (mb * 1024 * 1024).bytes2Str;

  static String _uptime(int bootSeconds) {
    final d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(bootSeconds * 1000),
    );
    if (d.inDays > 0) return '${d.inDays} d ${d.inHours % 24} h';
    if (d.inHours > 0) return '${d.inHours} h';
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds} s';
  }
}
