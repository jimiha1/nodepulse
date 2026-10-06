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

const _sponsorUrl = 'https://cdn.lollipopkit.com/donate';

final class _AppAboutPage extends StatefulWidget {
  const _AppAboutPage();

  @override
  State<_AppAboutPage> createState() => _AppAboutPageState();
}

final class _AppAboutPageState extends State<_AppAboutPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          SizedBox(
            height: 77,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Btn.elevated(
                  icon: const Icon(Icons.edit_document),
                  text: libL10n.menuWiki,
                  onTap: Urls.appWiki.launchUrl,
                ),
                Btn.elevated(
                  icon: const Icon(Icons.feedback),
                  text: libL10n.feedback,
                  onTap: Urls.appHelp.launchUrl,
                ),
                Btn.elevated(
                  icon: const Icon(MingCute.question_fill),
                  text: libL10n.license,
                  onTap: () => showLicensePage(context: context),
                ),
                Btn.elevated(
                  icon: const Icon(MingCute.heart_fill),
                  text: l10n.sponsor,
                  onTap: () => _sponsorUrl.launchUrl(),
                ),
              ].joinWith(UIs.width13),
            ),
          ),
          UIs.height13,
          // The DB-IP line is required, not courteous: the city data is a CC BY
          // 4.0 derivative and attribution has to travel with it. Nothing is
          // bundled any more — the download is the whole of it — so this page
          // is not where the licence condition is discharged; the consent
          // dialog carries the manifest's own attribution line, which is the
          // copy that arrives with the data. It is repeated here because that
          // dialog is seen once, and somebody looking for what this app is
          // built on looks at About.
          SimpleMarkdown(
            data:
                '''
#### Map data
IP geolocation by [DB-IP](https://db-ip.com), used under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Built into
[ipgeo-shards](${Urls.geoDataRepo}), which is where the recipe is.

Coastlines from [Natural Earth](https://www.naturalearthdata.com/), which is
in the public domain. Named as a source, not as an endorsement — the project
asks that none be implied.

#### Contributors
${GithubIds.contributors.map((e) => e.prsMarkdownLink).join(' ')}

#### Participants
${GithubIds.participants.map((e) => e.issuesMarkdownLink).join(' ')}

#### My other apps
[GPT Box](https://github.com/lollipopkit/flutter_gpt_box)

${l10n.madeWithLove('[lollipopkit](${Urls.myGithub})')}
''',
          ).paddingAll(13).cardx,
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
