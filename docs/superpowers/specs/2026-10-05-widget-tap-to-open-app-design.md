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

1. **整块小组件点击 → 进入 App**，并直接落在**该小组件所显示的那台服务器**的详情页。这是绝大多数场景下的期望行为。
2. **配置面板入口保留**，改为一个专属的小点击目标，两个功能并存。
3. **未配置状态例外**：尚未选择服务器的小组件没有「服务器详情页」可进，此时整块点击仍应打开配置面板——这是该状态下唯一有意义的动作。
4. 不破坏现有能力：手动刷新、自动刷新、失败重试、过期变色等全部保留。

### 1.3 关键约束（决定了方案形态）

- **小组件无法响应长按**。桌面（Launcher）会拦截长按用于拖拽/调整，`RemoteViews` 拿不到该手势。因此「点击进 App / 长按配置」这类分法不可行，**必须靠点击区域划分**。
- **2x2 宽度只有 110dp**（`widget_small.xml`），减去左右各 10dp 内边距后仅剩 90dp 可用，表头空间极为紧张。这是本设计中最主要的取舍来源。
- 应用已具备 `serverbox://` 深链通道（`AppLink` + `MainActivity.acceptLink`），但目前**只认识 `serverbox://tab/<name>`**，没有「按服务器打开」的形态，需要扩展。

---

## 2. 交互设计

### 2.1 两条交互逻辑

| 目标 | 触发方式 | 结果 |
|---|---|---|
| **进入 App**（主路径） | 点击小组件的**内容区**（图表区 / 数值胶囊区）**或表头的服务器名称** | 打开 App，并直达该服务器的详情页 |
| **打开配置面板** | 点击表头的**齿轮图标 ⚙** | 弹出原有的配置面板 |

内容区是小组件上面积最大的单一可点目标（2x2 约占 49%，4x2 约占 55%；表头约占 24%，其余为内外边距），且名称也是进入 App 的入口，因此「大多数情况下是进入 App」由面积占比天然保证。齿轮仅占整块约 4.8%（24dp² / 110dp²）。

### 2.2 状态分支

点击行为随小组件状态变化，避免出现「点了没反应」或「进到空页面」：

```
小组件状态                整块点击行为
─────────────────────────────────────────────
未配置（无服务器）    →   打开配置面板      ← 没有详情页可进
已配置 + 有数据       →   进入 App 详情页
已配置 + 无凭据/网络错误 → 进入 App 详情页   ← 与错误文案一致
```

第三种情况值得说明：现有错误文案 `widget_err_no_token`（"无凭据 —— 请打开 ServerBox"）已经在引导用户打开 App，此前却没有任何点击路径能打开 App。本设计让文案与实际行为终于一致。

### 2.3 表头布局

```
4x2（250dp，空间充裕）：
┌─────────────────────────────────────┐
│ Osaka · JP        14:20   ⟳   ⚙  │
└─────────────────────────────────────┘
  ↑名称(可点进App)   ↑时间  ↑刷新 ↑配置

2x2（110dp，空间紧张）：
┌──────────────────────┐
│ Osaka ·…      ⟳  ⚙ │
└──────────────────────┘
  ↑名称被压缩    ↑刷新 ↑配置
```

**2x2 的取舍**：可用宽度为 `110 - 10×2 = 90dp`。当前名称独占 `90 - 24(⟳) - 4(margin) = 62dp`；加入 24dp 齿轮后降到 `90 - 24 - 4 - 24 - 4 = 34dp`，即名称与两个图标几乎各占一半——这是必须正视的压缩。名称已设 `ellipsize="end"` + `singleLine`，会优雅省略为 `Osaka ·…` 而不会破坏布局。为缓解，2x2 下把两个图标从 24dp 缩到 20dp 并把间距收到 2dp，名称回到 `90 - 20 - 2 - 20 - 2 = 46dp`。

> 备选方案（若认为名称不可压缩）：2x2 用齿轮**取代**刷新图标，放弃桌面手动刷新。代价是失去手动刷新（仅剩 30 分钟自动更新与失败重试）。本设计默认保留刷新，因为「并存」的要求倾向于不删减既有能力。

### 2.4 未配置状态的文案修正

现有字符串 `widget_err_not_configured` 为 **"点按选择服务器" / "Tap to pick a server"**。由于整块点击在**已配置**时改为进入 App，该文案只在未配置状态出现，语义仍然正确，**无需修改**。这一点在设计时特意核对过，避免留下与实际行为不符的文案。

---

## 3. 技术实现

### 3.1 点击接线（`HomeWidget.setupClickIntent`）

由「整块 → 配置」改为「内容区 + 名称 → App；齿轮 → 配置」：

```
widget_container / widget_content / widget_charts_container / widget_name
    → PendingIntent.getActivity(MainActivity, VIEW, serverbox://server/<id>)
widget_config (新增齿轮)
    → PendingIntent.getActivity(WidgetConfigureActivity, EXTRA_APPWIDGET_ID)
widget_refresh
    → PendingIntent.getBroadcast(...)   ← 不变
```

未配置时（`config.serverId` 为空）整块点击回落到配置面板。由于 `setupClickIntent` 在 `update()` 中于读取配置**之前**调用（`HomeWidget.kt:169-170`），需将其下移或把 `serverId` 作为参数传入，使接线能读到它。

**接线只需三个目标，不必逐层绑定**：`widget_container` 是 `match_parent` 的根布局，给它设 `setOnClickPendingIntent` 即覆盖整个小组件（触摸事件在子 View 不可点时上浮到父容器），内容区、图表区、服务器名称都由此覆盖。齿轮与刷新各自带独立绑定，作为子 View 会**覆盖**父容器的点击——这正是两条交互得以分离的机制，也是当前刷新图标能在整块点击中独善其身的原因。

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

名称不放进深链：id 已经足够定位，名称随快照变化（改名、切站点），塞进 URL 反而会陈旧。`CfDetailPage` 本身已能处理「快照里找不到该 id」的情况（`_fallbackNode()`），因此冷启动、站点未加载完成时也不会崩。

### 3.4 图标

齿轮图标复用仓库中**已存在但未被引用**的 `android/app/src/main/res/drawable/settings_24.xml`，无需新增素材。新增 `widget_config` 的 ImageView 到 `home_widget.xml` 表头，并补 `contentDescription`（`widget_config_desc`）。

---

## 4. 边界与错误处理

| 场景 | 行为 |
|---|---|
| 小组件未配置 | 整块点击 → 配置面板 |
| 深链 id 在快照中不存在 | `CfDetailPage._fallbackNode()` 兜底，页面正常打开 |
| App 冷启动时收到深链 | 沿用现有 `pendingLink` 机制（`MainActivity` 持有，Dart 首帧后拉取） |
| App 已在前台时收到深链 | 沿用 `onNewIntent` → `acceptLink` → `linkChannel.invokeMethod("opened")` |
| 服务器名称过长（2x2） | `ellipsize="end"` 省略，不破坏布局 |
| 点击图标区域 | 齿轮与刷新各自独立 `PendingIntent`，不触发整块跳转 |

---

## 5. 测试

- **Dart**：`AppLink.parse('serverbox://server/abc')` → `ServerLink('abc')`；非法形态（多段、空段、错 host）返回 null。新建 `test/unit/app/app_link_test.dart`（当前该模型**没有任何测试**，属于顺带补齐）。
- **Dart**：`_consumePending` 的 `ServerLink` 分支——快照有该 id 时取到正确名称，无该 id 时回落为 id 本身。
- **Kotlin**：`HomeWidget` 的点击接线可测性有限（`PendingIntent` + `RemoteViews` 依赖框架，本模块仅有 JUnit、无 Robolectric，见 `MemoryPrefs.kt` 注释）。因此**不新增 Kotlin 单测**，改为实机验证。
- **实机验证**（必需）：在 BKQ-AN10 上
  1. 点 2x2 内容区 → 进入该服务器详情页；
  2. 点 2x2 齿轮 → 打开配置面板；
  3. 点 4x2 内容区 → 同上；
  4. 点刷新图标 → 数据刷新且**不**跳转；
  5. 删除配置（未配置状态）→ 整块点击回到配置面板。

---

## 6. 影响面与不做的事

**改动文件**：
- `android/.../widget/HomeWidget.kt` — 点击接线 + 状态分支
- `android/app/src/main/res/layout/home_widget.xml` — 表头加齿轮
- `android/app/src/main/res/values*/strings.xml` — 新增 `widget_config_desc`
- `lib/data/model/app/app_link.dart` — `ServerLink`
- `lib/view/page/home/lifecycle.dart` — 消费 `ServerLink`
- 新增 `test/unit/app/app_link_test.dart`

**明确不做**：
- 不改配置面板自身的 UI（服务器/模式/图表/字段选择维持现状）。
- 不改自动刷新、重试、过期变色逻辑。
- 不为小组件引入长按手势（平台不支持）。
- 不把配置面板搬进 App（虽然更合理，但超出本次「两个功能并存」的范围）。
