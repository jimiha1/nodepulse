# 2x4 竖版桌面小组件实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 删除 2x2 数值小组件，新增 2x4 竖版状态卡，版面构成取自参考图、视觉语言取自现有 4x2。

**Architecture:** 沿用 `HomeWidget` 抽象基类与 `RemoteViews` 更新路径；新增 `WidgetKind.TALL` 与独立布局 `home_widget_tall.xml`；稳定性指标抽成无 Android 依赖的 `WidgetStability`；条形图由 `WidgetBars` 生成小位图下发。

**Tech Stack:** Kotlin、Android AppWidget（`RemoteViews`）、JUnit4（JVM 单测，无 Robolectric）。

**Spec:** `docs/superpowers/specs/2026-10-22-widget-2x4-tall-design.md`

## Global Constraints

- 不运行任何代码格式化工具。
- 提交信息：小写前缀 + 祈使句英文（`feat:`、`fix:`、`refactor:`、`rm:`、`docs:`、`test:`）。
- 单测命令：`source /home/ops/toolchain/env.sh && cd android && ./gradlew :app:testDebugUnitTest --tests 'app.nodepulse.widget.*' -x :app:compileFlutterBuildDebug`。
- 字符串只补 `values/` 与 `values-zh-rCN/`，其余语言回落英文。
- 颜色引用 `@color/widget*` 或 spec 固定十六进制；4x2（`MEDIUM`）行为不得改变。

## Review Focus

1. **旧快照兼容**：升级前写入的 10 字段 history 必须仍能读出，不能因新增 ping 列整条丢弃。
2. **空/缺数据**：`ping_*`、`loss_*`、`cpu_cores`、`region`、`last_updated` 缺失时显示 `--` 或隐藏，绝不显示 0 或崩溃。
3. **位图预算**：一次更新的全部位图远低于 `RemoteViews` 1MB 事务上限。
4. **2 格窄屏溢出**：约 130dp 内容区，长字符串必须 `ellipsize=end` 而非撑破布局。
5. **provider 移除后的残留**：旧 2x2 实例被删除时 `onDeleted` 仍要清 config/snapshot/retry。

---

## Task 1: 读数与历史的新增字段

**Files:**
- Modify: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetApi.kt`
- Test: `android/app/src/test/kotlin/app/nodepulse/widget/CfWidgetParseTest.kt`

**Interfaces:**
- Consumes: 现有 `Reading`、`HistoryPoint`、`parseCfMetrics`、`parseCfHistory`
- Produces: `Reading` 新增 `cpuCores: Int?`、`region: String?`、`ramUsedBytes/ramTotalBytes/diskUsedBytes/diskTotalBytes: Double`、`netIn: Double`、`netOut: Double`、`netRxMonthly: Double`、`netTxMonthly: Double`、`load5: Double`、`load15: Double`、`pingCt/pingCu/pingCm: Double?`、`lossCt/lossCu/lossCm: Double?`；`HistoryPoint` 新增 `pingCt/pingCu/pingCm: Double?`、`lossCt/lossCu/lossCm: Double?`；`WidgetApi.formatSharedUnit(a: Double, b: Double): String` 与 `WidgetApi.formatSharedPair(down: Double, up: Double, perSecond: Boolean = false): String`

  注：`ramUsedBytes` 等四个字节字段是执行中补的 —— §4.2 的内存/磁盘行要 `formatSharedUnit(used, total)`，而计划原文只列了拼好的字符串与百分比，没有可共享单位的原始字节对。

- [ ] **Step 1: 写失败测试**（先给 `rawServersJson` 补 `"cpu_cores": 2,` 与 `"load_avg": "0.04 0.10 0.05",` 两个键，再追加下列用例到 `CfWidgetParseTest`）

```kotlin
@Test
fun parseCfServerKeepsTheRawTallFields() {
    val server = WidgetStore.WidgetServer(
        id = "fd978320-c32c-474d-857a-3412a7526a7b", name = "日本节点", region = "JP",
    )
    val r = WidgetApi.parseCfMetrics(server, rawServersJson)
    assertEquals("JP", r.region)
    assertEquals(165.0, r.pingCt!!, 0.001)
    assertEquals(78.0, r.pingCu!!, 0.001)
    assertEquals(310.0, r.pingCm!!, 0.001)
    assertEquals(0.0, r.lossCt!!, 0.001)
    assertEquals(5.0, r.lossCu!!, 0.001)
    assertEquals(12.0, r.lossCm!!, 0.001)
    assertEquals(13200.0, r.netIn, 0.001)
    assertEquals(2980.0, r.netOut, 0.001)
    // cpu_cores and the 5/15-minute loads come from the same payload; a
    // missing one must not turn into a zero that reads like a real value.
    assertEquals(2, r.cpuCores)
    assertEquals(0.10, r.load5, 0.001)
    assertEquals(0.05, r.load15, 0.001)
}

@Test
fun parseCfServerLeavesMissingTallFieldsEmpty() {
    val server = WidgetStore.WidgetServer(id = "x", name = "X", region = null)
    val r = WidgetApi.parseCfMetrics(server, """{"servers":[{"id":"x"}]}""")
    assertNull(r.region)
    assertNull(r.cpuCores)
    assertNull(r.pingCt)
    assertEquals(0.0, r.netIn, 0.001)
}

@Test
fun parseCfServerFallsBackToTheStoredRegion() {
    val server = WidgetStore.WidgetServer(id = "missing", name = "X", region = "HK")
    assertEquals("HK", WidgetApi.parseCfMetrics(server, """{"servers":[]}""").region)
}

@Test
fun parseCfHistoryReadsThePingColumns() {
    val body = """[{"timestamp":1,"cpu":1,"ping_ct":10,"ping_cu":null,"ping_cm":30}]"""
    val p = WidgetApi.parseCfHistory(body).single()
    assertEquals(10.0, p.pingCt!!, 0.001)
    assertNull(p.pingCu)
    assertEquals(30.0, p.pingCm!!, 0.001)
}

@Test
fun sharedUnitMergesWhenBothSidesAgree() {
    assertEquals("233 / 431 MiB", WidgetApi.formatSharedUnit(232.65 * 1048576, 431.0 * 1048576))
}

@Test
fun sharedUnitKeepsBothUnitsWhenTheyDiffer() {
    assertEquals("512 MiB / 2 GiB", WidgetApi.formatSharedUnit(512.0 * 1048576, 2048.0 * 1048576))
}

@Test
fun sharedPairPrefixesTheDirectionAndSharesTheUnit() {
    assertEquals(
        "↓14.1 · ↑13.2 KiB/s",
        WidgetApi.formatSharedPair(14.11 * 1024, 13.19 * 1024, perSecond = true),
    )
    assertEquals(
        "↓317 · ↑314 MiB",
        WidgetApi.formatSharedPair(317.0 * 1048576, 313.7 * 1048576),
    )
}

@Test
fun sharedPairSaysBothUnitsWhenTheyDiffer() {
    assertEquals(
        "↓1.2 GiB · ↑512 MiB",
        WidgetApi.formatSharedPair(1.2 * 1024 * 1048576, 512.0 * 1048576),
    )
}
```

- [ ] **Step 2: 运行确认失败**

```bash
source /home/ops/toolchain/env.sh
cd android && ./gradlew :app:testDebugUnitTest --tests 'app.nodepulse.widget.CfWidgetParseTest' -x :app:compileFlutterBuildDebug
```
Expected: 编译失败，`region` / `pingCt` / `formatSharedUnit` 未定义。

- [ ] **Step 3: 实现**

`Reading` 追加带默认值的字段（`= null` / `= 0.0`），不破坏现有构造调用。`parseCfMetrics` 填充：

- `region = o.optString("region").takeIf { it.isNotEmpty() } ?: server.region`
- `cpuCores = o.optIntOrNull("cpu_cores")`
- `netIn = netInSpeed`、`netOut = netOutSpeed`、`netRxMonthly = netRxMonthly`、`netTxMonthly = netTxMonthly`
- `load5 = loads.getOrNull(1) ?: 0.0`、`load15 = loads.getOrNull(2) ?: 0.0`
- 六个 ping/loss 直接透传已解析的局部变量

`parseCfHistory` 增加 `pingCt = o.optDoubleOrNull("ping_ct")` 等三行。

`formatSharedUnit(used, total)`：两侧 `formatBytes` 单位相同 → `"${compact(used)} / ${compact(total)} $unit"`；否则 → `"${formatBytes(used)} / ${formatBytes(total)}"`。`compact` 保留至多一位小数并去掉尾随 `.0`。

`formatSharedPair(down, up, perSecond = false)`：同样合并单位，输出 `"↓${compact(down)} · ↑${compact(up)} $unit"`（单位不同则各自带单位）；`perSecond` 为 true 时单位后加 `/s`。

- [ ] **Step 4: 运行确认通过** — 同 Step 2，Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/WidgetApi.kt android/app/src/test/kotlin/app/nodepulse/widget/CfWidgetParseTest.kt
git commit -m "feat: expose the raw readings the tall widget draws"
```

---

## Task 2: 稳定性计算

**Files:**
- Create: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetStability.kt`
- Test: `android/app/src/test/kotlin/app/nodepulse/widget/WidgetStabilityTest.kt`

**Interfaces:**
- Consumes: `WidgetApi.HistoryPoint.pingCt/pingCu/pingCm/lossCt/lossCu/lossCm`（Task 1）
- Produces: `internal object WidgetStability { data class Stats(val score: Int?, val lossPct: Double?, val jitterMs: Double?, val spikes: Int, val samples: Int); fun compute(history: List<WidgetApi.HistoryPoint>): Stats }`

- [ ] **Step 1: 写失败测试**

```kotlin
package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetStabilityTest {
    private fun point(
        pingCt: Double? = null, pingCu: Double? = null, pingCm: Double? = null,
        lossCt: Double? = null, lossCu: Double? = null, lossCm: Double? = null,
    ) = WidgetApi.HistoryPoint(
        cpu = 0.0, memory = 0.0, disk = 0.0, netRx = 0.0, netTx = 0.0,
        pingCt = pingCt, pingCu = pingCu, pingCm = pingCm,
        lossCt = lossCt, lossCu = lossCu, lossCm = lossCm,
    )

    @Test fun emptyHistoryHasNoScore() {
        val s = WidgetStability.compute(emptyList())
        assertNull(s.score); assertNull(s.lossPct); assertNull(s.jitterMs)
        assertEquals(0, s.spikes); assertEquals(0, s.samples)
    }

    @Test fun rowsWithoutPingAreNotSamples() {
        val s = WidgetStability.compute(listOf(point(), point(lossCt = 10.0)))
        assertEquals(0, s.samples); assertNull(s.score)
    }

    @Test fun cleanWindowScoresOneHundred() {
        val rows = (0 until 90).map { point(10.0, 10.0, 10.0, 0.2, 0.2, 0.2) }
        val s = WidgetStability.compute(rows)
        assertEquals(90, s.samples)
        assertEquals(0.2, s.lossPct!!, 0.001)
        assertEquals(0.0, s.jitterMs!!, 0.001)
        assertEquals(0, s.spikes); assertEquals(100, s.score)
    }

    @Test fun jitterIsMeanAbsoluteDeltaPerCarrier() {
        // CT |20-10|=10, CU |30-10|=20, CM 0 -> mean 10
        val s = WidgetStability.compute(listOf(point(10.0, 10.0, 10.0), point(20.0, 30.0, 10.0)))
        assertEquals(10.0, s.jitterMs!!, 0.001)
    }

    @Test fun jitterSkipsPairsWithAMissingEnd() {
        assertNull(WidgetStability.compute(listOf(point(10.0), point(null), point(30.0))).jitterMs)
    }

    @Test fun aSpikeNeedsTwiceTheMedianAnd50ms() {
        val calm = (0 until 9).map { point(10.0, 10.0, 10.0) }
        assertEquals(1, WidgetStability.compute(calm + point(60.0, 60.0, 60.0)).spikes)
        assertEquals(0, WidgetStability.compute(calm + point(49.0, 49.0, 49.0)).spikes)
    }

    @Test fun scoreIsClampedToZero() {
        val rows = (0 until 10).map { point(10.0, 10.0, 10.0, 100.0, 100.0, 100.0) }
        assertEquals(0, WidgetStability.compute(rows).score)
    }

    @Test fun allNullPingsLeaveEverythingEmpty() {
        val s = WidgetStability.compute((0 until 5).map { point() })
        assertNull(s.score); assertNull(s.jitterMs); assertNull(s.lossPct)
        assertEquals(0, s.spikes)
    }
}
```

- [ ] **Step 2: 运行确认失败** — `WidgetStability` 未定义，编译失败。

- [ ] **Step 3: 实现 `WidgetStability.kt`**

算法（spec §6）：

- 样本 = 至少一个 `ping*` 非 null 的行。
- `lossPct` = 所有样本中三网非 null loss 的均值；无值则 null。
- `jitterMs` = 对每个运营商取相邻样本 ping 差绝对值（跳过任一端 null），三网结果再取均值；无可配对则 null。
- `spikes` = 任一 ping > `max(2 × 全样本 ping 中位数, 50.0)` 的样本行数。
- `score = (100 - round(lossPct) - round(100.0 * spikes / samples)).coerceIn(0, 100)`；`samples == 0` 时 null。

- [ ] **Step 4: 运行确认通过** — Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/WidgetStability.kt android/app/src/test/kotlin/app/nodepulse/widget/WidgetStabilityTest.kt
git commit -m "feat: score the tall widget's last hour"
```

---

## Task 3: 快照兼容

**Files:**
- Modify: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetSnapshot.kt`
- Test: `android/app/src/test/kotlin/app/nodepulse/widget/WidgetSnapshotTest.kt`

**Interfaces:**
- Consumes: Task 1 的新字段
- Produces: `WidgetSnapshot.historyTo` 写 16 字段；`historyFrom` 接受 10 或 16 字段

- [ ] **Step 1: 写失败测试**

```kotlin
@Test
fun historyRoundTripsThePingColumns() {
    val points = listOf(
        WidgetApi.HistoryPoint(
            cpu = 1.0, memory = 2.0, disk = 3.0, netRx = 4.0, netTx = 5.0,
            pingCt = 10.0, pingCu = null, pingCm = 30.0,
        ),
    )
    val back = WidgetSnapshot.historyFrom(WidgetSnapshot.historyTo(points)).single()
    assertEquals(10.0, back.pingCt!!, 0.001)
    assertNull(back.pingCu)
    assertEquals(30.0, back.pingCm!!, 0.001)
}

@Test
fun aTenFieldSnapshotStillLoads() {
    // What the previous release wrote: ten numbers, no ping columns.
    val legacy = "1.00,2.00,3.00,4.00,5.00,6.00,7.00,8.00,9.00,0.00"
    val back = WidgetSnapshot.historyFrom(legacy).single()
    assertEquals(1.0, back.cpu, 0.001)
    assertNull(back.pingCt)
    assertNull(back.pingCu)
    assertNull(back.pingCm)
}
```

- [ ] **Step 2: 运行确认失败** — ping 字段未往返，`back.pingCt` 为 null 的断言在第一个测试失败。

- [ ] **Step 3: 实现**

`historyTo` 追加六个字段（三个 ping + 三个分网丢包），空值写 `-`；`historyFrom` 读前十个必填字段，其后的附加列按位置可选读取：缺列即 `null`，只有不足十列的行才丢弃。`-` 解析为 `null`。

- [ ] **Step 4: 运行确认通过** — Expected: PASS，且既有快照用例仍绿。

- [ ] **Step 5: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/WidgetSnapshot.kt android/app/src/test/kotlin/app/nodepulse/widget/WidgetSnapshotTest.kt
git commit -m "feat: keep the ping columns in the widget snapshot"
```

---

## Task 4: 条形图绘制

**Files:**
- Create: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetBars.kt`
- Test: `android/app/src/test/kotlin/app/nodepulse/widget/WidgetBarsTest.kt`

**Interfaces:**
- Consumes: `R.color.widgetText` / `widgetSummaryText`（仅 continuous/segmented 内部使用）
- Produces: `internal object WidgetBars { fun colorFor(fraction: Double?): Int; fun pingFraction(pingMs: Double?): Double?; fun segmented(fraction: Double?, w: Int, h: Int, density: Float): Bitmap?; fun continuous(fraction: Double?, w: Int, h: Int, density: Float): Bitmap? }`

**说明：** 位图生成需要 `Bitmap`/`Canvas`，JVM 单测里是空实现（`android.jar` stub 抛异常）。因此把**可测的算术**抽成纯函数（`colorFor`、`pingFraction`），位图函数只做绘制、由 Task 10 的编译与设备验收覆盖。

- [ ] **Step 1: 写失败测试**（只测纯函数）

```kotlin
package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetBarsTest {
    @Test fun pingFractionFallsFromOneToZero() {
        assertEquals(1.0, WidgetBars.pingFraction(0.0)!!, 0.001)
        assertEquals(0.5, WidgetBars.pingFraction(150.0)!!, 0.001)
        assertEquals(0.0, WidgetBars.pingFraction(300.0)!!, 0.001)
        assertEquals(0.0, WidgetBars.pingFraction(900.0)!!, 0.001)
    }

    @Test fun aMissingPingHasNoFraction() {
        assertNull(WidgetBars.pingFraction(null))
    }

    @Test fun colourBandsSplitAtTwoThirdsAndOneThird() {
        assertEquals(0xFF34C759.toInt(), WidgetBars.colorFor(1.0))
        assertEquals(0xFF34C759.toInt(), WidgetBars.colorFor(0.66))
        assertEquals(0xFFFF9F0A.toInt(), WidgetBars.colorFor(0.65))
        assertEquals(0xFFFF9F0A.toInt(), WidgetBars.colorFor(0.33))
        assertEquals(0xFFFF453A.toInt(), WidgetBars.colorFor(0.32))
        assertEquals(0xFF888888.toInt(), WidgetBars.colorFor(null))
    }
}
```

- [ ] **Step 2: 运行确认失败** — `WidgetBars` 未定义。

- [ ] **Step 3: 实现**

- `pingFraction(pingMs)`: null → null；否则 `(1.0 - pingMs / 300.0).coerceIn(0.0, 1.0)`。
- `colorFor(fraction)`: null → `0xFF888888`；`>= 0.66` → `0xFF34C759`；`>= 0.33` → `0xFFFF9F0A`；否则 `0xFFFF453A`。
- `segmented(...)`: 20 段，段间 1dp 间隙，已填充段用 `colorFor`，未填充段用 `0x33888888`。
- `continuous(...)`: 圆角半径 = h/2，先画整条轨道 `0x33888888`，再按 fraction 画填充。
- 两者 `fraction == null` 时只画轨道；`w <= 0 || h <= 0` 返回 null。

- [ ] **Step 4: 运行确认通过** — Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/WidgetBars.kt android/app/src/test/kotlin/app/nodepulse/widget/WidgetBarsTest.kt
git commit -m "feat: draw the widget's ping and stability bars"
```

---

## Task 5: 配置模型改用 TALL

**Files:**
- Modify: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetConfig.kt`
- Test: `android/app/src/test/kotlin/app/nodepulse/widget/WidgetConfigTest.kt`

**Interfaces:**
- Consumes: 现有 `WidgetKind`、`WidgetConfig`、`WidgetField`
- Produces: `WidgetKind.TALL`（替换 `SMALL`）；`WidgetConfig.DEFAULT_READING_FIELDS`（替换 `DEFAULT_SMALL_FIELDS`）；`CAP_SMALL_FIELDS` 与 `WidgetKind.CHART_COUNT` 删除

- [ ] **Step 1: 写失败测试**

```kotlin
@Test
fun aTallWidgetKeepsNoFieldList() {
    val config = WidgetConfig(
        serverId = "srv-1",
        kind = WidgetKind.TALL,
        fields = listOf(WidgetField.CPU, WidgetField.MEM),
        expiry = WidgetExpiry.H1,
    )
    WidgetConfig.saveToPrefs(mockPrefs, 77, config)
    val loaded = WidgetConfig.loadFromPrefs(mockPrefs, 77, WidgetKind.TALL)
    assertEquals(WidgetKind.TALL, loaded.kind)
    assertTrue(loaded.fields.isEmpty())
    assertEquals(WidgetExpiry.H1, loaded.expiry)
}

@Test
fun aMediumReadingStillGetsTheDefaultFields() {
    val loaded = WidgetConfig.loadFromPrefs(mockPrefs, 78, WidgetKind.MEDIUM)
    assertEquals(WidgetConfig.DEFAULT_READING_FIELDS, loaded.fields)
}
```

- [ ] **Step 2: 运行确认失败** — `WidgetKind.TALL` 与 `DEFAULT_READING_FIELDS` 未定义。

- [ ] **Step 3: 实现**

- `WidgetKind`：`SMALL` → `TALL`，注释改为「2x4, fixed rows」。删除 `CHART_COUNT`；`drawsCharts` 保持 `this == MEDIUM`。
- `WidgetConfig`：删除 `CAP_SMALL_FIELDS`；`DEFAULT_SMALL_FIELDS` 改名 `DEFAULT_READING_FIELDS`（内容不变）；`load`/`loadFromPrefs` 的 `kind` 默认值改 `TALL`。
- 上限计算：`kind == TALL -> 0`；`saveToPrefs` 在 `kind == TALL` 时不写 `fields` 键，`loadFromPrefs` 在 `kind == TALL` 时直接返回空列表（不读 `fields`）。
- `MEDIUM` 分支保持原样（`READING` 8 项、`COMBINED` 4 项、`CHART` 0 项）。

- [ ] **Step 4: 运行确认通过** — Expected: PASS。既有 `WidgetConfigTest` 中所有 `WidgetKind.SMALL` 引用改为 `TALL`，相关断言按新语义调整。

- [ ] **Step 5: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/WidgetConfig.kt android/app/src/test/kotlin/app/nodepulse/widget/WidgetConfigTest.kt
git commit -m "refactor: swap the 2x2 widget for a 2x4 one in the config"
```

---

## Task 6: 布局、注册与字符串

**Files:**
- Create: `android/app/src/main/res/layout/home_widget_tall.xml`
- Create: `android/app/src/main/res/xml/widget_tall.xml`
- Create: `android/app/src/main/res/drawable/widget_region_bg.xml`
- Create: `android/app/src/main/res/drawable/widget_divider.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/res/values/strings.xml`
- Modify: `android/app/src/main/res/values-zh-rCN/strings.xml`
- Delete: `android/app/src/main/res/xml/widget_small.xml`
- Delete: 15 个语言目录中的 `widget_small_label`

**Interfaces:**
- Consumes: `@color/widgetBackground`、`@color/widgetText`、`@color/widgetSummaryText`、`@drawable/refresh_24`、`@drawable/widget_background`
- Produces: 视图 id `widget_tall_body`、`widget_dot`、`widget_name`、`widget_region`、`widget_refresh`、`widget_time`、`widget_error`，行 id `widget_row_cpu`、`widget_row_mem`、`widget_row_disk`、`widget_row_load`、`widget_row_live`、`widget_row_month`、`widget_row_uptime`、`widget_row_ct`、`widget_row_cu`、`widget_row_cm`、`widget_row_stability`，及其 `_label` / `_value` 子 id，条形图 id `widget_bar_ct`、`widget_bar_cu`、`widget_bar_cm`、`widget_bar_stability`

- [ ] **Step 1: 新建 `widget_tall.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!--
    The tall widget: one server's full status, at a fixed 2x4. See
    `widget_medium.xml` for why neither widget resizes.
-->
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="250dp"
    android:targetCellWidth="2"
    android:targetCellHeight="4"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/home_widget_tall"
    android:configure="app.nodepulse.widget.WidgetConfigureActivity"
    android:resizeMode="none"
    android:widgetCategory="home_screen">
</appwidget-provider>
```

- [ ] **Step 2: 新建两个 drawable**

`widget_region_bg.xml`：6dp 圆角，`#1A888888` 填充。
`widget_divider.xml`：`<shape>` 矩形，`#1F888888` 填充，高度由布局的 `layout_height="1dp"` 决定。

- [ ] **Step 3: 新建 `home_widget_tall.xml`**

外层 `LinearLayout`（`@drawable/widget_background`，`padding=10dp`，vertical），内含：

1. `widget_tall_body`（vertical，`layout_weight=1`）——所有数据行。
2. `widget_error`（`TextView`，`layout_weight=1`，`gravity=center`，`visibility=gone`）。

`widget_tall_body` 的行序：

| id | 结构 |
|---|---|
| header | 横向：`widget_dot`（`●`，10sp）、`widget_name`（13sp bold，weight=1，`ellipsize=end`）、`widget_region`（`@drawable/widget_region_bg`，9sp，`paddingHorizontal=5dp`）、`widget_refresh`（24dp，`@drawable/refresh_24`） |
| `widget_row_cpu` | 横向：`widget_row_cpu_label`（10sp summary，weight=1）、`widget_row_cpu_value`（10sp bold mono，右对齐） |
| divider | `View`，1dp，`@drawable/widget_divider`，上下 `marginVertical=3dp` |
| `widget_row_mem` / `widget_row_disk` / `widget_row_load` / `widget_row_live` / `widget_row_month` / `widget_row_uptime` | 同 cpu 行结构，`layout_marginTop=2dp` |
| divider | 同上 |
| `widget_row_ct` / `widget_row_cu` / `widget_row_cm` | 横向：`_label`（10sp summary，`minWidth=26dp`）、`widget_bar_*`（`ImageView`，`layout_height=6dp`，weight=1，`scaleType=fitXY`）、`_value`（10sp bold mono，右对齐，`minWidth=34dp`） |
| divider | 同上 |
| `widget_row_stability` | 横向：`widget_row_stability_label`（10sp summary，weight=1）、`widget_row_stability_value`（10sp bold mono） |
| `widget_bar_stability` | `ImageView`，5dp 高，`scaleType=fitXY`，`marginTop=3dp` |
| footer | 横向：`widget_footer_text`（9sp summary，weight=1，`ellipsize=end`）、`widget_time`（9sp mono） |

所有 `_value` 与 footer 都设 `android:singleLine="true"`、`android:ellipsize="end"`。

- [ ] **Step 4: 改 manifest**

`StatusWidgetSmall` 的 `<receiver>` 替换为：

```xml
<receiver
    android:name=".widget.StatusWidgetTall"
    android:exported="false"
    android:label="@string/widget_tall_label">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        <action android:name="app.nodepulse.UPDATE_WIDGET" />
        <action android:name="miui.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_tall" />
</receiver>
```

同时更新上方注释：「2x4 holds one server's status, 4x2 holds charts」。

- [ ] **Step 5: 字符串**

`values/strings.xml` 新增 spec §10 的 13 个 key；`values-zh-rCN/strings.xml` 同。删除全部 15 个语言目录里的 `widget_small_label`。删除 `widget_small.xml`。

- [ ] **Step 6: 编译确认资源可用**

```bash
source /home/ops/toolchain/env.sh
cd android && ./gradlew :app:processDebugResources -x :app:compileFlutterBuildDebug
```
Expected: BUILD SUCCESSFUL。此时 `StatusWidgetTall` 尚不存在，`AndroidManifest` 的 receiver 引用会在 `compileDebugKotlin` 阶段失败——本步只验资源，故用 `processDebugResources`。

- [ ] **Step 7: 提交**

```bash
git add android/app/src/main/res android/app/src/main/AndroidManifest.xml
git commit -m "feat: register the 2x4 tall widget"
```

---

## Task 7: 渲染与刷新

**Files:**
- Modify: `android/app/src/main/kotlin/app/nodepulse/widget/HomeWidget.kt`
- Modify: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetApi.kt`（`load` 增加 `historyHours`）

**Interfaces:**
- Consumes: Task 1 的 `Reading` 字段、Task 2 的 `WidgetStability`、Task 3 的快照、Task 4 的 `WidgetBars`、Task 6 的视图 id
- Produces: `class StatusWidgetTall : HomeWidget(WidgetKind.TALL)`；`WidgetApi.load(context, server, historyHours: Double = 24.0)`

- [ ] **Step 1: 扩展 `WidgetApi.load`**

签名改为 `suspend fun load(context: Context, server: WidgetStore.WidgetServer, historyHours: Double = 24.0): Fetched`，把 `hours` 查询参数由字面量 `24` 改为 `$historyHours`。4x2 不传，保持 24。

- [ ] **Step 2: `HomeWidget` 的 provider 列表与工厂**

- `providers` → `listOf(StatusWidgetTall::class.java, StatusWidgetMedium::class.java)`
- `refreshAll` 的 `when` → `StatusWidgetTall::class.java -> StatusWidgetTall()`，`else -> StatusWidgetMedium()`
- `requestUpdate` 的 `when` → `WidgetKind.TALL -> StatusWidgetTall()`，`WidgetKind.MEDIUM -> StatusWidgetMedium()`
- `kindOf` 的 `when` → `StatusWidgetTall::class.java.name -> WidgetKind.TALL`

- [ ] **Step 3: 分派渲染**

`update()` 里按 `kind` 选布局：

```kotlin
val layout = if (kind == WidgetKind.TALL) R.layout.home_widget_tall else R.layout.home_widget
val views = RemoteViews(context.packageName, layout)
```

`showData` 开头按 kind 分支：`TALL -> showTall(...)` 并 return，其余走现有 4x2 逻辑。`showError`、`showLoading`、`showHeld` 同样按 kind 分支，TALL 只操作 `widget_tall_body`、`widget_error`、`widget_name`、`widget_time`。

历史窗口：`WidgetApi.load(context, server, historyHours = if (kind == WidgetKind.TALL) 1.0 else 24.0)`。

`Bounds`：新增 `TALL` 分支，`paddingDp = 10f`、`headerSp = 13f`，`widthPx/heightPx` 不用（TALL 无图表），保留字段以免改动调用方。

- [ ] **Step 4: `showTall`**

按 spec §4 逐行填值：

| 视图 | 内容 |
|---|---|
| `widget_dot` | 文本 `●`；颜色按 `lastUpdated` 距 now：<90s `#34C759`、≥90s `#FF453A`、null/≤0 `#888888` |
| `widget_region` | `reading.region`；为空则 `GONE` |
| `widget_row_cpu_label` | `cpuCores != null` → `getString(R.string.widget_row_cpu_cores, cores)`；否则 `"CPU"` |
| `widget_row_cpu_value` | `String.format(Locale.US, "%.1f%%", cpu)`，null → `--` |
| `widget_row_mem_label/value` | `widget_row_memory` / `WidgetApi.formatSharedUnit(ramUsed, ramTotal)` |
| `widget_row_disk_*` | 同上，磁盘 |
| `widget_row_load_*` | `widget_row_load` / `"%.2f %.2f %.2f".format(load1, load5, load15)` |
| `widget_row_live_*` | `widget_row_live` / `WidgetApi.formatSharedPair(netIn, netOut, perSecond = true)` |
| `widget_row_month_*` | `widget_row_month` / `WidgetApi.formatSharedPair(netRxMonthly, netTxMonthly)` |
| `widget_row_uptime_*` | `widget_row_uptime` / `uptimeText` |
| `widget_row_ct/cu/cm_label` | 三个运营商字符串 |
| `widget_row_*_value` | `ping != null` → `"${ping.toInt()}ms"`，否则 `--` |
| `widget_bar_ct/cu/cm` | `WidgetBars.segmented(WidgetBars.pingFraction(ping), w, h, density)` |
| `widget_row_stability_value` | `stats.score?.toString() ?: "--"` |
| `widget_bar_stability` | `WidgetBars.continuous(stats.score / 100.0, w, h, density)` |
| `widget_footer_text` | `getString(R.string.widget_stability_footer, lossText, jitterText, spikesText)`，无数据时三段都是 `--` |
| `widget_time` | 沿用 `showTime` 的格式与配色，写到 `widget_time` |

条形图宽度：`bounds.widthPx` 减去标签 `minWidth` 与数值 `minWidth` 及间隙；高度用布局里的 6dp/5dp 换算成 px。任一位图为 null 时把对应 `ImageView` 设为 `GONE`。

- [ ] **Step 5: 编译**

```bash
source /home/ops/toolchain/env.sh
cd android && ./gradlew :app:compileDebugKotlin -x :app:compileFlutterBuildDebug
```
Expected: BUILD SUCCESSFUL。

- [ ] **Step 6: 跑单测**

```bash
cd android && ./gradlew :app:testDebugUnitTest --tests 'app.nodepulse.widget.*' -x :app:compileFlutterBuildDebug
```
Expected: PASS。

- [ ] **Step 7: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/HomeWidget.kt android/app/src/main/kotlin/app/nodepulse/widget/WidgetApi.kt
git commit -m "feat: render the 2x4 tall widget"
```

---

## Task 8: 配置界面

**Files:**
- Modify: `android/app/src/main/kotlin/app/nodepulse/widget/WidgetConfigureActivity.kt`
- Modify: `android/app/src/main/res/layout/widget_configure.xml`

**Interfaces:**
- Consumes: Task 5 的 `WidgetKind.TALL`、`WidgetConfig`
- Produces: TALL 只显示服务器列表与过期阈值

- [ ] **Step 1: 改 `updateUI`**

`kind == WidgetKind.TALL` 分支：隐藏 `medium_mode_container`、`chart_count_container`、`chart_container`、`chart2_container`、`chart3_container`、`chart4_container`、`fields_container`；显示 `expiry_container`。删掉原来 `if (kind == WidgetKind.SMALL)` 的整块。

- [ ] **Step 2: 改保存逻辑**

- `selectedMode`：TALL 时固定 `MediumMode.CHART`（该字段对 TALL 无意义，但 `WidgetConfig` 需要它）。
- `selectedFields`：TALL 时 `emptyList()`。
- `selectedExpiry`：TALL 也读 `expiryGroup`，不再强制 `DEFAULT`。
- `kindOf(...) ?: WidgetKind.TALL`。

- [ ] **Step 3: 改布局注释**

`widget_configure.xml` 里 `expiry_container` 的注释由「MEDIUM only」改为「MEDIUM and TALL」。

- [ ] **Step 4: 编译**

```bash
source /home/ops/toolchain/env.sh
cd android && ./gradlew :app:compileDebugKotlin -x :app:compileFlutterBuildDebug
```
Expected: BUILD SUCCESSFUL。

- [ ] **Step 5: 提交**

```bash
git add android/app/src/main/kotlin/app/nodepulse/widget/WidgetConfigureActivity.kt android/app/src/main/res/layout/widget_configure.xml
git commit -m "feat: configure the tall widget with a server and an expiry"
```

---

## Task 9: 清理与全量验证

**Files:**
- 全仓库检索

- [ ] **Step 1: 找残留**

```bash
grep -rn "WidgetKind.SMALL\|StatusWidgetSmall\|widget_small\|CAP_SMALL\|DEFAULT_SMALL_FIELDS\|CHART_COUNT" android/app/src --include="*.kt" --include="*.xml"
```
Expected: 无输出。

- [ ] **Step 2: 跑全部 Android 单测**

```bash
source /home/ops/toolchain/env.sh
cd android && ./gradlew :app:testDebugUnitTest -x :app:compileFlutterBuildDebug
```
Expected: BUILD SUCCESSFUL。

- [ ] **Step 3: 跑 Dart 侧检查**

```bash
source /home/ops/toolchain/env.sh
cd /home/ops/nodepulse && flutter analyze lib test integration_test
```
Expected: 无新增 issue（本计划未改 Dart）。

- [ ] **Step 4: 构建 APK 做资源与 manifest 校验**

```bash
source /home/ops/toolchain/env.sh
cd /home/ops/nodepulse && flutter build apk --debug
```
Expected: BUILD SUCCESSFUL，`build/app/outputs/flutter-apk/app-debug.apk` 存在。

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "chore: drop the last 2x2 widget references"
```

---

## Task 10: 设备验收

**Files:** 无

- [ ] **Step 1: 安装**

```bash
source /home/ops/toolchain/env.sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
（若设备未连接，跳到 Step 4 记录未验证。）

- [ ] **Step 2: 添加小组件**

长按桌面 → 小组件 → NodePulse → 确认选择器只有「服务器状态」与「服务器曲线」两项。

- [ ] **Step 3: 逐项核对 spec §12**

1. 2x4 版面与 spec §4 一致，不可缩放。
2. 数据齐全时 11 行 + 稳定性条 + 脚注全部有值。
3. 断网后整卡保留上次读数，脚注时间变色。
4. 清空应用数据后显示「点按选择服务器」。

- [ ] **Step 4: 记录结果**

设备验收通过则继续；未连接设备则在最终汇报中明确写「设备验收未执行」，不写成通过。
