import 'package:extended_image/extended_image.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/core/utils/logo_url.dart';
import 'package:server_box/data/model/server/dist.dart';
import 'package:server_box/data/res/store.dart';

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

  Color _tintColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final dist = this.dist;
    if (dist == null) return const SizedBox.shrink();

    final asset = dist.markAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        color: _tintColor(context),
      );
    }

    final url = distMarkUrl(dist: dist, dark: context.isDark);
    if (url == null) return const SizedBox.shrink();

    final urlStr = url;
    if (_isSvgUrl(urlStr)) {
      return SvgPicture.network(
        urlStr,
        width: size,
        height: size,
        colorFilter: _tint(context),
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
