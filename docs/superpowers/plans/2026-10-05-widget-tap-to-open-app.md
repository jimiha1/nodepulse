# 小组件「点名称配置 / 点其余进 App」实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让桌面小组件的点击分为两条路径——点表头左上角服务器名打开配置面板，点其余任何位置进入 App 并直达该服务器详情页。

**Architecture:** 原生侧把 `widget_container`（`match_parent` 根布局）的 `PendingIntent` 从「配置面板」改成「`serverbox://server/<id>` 深链」，同时给 `widget_name` 单独绑一个「配置面板」的 `PendingIntent`（子 View 覆盖父容器，这是两条路径得以分离的机制）。未配置时整块回落到配置面板。Dart 侧扩展 `AppLink` 认识 `serverbox://server/<id>`，并在 `_consumePending` 里消费它。

**Tech Stack:** Kotlin（Android AppWidget / RemoteViews / PendingIntent）、Dart + Riverpod（Flutter）、`flutter_test`。

## Global Constraints

- **不要运行任何格式化工具。** 格式是刻意的，跟着被改文件的风格走。
- 提交信息：一个小写前缀 + 祈使句描述，英文——`feat:`、`fix:`、`docs:`、`opt.:`、`rm:`、`refactor:`、`test:`、`chore:`、`migrate:`。
- 从 Git Bash 运行 `make`（Makefile 需要 `SHELL := /bin/bash`）。
- 应用通常已经在用户的 IDE 里跑着——**不要再起第二个 `flutter run`**。
- 不改 `home_widget.xml`、`strings.xml`、`colors.xml`、`widget_small.xml`、`widget_medium.xml`。本设计外观零改动。
- 新增/修改的 Dart 文件必须 `make analyze` 干净。

---

### Task 1: `ServerLink` 深链模型

**Files:**
- Modify: `lib/data/model/app/app_link.dart`
- Test: `test/unit/app/app_link_test.dart`（新建）

**Interfaces:**
- Consumes: 无（`AppLink` 是自包含的纯函数模型）
- Produces:
  - `final class ServerLink extends AppLink`，构造 `const ServerLink(String id)`，字段 `final String id`，静态常量 `_host = 'server'`
  - `AppLink.parse('serverbox://server/<id>')` 返回 `ServerLink`，`ServerLink.toUri()` 往返一致

- [ ] **Step 1: 写失败的测试**

新建 `test/unit/app/app_link_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/app/app_link.dart';

void main() {
  group('ServerLink', () {
    test('parses a server id', () {
      final link = AppLink.parse('serverbox://server/abc123');
      expect(link, isA<ServerLink>());
      expect((link! as ServerLink).id, 'abc123');
    });

    test('round-trips through toUri', () {
      const link = ServerLink('abc123');
      expect(link.toUri().toString(), 'serverbox://server/abc123');
      final again = AppLink.parse(link.toUri().toString());
      expect(again, isA<ServerLink>());
      expect((again! as ServerLink).id, 'abc123');
    });

    test('tolerates a trailing slash and surrounding whitespace', () {
      final link = AppLink.parse('  serverbox://server/abc123/  ');
      expect((link! as ServerLink).id, 'abc123');
    });

    test('refuses extra path segments', () {
      expect(AppLink.parse('serverbox://server/abc/def'), isNull);
    });

    test('refuses an empty id', () {
      expect(AppLink.parse('serverbox://server/'), isNull);
      expect(AppLink.parse('serverbox://server'), isNull);
    });

    test('refuses an unknown host', () {
      expect(AppLink.parse('serverbox://node/abc'), isNull);
    });

    test('refuses a foreign scheme', () {
      expect(AppLink.parse('https://server/abc'), isNull);
    });
  });

  group('TabLink', () {
    test('still parses, unaffected by the new shape', () {
      final link = AppLink.parse('serverbox://tab/server');
      expect(link, isA<TabLink>());
    });
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `make test-one TEST=test/unit/app/app_link_test.dart`
Expected: 编译失败，`ServerLink` 未定义（`Undefined name 'ServerLink'`）。这是预期的——先红后绿。

- [ ] **Step 3: 实现 `ServerLink`**

在 `lib/data/model/app/app_link.dart` 的 `_parse` 里加一个分支：

```dart
    return switch (uri.host.toLowerCase()) {
      TabLink._host when segs.length == 1 => TabLink._parse(segs.single),
      ServerLink._host when segs.length == 1 => ServerLink(segs.single),
      _ => null,
    };
```

在文件末尾 `TabLink` 之后加：

```dart
/// One server, by its id on the CF site.
///
/// The name is deliberately not carried: it changes with the site (a rename,
/// a different site), so an id is the only part that stays true, and the
/// caller already has a snapshot to look the name up in.
final class ServerLink extends AppLink {
  const ServerLink(this.id);

  static const _host = 'server';

  final String id;

  @override
  Uri toUri() =>
      Uri(scheme: AppLink.scheme, host: _host, pathSegments: [id]);
}
```

注意 `_parse` 已有的守卫会拒绝空段（`segs.any((seg) => seg.isEmpty)`），所以 `serverbox://server/` 与 `serverbox://server` 都落到 `segs.length == 1` 之外并返回 null，不需要额外判断。

- [ ] **Step 4: 运行测试，确认通过**

Run: `make test-one TEST=test/unit/app/app_link_test.dart`
Expected: 全部 PASS（8 个）。

- [ ] **Step 5: 分析**

Run: `make analyze`
Expected: 无新增警告。

- [ ] **Step 6: 提交**

```bash
git add lib/data/model/app/app_link.dart test/unit/app/app_link_test.dart
git commit -m "feat: teach AppLink the serverbox://server/<id> shape"
```

---

### Task 2: 消费 `ServerLink`，打开该服务器详情页

**Files:**
- Modify: `lib/view/page/home/lifecycle.dart`（`_consumePending`，约 63-82 行）
- Modify: `lib/view/page/home.dart`（补 `cf_detail/view.dart` 的 import）

**Interfaces:**
- Consumes: Task 1 的 `ServerLink`（`final String id`）
- Produces: 无对外接口；行为是「冷启动/前台收到 `serverbox://server/<id>` 时推送 `CfDetailPage`」

- [ ] **Step 1: 补 import**

`_consumePending` 住在 `part of '../home.dart'` 的 `lifecycle.dart` 里，而 `CfDetailPage` / `CfDetailArgs` 定义在 `lib/view/page/server/cf_detail/view.dart`。`cf_tab.dart` 是唯一引用它的文件，说明它没有被 `home.dart` 的 import 图带进来。在 `lib/view/page/home.dart` 的 import 区（`home_tab.dart` 那一行附近，按字母序）加：

```dart
import 'package:server_box/view/page/server/cf_detail/view.dart';
```

- [ ] **Step 2: 加 `ServerLink` 分支**

把 `_consumePending` 里现有的：

```dart
      final parsed = AppLink.parse(link);
      if (parsed is TabLink && mounted) {
        final idx = _tabs.indexOf(parsed.tab);
        if (idx >= 0) _onDestinationSelected(idx);
      }
```

改成：

```dart
      final parsed = AppLink.parse(link);
      if (parsed is TabLink && mounted) {
        final idx = _tabs.indexOf(parsed.tab);
        if (idx >= 0) _onDestinationSelected(idx);
      } else if (parsed is ServerLink && mounted) {
        // The name comes from the snapshot because the link carries only the
        // id; the page falls back on its own when the id is not in it yet, so
        // a cold start that lands here before the first poll still opens.
        final name = ref
                .read(cfServersProvider)
                .value
                ?.servers
                .where((s) => s.id == parsed.id)
                .map((s) => s.name)
                .firstOrNull ??
            parsed.id;
        CfDetailPage.route.go(context, CfDetailArgs(id: parsed.id, name: name));
      }
```

`firstOrNull` 是 `fl_lib` 的 `IterX` 扩展（`src/core/ext/iter.dart`，已由 `fl_lib.dart` 导出），`home.dart` 顶部已 `import 'package:fl_lib/fl_lib.dart';`，无需新 import。`?.` 会短路整条后续链，所以 `servers` 为 null 时整个表达式是 null，`?? parsed.id` 接管。

- [ ] **Step 3: 分析**

Run: `make analyze`
Expected: 无新增警告。

- [ ] **Step 4: 跑全量 Dart 测试**

Run: `make test`
Expected: 全绿（此前基线是 558 个通过 + Task 1 新增的 8 个）。

- [ ] **Step 5: 提交**

```bash
git add lib/view/page/home.dart lib/view/page/home/lifecycle.dart
git commit -m "feat: open a server's detail page from a serverbox://server link"
```

---

### Task 3: 拆分点击接线（原生侧）

**Files:**
- Modify: `android/app/src/main/kotlin/tech/lolli/toolbox/widget/HomeWidget.kt`（`update()` 约 163-179 行；`setupClickIntent()` 约 349-373 行）

**Interfaces:**
- Consumes: `WidgetConfig.serverId`（`String`，空串表示未配置）、`WidgetStore.WidgetServer.id`
- Produces: 无 Kotlin 侧对外接口；行为是「名称 → 配置面板；整块 → App 深链；未配置 → 整块配置面板」

- [ ] **Step 1: 给 `setupClickIntent` 加 `serverId` 参数**

把签名和函数体改成：

```kotlin
    /**
     * Wires the two ways into the widget.
     *
     * The whole widget opens the app on the server it is showing; the name in
     * the header opens the configuration panel instead. A child view's own
     * click binding overrides the container's, which is what keeps the two
     * apart — the refresh icon relies on the same thing.
     *
     * [serverId] empty means nothing is configured yet: there is no server
     * page to open, so the whole widget falls back to the configuration panel,
     * which is the only useful thing to do in that state.
     */
    private fun setupClickIntent(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int,
        serverId: String,
    ) {
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val configure = Intent(context, WidgetConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = android.net.Uri.parse("sbm://widget/$appWidgetId")
        }
        views.setOnClickPendingIntent(
            R.id.widget_name,
            PendingIntent.getActivity(context, appWidgetId, configure, flag),
        )

        if (serverId.isEmpty()) {
            // Same target as the name, reached by tapping anywhere: a widget
            // with no server has no page to open.
            views.setOnClickPendingIntent(
                R.id.widget_container,
                PendingIntent.getActivity(context, appWidgetId, configure, flag),
            )
        } else {
            // Its own request code, so this PendingIntent is not the same
            // object as the configure one above and cannot be handed back by
            // FLAG_UPDATE_CURRENT when either is re-created.
            val open = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = android.net.Uri.parse("serverbox://server/$serverId")
                // The widget is on the home screen; the app's task is what
                // should come forward, not a second copy of it.
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_container,
                PendingIntent.getActivity(context, appWidgetId + 1, open, flag),
            )
        }

        val refresh = Intent(context, javaClass).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            data = android.net.Uri.parse("sbm://widget/refresh/$appWidgetId")
        }
        views.setOnClickPendingIntent(
            R.id.widget_refresh,
            PendingIntent.getBroadcast(context, appWidgetId, refresh, flag),
        )
    }
```

需要新增 import：`tech.lolli.toolbox.MainActivity`。加在 `import tech.lolli.toolbox.R` 旁边（按字母序，`MainActivity` 在 `R` 之前）。

- [ ] **Step 2: 让 `update()` 把 `serverId` 传进去**

现在 `update()` 在读到配置**之前**就调用了 `setupClickIntent`（约 169-172 行）：

```kotlin
        val views = RemoteViews(context.packageName, R.layout.home_widget)
        setupClickIntent(context, views, appWidgetId)

        val config = WidgetConfig.load(context, appWidgetId, kind)
```

把这两段交换顺序，并把 `serverId` 传进去：

```kotlin
        val views = RemoteViews(context.packageName, R.layout.home_widget)

        // Read first: which click target the container gets depends on
        // whether a server has been picked yet.
        val config = WidgetConfig.load(context, appWidgetId, kind)
        setupClickIntent(context, views, appWidgetId, config.serverId)
```

`config` 下面原有的 `val server = config.serverId.takeIf { ... }` 及 `if (server == null) { ... return }` 保持在 `setupClickIntent` 之后不动——未配置时仍然要先把点击接好（此时它指向配置面板），再走 `showError` 的提前 return。

- [ ] **Step 3: 编译**

Run: `cd android && ./gradlew :app:compileDebugKotlin`（或在仓库根 `make build PLATFORM=android` 只到编译阶段）
Expected: `BUILD SUCCESSFUL`。若 Gradle 环境未就绪，退一步：这一步的验收由 Task 4 的实机运行覆盖，但**必须先让 Kotlin 编译通过**再进 Task 4。

- [ ] **Step 4: 提交**

```bash
git add android/app/src/main/kotlin/tech/lolli/toolbox/widget/HomeWidget.kt
git commit -m "feat: split widget taps into name-for-settings and rest-for-app"
```

---

### Task 4: 实机验证

**Files:** 无（纯验证）

**Interfaces:**
- Consumes: Task 1-3 的全部产出
- Produces: 一份「通过/不通过」的结论；不通过则回到对应 Task 修

前置：设备是 Honor BKQ-AN10（已连接、已授权 adb）。应用已经在跑时用 Dart MCP 热重载；原生改动必须重新构建安装（原生代码不吃热重载）。

- [x] **Step 1: 构建并安装**

Run: `flutter build apk --debug` + `adb install -r`
Expected: 安装成功，桌面小组件仍在（更新不会清掉已放置的实例）。**实测通过**：两个 4x2 实例（id 4999=Osaka、5014=LAX）都还在。

- [x] **Step 2: 逐条验证**

**实测结果**（2026-10-05，BKQ-AN10，density 3.5）：

| # | 场景 | 证据 | 结论 |
|---|---|---|---|
| 1 | 点名称 → 配置面板 | logcat `START u0 {dat=sbm://widget/... cmp=…/.widget.WidgetConfigureActivity}`；焦点为 `WidgetConfigureActivity`；`Displayed …WidgetConfigureActivity` | ✅ |
| 2 | 点图表区 → 进 App 该服务器 | logcat `START u0 {dat=serverbox://server/… cmp=…/.MainActivity}`；`dumpsys activity activities` 显示完整 URI `serverbox://server/fd978320-…`（Osaka 的 id） | ✅ |
| 3 | 点表头空白（名称右侧）→ 进 App | 名称槽位实测 `[110,272][902,349]`（226dp 宽），其右侧命中 `widget_container` 的绑定 | ✅ |
| 4 | 两个实例各自进对的服务器 | Osaka 组件 → 详情页标题 **Osaka**；LAX 组件 → 标题 **LAX**。快照顺序是 `[LAX, Osaka]`，若忽略 id 两者会显示同一台 | ✅ |
| 5 | 点刷新图标 → 只刷新不跳转 | logcat 无任何 `START u0`；焦点仍是 launcher | ✅ |
| 6 | 未配置 → 整块点击回配置面板 | 见下方「验证发现的缺陷」——**首次实测失败，修复后复测通过** | ✅（修复后） |
| 7 | id 不在快照 → 详情页仍打开 | 详情页标题回落为该 id；`_fallbackNode()` 兜底 | ✅ |

Expected: 7 条全部符合。

- [x] **Step 3: 提交验证结论**

**验证发现的缺陷（已修，`4f36ae6e`）**：最初的 `setupClickIntent(context, views, appWidgetId, config.serverId)` 用「**是否存了 serverId 字符串**」决定整块点击的目标。但小组件指向的服务器若已从站点消失，`WidgetStore.server()` 解析不出对象，页面走 `showError(widget_err_not_configured)` 显示「点按选择服务器」——而点击却仍被接到 App 深链上，文案与行为不一致。

修复：把判断从「有 id」改成「**服务器能解析出来**」，即 `setupClickIntent(context, views, appWidgetId, server?.id)`，参数类型改为 `String?`，`serverId == null` 时整块回落配置面板。这与 `if (server == null)` 的既有分支同源，两者不会再分叉。

复测：把 5014 的 `widget_5014_server` 从配置里移除（先 `md5sum` 备份，测完按原字节还原并校验 md5 一致），重新安装触发重绘，小组件显示「点按选择服务器」；点其**正文**（非名称）→ logcat `cmp=…/.widget.WidgetConfigureActivity`，焦点为配置面板。**通过**。

