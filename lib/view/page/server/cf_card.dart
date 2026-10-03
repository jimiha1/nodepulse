import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/cf/cf_server.dart';
import 'package:server_box/data/model/server/dist.dart';
import 'package:server_box/view/widget/dist_icon.dart';

/// One CF node, as the CF home page draws it.
///
/// Deliberately plainer than the SSH server card it sits beside in spirit:
/// it is one reading of one machine, drawn as rows, and everything it cannot
/// say about that machine belongs to its detail page. The rows come and go
/// with what the site sent — a ping that timed out is no row, not a dash.
class CfServerCard extends StatelessWidget {
  const CfServerCard({
    super.key,
    required this.node,
    this.showExpire = false,
    this.showPrice = false,
    this.onTap,
  });

  final CfServer node;

  /// The site's own switches, handed down from the snapshot: a site that
  /// hides expiry and price gets a card without the row for them.
  final bool showExpire;
  final bool showPrice;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CardX(
      child: InkWell(
        borderRadius: CardX.borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 8),
              _resourceBar(
                context: context,
                label: 'CPU',
                percent: node.cpu,
                detail: node.cpuCores == null ? '' : 'x${node.cpuCores}',
              ),
              _resourceBar(
                context: context,
                label: libL10n.memory,
                percent: _pctOf(node.ramUsed, node.ramTotal),
                detail: '${_mb(node.ramUsed)} / ${_mb(node.ramTotal)}',
                color: const Color(0xFF0A84FF),
              ),
              _resourceBar(
                context: context,
                label: libL10n.disk,
                percent: _pctOf(node.diskUsed, node.diskTotal),
                detail: '${_mb(node.diskUsed)} / ${_mb(node.diskTotal)}',
                color: const Color(0xFFFF9F0A),
              ),
              const SizedBox(height: 10),
              // Modular 2x2 layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildNetworkTile(context)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTrafficTile(context)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPingLossTile(context)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSystemTile(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileContainer({required BuildContext context, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      child: child,
    );
  }

  Widget _buildNetworkTile(BuildContext context) {
    return _tileContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 12, color: _greyOf(context).withValues(alpha: 0.75)),
              const SizedBox(width: 4),
              Text(
                '实时速率',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: _greyOf(context).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text('↓ ', style: TextStyle(fontSize: 12, color: _greyOf(context).withValues(alpha: 0.75))),
              Expanded(
                child: Text(
                  '${node.netInSpeed.bytes2Str}/s',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('↑ ', style: TextStyle(fontSize: 11, color: _greyOf(context).withValues(alpha: 0.75))),
              Expanded(
                child: Text(
                  '${node.netOutSpeed.bytes2Str}/s',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _greyOf(context).withValues(alpha: 0.9),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficTile(BuildContext context) {
    final remainingText = node.trafficUsedRatio >= 0
        ? (node.trafficLimitBytes - node.trafficUsedBytes).clamp(0, 1 << 62).bytes2Str
        : '∞';
    return _tileContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_usage_rounded, size: 12, color: _greyOf(context).withValues(alpha: 0.75)),
              const SizedBox(width: 4),
              Text(
                '月度流量',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: _greyOf(context).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l10n.cfTrafficRemaining} ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: _greyOf(context).withValues(alpha: 0.75),
                  ),
                ),
                TextSpan(
                  text: remainingText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '已用 ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: _greyOf(context).withValues(alpha: 0.75),
                  ),
                ),
                TextSpan(
                  text: (node.netRxMonthly + node.netTxMonthly).bytes2Str,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _greyOf(context).withValues(alpha: 0.9),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPingLossTile(BuildContext context) {
    Widget line(String name, double? ping, double? loss) {
      final pText = ping != null ? '$name ${ping.toInt()}ms' : '$name -';
      final lText = loss != null ? '${loss.toInt()}%' : '-';
      final hasLoss = (loss ?? 0) > 0;
      return Row(
        children: [
          Expanded(
            child: Text(
              pText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            lText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: hasLoss ? FontWeight.w700 : FontWeight.w400,
              color: hasLoss ? Colors.redAccent : _greyOf(context).withValues(alpha: 0.65),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }

    return _tileContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.network_ping_rounded, size: 12, color: _greyOf(context).withValues(alpha: 0.75)),
              const SizedBox(width: 4),
              Text(
                '三网网络',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: _greyOf(context).withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              Text(
                '丢包',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: _greyOf(context).withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          line('电信', node.pingCt, node.lossCt),
          const SizedBox(height: 2.5),
          line('联通', node.pingCu, node.lossCu),
          const SizedBox(height: 2.5),
          line('移动', node.pingCm, node.lossCm),
        ],
      ),
    );
  }

  Widget _buildSystemTile(BuildContext context) {
    return _tileContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 12, color: _greyOf(context).withValues(alpha: 0.75)),
              const SizedBox(width: 4),
              Text(
                '运行状态',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: _greyOf(context).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l10n.cfLoad} ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: _greyOf(context).withValues(alpha: 0.75),
                  ),
                ),
                TextSpan(
                  text: node.load1.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '连接 ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: _greyOf(context).withValues(alpha: 0.75),
                  ),
                ),
                TextSpan(
                  text: 'TCP ${node.tcpConn}  UDP ${node.udpConn}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _greyOf(context).withValues(alpha: 0.9),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '进程 ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: _greyOf(context).withValues(alpha: 0.75),
                  ),
                ),
                TextSpan(
                  text: '${node.processes}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _greyOf(context).withValues(alpha: 0.9),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: node.online ? const Color(0xFF34C759) : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  node.name,
                  style: UIs.text15Bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (node.region case final region?) ...[
                const SizedBox(width: 5),
                _regionBadge(context, region),
              ],
              if (node.group case final group? when group.isNotEmpty && group.toLowerCase() != 'default') ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    group,
                    style: UIs.text12Grey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              _os(context),
              if (node.bootTime != null) ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _uptime(node.bootTime!),
                    style: UIs.text12Grey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (node.expireDate case final exp? when exp.isNotEmpty) ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '到期 ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _greyOf(context).withValues(alpha: 0.75),
                ),
              ),
              Text(
                exp,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _greyOf(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
        if (showPrice && node.price != null && node.price!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            node.price!,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: _greyOf(context).withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }

  /// The region as a plain code badge: a flag needs an emoji font the
  /// platform may not carry, and a two-letter code reads at 12pt.
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

  Widget _resourceBar({
    required BuildContext context,
    required String label,
    required double percent,
    required String detail,
    Color? color,
  }) {
    final effectiveColor = color ?? switch (percent) {
      > 85 => Colors.redAccent,
      > 60 => Colors.orangeAccent,
      _ => const Color(0xFF34C759),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(label, style: UIs.text12Grey),
          ),
          SizedBox(
            width: 52,
            child: Text(_percent(percent), style: UIs.text13Bold),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (percent / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(effectiveColor),
              ),
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(detail, style: UIs.text12Grey),
          ],
        ],
      ),
    );
  }

  /// The OS, with the mark the distro-icon mechanism ships for it when it
  /// recognises the free-text `os` field — and the generic machine icon when
  /// it does not, which is most of the time and says "not known", which is
  /// the truth.
  Widget _os(BuildContext context) {
    final os = node.os;
    if (os == null || os.isEmpty) return const SizedBox.shrink();
    return distIconOf(_distOf(os), size: 15) ??
        Icon(MingCute.linux_fill, size: 15, color: _greyOf(context));
  }

  Color _greyOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Which shipped distribution a free-text `os` names, the most specific of
  /// the names it contains — "Ubuntu 22.04" is `ubuntu`, "Void Linux" is
  /// `voidlinux`, and anything unreadable is no distribution at all.
  Dist? _distOf(String? os) {
    if (os == null) return null;
    final flat = os.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    Dist? best;
    for (final dist in Dist.values) {
      if (!flat.contains(dist.name)) continue;
      if (best == null || dist.name.length > best.name.length) best = dist;
    }
    return best;
  }

  String _uptime(int bootSeconds) {
    final d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(bootSeconds * 1000),
    );
    if (d.inDays > 0) return '${d.inDays} d ${d.inHours % 24} h';
    if (d.inHours > 0) return '${d.inHours} h';
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds} s';
  }

  static double _pctOf(int used, int total) =>
      total <= 0 ? 0 : (used / total).clamp(0.0, 1.0) * 100;

  static String _percent(double v) => '${v.toStringAsFixed(1)}%';

  /// The model keeps memory and disk in MB; the formatter speaks bytes.
  static String _mb(int mb) => (mb * 1024 * 1024).bytes2Str;
}
