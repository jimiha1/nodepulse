part of 'entry.dart';

/// The one "check update" row, drawn by the About page and by the App
/// settings group.
///
/// Defined once because the two call sites must agree: they read the same
/// notifier and the same three states, and a second copy is a second place
/// for the wording to drift. [trailing] is the only thing that differs —
/// the settings row carries the automatic-check switch, the About page
/// carries nothing.
Widget _checkUpdateTile(BuildContext context, {Widget? trailing}) {
  return ListTile(
    leading: const Icon(Icons.update),
    title: Text(libL10n.checkUpdate),
    subtitle: ValBuilder(
      listenable: AppUpdateIface.newestBuild,
      builder: (val) {
        String display;
        if (val != null) {
          if (val > BuildData.build) {
            display = libL10n.versionHasUpdate(val);
          } else {
            display = libL10n.versionUpdated(BuildData.build);
          }
        } else {
          display = libL10n.versionUnknownUpdate(BuildData.build);
        }
        return Text(display, style: UIs.textGrey);
      },
    ),
    onTap: () => Fns.throttle(
      () => AppUpdateIface.doUpdate(
        context: context,
        build: BuildData.build,
        githubReleasesUrl: Urls.githubReleasesApi,
        force: BuildMode.isDebug,
      ),
    ),
    trailing: trailing,
  );
}

final class _AppAboutPage extends StatelessWidget {
  const _AppAboutPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(13),
        children: [
          UIs.height13,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 47, maxWidth: 47),
            child: UIs.appIcon,
          ),
          const Text(
            '${BuildData.name}\nv${BuildData.build}',
            textAlign: TextAlign.center,
            style: UIs.text15,
          ),
          UIs.height13,
          CardX(child: _checkUpdateTile(context)),
        ],
      ),
    );
  }
}
