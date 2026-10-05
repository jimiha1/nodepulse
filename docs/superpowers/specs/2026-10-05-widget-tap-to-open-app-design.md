# 小组件「点击进入 App」与「配置面板」双交互设计文档

## 1. 概述与背景

### 1.1 现状

Android 桌面小组件（2x2 SMALL / 4x2 MEDIUM）目前的点击行为由 `HomeWidget.setupClickIntent()`（`HomeWidget.kt:349`）统一接线：

| 点击区域 | 当前行为 |
|---|---|
| `widget_container`（整块小组件） | 打开 `WidgetConfigureActivity` 配置面板 |
| `widget_refresh`（表头 ⟳ 图标） | 发送刷新广播，仅刷新该实例 |

也就是说，**整块小组件的唯一用途就是打开配置面板**。用户想查看某台服务器的实时数据时，桌面上的小组件反而成了一个死胡同——点它只会弹出配置对话框。

### 1.2 目标

1. **点击小组件主体 → 进入 App**，并直接落在**该小组件所显示的那台服务器**的详情页。这是绝大多数场景下的期望行为。
2. **配置面板入口保留**，改到**表头左上角的服务器名称**上，两个功能并存。
3. **未配置状态例外**：尚未选择服务器的小组件没有「服务器详情页」可进，此时整块点击仍应打开配置面板——这是该状态下唯一有意义的动作。
4. 不破坏现有能力：手动刷新、自动刷新、失败重试、过期变色等全部保留。

### 1.3 关键约束（决定了方案形态）

- **小组件无法响应长按**。桌面（Launcher）会拦截长按用于拖拽/调整，`RemoteViews` 拿不到该手势。因此「点击进 App / 长按配置」这类分法不可行，**必须靠点击区域划分**。
- **点击区域划分不能新增图标**。此前设想的「加一个齿轮」会挤占表头宽度（2x2 下名称被压缩近一半），且改变了用户已经习惯的外观。**把配置入口放在已有的服务器名称上**，不新增任何视觉元素，外观与现状完全一致。
- 应用已具备 `serverbox://` 深链通道（`AppLink` + `MainActivity.acceptLink`），但目前**只认识 `serverbox://tab/<name>`**，没有「按服务器打开」的形态，需要扩展。

---

## 2. 交互设计

### 2.1 两条交互逻辑

| 目标 | 触发方式 | 结果 |
|---|---|---|
| **打开配置面板** | 点击表头**左上角的服务器名称** | 弹出原有的配置面板 |
| **进入 App**（主路径） | 点击小组件的**其余任何位置**（图表区 / 数值胶囊区 / 表头空白 / 时间） | 打开 App，并直达该服务器的详情页 |

用一句话概括给用户的规则：**「点名字改设置，点其他地方看数据」**。

名称是表头里一个固定的小目标，其余全部面积都归「进入 App」——所以「大多数情况下是进入 App」由面积占比天然保证，不需要额外设计。按实测尺寸估算，配置区约占整块 **9%**，进入 App 约占 **91%**。名称本身已设 `ellipsize="end"` + `singleLine`，长名字会优雅省略，不影响布局。

**一处必须如实说明的偏差**：`widget_name` 是 `layout_width="0dp"` + `layout_weight="1"`，它的**可点范围是整个加权槽位，而不是文字本身**——4x2 下约 230dp 宽，占表头宽度的约 78%。也就是说，短名字（如 `Osaka`）右侧的空白区点下去也会打开配置面板，而不是进入 App。

之所以接受这个偏差：要让可点区域紧贴文字，只能用 `wrap_content`，但那样长名字会撑开并挤掉时间与刷新图标（`LinearLayout` 对非加权子 View 不会自动收缩），而 `RemoteViews` 拿不到文字的实际边界，无法在两者间取巧。加权槽位是布局上唯一稳妥的选择，代价是配置区比视觉上的名字宽。

如果认为这一点不可接受，替代方案是**把名称槽位收窄**：给名称加 `android:maxWidth`（例如 2x2 用 90dp、4x2 用 140dp），再补一个 `layout_weight="1"` 的 `Space` 吸收剩余宽度，使可点区域与文字宽度接近。代价是长名字会更早省略。**本设计默认采用前者**（不改布局），如需后者请单独确认。

### 2.2 状态分支

点击行为随小组件状态变化，避免出现「点了没反应」或「进到空页面」：

```
小组件状态                    整块点击行为
─────────────────────────────────────────────
未配置（无服务器）        →   打开配置面板      ← 没有详情页可进
已配置 + 有数据           →   进入 App 详情页
已配置 + 无凭据/网络错误  →   进入 App 详情页   ← 与错误文案一致
```

第三种情况值得说明：现有错误文案 `widget_err_no_token`（"无凭据 —— 请打开 ServerBox"）已经在引导用户打开 App，此前却没有任何点击路径能打开 App。本设计让文案与实际行为终于一致。

**未配置状态下名称的行为**：仍指向配置面板，与整块一致。此时名称显示的是 App 名（`showError(name = null)` 回落到 `R.string.app_name`），点它和点别处到达同一个地方，不会产生歧义。

### 2.3 表头布局（外观不变）

```
4x2（实测约 314.9dp 宽）：
┌─────────────────────────────────────┐
│ Osaka · JP        14:20   ⟳       │
└─────────────────────────────────────┘
  ↑ 名称：配置入口     ↑时间  ↑刷新
    （其余区域：进入 App）

2x2（实测约 157dp 宽，无时间槽）：
┌──────────────────────┐
│ Osaka · JP     ⟳    │
└──────────────────────┘
  ↑ 名称：配置入口  ↑刷新
```

**与现状的差异只有点击行为，没有一个像素的视觉改动**：不新增图标、不改字号、不改间距。这正是选择「名称即配置入口」而非「新增齿轮」的原因——它把此前方案里 2x2 名称被压缩近一半的取舍整个消除了。

### 2.4 未配置状态的文案

现有字符串 `widget_err_not_configured` 为 **"点按选择服务器" / "Tap to pick a server"**。该文案只在未配置状态出现，而此状态下整块点击确实打开配置面板，语义仍然正确，**无需修改**。

---

## 3. 技术实现

### 3.1 点击接线（`HomeWidget.setupClickIntent`）

由「整块 → 配置」改为「名称 → 配置；整块 → App」：

```
widget_name
    → PendingIntent.getActivity(WidgetConfigureActivity, EXTRA_APPWIDGET_ID)   ← 配置面板
widget_container（match_parent 根布局，覆盖其余全部区域）
    → PendingIntent.getActivity(MainActivity, VIEW, serverbox://server/<id>)   ← 进入 App
widget_refresh
    → PendingIntent.getBroadcast(...)                                          ← 不变
```

**接线只需三个目标，不必逐层绑定**：`widget_container` 是 `match_parent` 的根布局，给它设 `setOnClickPendingIntent` 即覆盖整个小组件（触摸事件在子 View 不可点时上浮到父容器），图表区、胶囊区、表头空白、时间全部由此覆盖。名称与刷新各自带独立绑定，作为子 View 会**覆盖**父容器的点击——这正是两条交互得以分离的机制，也是当前刷新图标能在整块点击中独善其身的原因。

**未配置时的回落**：`config.serverId` 为空时，`widget_container` 不设 App 深链，改设配置面板（名称的绑定保持不变，两条路径通向同一处）。由于 `setupClickIntent` 在 `update()` 中于读取配置**之前**调用（`HomeWidget.kt:169-170`），需把 `serverId` 作为参数传入，或将其调用下移到 `WidgetConfig.load` 之后。**选择传参**：`update()` 里 `config` 之后还有一次 `server == null` 的提前 return，下移会让接线在未配置分支里漏掉；传参则两种情况都能在同一个函数里写清。

### 3.2 深链扩展（Dart 侧）

`AppLink` 新增一种形态：

```dart
/// 一台服务器，按它在 CF 站点上的 id。
final class ServerLink extends AppLink {
  const ServerLink(this.id);
  static const _host = 'server';
  final String id;
  @override
  Uri toUri() => Uri(scheme: AppLink.scheme, host: _host, pathSegments: [id]);
}
```

`_parse` 中新增 `ServerLink._host when segs.length == 1 => ServerLink(segs.single)`。

深链经 `serverbox://` scheme 进入，`MainActivity.acceptLink`（`MainActivity.kt:510`）已按 scheme 校验并存入 `pendingLink`，无需改动原生侧——`serverbox://server/<id>` 与既有的 `serverbox://tab/<name>` 走同一条通道。

### 3.3 深链消费（`home/lifecycle.dart` 的 `_consumePending`）

现有逻辑只处理 `TabLink`，新增 `ServerLink` 分支：

```dart
if (parsed is ServerLink && mounted) {
  // 名称从快照查，深链只带 id
  final name = ref.read(cfServersProvider).value?.servers
      .firstWhereOrNull((s) => s.id == parsed.id)?.name ?? parsed.id;
  CfDetailPage.route.go(context, args: CfDetailArgs(id: parsed.id, name: name));
}
```

名称不放进深链：id 已经足够定位，名称随快照变化（改名、切站点），塞进 URL 反而会陈旧。`CfDetailPage` 本身已能处理「快照里找不到该 id」的情况（`_fallbackNode()`，`cf_detail/view.dart:40`），因此冷启动、站点未加载完成时也不会崩。

### 3.4 无需新增素材

不新增图标、不新增 `contentDescription`、不新增字符串资源——这正是本方案相对「新增齿轮」的另一个好处。名称作为可点区域的语义由 `widget_name` 的既有文本承担，无障碍读屏仍按原样读出服务器名。

---

## 4. 边界与错误处理

| 场景 | 行为 |
|---|---|
| 小组件未配置 | 整块点击（含名称）→ 配置面板 |
| 深链 id 在快照中不存在 | `CfDetailPage._fallbackNode()` 兜底，页面正常打开 |
| App 冷启动时收到深链 | 沿用现有 `pendingLink` 机制（`MainActivity` 持有，Dart 首帧后拉取） |
| App 已在前台时收到深链 | 沿用 `onNewIntent` → `acceptLink` → `linkChannel.invokeMethod("opened")` |
| 服务器名称过长（2x2） | `ellipsize="end"` 省略，不破坏布局 |
| 点刷新图标 | 独立 `PendingIntent`，刷新且**不**跳转 |
| 用户找不到配置入口 | 见下方「已知弱点」 |

**已知弱点（如实记录）**：名称作为配置入口**在视觉上没有提示**，不看说明书的老用户可能一时找不到「怎么改设置」。三点缓解，按可靠性排序：

1. **未配置时整块即配置**——首次添加小组件的用户（最需要配置面板的人）不受影响。
2. **重新添加**：删除再添加小组件，Launcher 会走 `android:configure`，必然弹出配置面板。
3. **可选增强**（建议一并做，但独立于本设计，可单独取舍）：给两个 `appwidget-provider` 加 `android:widgetFeatures="reconfigurable"`，让支持该特性的 Launcher（Pixel / Nova 等）在长按小组件时提供「编辑」入口。对 Honor 自带桌面是否生效未验证，故不作为主路径。**本设计默认不包含此项**，若需要请单独确认。

---

## 5. 测试

- **Dart**：`AppLink.parse('serverbox://server/abc')` → `ServerLink('abc')`；非法形态（多段、空段、错 host）返回 null。新建 `test/unit/app/app_link_test.dart`（当前该模型**没有任何测试**，属于顺带补齐）。`AppLink` 是纯函数，可直接覆盖。
- **Dart**：`_consumePending` 的 `ServerLink` 分支**不做单测**。它是 `_HomePageState` 上的私有方法，依赖 `MethodChans`、`ref` 与 `context`，要测只能起整个 home 页面并把方法暴露出来——成本远高于收益。改为**实机验证第 6 条**覆盖：点小组件后详情页显示的必须是该实例对应的服务器，而不是列表第一台（这正是分支里「按 id 查名字」写错时会出现的症状）。
- **Kotlin**：`HomeWidget` 的点击接线可测性有限（`PendingIntent` + `RemoteViews` 依赖框架，本模块仅有 JUnit、无 Robolectric，见 `MemoryPrefs.kt` 注释）。因此**不新增 Kotlin 单测**，改为实机验证。
- **实机验证**（必需）：在 BKQ-AN10 上
  1. 点 2x2 服务器名称 → 打开配置面板；
  2. 点 2x2 其余任意位置（胶囊区/表头空白）→ 进入该服务器详情页；
  3. 点 4x2 名称 → 配置面板；点 4x2 图表区 → 详情页；
  4. 点刷新图标 → 数据刷新且**不**跳转；
  5. 删除配置（未配置状态）→ 点任意位置（含名称）回到配置面板；
  6. 详情页显示的是该小组件对应的服务器，而非默认第一台。

---

## 6. 影响面与不做的事

**改动文件**：
- `android/.../widget/HomeWidget.kt` — 点击接线（名称 → 配置；整块 → App，未配置回落配置）+ 状态分支
- `lib/data/model/app/app_link.dart` — 新增 `ServerLink`
- `lib/view/page/home/lifecycle.dart` — 消费 `ServerLink`
- 新增 `test/unit/app/app_link_test.dart`

**不改动**：`home_widget.xml`（外观不变，无需新增视图）、`strings.xml`、`colors.xml`、`widget_small.xml` / `widget_medium.xml`（除非单独确认启用 §4 的可选增强）。

**明确不做**：
- 不改配置面板自身的 UI（服务器/模式/图表/字段选择维持现状）。
- 不改自动刷新、重试、过期变色逻辑。
- 不为小组件引入长按手势（平台不支持）。
- 不把配置面板搬进 App（虽然更合理，但超出本次「两个功能并存」的范围）。
