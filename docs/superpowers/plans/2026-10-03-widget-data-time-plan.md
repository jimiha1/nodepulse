# 4x2 Android 桌面小组件数据时间与过期变色实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 4x2（MEDIUM）Android 桌面小组件表头添加基于真实服务端上报时间戳 `last_updated` 的数据时间显示（`HH:mm`），修复小组件错误状态下单向将时间 `GONE` 导致的永久消失 Bug，支持在小组件配置页自由设置数据过期阈值（10m/30m/1h/2h/never），并按新鲜度联动颜色（灰/琥珀/红）。2x2（SMALL）小组件保持不显示时间以节省紧凑空间。

**Architecture:**
1. 数据层：`WidgetApi.kt` 从 `/api/servers` 中解析 `last_updated` 时间戳存入 `Reading` 数据类。
2. 配置层：`WidgetConfig.kt` 增加 `WidgetExpiry` 档位枚举，支持读写 SharedPreferences（`widget_{id}_expiry`）。
3. UI 配置层：`widget_configure.xml` 与 `WidgetConfigureActivity.kt` 增加过期单选组，仅针对 MEDIUM 模式显示。
4. 渲染层：`HomeWidget.kt` 在 `showData()` 与 `showLoading()` 恢复时间可见性（MEDIUM 设为 `VISIBLE`，SMALL 设为 `GONE`），并根据当前时间与数据时间差值匹配颜色。

**Tech Stack:** Kotlin, Android RemoteViews, SharedPreferences, JUnit 4, Gradle.

## Global Constraints
- 仅对 4x2（MEDIUM）尺寸小组件启用时间与变色；2x2（SMALL）小组件必须保持时间 `View.GONE`，不占空间。
- 时间格式恒定为 `HH:mm`（24小时制，设备本地时区）。当无有效时间戳时显示 `--`。
- 颜色对比度必须满足 WCAG AA（浅色模式琥珀 `#B45309`、红 `#DC2626`；深色模式琥珀 `#FFB340`、红 `#FF453A`）。
- 绝不运行全局代码格式化工具；严格匹配所在文件的现有代码风格。

---

### Task 1: 颜色与多语言字符串资源配置

**Files:**
- Modify: `android/app/src/main/res/values/colors.xml:4-7`
- Modify: `android/app/src/main/res/values-night/colors.xml:3-6`
- Modify: `android/app/src/main/res/values/strings.xml:65-75`
- Modify: `android/app/src/main/res/values-zh-rCN/strings.xml:45-55`

**Interfaces:**
- Produces:
  - Colors: `@color/widgetTimeAging`, `@color/widgetTimeStale`
  - Strings: `@string/widget_expiry_title`, `@string/widget_expiry_10m`, `@string/widget_expiry_30m`, `@string/widget_expiry_1h`, `@string/widget_expiry_2h`, `@string/widget_expiry_never`

- [ ] **Step 1: 在 `colors.xml` 添加浅色模式时间警告颜色**

编辑 `android/app/src/main/res/values/colors.xml`，在 `<resources>` 内添加：
```xml
    <color name="widgetTimeAging">#B45309</color>
    <color name="widgetTimeStale">#DC2626</color>
```

- [ ] **Step 2: 在 `values-night/colors.xml` 添加深色模式时间警告颜色**

编辑 `android/app/src/main/res/values-night/colors.xml`，在 `<resources>` 内添加：
```xml
    <color name="widgetTimeAging">#FFB340</color>
    <color name="widgetTimeStale">#FF453A</color>
```

- [ ] **Step 3: 在 `values/strings.xml` 添加英文多语言字符串**

编辑 `android/app/src/main/res/values/strings.xml`，在尾部添加：
```xml
    <string name="widget_expiry_title">Data Expiry Alert</string>
    <string name="widget_expiry_10m">10 minutes</string>
    <string name="widget_expiry_30m">30 minutes (Default)</string>
    <string name="widget_expiry_1h">1 hour</string>
    <string name="widget_expiry_2h">2 hours</string>
    <string name="widget_expiry_never">Disabled</string>
```

- [ ] **Step 4: 在 `values-zh-rCN/strings.xml` 添加中文多语言字符串**

编辑 `android/app/src/main/res/values-zh-rCN/strings.xml`，在尾部添加：
```xml
    <string name="widget_expiry_title">数据过期变色</string>
    <string name="widget_expiry_10m">10 分钟</string>
    <string name="widget_expiry_30m">30 分钟 (默认)</string>
    <string name="widget_expiry_1h">1 小时</string>
    <string name="widget_expiry_2h">2 小时</string>
    <string name="widget_expiry_never">不提示变色</string>
```

- [ ] **Step 5: 验证资源编译无误**

Run: `cd android && ./gradlew :app:processDebugResources`
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/res/values*/colors.xml android/app/src/main/res/values*/strings.xml
git commit -m "feat(widget): add colors and strings for widget time and expiry configuration"
```

---

### Task 2: 数据模型与配置类扩展 (TDD)

**Files:**
- Modify: `android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetApi.kt:36-57,100-245`
- Modify: `android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetConfig.kt:1-200`
- Test: `android/app/src/test/kotlin/tech/lolli/toolbox/widget/CfWidgetParseTest.kt`

**Interfaces:**
- Consumes: Task 1 的字符串与资源定义
- Produces:
  - `WidgetApi.Reading.lastUpdated: Long?`
  - `enum class WidgetExpiry(val minutes: Int, val key: String)` 与 `WidgetConfig.expiry: WidgetExpiry`
  - `WidgetConfig.loadFromPrefs` / `saveToPrefs` 支持 `widget_{id}_expiry`

- [ ] **Step 1: 编写失败的单元测试**

在 `android/app/src/test/kotlin/tech/lolli/toolbox/widget/CfWidgetParseTest.kt` 中添加：
```kotlin
    @Test
    fun parseCfServerNodeLastUpdated() {
        val server = WidgetStore.WidgetServer(
            id = "fd978320-c32c-474d-857a-3412a7526a7b",
            name = "日本节点",
            region = "JP",
        )
        val jsonWithLastUpdated = """
        {
          "servers": [{
            "id": "fd978320-c32c-474d-857a-3412a7526a7b",
            "name": "日本节点",
            "cpu": 5.0,
            "last_updated": 1759410000000
          }]
        }
        """.trimIndent()
        val reading = WidgetApi.parseCfMetrics(server, jsonWithLastUpdated)
        assertEquals(1759410000000L, reading.lastUpdated)
    }

    @Test
    fun widgetConfigExpiryPersistence() {
        val prefs = androidx.test.core.app.ApplicationProvider.getApplicationContext<android.content.Context>()
            .getSharedPreferences("test_widget_config", android.content.Context.MODE_PRIVATE)
        val config = WidgetConfig(
            serverId = "srv-1",
            kind = WidgetKind.MEDIUM,
            expiry = WidgetExpiry.H1,
        )
        WidgetConfig.saveToPrefs(prefs, 101, config)
        val loaded = WidgetConfig.loadFromPrefs(prefs, 101, WidgetKind.MEDIUM)
        assertEquals(WidgetExpiry.H1, loaded.expiry)
    }
```

- [ ] **Step 2: 运行测试验证失败**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "tech.lolli.toolbox.widget.CfWidgetParseTest"`
Expected: FAIL (unresolved reference: lastUpdated, WidgetExpiry)

- [ ] **Step 3: 在 `WidgetApi.kt` 中增加 `lastUpdated` 解析**

修改 `android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetApi.kt`：
在 `data class Reading` 中增加：
```kotlin
        val avgLoss: Double? = null,
        val lastUpdated: Long? = null,
    )
```
在 `parseCfMetrics()` 内部末尾提取：
```kotlin
        val lastUpdatedRaw = o.optLong("last_updated", 0L)
        val lastUpdated = if (lastUpdatedRaw > 0) lastUpdatedRaw else null

        return Reading(
            name = o.optString("name").ifEmpty { server.name },
            cpu = cpu,
            ...
            avgLoss = avgLoss,
            lastUpdated = lastUpdated,
        )
```

- [ ] **Step 4: 在 `WidgetConfig.kt` 中添加 `WidgetExpiry` 及持久化逻辑**

修改 `android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetConfig.kt`：
增加枚举：
```kotlin
enum class WidgetExpiry(val minutes: Int, val key: String) {
    M10(10, "10m"),
    M30(30, "30m"),
    H1(60, "1h"),
    H2(120, "2h"),
    NEVER(0, "never");

    companion object {
        val DEFAULT = M30
        fun fromKey(key: String?): WidgetExpiry =
            entries.firstOrNull { it.key == key } ?: DEFAULT
    }
}
```
在 `data class WidgetConfig` 中增加：
```kotlin
    val chart4: String = DEFAULT_CHART4,
    val expiry: WidgetExpiry = WidgetExpiry.DEFAULT,
)
```
在 `loadFromPrefs()` 中读取：
```kotlin
            val expiry = WidgetExpiry.fromKey(prefs.getString(key(appWidgetId, "expiry"), null))
```
并在返回 `WidgetConfig(...)` 中传入 `expiry = expiry`。

在 `saveToPrefs()` 中保存：
```kotlin
                .putString(key(appWidgetId, "expiry"), config.expiry.key)
```

在 `forgetFromPrefs()` 中清除：
```kotlin
                .remove(key(appWidgetId, "expiry"))
```

- [ ] **Step 5: 重新运行单元测试验证通过**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "tech.lolli.toolbox.widget.CfWidgetParseTest"`
Expected: BUILD SUCCESSFUL & tests pass

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetApi.kt android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetConfig.kt android/app/src/test/kotlin/tech/lolli/toolbox/widget/CfWidgetParseTest.kt
git commit -m "feat(widget): parse last_updated and add WidgetExpiry config persistence"
```

---

### Task 3: 配置界面新增数据过期单选配置

**Files:**
- Modify: `android/app/src/main/res/layout/widget_configure.xml:180-220`
- Modify: `android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetConfigureActivity.kt:70-230`

**Interfaces:**
- Consumes: Task 1 字符串与 Task 2 `WidgetExpiry` / `WidgetConfig.expiry`
- Produces: 配置界面完整支持对 MEDIUM 小组件的过期时间选择与持久化

- [ ] **Step 1: 在 `widget_configure.xml` 增加过期时间单选容器**

在 `android/app/src/main/res/layout/widget_configure.xml` 的 `fields_container` 下方添加：
```xml
            <!-- Data Expiry Selector (for MEDIUM mode) -->
            <LinearLayout
                android:id="@+id/expiry_container"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="16dp"
                android:orientation="vertical"
                android:visibility="gone">

                <TextView
                    android:id="@+id/expiry_title"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/widget_expiry_title"
                    android:textSize="13sp"
                    android:textStyle="bold" />

                <RadioGroup
                    android:id="@+id/expiry_group"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:layout_marginTop="4dp"
                    android:orientation="vertical">

                    <RadioButton
                        android:id="@+id/expiry_10m"
                        android:layout_width="match_parent"
                        android:layout_height="wrap_content"
                        android:text="@string/widget_expiry_10m" />

                    <RadioButton
                        android:id="@+id/expiry_30m"
                        android:layout_width="match_parent"
                        android:layout_height="wrap_content"
                        android:text="@string/widget_expiry_30m" />

                    <RadioButton
                        android:id="@+id/expiry_1h"
                        android:layout_width="match_parent"
                        android:layout_height="wrap_content"
                        android:text="@string/widget_expiry_1h" />

                    <RadioButton
                        android:id="@+id/expiry_2h"
                        android:layout_width="match_parent"
                        android:layout_height="wrap_content"
                        android:text="@string/widget_expiry_2h" />

                    <RadioButton
                        android:id="@+id/expiry_never"
                        android:layout_width="match_parent"
                        android:layout_height="wrap_content"
                        android:text="@string/widget_expiry_never" />
                </RadioGroup>
            </LinearLayout>
```

- [ ] **Step 2: 在 `WidgetConfigureActivity.kt` 绑定控件与存取逻辑**

修改 `android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetConfigureActivity.kt`：
1. 查找视图组件：
```kotlin
        val expiryContainer = findViewById<LinearLayout>(R.id.expiry_container)
        val expiryGroup = findViewById<RadioGroup>(R.id.expiry_group)
```
2. 回显现有配置：
```kotlin
        if (kind == WidgetKind.MEDIUM) {
            when (existing.expiry) {
                WidgetExpiry.M10 -> expiryGroup.check(R.id.expiry_10m)
                WidgetExpiry.M30 -> expiryGroup.check(R.id.expiry_30m)
                WidgetExpiry.H1 -> expiryGroup.check(R.id.expiry_1h)
                WidgetExpiry.H2 -> expiryGroup.check(R.id.expiry_2h)
                WidgetExpiry.NEVER -> expiryGroup.check(R.id.expiry_never)
            }
        }
```
3. 在 `updateUI()` 中处理可见性：
```kotlin
        if (kind == WidgetKind.SMALL) {
            ...
            expiryContainer.visibility = View.GONE
        } else {
            ...
            expiryContainer.visibility = View.VISIBLE
        }
```
4. 在保存按钮点击回调中保存：
```kotlin
            val selectedExpiry = if (kind == WidgetKind.SMALL) {
                WidgetExpiry.DEFAULT
            } else {
                when (expiryGroup.checkedRadioButtonId) {
                    R.id.expiry_10m -> WidgetExpiry.M10
                    R.id.expiry_1h -> WidgetExpiry.H1
                    R.id.expiry_2h -> WidgetExpiry.H2
                    R.id.expiry_never -> WidgetExpiry.NEVER
                    else -> WidgetExpiry.M30
                }
            }
```
并传入 `WidgetConfig(..., expiry = selectedExpiry)`。

- [ ] **Step 3: 运行单元测试或资源检查确认构建通过**

Run: `cd android && ./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/res/layout/widget_configure.xml android/app/src/main/kotlin/tech/lolli/toolbox/widget/WidgetConfigureActivity.kt
git commit -m "feat(widget): add data expiry configuration UI to WidgetConfigureActivity"
```

---

### Task 4: 小组件渲染逻辑与 Bug 修复 (TDD)

**Files:**
- Modify: `android/app/src/main/kotlin/tech/lolli/toolbox/widget/HomeWidget.kt:250-290,500-515`
- Test: `android/app/src/test/kotlin/tech/lolli/toolbox/widget/CfWidgetParseTest.kt`

**Interfaces:**
- Consumes: Task 1 颜色、Task 2 `lastUpdated` 与 `expiry`
- Produces: 修复 `widget_time` 单向不可见 Bug；4x2 显示数据时间与变色；2x2 彻底隐藏时间

- [ ] **Step 1: 编写变色判定函数的单元测试**

在 `android/app/src/test/kotlin/tech/lolli/toolbox/widget/CfWidgetParseTest.kt` 中添加：
```kotlin
    @Test
    fun resolveTimeColorTiers() {
        val now = 1759410000000L
        val expiry30m = WidgetExpiry.M30 // T = 30m = 1800s = 1800000ms

        // 1. Fresh: age = 10m <= 30m -> SummaryText
        val freshColor = HomeWidget.resolveTimeColorRes(now - 10 * 60 * 1000L, expiry30m, now)
        assertEquals(tech.lolli.toolbox.R.color.widgetSummaryText, freshColor)

        // 2. Aging: age = 45m (30m < 45m <= 120m) -> Aging
        val agingColor = HomeWidget.resolveTimeColorRes(now - 45 * 60 * 1000L, expiry30m, now)
        assertEquals(tech.lolli.toolbox.R.color.widgetTimeAging, agingColor)

        // 3. Stale: age = 150m > 120m -> Stale
        val staleColor = HomeWidget.resolveTimeColorRes(now - 150 * 60 * 1000L, expiry30m, now)
        assertEquals(tech.lolli.toolbox.R.color.widgetTimeStale, staleColor)

        // 4. NEVER: always SummaryText
        val neverColor = HomeWidget.resolveTimeColorRes(now - 300 * 60 * 1000L, WidgetExpiry.NEVER, now)
        assertEquals(tech.lolli.toolbox.R.color.widgetSummaryText, neverColor)
    }
```

- [ ] **Step 2: 运行测试验证失败**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "tech.lolli.toolbox.widget.CfWidgetParseTest"`
Expected: FAIL (unresolved reference: resolveTimeColorRes)

- [ ] **Step 3: 在 `HomeWidget.kt` 中实现变色计算与渲染修复**

编辑 `android/app/src/main/kotlin/tech/lolli/toolbox/widget/HomeWidget.kt`：
1. 在 `companion object` 中提供静态帮助函数 `resolveTimeColorRes`（便于单测与复用）：
```kotlin
        fun resolveTimeColorRes(
            lastUpdated: Long?,
            expiry: WidgetExpiry,
            now: Long = System.currentTimeMillis(),
        ): Int {
            if (lastUpdated == null || lastUpdated <= 0 || expiry == WidgetExpiry.NEVER) {
                return R.color.widgetSummaryText
            }
            val ageMs = (now - lastUpdated).coerceAtLeast(0)
            val thresholdMs = expiry.minutes * 60 * 1000L
            return when {
                ageMs <= thresholdMs -> R.color.widgetSummaryText
                ageMs <= 4 * thresholdMs -> R.color.widgetTimeAging
                else -> R.color.widgetTimeStale
            }
        }
```
2. 修改 `showLoading()`：
```kotlin
    private fun showLoading(
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        name: String,
    ) {
        views.setTextViewText(R.id.widget_name, name)
        if (kind == WidgetKind.MEDIUM) {
            views.setViewVisibility(R.id.widget_time, View.VISIBLE)
            views.setTextViewText(R.id.widget_time, "…")
            views.setTextColor(R.id.widget_time, ContextCompat.getColor(context, R.color.widgetSummaryText))
        } else {
            views.setViewVisibility(R.id.widget_time, View.GONE)
        }
        views.setViewVisibility(R.id.error_message, View.GONE)
        manager.updateAppWidget(appWidgetId, views)
    }
```
*(注意：若 `showLoading` 没有 `context`，从调用方传入 `context`)*

3. 修改 `showData()`：
```kotlin
    private fun showData(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        config: WidgetConfig,
        reading: WidgetApi.Reading,
        history: List<WidgetApi.HistoryPoint>,
        bounds: Bounds,
    ) {
        views.setTextViewText(R.id.widget_name, reading.name)
        if (kind == WidgetKind.MEDIUM) {
            views.setViewVisibility(R.id.widget_time, View.VISIBLE)
            val ts = reading.lastUpdated
            if (ts != null && ts > 0) {
                val timeStr = android.text.format.DateFormat.format("HH:mm", java.util.Date(ts)).toString()
                views.setTextViewText(R.id.widget_time, timeStr)
                val colorRes = resolveTimeColorRes(ts, config.expiry)
                views.setTextColor(R.id.widget_time, androidx.core.content.ContextCompat.getColor(context, colorRes))
            } else {
                views.setTextViewText(R.id.widget_time, "--")
                views.setTextColor(R.id.widget_time, androidx.core.content.ContextCompat.getColor(context, R.color.widgetSummaryText))
            }
        } else {
            views.setViewVisibility(R.id.widget_time, View.GONE)
        }
        views.setViewVisibility(R.id.error_message, View.GONE)
        ...
```

4. 检查 `showError()` 保持：
```kotlin
        views.setViewVisibility(R.id.widget_time, View.GONE)
```

- [ ] **Step 4: 运行单元测试验证通过**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "tech.lolli.toolbox.widget.CfWidgetParseTest"`
Expected: BUILD SUCCESSFUL & all tests pass

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/kotlin/tech/lolli/toolbox/widget/HomeWidget.kt android/app/src/test/kotlin/tech/lolli/toolbox/widget/CfWidgetParseTest.kt
git commit -m "fix(widget): restore widget_time visibility on MEDIUM, show data time and apply expiry colors"
```

---

### Task 5: 真机编译构建与端到端视觉验证

**Files:**
- Output APK: `build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 1: 编译 Debug APK 并安装到已连接的荣耀真机**

Run:
```bash
export MSYS_NO_PATHCONV=1
flutter build apk --debug
adb -s 192.0.2.17:42389 install -r build/app/outputs/flutter-apk/app-debug.apk
```
Expected: `Success`

- [ ] **Step 2: 发送广播触发桌面小组件刷新**

Run:
```bash
export MSYS_NO_PATHCONV=1
adb -s 192.0.2.17:42389 shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE -n tech.lolli.toolbox/.widget.StatusWidgetMedium
```

- [ ] **Step 3: 使用 adb 截屏与 UI dump 验证视觉表现**

Run:
```bash
export MSYS_NO_PATHCONV=1
adb -s 192.0.2.17:42389 shell uiautomator dump /sdcard/ui_verify.xml
adb -s 192.0.2.17:42389 pull /sdcard/ui_verify.xml "D:/adbtmp/ui_verify.xml"
```
验证检查点：
1. `D:/adbtmp/ui_verify.xml` 中出现 `tech.lolli.toolbox:id/widget_time` 节点。
2. 文本格式符合 `\d{2}:\d{2}`。
3. 名字与时间无重叠或挤压。

- [ ] **Step 4: 清理临时测试脚本与文件**

Run:
```bash
rm -rf D:/adbtmp/*.py D:/adbtmp/*.log
```

- [ ] **Step 5: 最终状态检查与文档更新**

Run:
```bash
git status --short
```
确保仅保留规范提交，无杂散未跟踪代码文件。
