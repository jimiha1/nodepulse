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
              const SizedBox(height: 7),
              _usage(
                'CPU',
                node.cpu,
                node.cpuCores == null ? null : 'x${node.cpuCores}',
              ),
              _usage(
                libL10n.memory,
                _pctOf(node.ramUsed, node.ramTotal),
                '${_mb(node.ramUsed)} / ${_mb(node.ramTotal)}',
              ),
              _usage(
                libL10n.disk,
                _pctOf(node.diskUsed, node.diskTotal),
                '${_mb(node.diskUsed)} / ${_mb(node.diskTotal)}',
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 13,
                runSpacing: 5,
                children: [
                  _os(context),
                  _kv(l10n.cfLoad, node.load1.toStringAsFixed(2)),
                  Text('↓ ${node.netInSpeed.bytes2Str}/s', style: UIs.text13),
                  Text('↑ ${node.netOutSpeed.bytes2Str}/s', style: UIs.text13),
                  _kv(
                    libL10n.total,
                    '↓ ${node.netRxMonthly.bytes2Str} ↑ ${node.netTxMonthly.bytes2Str}',
                  ),
                  _kv('TCP', '${node.tcpConn}'),
                  _kv('UDP', '${node.udpConn}'),
                ],
              ),
              if (node.bootTime != null || node.trafficUsedRatio >= 0) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 13,
                  runSpacing: 5,
                  children: [
                    if (node.bootTime != null)
                      _kv(libL10n.uptime, _uptime(node.bootTime!)),
                    if (node.trafficUsedRatio >= 0)
                      _kv(
                        l10n.cfTrafficRemaining,
                        (node.trafficLimitBytes - node.trafficUsedBytes)
                            .clamp(0, 1 << 62)
                            .bytes2Str,
                      ),
                  ],
                ),
              ],
              if (_pings().isNotEmpty || (showExpire && node.expireDate != null))
                ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 13,
                    runSpacing: 5,
                    children: [
                      ..._pings(),
                      if (showExpire && node.expireDate != null)
                        _expireItem(context),
                    ],
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: node.online ? Colors.lightGreen : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
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

  /// One share of the machine, as a fixed-width reading: the label, the
  /// percentage and whatever qualifies it, on one line.
  Widget _usage(String label, double percent, String? detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: UIs.text12Grey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 62,
            child: Text(_percent(percent), style: UIs.text13),
          ),
          Expanded(
            child: Text(
              detail ?? '',
              style: UIs.text12Grey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: UIs.text12Grey),
          TextSpan(text: value, style: UIs.text13),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// The OS, with the mark the distro-icon mechanism ships for it when it
  /// recognises the free-text `os` field — and the generic machine icon when
  /// it does not, which is most of the time and says "not known", which is
  /// the truth.
  Widget _os(BuildContext context) {
    final os = node.os;
    if (os == null || os.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      distIconOf(_distOf(os), size: 14) ??
          Icon(MingCute.linux_fill, size: 14, color: _greyOf(context)),
      const SizedBox(width: 3),
      Text(os, style: UIs.text12Grey),
    ]);
  }

  /// The three mainland pings, the ones that exist. A null ping is a timeout
  /// or an unconfigured probe — either way it has no number to show, so it
  /// takes no slot: three dashes read as a row that is broken, and omitting
  /// the ones that are absent reads as a row that is short.
  List<Widget> _pings() {
    Text? at(String label, double? ms) => switch (ms) {
      null => null,
      final v => Text(
        '$label ${v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0)}ms',
        style: UIs.text13,
      ),
    };
    return [?at('CT', node.pingCt), ?at('CU', node.pingCu), ?at('CM', node.pingCm)];
  }

  Widget _expireItem(BuildContext context) {
    final price = showPrice ? node.price : null;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('${l10n.cfExpire} ', style: UIs.text12Grey),
      Text(node.expireDate ?? '--', style: UIs.text13),
      if (price case final p? when p.isNotEmpty) ...[
        const SizedBox(width: 5),
        Text(p, style: UIs.text12Grey),
      ],
    ]);
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
