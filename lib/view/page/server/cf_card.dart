import 'dart:math' as math;
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 5),
              _resourceBars(context),
              const SizedBox(height: 7),
              // Modular 2x2 layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildNetworkTile(context)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTrafficTile(context)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPingLossTile(context)),
                  const SizedBox(width: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                '剩余流量',
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
                  text: '已用流量 ',
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
    required double detailWidth,
    Color? color,
  }) {
    final effectiveColor = color ?? switch (percent) {
      > 85 => Colors.redAccent,
      > 60 => Colors.orangeAccent,
      _ => const Color(0xFF34C759),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, style: UIs.text12Grey),
          ),
          SizedBox(
            width: _percentWidth,
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
          // Held open even when this row has no detail of its own: the CPU row
          // has nothing to say when the node reports no core count, and a bar
          // that grew into that gap would be the one bar of the three at a
          // different length.
          const SizedBox(width: _detailGap),
          SizedBox(
            width: detailWidth,
            child: Text(
              detail,
              style: UIs.text12Grey,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// The three resource rows, with one detail-column width shared between
  /// them so their bars end at the same x.
  ///
  /// The width is measured against the width the rows actually get: the
  /// labels and the percent column are fixed, and what is left over is what
  /// the bar and the detail have to divide. See [_detailWidthOf].
  Widget _resourceBars(BuildContext context) {
    final cpuDetail = node.cpuCores == null ? '' : 'x${node.cpuCores}';
    final ramDetail = _mbPair(node.ramUsed, node.ramTotal);
    final diskDetail = _mbPair(node.diskUsed, node.diskTotal);

    return LayoutBuilder(
      builder: (context, constraints) {
        final detailWidth = _detailWidthOf(
          context,
          [cpuDetail, ramDetail, diskDetail],
          constraints.maxWidth,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resourceBar(
              context: context,
              label: 'CPU',
              percent: node.cpu,
              detail: cpuDetail,
              detailWidth: detailWidth,
            ),
            _resourceBar(
              context: context,
              label: libL10n.memory,
              percent: _pctOf(node.ramUsed, node.ramTotal),
              detail: ramDetail,
              detailWidth: detailWidth,
              color: const Color(0xFF0A84FF),
            ),
            _resourceBar(
              context: context,
              label: libL10n.disk,
              percent: _pctOf(node.diskUsed, node.diskTotal),
              detail: diskDetail,
              detailWidth: detailWidth,
              color: const Color(0xFFFF9F0A),
            ),
          ],
        );
      },
    );
  }

  /// The width of the widest of [details], so the three rows can share one
  /// detail column and their bars can end at the same x.
  ///
  /// Measured rather than fixed: the string is a pair of `bytes2Str` results
  /// whose width follows the unit it lands on ("3 GB" against "435 MB"), and
  /// the column has to hold the widest the row will ever show. Clamped to
  /// [available] minus what the bar needs to stay a bar — past that the
  /// ellipsis on the row shortens the number instead of the bar.
  double _detailWidthOf(
    BuildContext context,
    List<String> details,
    double available,
  ) {
    var widest = 0.0;
    for (final detail in details) {
      if (detail.isEmpty) continue;
      final w = _measureText(context, detail, UIs.text12Grey);
      if (w > widest) widest = w;
    }
    if (widest == 0) return 0;
    // What the bar is allowed to keep: the label and percent columns, the
    // gap, and a bar still worth reading, all taken out of the row before the
    // detail gets the rest. A detail wider than that share is ellipsised
    // rather than allowed to leave the three bars a sliver. Measured against
    // the row rather than capped at a constant, because at a large text scale
    // a constant that fits at 1.0 no longer fits at all.
    final barFloor = _labelWidth + _percentWidth + _detailGap + _minBarWidth;
    final cap = available - barFloor;
    if (cap <= 0) return 0;
    return widest.clamp(0.0, cap);
  }

  /// The two fixed columns left of the bar, matching [_resourceBar].
  static const _labelWidth = 38.0;
  static const _percentWidth = 52.0;

  /// The gap between the bar and the detail column, matching [_resourceBar].
  static const _detailGap = 8.0;

  /// Below this the bar stops reading as a measure of anything.
  static const _minBarWidth = 40.0;

  /// [text]'s width as `Text` lays it out: [style] over the inherited one,
  /// which `Text` merges and a bare painter does not.
  static double _measureText(BuildContext context, String text, TextStyle style) {
    final inherited = DefaultTextStyle.of(context);
    final painter = TextPainter(
      text: TextSpan(text: text, style: inherited.style.merge(style)),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textWidthBasis: inherited.textWidthBasis,
      textHeightBehavior: inherited.textHeightBehavior,
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
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

  /// Formats a used / total MB pair into a compact string sharing the unit at the end,
  /// e.g. "4.9 / 12 GB", "53.6 / 98.1 GB", "1 / 4 GB", "20 / 40 GB".
  static String _mbPair(int usedMb, int totalMb) {
    if (totalMb <= 0) return '${_mb(usedMb)} / 0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final usedB = usedMb * 1024.0 * 1024.0;
    final totalB = totalMb * 1024.0 * 1024.0;

    var val = totalB;
    var idx = 0;
    while (val / 1024 >= 1 && idx < units.length - 1) {
      val /= 1024;
      idx++;
    }

    final unitStr = units[idx];
    final denom = math.pow(1024, idx);

    final usedVal = usedB / denom;
    final totalVal = totalB / denom;

    String fmt(double v) {
      final s = v.toStringAsFixed(1);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }

    return '${fmt(usedVal)} / ${fmt(totalVal)} $unitStr';
  }
}
