# 关于页精简与「检查更新」重指向设计文档

## 1. 概述与背景

### 1.1 现状

关于页（`lib/view/page/setting/about.dart`，101 行）自上而下三块：

| 区块 | 内容 |
|---|---|
| 图标与版本号 | `UIs.appIcon` + `ServerBox\nv1719` |
| 四个按钮 | Wiki（`Urls.appWiki`）、反馈（`Urls.appHelp`）、许可证（`showLicensePage`）、赞助（`cdn.lollipopkit.com/donate`） |
| Markdown 卡片 | DB-IP 署名与 ipgeo-shards、贡献者/参与者名单、GPT Box、made with love |

「检查更新」的能力已存在，但都不在关于页：

- `lib/view/page/home.dart:252` — 启动时按 `autoCheckAppUpdate` 开关自动检查；
- `lib/view/page/setting/entries/app.dart:106` — 通用设置里的行（副标题显示状态 + 自动检查开关）。

两处都调用 fl_lib 的 `AppUpdateIface.doUpdate()`（`packages/fl_lib/lib/src/core/update.dart`），且都指向**上游仓库**的 Releases：`Urls.githubReleasesApi` = `api.github.com/repos/lollipopkit/flutter_server_box/releases`。

本 fork 的公开仓库 `jimiha1/cf_server_box`：公开、有 3 个 tag、**尚无任何 release**（`/releases` 返回空数组）。

### 1.2 目标与已确认的决策

（2026-10-06 与用户确认，三项均取推荐项）

1. **整页精简**：四个按钮与整块 Markdown 卡片全删（含 DB-IP 署名段）。
2. **检查源改指本 fork**：查 `jimiha1/cf_server_box` 的 GitHub Releases。
3. **两处既有检查一并改指**（首页启动自动检查、通用设置行）：不删除，也不保留上游指向。
4. 不引入新的更新检查实现——fl_lib 的 `AppUpdateIface` 已是完整机制（拉取、解析、Release notes、Toast/对话框）。

### 1.3 关键事实（决定了方案形态）

- **tag → build**：取 tag 中最后一段连续数字（`v1.0.1720` → 1720），发版 tag 末尾数字大于当前 build（1719）即被检出。
- **资产匹配**（Android）：文件名以 `.apk` 结尾且含架构记号（`arm64`/`aarch64`、`x86_64`/`amd64`）。
- **`storeUrl` 只在 iOS 生效**：`_fetchAppStoreBuild` 对非 iOS 直接返回 null；本仓库只构建 Android（平台目录仅存 `android/`），两处调用去掉该参数。
- **当前 0 release 是合法状态**：检查正常完成、安静返回「无更新」，不报错、不弹窗。

---

## 2. 关于页设计

### 2.1 页面结构

```
┌──────────────────────────────────┐
│            [ 图标 47×47 ]          │
│             ServerBox             │
│               v1719               │
│  ┌────────────────────────────┐  │
│  │ ⟳  检查更新                  │  │
│  │    当前：v1.0.1719，点击检查更新 │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

- 保留：`SafeArea` + `ListView(padding: 13)` 骨架、图标、`ServerBox\nv${BuildData.build}` 版本号文字。
- 新增：一张卡（`.cardx`）内的检查行，`Icons.update` + `libL10n.checkUpdate`，与通用设置同一构造。
- 删除：四个按钮、`_sponsorUrl` 常量、Markdown 卡片。
- 无新增文案：复用 fl_lib 既有词条 `checkUpdate` / `versionHasUpdate` / `versionUpdated` / `versionUnknownUpdate`。

### 2.2 检查行的三态与点击

副标题由 `AppUpdateIface.newestBuild`（`ValueNotifier<int?>`）驱动：

| `newestBuild` | 副标题（fl_lib 既有文案） |
|---|---|
| null（未检查/检查失败） | 当前：v1.0.1719，点击检查更新 |
| > 当前 build | 找到新版本：v1.0.1720, 点击更新 |
| ≤ 当前 build | 当前：v1.0.1719, 已是最新版本 |

点击 → `Fns.throttle` 节流 → `AppUpdateIface.doUpdate(build, githubReleasesUrl: Urls.githubReleasesApi, force: BuildMode.isDebug)`。后续流程全归 fl_lib：GitHub 源不设 min/urgent，命中新版本时按 normal 级弹 Toast（10 秒，带「更新」动作），点动作开更新对话框（含 Release notes 与下载链接）。

不自动检查：页面打开本身不发请求，检查只由点击触发（自动检查由首页启动那处按开关负责）。检查失败沿用 fl_lib 的静默处理（记日志、副标题保持原状），与通用设置行一致。

### 2.3 共享构造与页面降级

- 检查行定义一次（`_checkUpdateTile(BuildContext, {Widget? trailing})`，放在 `about.dart`——它与 `entries/app.dart` 同属 `entry.dart` 的 part，函数可直接互见），关于页与通用设置行共用；后者以 `trailing: StoreSwitch(autoCheckAppUpdate)` 保留其开关，行为不变。两处读同一个 notifier、同一组三态，复制一份就是多一处要同步维护的地方。
- 页面由 `StatefulWidget` + `AutomaticKeepAliveClientMixin` 降为 `StatelessWidget`：keep-alive 是旧 Tab 结构的遗留（设置页现在是 level/`PageView` 体系，其余叶子页均无此 mixin），本页也没有需要保活的状态。

---

## 3. 检查源重指向（`lib/data/res/url.dart`）

| 常量 | 现在 | 改为 |
|---|---|---|
| `myGithub` | `https://github.com/lollipopkit` | `https://github.com/jimiha1` |
| `githubApi` | `https://api.github.com/repos/lollipopkit` | `https://api.github.com/repos/jimiha1` |
| `thisRepo` | `$myGithub/flutter_server_box` | `$myGithub/cf_server_box` |
| `githubReleasesApi` | `$githubApi/flutter_server_box/releases` | `$githubApi/cf_server_box/releases` |

**删除的常量及依据**：

- `appWiki`、`appHelp` — 唯一使用者是被删的两个按钮。
- `appStore` — 唯一使用者是两处检查调用的 `storeUrl`；本仓库无 iOS 发布，删除后 iOS 分支退化为「无更新路径」，与「不发布 iOS」一致。
- `geoData`、`geoDataFallback`、`geoDataRepo` — 城市级 IP 归属地功能已随裁剪移除（`IpGeo` 类与下载逻辑均不存在），三个常量已无活引用；最后一个引用者正是本次删除的卡片（`geoDataRepo` 出现在 Markdown 里）。注意其中 `ipgeo-shards` 是上游的仓库，不随 fork 改名，故不能靠改 `myGithub` 了事——只能随引用一起删。

**保持不动**：

- `rawRepo` / `themeCatalog` — 主题目录的数据文件地址（上游仓库里的一个文件），与「本应用的仓库身份」无关，主题功能仍在使用。
- `site` / `docs` / `privacyPolicy` / `monitorAgentDoc` 等 — 文档链接，仍可用。

**调用点改动**（两处）：`home.dart`、`entries/app.dart` 去掉 `storeUrl: Urls.appStore`。

**连带效果**：`Urls.newIssue`（崩溃报告对话框的跳转目标，`crash_report_dialog.dart:62`）随 `thisRepo` 一起改指 fork——崩溃报告应报到本仓库。

---

## 4. 关联清理

- **删 `lib/data/res/github_id.dart`**（贡献者/参与者名单）：唯一使用者是被删的 Markdown 卡片；同时删 `entry.dart` 里对应的 import。
- **`dist_license.dart` 保留**：`registerDistMarkLicenses()` 的注册调用不动，仅更新其文档注释（原注释指向「Settings → About → License」，该入口已不存在）。
- **ARB 词条不删**：`menuWiki`、`feedback`、`license`、`sponsor` 等词条留着（删词条要重跑 `gen-l10n` 且收益为零）。

### 4.1 合规说明（如实记录，不阻塞本设计）

- 删除「许可证」按钮后，Flutter 的 `showLicensePage`（第三方包许可证 + 发行版商标声明）在 App 内不再有入口。
- 四个发行版商标（Debian / Gentoo / NixOS / Alpine）仍显示在服务器卡片上；其中三个的 CC 许可要求署名。声明仍随包体分发（`assets/distro/README.md`，整目录打包），但不再有渲染出口。
- DB-IP：城市级 IP 数据已不下载、不内置，署名义务随之消失；卡片上那行是本仓库最后的残留引用。
- 若希望彻底消除商标署名义务，可另做一次改动：移除四个内置商标（卡片回落为通用 Linux 图标）。**本设计不含此项。**

---

## 5. 发版须知（让检查真正能命中）

- 打 tag：`v1.0.<build>`，末尾数字必须大于已安装 build（当前 1719）。
- 发布为 Release（draft 会被忽略）；上传 APK，文件名含架构记号（arm64 设备需 `arm64`/`aarch64`，x86_64 设备需 `x86_64`/`amd64`）。
- 勾选 prerelease 的版本只在开启「预发布更新」（`betaTest`）的设备上可见。
- 已有 tag（`v1.0.0` 等）解析出的 build 是 0，不会造成误报。
- 首个 Release 发布后，「找到新版本」路径即可在真机自然验证；在那之前真机验证的是「无 release」分支。

---

## 6. 测试与验证

- **新增 `test/unit/app/urls_test.dart`**（钉住决策，防上游合并把地址改回去）：
  - `Urls.githubReleasesApi` == `https://api.github.com/repos/jimiha1/cf_server_box/releases`；
  - `Urls.newIssue` == `https://github.com/jimiha1/cf_server_box/issues/new`。
- **不新增 widget 测试**：页面是私有类；行为是 fl_lib 既有路径的薄封装，机制本身已由 fl_lib 的 `update_test.dart` / `update_iface_test.dart` 覆盖。
- `make analyze` 通过；`make test-one TEST=test/unit/app/urls_test.dart` 通过。
- **实机**（BKQ-AN10，热重载）：长按首页概览卡 → 设置 → 关于：
  1. 显示图标与 `ServerBox v1719`；
  2. 检查行副标题为「当前：v1.0.1719，点击检查更新」；
  3. 点击检查：无崩溃、无异常弹窗，logcat 走「无 release」分支，副标题保持原状；
  4. 四个按钮与 Markdown 卡片不再存在。

---

## 7. 影响面与不做的事

**改动文件**：

- `lib/view/page/setting/about.dart` — 页面重写（删按钮与卡片、加检查行、降为 StatelessWidget、定义共享的检查行构造）
- `lib/view/page/setting/entries/app.dart` — 复用共享构造（行为不变）
- `lib/view/page/setting/entry.dart` — 删 `github_id.dart` import
- `lib/data/res/github_id.dart` — 删除
- `lib/data/res/url.dart` — 重指向 + 删死常量
- `lib/view/page/home.dart` — 去掉 `storeUrl`
- `lib/data/model/server/dist_license.dart` — 注释更新
- `test/unit/app/urls_test.dart` — 新增

**明确不做**：

- 不创建 Release（是否发版、何时发版是用户决定）。
- 不清理 globe 遗留（`assets/geo/`、`shaders/globe.frag`、`globeEnabled` 等设置键）——另一次精简的范畴。
- 不改上游文档链接（`Urls.site` / `docs`）与隐私政策链接。
- 不删 ARB 词条。
- 不改版本号显示格式（顶部仍是 `v1719`；检查行副标题沿用 fl_lib 的 `v1.0.<build>` 文案）。
- 不改首页自动检查与通用设置行的其余行为（开关、搜索关键词等）。
