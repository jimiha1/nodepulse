# 4x2 Android 桌面小组件视觉与布局重构设计文档

## 1. 概述与目标
重构 ServerBox 4x2（MEDIUM）桌面小组件的排版与视觉设计，解决原本留白太空、单指标展示利用率低、混合模式间距过大等问题：
1. **图表模式（CHART Mode）**：支持 1~4 个图表自由选择（1 全图、左右 2 列、或 2x2 网格 4 图表）。
2. **数值模式（READING Mode）**：升级为双列胶囊小卡片风格（2 列 x 3 行 = 6 项指标），增强信息密度与层次感。
3. **组合模式（COMBINED Mode）**：紧凑排布上部双图表（缩小间隙）+ 下部 4 个双列小胶囊卡片（2 列 x 2 行），消除冗余空白。
4. **性能与安全**：在 RemoteViews 限制与 Android Binder IPC 1MB 事务上限内完成高质量内存 Canvas 绘图与布局更新。

---

## 2. 界面排版详细设计

### 2.1 胶囊小卡片设计 (`widget_capsule_bg.xml`)
- 圆角矩形背景（corner: 6dp），深灰/浅黑半透明底色（`#1AFFFFFF` 或暗黑适配），增加轻微内边距（4dp 垂直，6dp 水平）。
- 内部布局：水平排列或上下两排：
  - `label`: 9sp 浅灰等宽标签（如 `CPU`, `RAM`, `DISK`）。
  - `value`: 11sp 粗体高亮主色文本（如 `6.4%`, `42%`, `↓520K`），右对齐或下对齐。

### 2.2 图表网格布局 (`home_widget.xml`)
- 将 `widget_charts_container` 扩展为 2 行结构：
  - `Row 1`: `widget_chart_1`, `widget_chart_2`
  - `Row 2`: `widget_chart_3`, `widget_chart_4`
- 根据配置动态控制显示：
  - 1 图表：`widget_chart_1` 占据全屏，`Row 2` 隐藏，`widget_chart_2` 隐藏。
  - 2 图表：`Row 1` 包含 `widget_chart_1` 和 `widget_chart_2`（左右平分，中间间距 4dp），`Row 2` 隐藏。
  - 3/4 图表：`Row 1` 与 `Row 2` 同时显示，分别展示 2 个图表（2x2 网格）。

### 2.3 数值网格布局 (`home_widget.xml`)
- 将 `widget_content` 重构为 3 行双列结构（共 6 个胶囊单元 `widget_cell_1` ~ `widget_cell_6`）：
  - 每行一个水平 `LinearLayout`，包含左右 2 个权重相等的胶囊卡片（中间间距 4dp，行间距 3dp）。
  - `READING` 模式：激活全部 3 行共 6 个单元。
  - `COMBINED` 模式：激活前 2 行共 4 个单元，隐藏第 3 行。

---

## 3. 数据与配置交互 (`WidgetConfig.kt` & `WidgetConfigureActivity.kt`)
- `WidgetConfig` 新增字段：
  - `chartCount: Int = 1`（图表模式可选 1, 2, 4）
  - `chart3: String = "disk"`
  - `chart4: String = "load"`
  - 字段上限常数：`CAP_MEDIUM_READING_FIELDS = 6`, `CAP_COMBINED_FIELDS = 4`。
- 配置界面交互调整：
  - 图表模式：新增「图表数量」选择项（1个、2个、4个），根据所选数量动态展示 Chart 1 ~ Chart 4 下拉选择器。
  - 数值模式：支持最多勾选 6 项指标。
  - 组合模式：支持最多勾选 4 项指标。

---

## 4. 渲染引擎调整 (`HomeWidget.kt` & `WidgetChart.kt`)
- `HomeWidget.kt` 中根据 `chartCount` 与图表区域宽高分别绘制 1、2、4 个小图表，计算精准的宽高像素以避免缩放拉伸失真。
- `WidgetChart.kt`：对微型图表（高度低于 80dp 时）自动隐去过多辅助标签或微调边距，保持走势线条清晰平滑。

---

## 5. 测试与验证
1. **JVM 单元测试**：针对 `WidgetConfig` 新增的 `chartCount`、`chart3`、`chart4` 及新上限编写解析与校验测试。
2. **真实设备渲染自测**：通过 Android ADB 命令更新小组件，在真机桌面验证 4x2 小组件在图表模式（1/2/4 图表）、数值模式（6 个胶囊卡片）以及组合模式（2 图表 + 4 胶囊卡片）下的视觉效果。
