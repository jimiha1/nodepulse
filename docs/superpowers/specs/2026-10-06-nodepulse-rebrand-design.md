# NodePulse：应用改名与图标重设计

**日期**：2026-10-06
**状态**：待执行

## 1. 背景与目标

这个仓库最初是 ServerBox 的 fork，经裁剪后只剩 CF-Server-Monitor 客户端与 Android 桌面小组件。它现在与上游 `flutter_server_box` 已基本无关，却仍叫 ServerBox、沿用上游的灰色机架图标与 `tech.lolli.toolbox` 包名。

本次把它当作一个全新应用重新命名与标识。

**目标**：应用在用户能看到的每一处都叫 NodePulse，用新图标，包名独立，与上游彻底切断标识层面的关系。

**非目标**：不改功能代码的行为；不迁移旧安装数据；不重写 git 历史；不发 Release。

## 2. 已确认的决策

| 项 | 决定 |
|---|---|
| 应用名 | **NodePulse** |
| 图标 | 心跳线（ECG 波形）+ 深海军蓝 `#1A3D5C` + 白色波形 |
| applicationId / namespace | `app.nodepulse` |
| Kotlin 包路径 | `tech.lolli.toolbox` → `app.nodepulse` |
| Dart 包名 | `server_box` → `nodepulse` |
| 版本号 | **不重置**，对齐为 `1.0.1799+1799`（见 §4.5） |
| GitHub 仓库名 | `cf_server_box` → `nodepulse` |

**选择「彻底换包名」的既定代价**：新包名在系统里是一个不同的应用。旧安装不能覆盖升级，站点配置、登录凭据、告警规则、已添加的桌面小组件都不会跟过来，需要重新配置。这是本设计接受的取舍，不是缺陷。

### 2.1 图标设计

- **形状**：一条 ECG 心跳线，从左侧起笔，中间一个尖峰，右侧收笔。占满图标宽度，粗线条、圆角端点。
- **配色**：底色 `#1A3D5C`（深海军蓝），波形纯白 `#FFFFFF`。
- **安全区**：波形控制在中心 66% 区域内，Android 启动器按圆形/方圆形裁剪后仍完整（见 `.tmpshot/icon-preview/color.html` 的遮罩预览）。
- **为什么是心跳线**：`Pulse` 的字面含义，且波形在小尺寸下比同心圆、弧线等方案更抗糊。

图标**不跟随应用主题色**。应用主题色是用户可改的（含主题商店，默认暗红 `#480F0F`），而图标一旦定下就是固定的品牌标识，不该随主题变化。

## 3. 现状：身份标识的分布

改动前逐项核实过的事实（这些数字是设计范围的依据）：

| 类别 | 位置 | 规模 |
|---|---|---|
| 显示名 | `pubspec.yaml` 的 `fl_build.appName` | 1 处（生成 `BuildData.name`，Dart 侧 7 处使用） |
| 显示名 | `android/.../res/values/strings.xml` 的 `app_name` | 1 处（`translatable="false"`，不需逐语言） |
| 小组件文案 | 15 个语言的 `strings.xml` 里内嵌的 "ServerBox" | 30 处（每语言 2 条：`widget_configure_empty`、`widget_err_no_token`，均为活文案） |
| ARB 文案 | `lib/l10n/app_*.arb` 的 12 处 "ServerBox" | **仅 2 处仍被使用**（`crashCollectIntro`、`crashLastRunFailed`）；其余 10 处属已裁剪功能（agent、share、live activity 等），是死词条 |
| Dart 包名 | `package:server_box/` 前缀 | 104 个文件（lib 48 / test 54 / integration 2） |
| Kotlin 包名 | `android/app/src/main/kotlin/tech/lolli/toolbox/**` | 17 个主源文件 + 10 个测试文件 |
| 广播 action | `AndroidManifest.xml` 的 `tech.lolli.toolbox.UPDATE_WIDGET` | 2 处 |
| 小组件配置入口 | `res/xml/widget_small.xml`、`widget_medium.xml` | 2 处 |
| deeplink | `AppLink.scheme`（Dart）+ `LINK_SCHEME`（Kotlin）+ Manifest | 3 处 |
| UA 字符串 | `ServerBox-Alert/1`（2 处）、`ServerBox-Widget/2`、`ServerBox-DoH/1` | 4 处 |
| 图标 | `assets/app_icon.png` + 5 组密度 × 4 变体 = 20 个 PNG，另加 2 个背景色 XML | 23 个文件 |
| CI 注释 | `.github/workflows/build.yml` 提到 `ServerBox` | 3 处（注释，非功能） |
| README | 标题 `CF ServerBox` | 2 个文件（README.md / README_zh.md） |

**ARB 死词条的处置**：本次**只改**仍在使用的 2 个键，其余 10 处不动。理由：它们属于已删除的功能，改它们的文案等于为一个不存在的东西做本地化；而删掉它们需要重跑 `gen-l10n` 并逐语言核对，收益为零。**这一条是明确的取舍，记录在此**。

## 4. 设计

### 4.1 图标生成（新增 `scripts/gen_app_icon.py`）

沿用仓库既有做法：`scripts/gen_tray_icons.py` 就是一个手写的 PNG/PDF 编码器，不依赖任何绘图工具（本机也没有 ImageMagick/Inkscape）。新脚本同样手写 PNG 编码（zlib + struct），把图标画成**代码**而不是塞一个来路不明的二进制：

- 输出 `assets/app_icon.png`（512×512 RGBA）
- 输出 5 组密度的 `ic_launcher.png`、`ic_launcher_round.png`、`ic_launcher_foreground.png`、`ic_launcher_monochrome.png`（共 20 个 PNG）
- 自适应图标的 foreground 按 Android 规范留出安全区（内容限制在中心 66%），background 为纯色
- 同时改写 `values/ic_launcher_background.xml`（现为 `#FFFFFF`）与 `values-night/ic_launcher_background.xml`（现为 `#372D2D`）为同一底色 `#1A3D5C` —— 两个文件都要改，否则深色模式下背景仍是旧的暖灰

脚本可重跑、可审阅、可 diff —— 这与仓库「assets 是产物、生成器入库」的既有约定一致。

### 4.2 显示名与文案

- `pubspec.yaml`：`fl_build.appName: ServerBox` → `NodePulse`
- `res/values/strings.xml`：`app_name` → `NodePulse`
- 15 个语言的 `strings.xml`：`widget_configure_empty`、`widget_err_no_token` 句中的 "ServerBox" → "NodePulse"（各语言的句子结构不动，只换词）
- ARB：`crashCollectIntro`、`crashLastRunFailed` 两个键的 16 个语言文件中，把 "ServerBox" 换成 "NodePulse"

### 4.3 包名迁移

- `android/app/build.gradle`：`namespace` 与 `applicationId` → `app.nodepulse`
- 目录移动：`android/app/src/main/kotlin/tech/lolli/toolbox/` → `android/app/src/main/kotlin/app/nodepulse/`（测试目录同理）
- 27 个 `.kt` 文件：`package tech.lolli.toolbox...` → `package app.nodepulse...`，以及所有 `import tech.lolli.toolbox...` → `import app.nodepulse...`
- `AndroidManifest.xml`：两处 `tech.lolli.toolbox.UPDATE_WIDGET` → `app.nodepulse.UPDATE_WIDGET`
- `res/xml/widget_small.xml`、`widget_medium.xml`：`android:configure` 全限定类名

**这是风险最高的一步**：`flutter analyze` 不编译 Kotlin，遗漏的 import 不会被它发现。验证必须是 `flutter build apk`（真正调用 Gradle/Kotlin 编译器）。

### 4.4 Dart 包名

- `pubspec.yaml`：`name: server_box` → `name: nodepulse`
- 104 个文件的 `package:server_box/` → `package:nodepulse/`（纯机械替换）
- 生成的 `lib/hive_registrar.g.dart` 含该前缀，但它是生成物 —— 改完源码后按仓库约定重跑生成，不手改

### 4.5 其余标识

- deeplink scheme：`serverbox` → `nodepulse`（Dart `AppLink.scheme`、Kotlin `LINK_SCHEME`、Manifest `<data android:scheme>`）
- UA：`ServerBox-Alert/1` → `NodePulse-Alert/1`（2 处）、`ServerBox-Widget/2` → `NodePulse-Widget/2`、`ServerBox-DoH/1` → `NodePulse-DoH/1`
- README 标题
- CI 注释（3 处，非功能）
- GitHub 仓库改名（`gh repo rename`，GitHub 自动重定向旧地址）；本地 remote URL 跟着更新

#### 版本号：不重置，对齐提交数

**这一条推翻了本设计初稿的决定，理由是初稿基于错误前提。** 初稿打算重置为 `1.0.0+1`，前提是版本号由 pubspec 决定。实际不是：

- `BuildData.build` 由 `fl_build` 从 **git 提交数**生成（`git rev-list --count HEAD`，见 `packages/fl_build/lib/utils.dart` 的 `_commitCount`），不是 pubspec 的 version。当前提交数 1799，而 `build_data.dart` 里还是 1719 —— 那个值已经过期。
- `.github/workflows/build.yml` 有一条硬校验：`GITHUB_REF_NAME` 必须等于 `v1.0.${build_data}`，且 `pubspec` 的 version 必须等于 `1.0.${build_data}+${build_data}`。三者严格绑定，CI 发布时不一致即失败。
- `AppUpdate` 用 `newest > BuildData.build` 判断是否有新版。build 号若倒退回 1，任何旧版本号都会大于它，更新检查将永远误报。

所以 build 号**无法人为重置**（它由仓库的提交数实时决定），强行重置还会破坏 CI 与更新检查。

**决定**：pubspec 的 `version:` 对齐为 `1.0.1799+1799`，与 `BuildData.build` 和未来的 tag 一致；不改 CI、不改 fl_build。构建号继续随提交数单调递增。用户看到的是应用名与图标，不是这个数字。

`lib/data/res/build_data.dart` 是生成物（`fl_build` 写出），按仓库约定不手改 —— 本次由 `dart run fl_build` 重新生成，`name` 字段随之变成 `NodePulse`。

### 4.6 明确不做

- **不迁移旧数据**（见 §2 的取舍说明）
- 不动 `Urls.rawRepo` / `themeCatalog`（上游主题目录，与本应用身份无关）
- 不改 `assets/distro/`、`assets/geo/` 等资源
- 不重写 git 历史（旧提交里的 "ServerBox" 字样保留）
- 不发 Release、不推送（除非另行交代）
- 不删 ARB 死词条（见 §3 的取舍说明）

## 5. 执行顺序

分 6 个任务，每个一次提交、可独立回滚：

1. **图标生成脚本 + 图标资源** —— 新增脚本，产出全部 PNG，替换现有图标
2. **显示名与文案** —— `appName`、`app_name`、15 个语言的 strings、2 个 ARB 键
3. **包名与目录迁移** —— Gradle、目录移动、27 个 Kotlin 文件、Manifest、widget xml
4. **Dart 包名** —— `pubspec.yaml` + 104 个文件 + 重跑生成
5. **scheme / UA / 版本对齐 / README / 仓库改名**
6. **全量验证与真机**

## 6. 验证

1. `flutter analyze lib test` 干净
2. `flutter test test/unit/` 全绿（基线：427 通过、1 跳过）
3. **`flutter build apk --debug` 成功** —— 这一步才真正编译 Kotlin，是任务 3 的唯一硬验证
4. 真机（BKQ-AN10）：
   - 应用列表与设置里显示 **NodePulse**
   - 图标是新的心跳线图标（含圆形遮罩下的裁剪正确性）
   - 通知来自新应用名
   - 桌面小组件仍可添加、可配置、可刷新
   - 旧版 ServerBox 与新 NodePulse **并存**（包名不同，预期行为）
   - 深链 `nodepulse://` 能打开应用
5. `grep` 复核：`lib/`、`android/` 下不再有 `tech.lolli.toolbox`、`package:server_box/`、`serverbox://` 的活引用

## 7. 风险

| 风险 | 应对 |
|---|---|
| Kotlin 包迁移遗漏导致编译失败 | 任务 3 的验证必须是 `flutter build apk`，不能只看 analyze |
| 104 个文件的 import 替换出错 | 机械替换 + `flutter analyze` 全量校验 + 单测 |
| 换包名后旧用户数据丢失 | 已确认接受（§2）；文档与提交信息中如实说明 |
| 版本号未重置，看起来像继承自旧项目 | 已确认接受（§4.5）；它是内部构建号，用户看到的是应用名与图标 |
| 图标在圆形遮罩下被裁 | 已在 `color.html` 中验证安全区，脚本按同一几何生成 |
| 生成脚本手写 PNG 编码出错 | 输出后用 Flutter 实际加载验证（真机截图） |
