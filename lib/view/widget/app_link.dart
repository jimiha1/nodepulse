import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/data/model/app/app_link.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/data/model/server/server_private_info.dart';
import 'package:server_box/data/provider/app/session_requests.dart';
import 'package:server_box/data/provider/server/all.dart';
import 'package:server_box/view/page/server/edit/edit.dart';
import 'package:server_box/view/widget/server_func_btns.dart';

/// Acts on a `serverbox://` link, and puts one on the clipboard.
///
/// Every action goes through the path the same button in the app takes, so a
/// link can do nothing a tap could not — and asks wherever that tap asks:
/// connecting, a snippet's countdown, saving a new server.
abstract final class AppLinkUi {
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    String raw,
  ) async {
    final link = AppLink.parse(raw);
    if (link == null) {
      Loggers.app.warning('Unhandled link: $raw');
      Toast.error(libL10n.invalidUrl);
      return;
    }
    switch (link) {
      case ServerLink(:final id, :final func):
        final spi = _server(ref, id);
        if (spi == null) return;
        if (func == null) {
          ref.read(serverDetailRequestProvider.notifier).go(id);
          ref.read(homeTabRequestProvider.notifier).go(AppTab.server);
        } else {
          runServerFunc(func, spi, context, ref);
        }
      case AddServerLink(:final name, :final host, :final port, :final user):
        await ServerEditPage.route.go(
          context,
          args: ServerEditArgs.draft((
            name: name,
            host: host,
            port: port,
            user: user,
          )),
        );
      case TabLink(:final tab):
        ref.read(homeTabRequestProvider.notifier).go(tab);
    }
  }

  static void copy(AppLink link) {
    Pfs.copy(link.toString());
    Toast.success(libL10n.success);
  }

  static Spi? _server(WidgetRef ref, String id) {
    final spi = ref.read(serversProvider).servers[id];
    if (spi == null) Toast.error(libL10n.notExistFmt('${libL10n.server} $id'));
    return spi;
  }
}
