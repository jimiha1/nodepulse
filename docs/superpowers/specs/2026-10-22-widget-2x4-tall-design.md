# 2x4 竖版桌面小组件设计文档

## 1. 概述与目标

仓库现有的两个 Android 桌面小组件是 **2x2**（`StatusWidgetSmall`，纯数值胶囊）和 **4x2**（`StatusWidgetMedium`，图表 / 数值 / 组合三种模式）。本次：

1. **删除 2x2 小组件**（provider、布局参数、配置项、字符串全部移除）。
2. **新增 2x4 竖版小组件**，版面构成取自参考图（单台服务器的完整状态卡），配色、字体尺度、圆角与内边距取自 4x2 小组件既有的视觉语言。
3. 保留 4x2 小组件及其三种模式，不做改动。

目标读者：把服务器状态长期钉在桌面、希望一眼看完「身份 → 资源 → 流量 → 网络质量 → 稳定性」的用户。参考图并排展示两张卡，即该小组件的两个实例各绑一台服务器。

## 2. 非目标

- 不把 2x4 做成可缩放或可在横竖两种版面间切换的组件。尺寸与内容仍然是一个决定（沿用 `resizeMode="none"` 的理由）。
- 不迁移桌面上已有的 2x2 实例。Android 不允许把实例从一个 provider 搬到另一个，升级后旧实例随 provider 消失而被系统移除，用户需重新添加。
- 不改动 4x2 的任何行为。
- 不为 2x4 提供字段勾选。行序本身承载语义，允许打乱会破坏阅读顺序。

## 3. 组件身份与注册

| 项 | 值 |
|---|---|
| 类 | `StatusWidgetTall : HomeWidget(WidgetKind.TALL)` |
| 注册 | `AndroidManifest.xml` 的 `<receiver>`，与 4x2 同一套 intent-filter |
| 尺寸 | `widget_tall.xml`：`minWidth=110dp`、`minHeight=250dp`、`targetCellWidth=2`、`targetCellHeight=4`、`resizeMode="none"` |
| 布局 | `home_widget_tall.xml`（独立布局，不复用 4x2 的 `home_widget.xml`） |
| 标签 | `widget_tall_label`，仅补 `values/` 与 `values-zh-rCN/`，其余语言回落英文 |

独立布局的理由：两者结构差异过大（2x4 是固定十一行 + 一条稳定性条 + 一条脚注，4x2 是图表网格与胶囊网格），共用一套 `RemoteViews` 会让每次更新都要显式复位十几个可见性，并且白白撑大 binder 事务。

`WidgetKind` 枚举把 `SMALL` 替换为 `TALL`；`StatusWidgetSmall`、`widget_small.xml`、`widget_small_label`（含 15 个语言目录）一并删除。

## 4. 版面

自上而下，全部为固定行，无动态隐藏：

```
┌─────────────────────────────┐
│ ● aliyun-hk-01      [HK] ⟳ │  header
│ CPU · 2 cores         0.0%  │  row 1
│ ─────────────────────────── │  divider
│ Memory       233 / 431 MiB  │  row 2
│ Disk         412 / 1021 MiB │  row 3
│ Load         0.00 0.00 0.00 │  row 4
│ Live          ↓14.1 · ↑13.2 KiB/s │ row 5
│ This month    ↓317 · ↑314 MiB │ row 6
│ Uptime                7h 39m│  row 7
│ ─────────────────────────── │  divider
│ 电信  ▮▮▮▮▮▮▮▮▮▮        10ms │  row 8
│ 联通  ▮▮▮▮▮▮▮▮▮▮         7ms │  row 9
│ 移动  ▮▮▮▮▮▮▮▮▮▮        16ms │  row 10
│ ─────────────────────────── │  divider
│ Stability last hour      100│  row 11
│ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ │  bar
│ loss 0.2% · jitter 2.0ms · spikes 0/90   14:20 │  footer
└─────────────────────────────┘
```

### 4.1 视觉语言（取自 4x2）

- 容器：`@drawable/widget_background`（16dp 圆角），背景色 `@color/widgetBackground`，内边距 10dp。
- 标签列：`@color/widgetSummaryText`，10sp。
- 数值列：`@color/widgetText`，10sp，`monospace`，`textStyle=bold`，右对齐，`singleLine`，`ellipsize=end`。
- 强调绿：`#34C759`（4x2 图表 CPU 曲线同色）。
- 分隔线：`@color/widgetSummaryText` 12% 透明度，1dp 高，上下 4dp 外边距。
- 头部：状态点用 `TextView` 文本 `●` + `setTextColor`，避免为一个圆点新增 drawable；服务器名 13sp bold；右侧 region 胶囊（`widget_region_bg.xml`，6dp 圆角，`#1A888888` 底，9sp）；最右是 24dp 刷新图标，沿用 4x2 的 `refresh_24`。

状态点取值沿用 Flutter 端 `CfServer._isOnline` 的规则，避免两处判断漂移：

| 条件 | 颜色 |
|---|---|
| `last_updated` 距今 < 90s | `#34C759` |
| `last_updated` 距今 ≥ 90s | `#FF453A` |
| `last_updated` 缺失或 ≤ 0 | `#888888` |

### 4.2 窄宽度适配

2 格宽在 320dp 屏幕上内容区约 130dp，参考图的完整写法（`232.65 MiB / 431.00 MiB`）放不下。因此数值列采用**共享单位**写法：

| 行 | 参考图 | 本设计 |
|---|---|---|
| Memory | `232.65 MiB / 431.00 MiB` | `233 / 431 MiB` |
| Disk | `412.00 MiB / 1021.00 MiB` | `412 / 1021 MiB` |
| Live | `14.11 KiB/s · 13.19 KiB/s` | `↓14.1 · ↑13.2 KiB/s` |
| This month | `317.00 MiB / 313.70 MiB` | `↓317 · ↑314 MiB` |

信息量不变（已用 / 总量 + 单位），字符数减半。`formatBytes` 新增 `sharedUnit(used, total)` 辅助函数：两者落在同一量级时合并单位，否则退回各自带单位的写法。

### 4.3 数值格式

- 百分比：`0.0%`（1 位小数，与图片一致；4x2 用 0 位，这里不复用）。
- Load：`0.00 0.00 0.00`（1/5/15 分钟）。
- Uptime：`7h 39m`（沿用 `WidgetApi.formatUptime`）。
- 速率：`formatBytes` 的紧凑写法 + 两位有效小数，后缀 `KiB/s`。
- 缺失值：`--`。
- `cpu_cores` 缺失时第一行只写 `CPU`，不带 `· N cores`。
- `region` 缺失或为空时胶囊整体 `GONE`，不占位。

### 4.4 数据新鲜度时间

4x2 把 `HH:mm` 放在头部右侧；2x4 的头部右侧已被 region 胶囊占用，且宽度只有两格，所以时间挪到**脚注右端**，与 `loss · jitter · spikes` 同一行、右对齐。

颜色规则沿用 `HomeWidget.resolveTimeColorRes`，不新增判断：正常 `@color/widgetSummaryText`，过期 `@color/widgetTimeAging`，更久 `@color/widgetTimeStale`，阈值仍由 `WidgetExpiry` 决定。加载中显示 `…`，无时间戳显示 `--`。

## 5. 数据

### 5.1 `WidgetApi.Reading` 新增字段

现有 `Reading` 只保存拼好的字符串，2x4 需要原始值：

```kotlin
val cpuCores: Int? = null,
val region: String? = null,
val netIn: Double = 0.0,          // B/s
val netOut: Double = 0.0,         // B/s
val netRxMonthly: Double = 0.0,   // B
val netTxMonthly: Double = 0.0,   // B
val load5: Double = 0.0,
val load15: Double = 0.0,
val pingCt: Double? = null,
val pingCu: Double? = null,
val pingCm: Double? = null,
val lossCt: Double? = null,
val lossCu: Double? = null,
val lossCm: Double? = null,
```

`region` 优先取 `/api/servers` 载荷里的 `region`，缺失时回落到 `WidgetStore.WidgetServer.region`。

### 5.2 `HistoryPoint` 新增 ping 列

`/api/history/all` 已经返回 `ping_ct/cu/cm`（Dart 端 `CfHistoryRow` 已在解析），Kotlin 端此前未解析。新增：

```kotlin
val pingCt: Double? = null,
val pingCu: Double? = null,
val pingCm: Double? = null,
```

### 5.3 历史窗口

`WidgetApi.load` 增加 `historyHours: Double` 参数：`TALL` 传 `1`，`MEDIUM` 维持 `24`。2x4 的稳定性区只声明「last hour」，拉 24 小时既浪费一次冷查询，也让窗口语义与标题不符。

### 5.4 快照兼容

`WidgetSnapshot` 的 history 序列化从 10 字段扩到 13 字段（`pingCt/pingCu/pingCm`，空值写 `-`）。`historyFrom` 接受 10 或 13 字段：10 字段的旧快照把三个 ping 读成 `null`，不丢行。`readingTo/readingFrom` 同步补新字段，旧快照缺键时取默认值。

## 6. 稳定性计算

新增纯函数对象 `WidgetStability`（无 Android 依赖，可直接单测）：

```kotlin
data class Stats(
    val score: Int?,        // 0..100，无样本时 null
    val lossPct: Double?,   // 三网丢包率窗口均值
    val jitterMs: Double?,  // 相邻样本 ping 差的绝对值均值，按运营商分别算再平均
    val spikes: Int,        // 尖刺计数
    val samples: Int,       // 参与计算的样本数
)
```

规则：

- **样本筛选**：只取窗口内至少有一个 ping 值非 `null` 的行。
- **loss**：三网 `loss_*` 中非 `null` 值的均值。
- **jitter**：对每个运营商，取相邻样本 ping 差值的绝对值，跳过任一端为 `null` 的对；三网结果再取均值。
- **spike**：单样本 ping 超过 `max(2 × 窗口中位数, 50ms)` 记一次。
- **score**：`clamp(100 − round(loss) − round(100 × spikes / samples), 0, 100)`。

参考图那组数（loss 0.2%、spikes 0/90）代入得 100，与图一致。

无历史（或全部为 `null`）时：`score = null`，整段显示 `--`、空条、脚注 `--`，不编造分数。

## 7. 位图绘制

`RemoteViews` 无法承载自定义 View，条形图必须以位图下发。新增 `WidgetBars`：

- `segmented(context, fraction, color, w, h, density)`：20 段圆角小方块，用于三条 ping 条。
- `continuous(context, fraction, color, w, h, density)`：单条圆角进度条，用于稳定性。

尺寸在布局里给定（ping 条高 6dp、稳定性条高 5dp），位图按 `ImageView` 实际宽度生成，单张约 1KB。一次更新最多 4 张，远低于 4x2 已有的 640KB 位图预算。

颜色分档（ping 与稳定性共用）：

| 区间 | 颜色 |
|---|---|
| ≥ 66% | `#34C759` |
| 33%–66% | `#FF9F0A` |
| < 33% | `#FF453A` |
| 无数据 | `#888888`（仅轨道，无填充） |

ping 条的填充比例：`clamp(1 − ping / 300, 0, 1)`。

## 8. 配置界面

`WidgetConfigureActivity` 对 `TALL` 只保留两项：

1. **服务器**（沿用现有单选列表）。
2. **数据过期变色阈值**（沿用 `WidgetExpiry`）。

隐藏：模式单选、图表数量、图表 1~4、字段勾选、字段上限提示。`expiry` 对 `TALL` 不再强制 `DEFAULT`——2x4 的脚注同样带时间，过期变色同样有意义。

`WidgetConfig` 相应调整：

- `CAP_SMALL_FIELDS` 删除；`DEFAULT_SMALL_FIELDS` 改名为 `DEFAULT_READING_FIELDS`（4x2 数值模式仍在用）。
- `kind == TALL` 时字段列表恒为空，读写都跳过 `fields` 键。
- `load`/`loadFromPrefs` 的 `kind` 默认参数由 `SMALL` 改为 `TALL`；`WidgetConfigureActivity` 里 `kindOf(...) ?: WidgetKind.SMALL` 的兜底同样改为 `TALL`。
- `WidgetKind.CHART_COUNT` 无引用，随 `SMALL` 一并删除。

## 9. 刷新与错误处理

沿用 `HomeWidget` 现有机制，不改协议：

- `WidgetPeriodicRefresh` 15 分钟自刷新、`WidgetRetry` 六次重试、`activeUpdates` 去重、`COROUTINE_TIMEOUT` 30 秒。
- 失败且无快照：隐藏 `widget_tall_body`，显示 `error_message`，与 4x2 一致。
- 失败但有快照：整卡重绘为上次读数，脚注时间按 `WidgetExpiry` 变色。
- 点击：整卡打开 `nodepulse://server/<id>`；服务器名打开配置页；刷新图标立即刷新。

`Bounds` 增加 `TALL` 分支：内边距 10dp、头部 13sp、无图表高度计算。

## 10. 文案

新增字符串（`values/` + `values-zh-rCN/`）：

| key | en | zh-CN |
|---|---|---|
| `widget_tall_label` | `Server status` | `服务器状态` |
| `widget_row_cpu_cores` | `CPU · %d cores` | `CPU · %d 核` |
| `widget_row_memory` | `Memory` | `内存` |
| `widget_row_disk` | `Disk` | `磁盘` |
| `widget_row_load` | `Load` | `负载` |
| `widget_row_live` | `Live` | `实时` |
| `widget_row_month` | `This month` | `本月` |
| `widget_row_uptime` | `Uptime` | `运行时间` |
| `widget_row_telecom` | `Telecom` | `电信` |
| `widget_row_unicom` | `Unicom` | `联通` |
| `widget_row_mobile` | `China Mobile` | `移动` |
| `widget_stability_title` | `Stability last hour` | `近 1 小时稳定性` |
| `widget_stability_footer` | `loss %1$s · jitter %2$s · spikes %3$s` | `丢包 %1$s · 抖动 %2$s · 尖刺 %3$s` |

删除 `widget_small_label`（15 个语言目录）。

## 11. 测试

| 文件 | 覆盖 |
|---|---|
| `WidgetConfigTest` | `TALL` 不读写 `fields`；`TALL` 保留 `expiry`；`MEDIUM` 行为不变 |
| `WidgetStabilityTest`（新增） | 空历史、单样本、全丢包、ping 全 `null`、尖刺阈值边界、分数上下限 |
| `CfWidgetParseTest` | `Reading` 新增字段解析；`region` 回落；`load5/15` |
| `WidgetSnapshotTest` | 13 字段往返；10 字段旧快照读成 `null` 且不丢行 |

不新增 instrumentation 测试：仓库现有小组件测试全部是 JVM 单测，`RemoteViews` 渲染无法在无设备环境下断言。

## 12. 验收标准

1. 桌面长按添加小组件时，选择器只剩两个条目：`服务器状态`（2x4）与`服务器曲线`（4x2）。
2. 放置 2x4 后版面与第 4 节一致，两格宽四格高，不可缩放。
3. 数据齐全时 11 行 + 稳定性条 + 脚注全部有值，无 `--`。
4. 断网后整卡保留上次读数，脚注时间变色；清空数据后显示错误文案。
5. `flutter build apk --config-only` 之后，`cd android && ./gradlew :app:testDebugUnitTest -x :app:compileFlutterBuildDebug` 全绿——与 CI 的 `android` job 同一条命令。
6. `flutter analyze lib test integration_test` 无新增问题。
