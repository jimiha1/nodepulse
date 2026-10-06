import 'package:extended_image/extended_image.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/core/utils/logo_url.dart';
import 'package:nodepulse/data/model/server/dist.dart';
import 'package:nodepulse/data/res/store.dart';

String? distMarkUrl({required Dist? dist, required bool dark}) {
  final configured = Stores.setting.serverMarkUrl.fetch();
  if (configured.isEmpty) return null;

  var url = resolveLogoUrl(configured);
  if (url.contains(_distToken)) {
    if (dist == null) return null;
    url = url.replaceAll(_distToken, distFileName(dist));
  }
  url = url.replaceAll(_brightToken, dark ? 'dark' : 'light');
  return isFetchableLogoUrl(url) ? url : null;
}

String distFileName(Dist dist) =>
    Stores.setting.distNameMap.fetch()[dist.name] ?? dist.name;

bool _isSvgUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.svg');
}

const _distToken = '{DIST}';
const _brightToken = '{BRIGHT}';

Widget? distIcon(String serverId, {double size = 20}) =>
    Stores.setting.showDistMark.fetch() ? DistIcon(serverId, size: size) : null;

Widget? distIconOf(Dist? dist, {double size = 20}) =>
    Stores.setting.showDistMark.fetch() ? DistIconOf(dist, size: size) : null;

class DistIcon extends StatelessWidget {
  const DistIcon(this.serverId, {super.key, this.size = 20});

  final String serverId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!Stores.setting.showDistMark.fetch()) return const SizedBox.shrink();

    return StreamBuilder<void>(
      stream: Stores.serverDist.changes,
      builder: (_, _) =>
          DistIconOf(Stores.serverDist.get(serverId), size: size),
    );
  }
}

class DistIconOf extends StatelessWidget {
  const DistIconOf(this.dist, {super.key, this.size = 20});

  final Dist? dist;
  final double size;

  ColorFilter _tint(BuildContext context) =>
      ColorFilter.mode(_tintColor(context), BlendMode.srcIn);

  Color _tintColor(BuildContext context) =>
      IconTheme.of(context).color ??
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Drawn wherever there is no mark: no address and no shipped file, an
  /// address that could not be fetched, or a distribution nothing recognised.
  ///
  /// A blank of the same size would keep the row from shifting just as well,
  /// but it reads as something missing; an icon reads as "not known", which is
  /// the truth.
  ///
  /// Two of them, because there are two different things not to know. A
  /// distribution that *was* recognised and simply has no mark here — Ubuntu
  /// is the case most people will meet — is a Linux for certain, and a penguin
  /// says so. One that was not recognised at all might be a BSD, macOS or
  /// Windows, all of which `uname -or` reaches, so the penguin would be a
  /// guess and the machine is all that can be claimed.
  ///
  /// Takes the same colour as the marks, so a column of them is one column.
  Widget _fallback(BuildContext context) => Icon(
    dist?.isLinux == true ? MingCute.linux_fill : BoxIcons.bxs_server,
    size: size,
    color: _tintColor(context),
  );

  @override
  Widget build(BuildContext context) {
    // Belt and braces. Every call site goes through `distIconOf`, which answers
    // null and lets the slot be omitted — but a widget built directly must not
    // draw a mark the switch says is off.
    if (!Stores.setting.showDistMark.fetch()) return const SizedBox.shrink();

    final dist = this.dist;

    final asset = dist?.markAsset;
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: _tint(context),
        semanticsLabel: dist?.name,
      );
    }

    if (dist == null) return _fallback(context);

    final url = distMarkUrl(dist: dist, dark: context.isDark);
    if (url == null) return _fallback(context);

    final urlStr = url;
    if (_isSvgUrl(urlStr)) {
      return SvgPicture.network(
        urlStr,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: _tint(context),
        semanticsLabel: dist.name,
        placeholderBuilder: (_) => SizedBox.square(dimension: size),
        errorBuilder: (_, _, _) => _fallback(context),
      );
    }

    return ExtendedImage.network(
      urlStr,
      width: size,
      height: size,
      color: _tintColor(context),
    );
  }
}
