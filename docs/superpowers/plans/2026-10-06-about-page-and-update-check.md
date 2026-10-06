# About Page Trim & Update-Check Repointing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trim the About page to icon + version + a "check update" row, and point every update check (and the crash-report link) at this fork's own GitHub repository instead of upstream's.

**Architecture:** The update machinery already exists in the vendored `fl_lib` package (`AppUpdateIface.doUpdate` + `AppUpdate.fromGitHubReleasesUrl`). This plan changes only *which repository* it reads and *where the row lives*: it repoints the URL constants in `lib/data/res/url.dart`, rewrites `about.dart` to a one-row page, and lifts the row's widget into a shared builder so the About page and the existing App-settings row render the same thing from one definition.

**Tech Stack:** Flutter 3.47 / Dart; `fl_lib` (vendored submodule, not modified); `flutter_test`; `flutter analyze`.

## Global Constraints

- **Never run code formatters.** Formatting is deliberate; match the style of the file you edit.
- **Never hand-edit `*.g.dart` / `*.freezed.dart`.**
- **No new ARB strings.** Reuse fl_lib's existing `libL10n.checkUpdate` / `versionHasUpdate` / `versionUpdated` / `versionUnknownUpdate`.
- **Do not modify anything under `packages/`** (vendored submodules).
- **Commit prefix:** one lowercase prefix + imperative English description (`feat:`, `fix:`, `docs:`, `refactor:`, `rm:`, `chore:`).
- **Commands run from Git Bash at repo root.** `make` is NOT available on this machine — use `flutter` directly. `crates/` and the root `Cargo.toml` were removed by the trim, so there is no Rust pre-build step.
- **The app is usually already running from the user's IDE.** Do not start a second `flutter run`. Apply Dart changes via the dart MCP server (`dtd` → `listDtdUris` → `connect` → `hot_reload`; `hot_restart` for anything before `runApp`).
- **Target values (verbatim):**
  - `myGithub` = `https://github.com/jimiha1`
  - `githubApi` = `https://api.github.com/repos/jimiha1`
  - `thisRepo` = `$myGithub/cf_server_box`
  - `githubReleasesApi` = `$githubApi/cf_server_box/releases`
  - Current build = `1719`

---

### Task 1: Repoint the repository URL constants

**Files:**
- Modify: `lib/data/res/url.dart:1-22` (the four identity constants) and remove the dead constants at `:20-22`, `:86-98`
- Test: `test/unit/app/urls_test.dart` (create)

**Interfaces:**
- Consumes: nothing.
- Produces: `Urls.githubReleasesApi` → `https://api.github.com/repos/jimiha1/cf_server_box/releases`; `Urls.newIssue` → `https://github.com/jimiha1/cf_server_box/issues/new`. `Urls.geoData` and `Urls.geoDataFallback` no longer exist. `Urls.myGithub`, `Urls.thisRepo`, `Urls.rawRepo`, `Urls.themeCatalog`, `Urls.site`, `Urls.docs`, `Urls.privacyPolicy` and the doc links remain. `Urls.appWiki`, `Urls.appHelp`, `Urls.geoDataRepo` and `Urls.appStore` **also remain** — their last readers are removed by Tasks 3 and 4, and deleting them here would leave `flutter analyze` failing at this commit.

- [ ] **Step 1: Write the failing test**

Create `test/unit/app/urls_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/res/url.dart';

/// The update check and the crash-report link both read this fork's own
/// repository. An upstream merge that restores the original owner would
/// silently point them at a project this build is not.
void main() {
  test('the update check reads this fork releases', () {
    expect(
      Urls.githubReleasesApi,
      'https://api.github.com/repos/jimiha1/cf_server_box/releases',
    );
  });

  test('a crash report is filed against this fork', () {
    expect(
      Urls.newIssue,
      'https://github.com/jimiha1/cf_server_box/issues/new',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/app/urls_test.dart`
Expected: FAIL — both expectations report the upstream `lollipopkit/flutter_server_box` URLs.

- [ ] **Step 3: Repoint the identity constants**

In `lib/data/res/url.dart`, change the first four lines to:

```dart
abstract final class Urls {
  static const myGithub = 'https://github.com/jimiha1';
  static const githubApi = 'https://api.github.com/repos/jimiha1';
  static const thisRepo = '$myGithub/cf_server_box';
```

`githubReleasesApi` (currently `:19`) then reads `$githubApi/cf_server_box/releases` — change the literal to match:

```dart
  static const githubReleasesApi = '$githubApi/cf_server_box/releases';
```

- [ ] **Step 4: Delete the two constants that are already dead**

In the same file, delete the `geoData` block — `geoData` (`:86`), `geoDataFallback` (`:94-95`) and the doc comments above each.

These two have no reader at all any more: the city-level IP geolocation feature was removed by the trim (`IpGeo` and its download logic no longer exist), and their only remaining reference was the About-page card this plan deletes. `ipgeo-shards` is upstream's repository and does not follow the fork rename, which is why they cannot be fixed by changing `myGithub`.

**Do not delete `appWiki`, `appHelp`, `geoDataRepo` or `appStore` here.** They still have live readers in `about.dart` (Tasks 3) and `home.dart` (Task 4); removing them now would leave `flutter analyze` failing at this commit. Each is deleted by the task that removes its last reader.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/app/urls_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/data/res/url.dart test/unit/app/urls_test.dart
git commit -m "feat: point the update check and issue link at this fork"
```

---

### Task 2: Lift the check-update row into one shared builder

**Files:**
- Modify: `lib/view/page/setting/about.dart` (add the builder; the page rewrite is Task 3)
- Modify: `lib/view/page/setting/entries/app.dart:106-142` (`_buildCheckUpdate` delegates to it)

**Interfaces:**
- Consumes: `Urls.githubReleasesApi` (Task 1).
- Produces: `Widget _checkUpdateTile(BuildContext context, {Widget? trailing})` — a top-level function in `about.dart`. Both `about.dart` and `entries/app.dart` are `part` files of `entry.dart`, so the function is visible to both with no import. It returns a `ListTile` whose `onTap` is throttled and calls `AppUpdateIface.doUpdate`.

- [ ] **Step 1: Add the shared builder to `about.dart`**

Insert after the `part of 'entry.dart';` line in `lib/view/page/setting/about.dart`:

```dart
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
```

Note the two deliberate differences from the current `_buildCheckUpdate`: `storeUrl: Urls.appStore` is gone (the constant no longer exists; it only ever mattered on iOS, and this build ships Android only), and `trailing` is a parameter.

- [ ] **Step 2: Delegate the settings row to it**

Replace the body of `_buildCheckUpdate` in `lib/view/page/setting/entries/app.dart` (currently `:106-142`) with:

```dart
  SettingsRow _buildCheckUpdate() {
    final label = libL10n.checkUpdate;
    return SettingsRow(
      label,
      () => _checkUpdateTile(
        context,
        trailing: StoreSwitch(prop: _setting.autoCheckAppUpdate),
      ),
      keywords: 'v${BuildData.build}',
    );
  }
```

- [ ] **Step 3: Verify it compiles and behaves the same**

Run: `flutter analyze lib`
Expected: `No issues found!`

Then hot-reload the running app and confirm the App settings page → 更新 → 「检查更新」 row still shows the same subtitle and still carries the auto-check switch. (If the IDE-run app is not attached, defer this to the smoke test in Task 5.)

- [ ] **Step 4: Commit**

```bash
git add lib/view/page/setting/about.dart lib/view/page/setting/entries/app.dart
git commit -m "refactor: draw the update row from one definition"
```

---

### Task 3: Rewrite the About page and delete the contributors table

**Files:**
- Modify: `lib/view/page/setting/about.dart` (replace the page body)
- Modify: `lib/view/page/setting/entry.dart:22` (drop the `github_id.dart` import)
- Modify: `lib/data/res/url.dart` (delete the three constants this task orphans)
- Delete: `lib/data/res/github_id.dart`

**Interfaces:**
- Consumes: `_checkUpdateTile` (Task 2).
- Produces: `_AppAboutPage` as a `StatelessWidget` showing the icon, the version line and the check row. `Urls.appWiki`, `Urls.appHelp` and `Urls.geoDataRepo` no longer exist. `Urls.appStore` still exists (Task 4 removes it).

- [ ] **Step 1: Replace the page**

In `lib/view/page/setting/about.dart`, delete `const _sponsorUrl = ...` and everything from `final class _AppAboutPage extends StatefulWidget {` to the end of the file, then append:

```dart
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
```

The `AutomaticKeepAliveClientMixin` goes with the state class: it was left over from the old tab layout, the settings tree is now a `PageView` of leaf pages, and no other leaf page keeps itself alive. There is no state here worth keeping.

- [ ] **Step 2: Drop the now-unused import**

In `lib/view/page/setting/entry.dart`, delete line 22:

```dart
import 'package:server_box/data/res/github_id.dart';
```

- [ ] **Step 3: Delete the contributors table**

```bash
git rm lib/data/res/github_id.dart
```

Its only reader was the contributors/participants Markdown card removed in Step 1.

- [ ] **Step 4: Delete the constants this task orphaned**

In `lib/data/res/url.dart`, delete these three and their doc comments:

- `static const appHelp = '$thisRepo#-help';`
- `static const appWiki = '$thisRepo/wiki';`
- `static const geoDataRepo = '$myGithub/ipgeo-shards';`

The two app links were read only by the Wiki and 反馈 buttons deleted in Step 1; `geoDataRepo` was read only by the Markdown card. Nothing else references them.

- [ ] **Step 5: Verify no dangling references**

Run: `grep -rn "GithubIds\|Urls.appWiki\|Urls.appHelp\|Urls.geoData" lib/`
Expected: no output (the contributors list, the Wiki/反馈 buttons and every geo constant are gone).

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/view/page/setting/about.dart lib/view/page/setting/entry.dart lib/data/res/url.dart lib/data/res/github_id.dart
git commit -m "feat: trim the about page to version and update check"
```

---

### Task 4: Drop the store URL from the launch-time check and fix the stale comment

**Files:**
- Modify: `lib/view/page/home.dart:257` (drop `storeUrl`)
- Modify: `lib/data/res/url.dart` (delete `appStore`, its last reader)
- Modify: `lib/data/model/server/dist_license.dart:1-16` (doc comment only)

**Interfaces:**
- Consumes: nothing.
- Produces: `Urls.appStore` no longer exists. Nothing new; this is a call-site fix plus a stale-comment correction.

- [ ] **Step 1: Drop the store URL from the launch-time check**

In `lib/view/page/home.dart`, in the `AppUpdateIface.doUpdate(...)` call (around `:252-260`), delete the line:

```dart
          storeUrl: Urls.appStore,
```

It only ever applied to iOS, which this build does not ship — and with Task 2's row no longer passing it either, nothing reads the constant.

- [ ] **Step 2: Delete the now-orphaned constant**

In `lib/data/res/url.dart`, delete:

```dart
  static const appStore = 'https://apps.apple.com/app/id1586449703';
```

- [ ] **Step 3: Correct the license-registry comment**

In `lib/data/model/server/dist_license.dart`, the class doc currently says the notices are reachable at "Settings → About → License". That entry no longer exists. Replace the first paragraph (`:3-5`) with:

```dart
/// Puts the shipped marks' terms where [LicenseRegistry] collects them.
///
/// This build no longer opens Flutter's `showLicensePage` from anywhere, so
/// these entries are not currently rendered. The registration is kept because
/// the notices still ship — `assets/distro/README.md` carries the same text —
/// and because dropping it would make the bundle's contents and its terms
/// diverge. Three of the four are under a Creative Commons licence — Alpine's
/// mark is simple enough that no copyright subsists in it — and every one of
/// those asks for credit "in any reasonable manner based on the medium,
/// means, and context".
```

Leave the rest of the file (the four license bodies and `registerDistMarkLicenses`) untouched.

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/view/page/home.dart lib/data/res/url.dart lib/data/model/server/dist_license.dart
git commit -m "fix: drop the store URL from the launch-time update check"
```

---

### Task 5: Full verification and device smoke test

**Files:** none (verification only).

**Interfaces:**
- Consumes: all of the above.
- Produces: a verified build.

- [ ] **Step 1: Analyze the whole tree**

Run: `flutter analyze lib test`
Expected: `No issues found!`

- [ ] **Step 2: Run the new test and the app's unit suite**

Run: `flutter test test/unit/app/urls_test.dart`
Expected: PASS (2 tests).

Run: `flutter test test/unit/`
Expected: all pass. (Baseline: this suite was green before the change; if a pre-existing failure appears, note it and confirm it also fails on the pre-change commit rather than assuming this change caused it.)

- [ ] **Step 3: Hot-restart the running app**

Via the dart MCP server: `dtd` → `listDtdUris` → `connect` → `hot_restart` (the page class changed shape, so a hot restart rather than a reload). Do not start a second `flutter run`.

- [ ] **Step 4: Smoke-test the About page on device**

Long-press the overview card on the home page → 设置 → 关于. Confirm:

1. The page shows the app icon and `ServerBox v1719` — nothing else above the row.
2. The row reads 「检查更新」 with subtitle 「当前：v1.0.1719，点击检查更新」.
3. Tapping it completes without a crash and without an unexpected dialog; with zero releases published, logcat shows the check finding nothing and the subtitle stays as it was.
4. The four buttons (Wiki / 反馈 / 许可证 / 赞助) and the Markdown card are gone.
5. Going to 设置 → 应用 → 更新 shows the same row, still with the auto-check switch.

- [ ] **Step 5: Confirm nothing else regressed**

Run: `git status --short`
Expected: only the files this plan touched are modified; `.superpowers/sdd/progress.md`, `.zcodeignore` and `test_real_req.json` may appear but are pre-existing and must not be committed.

---

## Notes for the reviewer

- **No new ARB strings and no `make gen`:** every string reused already exists in `fl_lib`'s `libL10n` and in the app's own `l10n`.
- **Why no widget test for the page:** `_AppAboutPage` is private and its behaviour is a thin wrapper over fl_lib's `AppUpdateIface`, which fl_lib already covers with `update_test.dart` and `update_iface_test.dart`. The one decision worth pinning — which repository is read — is pinned by `urls_test.dart`.
- **The check cannot report a new version yet:** `jimiha1/cf_server_box` has no releases. That is a valid state, not a bug; the "update found" path becomes exercisable the first time a release is published with a tag whose trailing number exceeds 1719 and an APK asset whose name carries the device's architecture.
