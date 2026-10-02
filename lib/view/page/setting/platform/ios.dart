import 'package:fl_lib/fl_lib.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/core/chan.dart';
import 'package:server_box/core/extension/context/inset.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/core/utils/misc.dart';
import 'package:server_box/data/res/store.dart';

class IosSettingsPage extends StatefulWidget {
  /// Whether it is being shown inside the settings pane rather than pushed.
  ///
  /// The pane already names what it is showing, in the one bar the page has;
  /// a second one under it would say it twice.
  final bool embedded;

  const IosSettingsPage({super.key, this.embedded = false});

  @override
  State<IosSettingsPage> createState() => _IosSettingsPageState();

  static const route = AppRouteNoArg(
    page: IosSettingsPage.new,
    path: '/settings/ios',
  );
}

class _IosSettingsPageState extends State<IosSettingsPage> {
  final _pushToken = ValueNotifier<String?>(null);

  late final _pushTokenFuture = getToken();

  /// Whether iOS itself would allow one. Read once per visit to this page: the
  /// user can change it in Settings, but only by leaving this one.
  late final _liveActivityAvailableFuture = MethodChans.liveActivityAvailable();

  void _showCopyResult(bool success) {
    if (success) {
      Toast.success(libL10n.success);
    } else {
      Toast.error(libL10n.fail);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pushToken.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: context.padBottom(const EdgeInsets.symmetric(horizontal: 17)),
      children: [
        _buildPushToken(),
        _buildLiveActivity(),
        _buildAutoUpdateHomeWidget(),
      ].nonNulls.map((e) => CardX(child: e)).toList(),
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: CustomAppBar(title: const Text('iOS')),
      body: body,
    );
  }

  Widget _buildPushToken() {
    return ListTile(
      title: Text(l10n.pushToken),
      trailing: IconButton(tooltip: libL10n.copy, 
        icon: const Icon(Icons.copy),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.zero,
        onPressed: () {
          final val = _pushToken.value;
          if (val != null) {
            Pfs.copy(val);
            _showCopyResult(true);
          } else {
            _showCopyResult(false);
          }
        },
      ),
      subtitle: FutureWidget<String?>(
        future: _pushTokenFuture,
        loading: const Text('...'),
        error: (error, trace) => Text('${libL10n.error}: $error'),
        success: (text) {
          _pushToken.value = text;
          return Text(
            text ?? 'null',
            style: UIs.textGrey,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        },
      ),
    );
  }

  /// One switch for every Live Activity this app raises.
  ///
  /// Off by default, and a change of behaviour: one used to appear whenever a
  /// terminal connected, with nothing to stop it. What it shows — a server's
  /// name, and the state of a connection to it — is readable without unlocking
  /// the phone, so it is opted into rather than out of.
  ///
  /// The subtitle carries the system's answer as well as the app's, because
  /// they fail identically from the user's side: the switch is on, nothing
  /// appears, and only one of the two places says why.
  Widget _buildLiveActivity() {
    return ListTile(
      title: Text(l10n.liveActivity),
      subtitle: FutureWidget<bool>(
        future: _liveActivityAvailableFuture,
        loading: Text(l10n.liveActivityTip, style: UIs.textGrey),
        error: (e, _) => Text('${libL10n.error}: $e', style: UIs.textGrey),
        success: (available) => Text(
          available == true
              ? l10n.liveActivityTip
              : l10n.liveActivitySystemDisabled,
          style: UIs.textGrey,
        ),
      ),
      trailing: StoreSwitch(prop: Stores.setting.liveActivity),
    );
  }

  Widget _buildAutoUpdateHomeWidget() {
    return ListTile(
      title: Text(l10n.autoUpdateHomeWidget),
      subtitle: Text(l10n.whenOpenApp, style: UIs.textGrey),
      trailing: StoreSwitch(prop: Stores.setting.autoUpdateHomeWidget),
    );
  }
}
