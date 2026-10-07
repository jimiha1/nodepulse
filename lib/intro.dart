part of 'app.dart';

/// One step of the intro, and the question of whether it applies.
///
/// The predicate travels with the page. It used to be a number keyed into a
/// map, tested in a `where` several methods away — so adding a step meant two
/// edits in two places, and the condition for a step was nowhere near the step
/// it belonged to.
typedef _IntroStep = ({Future<bool> Function() applies, IntroPageBuilder build});

/// The latest revision of the feature pages — see
/// [SettingStore.featureIntroVer]. A page added later names the next number,
/// and this moves to it.
const _kFeatureIntroVer = 2;

final class _IntroPage extends StatelessWidget {
  const _IntroPage(this.pages);

  final List<IntroPageBuilder> pages;

  static final _setting = Stores.setting;

  static const _kIntroListPad = 17.0;
  static const _kMaxPadTop = 120.0;

  /// Every step there is, in the order they are shown.
  ///
  /// A list rather than a map: the order is the list's, and nothing needs a
  /// number to refer to a step by.
  static List<_IntroStep> get _steps => [
    (applies: _needsBackupPassword, build: _buildBackupPasswordMigration),
  ];

  /// The steps this launch should show.
  static Future<List<IntroPageBuilder>> get builders async {
    final builders = <IntroPageBuilder>[];
    for (final step in _steps) {
      if (await step.applies()) builders.add(step.build);
    }
    return builders;
  }

  // — When a step applies ————————————————————————————————————————————

  /// Upgrading from a build that predates the backup password, without one set.
  ///
  /// `lastVer > 0` is what separates an upgrade from a first install: a fresh
  /// one has no data to protect and is offered the password elsewhere.
  static Future<bool> _needsBackupPassword() async {
    if (_setting.lastVer.fetch() == 0) return false;
    if (_setting.introVer.fetch() >= 2) return false;
    return (await SecureStoreProps.bakPwd.read())?.isNotEmpty != true;
  }

  // — Widget build ——————————————————————————————————————————————————

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        // Proportional on phones, capped so a tall desktop window doesn't push
        // the title halfway down the screen — it is used twice per page, above
        // and below the title.
        final padTop = (cons.maxHeight * .16).clamp(0.0, _kMaxPadTop);
        return IntroPage(
          key: ValueKey(Localizations.localeOf(context)),
          args: IntroPageArgs(
            pages: pages.map((e) => e(context, padTop)).toList(),
            maxWidth: PageColumns.columnWidth,
            onDone: _onDone,
          ),
        );
      },
    );
  }

  static void _onDone(BuildContext ctx) {
    SqliteStore.transact(() {
      _setting.introVer.putSync(BuildData.build);
      final lastVer = _setting.lastVer;
      if (lastVer.fetch() == 0) lastVer.putSync(BuildData.build);
      _setting.featureIntroVer.putSync(_kFeatureIntroVer);
    });
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(builder: (_) => _buildHomeWithWindowFrame()),
    );
  }

  // — Shared pieces —————————————————————————————————————————————————

  /// Keeps the content in the same column the rest of the app reads in, while
  /// the scrollbar stays at the window edge.
  static Widget _introList({required List<Widget> children}) {
    // [IntroPage] is a bare `Scaffold` holding a `PageView`, so a page's
    // viewport starts at the very top of the screen — and a list long enough
    // to scroll draws its title over the clock and the status icons. Bounding
    // the viewport rather than padding the list is what clips it there, which
    // is the difference between a title that stops under the status bar and
    // one that slides past it.
    //
    // `bottom: false` because the page already ends in a `BottomAppBar`, and
    // outside the [LayoutBuilder] so the width the column is centred in is the
    // one left after a landscape cutout.
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (_, cons) {
          final rest = (cons.maxWidth - PageColumns.columnWidth) / 2;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: math.max(rest, _kIntroListPad),
            ),
            children: children,
          );
        },
      ),
    );
  }

  // — Pages —————————————————————————————————————————————————————————

  static Widget _buildBackupPasswordMigration(BuildContext ctx, double padTop) {
    final l10n = ctx.l10n;

    return _introList(
      children: [
        SizedBox(height: padTop),
        IntroPage.title(text: l10n.backupPassword, big: true),
        SizedBox(height: padTop * 0.5),
        Text(
          l10n.backupTip,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: padTop * 0.5),
        ListTile(
          leading: const Icon(Icons.lock, color: Colors.orange),
          title: Text(l10n.backupPassword),
          subtitle: Text(l10n.backupPasswordTip, style: UIs.textGrey),
          trailing: const Icon(Icons.keyboard_arrow_right),
          onTap: () => _askBackupPassword(ctx),
        ).cardx,
        // Nothing further here: the two lines above — `backupTip` under the
        // title and `backupPasswordTip` on the tile — already say what this
        // step is and why. A third sentence restating it was also the one
        // string on this page that was never translated.
        UIs.height77,
      ],
    );
  }

  // — Actions ———————————————————————————————————————————————————————

  static Future<void> _askBackupPassword(BuildContext ctx) async {
    final controller = MaskedTextEditingController();
    final result = await ctx.showRoundDialog<bool>(
      title: ctx.l10n.backupPassword,
      // Disposed by the tree. It was never disposed at all before, which leaks
      // one controller per visit and — unlike the crash the same shape causes
      // elsewhere — says nothing about it.
      child: DisposeWith(
        notifiers: [controller],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.l10n.backupPasswordTip, style: UIs.textGrey),
            UIs.height13,
            MaskedInput(
              label: ctx.l10n.backupPassword,
              controller: controller,
              // `popDialog`, not `pop`: the dialog is on the root navigator
              // and `ctx` is the page's. It happens to be the same one today
              // only because the intro is `MaterialApp.home` — under a pane or
              // a tab this would close the page, leave the dialog up, and
              // never complete the future the password is written from.
              onSubmitted: (_) => ctx.popDialog(true),
            ),
          ],
        ),
      ),
      actions: Btnx.cancelOk,
    );
    if (result != true) return;

    final pwd = controller.text.trim();
    if (pwd.isEmpty) return;
    await SecureStoreProps.bakPwd.write(pwd);
    Toast.show(ctx.l10n.backupPasswordSet);
  }
}
