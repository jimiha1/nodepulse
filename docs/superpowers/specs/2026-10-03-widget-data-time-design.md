# 4x2 Android 桌面小组件数据时间与过期变色设计文档

## 1. 概述与背景

### 1.1 现状与问题
当前 ServerBox 的 Android 桌面小组件在 4x2（MEDIUM）尺寸下，表头右侧存在刷新按钮，左侧为服务器名称。布局文件 `home_widget.xml` 中原本设计了 `widget_time`（TextView），用于显示当前时间，但存在以下严重问题：

1. **单向不可逆隐藏 Bug**：
   在 `HomeWidget.kt` 中，`showError()` 方法将 `widget_time` 设置为 `View.GONE`。然而在 `showData()` 和 `showLoading()` 中，仅调用了 `views.setTextViewText(R.id.widget_time, ...)`，未将其重新设置为 `View.VISIBLE`。
   由于每个小组件添加到桌面后必须经过初次未配置的错误状态（`server == null`），导致所有小组件的 `widget_time` 被永久置为 `GONE`，用户在屏幕上完全看不到时间。

2. **时间语义错误**：
   即使显示出来，原代码使用的也是 `java.util.Date()`（设备当前系统时间），代表「本次渲染的时刻」，无法反映服务端监控数据的真实采集时间。在服务器断网或长时间未上报时，极具误导性。

3. **刷新机制与新鲜度矛盾**：
   在 Android / 荣耀等设备上，`AppWidgetProvider` 的系统定期更新广播（`updatePeriodMillis`）被操作系统严格限制为最小 30 分钟（`1800000ms`）。若将过期变色阈值写死为较短时间（如 5 分钟），小组件在大部分生命周期中都会处于警告色状态，失去提示价值。

### 1.2 目标
1. 修复 `widget_time` 的可见性恢复逻辑。
2. 限制作用范围：**仅对 4x2（MEDIUM）小组件启用数据时间与变色**，2x2（SMALL）保持现状（隐藏时间，节省紧凑空间）。
3. 解析服务端上报的真实时间戳 `last_updated`，以 `HH:mm` 紧凑等宽文本格式显示数据时刻。
4. **过期时间支持独立配置**：在 4x2 小组件配置页增加过期阈值单选组（10分钟 / 30分钟(默认) / 1小时 / 2小时 / 不变色）。
5. 按照设定的阈值联动颜色渐变：新鲜（常规灰色）→ 偏旧（琥珀金）→ 过期（告警红），符合 WCAG AA 对比度标准。

---

## 2. 界面与交互详细设计

### 2.1 4x2 表头布局表现 (`home_widget.xml`)
沿用现有 `home_widget.xml` 表头结构，不破坏原有布局层级：
```xml
<LinearLayout
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:gravity="center_vertical"
    android:orientation="horizontal">

    <TextView
        android:id="@+id/widget_name"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:ellipsize="end"
        android:singleLine="true"
        android:textColor="@color/widgetText"
        android:textSize="14sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/widget_time"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="4dp"
        android:fontFamily="monospace"
        android:textColor="@color/widgetSummaryText"
        android:textSize="11sp" />

    <ImageView
        android:id="@+id/widget_refresh"
        android:layout_width="24dp"
        android:layout_height="24dp"
        android:layout_marginStart="4dp"
        android:padding="4dp"
        android:src="@drawable/refresh_24" />
</LinearLayout>
```

### 2.2 视觉与颜色标准
文字格式恒定为 `HH:mm`（24小时制，设备本地时区）。当 `last_updated` 缺失或非正数时，显示 `--`。

颜色定义遵循深浅模式适配，并达到 WCAG AA 对比度（≥ 4.5:1）：
| 状态定义 | 浅色模式颜色 | 深色模式颜色 | 白底对比度 | 黑底对比度 |
|---|---|---|---|---|
| **新鲜 (Fresh)** | `@color/widgetSummaryText` (`#333333`) | `@color/widgetSummaryText` (`#BBBBBB`) | 12.6:1 | 9.2:1 |
| **偏旧 (Aging)** | `@color/widgetTimeAging` (`#B45309`) | `@color/widgetTimeAging` (`#FFB340`) | 5.12:1 | 11.4:1 |
| **过期 (Stale)** | `@color/widgetTimeStale` (`#DC2626`) | `@color/widgetTimeStale` (`#FF453A`) | 4.89:1 | 5.3:1 |

### 2.3 小组件配置界面 (`widget_configure.xml`)
在 `WidgetConfigureActivity` 中，为 MEDIUM 模式小组件新增「数据过期时间（变色提示）」单选区域：
- 控件位置：放置于「展示模式」或「图表/字段配置」下方。
- 控件形态：垂直排列的 `RadioGroup`，包含 5 个 `RadioButton`：
  - `10 分钟` (`10m`)
  - `30 分钟 (默认)` (`30m`)
  - `1 小时` (`1h`)
  - `2 小时` (`2h`)
  - `不变色` (`never`)
- 仅当 `kind == WidgetKind.MEDIUM` 时显示该配置容器；`kind == WidgetKind.SMALL` 时设置 `View.GONE`。

---

## 3. 数据层与业务逻辑设计

### 3.1 数据解析 (`WidgetApi.kt`)
1. 修改 `Reading` 数据类，增加时间戳字段：
   ```kotlin
   data class Reading(
       val name: String,
       val cpu: Double?,
       ...
       val lastUpdated: Long? = null, // epoch 毫秒
   )
   ```
2. 在 `parseCfMetrics()` 中解析：
   ```kotlin
   val lastUpdatedRaw = o.optLong("last_updated", 0L)
   val lastUpdated = if (lastUpdatedRaw > 0) lastUpdatedRaw else null
   ```

### 3.2 配置持久化 (`WidgetConfig.kt`)
1. 新增过期档位枚举：
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
2. 在 `WidgetConfig` 增加属性 `expiry: WidgetExpiry = WidgetExpiry.DEFAULT`。
3. `loadFromPrefs()` 和 `saveToPrefs()` 增加 `widget_{id}_expiry` 键值的存取逻辑。

### 3.3 变色判定算法与生命周期 (`HomeWidget.kt`)
在 `showData()` 中按尺寸分支：

```kotlin
if (kind == WidgetKind.MEDIUM) {
    views.setViewVisibility(R.id.widget_time, View.VISIBLE)
    val ts = reading.lastUpdated
    if (ts != null && ts > 0) {
        val date = java.util.Date(ts)
        val timeStr = android.text.format.DateFormat.format("HH:mm", date).toString()
        views.setTextViewText(R.id.widget_time, timeStr)

        val colorRes = resolveTimeColor(context, ts, config.expiry)
        views.setTextColor(R.id.widget_time, androidx.core.content.ContextCompat.getColor(context, colorRes))
    } else {
        views.setTextViewText(R.id.widget_time, "--")
        views.setTextColor(R.id.widget_time, androidx.core.content.ContextCompat.getColor(context, R.color.widgetSummaryText))
    }
} else {
    // 2x2 (SMALL) 不显示时间
    views.setViewVisibility(R.id.widget_time, View.GONE)
}
```

变色逻辑 `resolveTimeColor(context, lastUpdated, expiry)`：
- 若 `expiry == WidgetExpiry.NEVER`，直接返回 `R.color.widgetSummaryText`。
- 计算数据年龄：`val ageMs = System.currentTimeMillis() - lastUpdated`。
- 设基础时间阈值 `T = expiry.minutes * 60 * 1000L`：
  - `ageMs <= T`：返回 `R.color.widgetSummaryText`（新鲜）。
  - `T < ageMs <= 4 * T`：返回 `R.color.widgetTimeAging`（偏旧）。
  - `ageMs > 4 * T`：返回 `R.color.widgetTimeStale`（过期）。

`showLoading()` 与 `showError()` 相应规范：
- `showLoading()`：对 MEDIUM 设置 `widget_time` 为 `View.VISIBLE` 并赋 `"…"`，对 SMALL 设置 `View.GONE`。
- `showError()`：统一将 `widget_time` 设为 `View.GONE`。

---

## 4. 资源变更清册

### 4.1 颜色资源 (`res/values/colors.xml` & `res/values-night/colors.xml`)
- `colors.xml` (浅色模式):
  - `<color name="widgetTimeAging">#B45309</color>` (琥珀)
  - `<color name="widgetTimeStale">#DC2626</color>` (深红)
- `colors-night.xml` (深色模式):
  - `<color name="widgetTimeAging">#FFB340</color>` (亮琥珀)
  - `<color name="widgetTimeStale">#FF453A</color>` (亮红)

### 4.2 字符串资源 (`res/values/strings.xml` & `res/values-zh-rCN/strings.xml`)
- `strings.xml`:
  - `<string name="widget_expiry_title">Data Expiry Threshold</string>`
  - `<string name="widget_expiry_10m">10 minutes</string>`
  - `<string name="widget_expiry_30m">30 minutes (Default)</string>`
  - `<string name="widget_expiry_1h">1 hour</string>`
  - `<string name="widget_expiry_2h">2 hours</string>`
  - `<string name="widget_expiry_never">Disabled</string>`
- `values-zh-rCN/strings.xml`:
  - `<string name="widget_expiry_title">数据过期变色</string>`
  - `<string name="widget_expiry_10m">10 分钟</string>`
  - `<string name="widget_expiry_30m">30 分钟 (默认)</string>`
  - `<string name="widget_expiry_1h">1 小时</string>`
  - `<string name="widget_expiry_2h">2 小时</string>`
  - `<string name="widget_expiry_never">不提示变色</string>`

---

## 5. 测试与验证方案

1. **单元测试 (`CfWidgetParseTest.kt`)**：
   - 验证 `parseCfMetrics()` 能正确从 json 中提取 `last_updated` 毫秒时间戳。
   - 验证缺失 `last_updated` 时能够容错 fallback 为 `null`。
   - 验证变色判断函数在各阈值区间（`<T`, `T~4T`, `>4T`, `NEVER`）返回对应的 ColorRes。
   - 验证 `WidgetConfig` 对 `expiry` 字段的持久化与读取。

2. **端到端真机验证**：
   - 在已连接的 Android 荣耀设备（TEST-DEVICE）上编译并安装 debug APK。
   - 观察 4x2 小组件表头正确呈现 `14:20` 等宽时间文本，无遮挡。
   - 进入小组件配置界面，验证 4x2 能正常切换过期档位并生效保存；2x2 配置界面不显示该选项。
   - 验证 2x2 小组件表头无时间文本，尺寸紧凑整洁。
