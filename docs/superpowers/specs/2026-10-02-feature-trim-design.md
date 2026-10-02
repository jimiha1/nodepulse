# ServerBox 裁剪设计 v2：CF-Server-Monitor 的 Android 客户端 + 小组件

日期：2026-10-02
状态：已经用户逐节确认（v1 为"保留自采通道的裁剪"，数据源确认为 CF-Server-Monitor 后整体修订为 v2）

## 背景与目标

本仓库是 ServerBox（Flutter + Rust workspace monorepo）。用户要一个个人使用的硬裁剪 fork，
只保留两个功能：**服务器状态查询** 和 **桌面小组件**。查询内容与用户部署的
https://monitor.example.com/ 一致 —— 该站点经访问确认是 **CF-Server-Monitor**
（https://github.com/huilang-me/CF-Server-Monitor ，Junimo 主题，站点已设为公开），
**不是** 本仓库的 `monitor/` 面板。

因此裁剪后的 app 定位是：**CF-Server-Monitor 的 Android 客户端 + 桌面小组件**。
app 不再自采任何数据，直接读该站 Cloudflare Worker 的公开 API，与网站同一份数据库。

## 已确认的需求决策

1. **硬裁剪**：直接删除不要的功能代码及依赖，不做隐藏开关。接受上游同步困难的代价。
2. **仅 Android**：删除 ios/、macos/、linux/、windows/ 四个平台目录。
3. **数据源 = CF Worker 公开 API**（推翻 v1 的"SSH + monitor 双通道保留"）：
   `GET /api/servers`、`GET /api/server`、`GET /api/history/all`，实时走 `WS /api/ws`。
   公开站点读接口免鉴权。SSH 通道（dartssh2、密钥管理、Spi 模型）与 monitor agent
   HTTP 通道全部删除。
4. **详情页内容对齐 CF 详情页**（推翻 v1 的"保留进程/Docker/服务只读列表"）：
   CF agent 只上报进程数，无列表数据源，三个列表整体删除。
5. **推送告警删除**（推翻 v1 的"推送告警保留"）：原功能是 monitor agent 通知渠道
   管理界面（`lib/data/model/server/monitor_push.dart`，`/api/v1/push`），CF 没有对应物；
   CF 的告警（离线/资源阈值）在其自身管理面板配置，app 不涉及。
6. **公开与账号密码两种访问方式都支持**：公开站点免鉴权直读；私有站点走登录流程 ——
   `POST /admin/api`（`{"action":"login","username":...,"password":...}`）换 JWT
   （HS256，7 天有效，无刷新端点）。REST 读带 `Authorization: Bearer`，WS 带 `token`
   查询参数。**"永久会话"体验**：JWT 有效期是 Worker 签发策略、app 端无法延长，因此
   凭据存 Android Keystore（flutter_secure_storage，需从 dev_dependencies 移入
   dependencies），token 临近过期或收到 401 时用存储凭据**静默重登录**换新 token ——
   用户只输入一次密码；仅当服务器侧密码变更时才提示重新输入。
7. **流量告警与续费提醒（app 本地通知）**：Android 原生周期任务（WorkManager，≥15 分钟）
   拉 `/api/servers` 检查 —— 流量用量超过设定比例（默认 90%，可配）或距到期 ≤ 设定天数
   （默认 7 天，可配）时发本地通知。去重：同一节点同一档阈值只通知一次（跨档升级再通知）；
   续费提醒每天至多一次。选择 app 本地通知而非 CF 自带 cron 告警：不依赖 CF 功能、
   公开/私有站点都可用、通知行为受 app 控制。
8. **小组件显示内容可自定义**：2x2 读数组件的显示字段可选（CPU、内存、磁盘、负载、
   上下行速率、累计流量、剩余流量、TCP/UDP 连接数、三网延迟、在线时长、到期时间的子集，
   行数上限由布局决定）；4x2 组件的**显示模式可选（图表 / 读数 / 组合）** ——
   图表模式选 CF 历史数据的 8 种指标之一；读数模式选字段子集（与 2x2 同一字段池，
   行数上限更大）；组合模式上方两列并排两个小图表（各选 1 个指标，如 CPU + 内存）、
   下方为读数行（选字段子集）。默认值保持现状（2x2 读数、4x2 图表）。

## 参考内容：CF 面板实际显示（已从线上页面完整抓取）

**列表页**：
- 总览卡：在线节点数（x/y）、实时带宽（↑↓ 汇总）、开机以来总流量
- 节点卡片：地区旗帜、名称、分组、系统图标、V4/V6、CPU%（核数）、内存%（已用/总量）、
  磁盘%（已用/总量）、负载、实时↑↓速率、累计出站/入站流量、**流量阈值（剩余额度）**、
  TCP 连接数、UDP 连接数、**三网延迟与丢包（电信/联通/移动）**、在线时长、
  **到期时间/续费价格**

**详情页**：
- 信息卡：系统状态、架构、显卡（GPU）、操作系统版本、内存/Swap、磁盘、负载 1/5/15、
  运行时长、实时网络、最近更新时间、总流量、流量阈值
- 图表（时间范围：实时/30 分钟/1/6 小时/1/2/7 天）：CPU 使用率、内存+Swap、磁盘已用、
  网络（速率+累计）、系统负载、磁盘 IO（读/写）、连接数（TCP/UDP）、进程数（仅数量）
- Ping 图表：三网延迟历史 + 丢包历史

**CF 没有**：进程列表、Docker、服务列表、SMART、传感器、电池。

## 目标形态

- 底部导航只剩 **服务器** 一个 tab（+ 固定设置入口）。
- **首页**：站点下**全部节点**的卡片列表（多服务器天然支持，节点来自 `/api/servers`），
  内容对齐 CF 列表页卡片；顶部带总览卡（在线节点数、实时带宽、累计流量）。
- **详情页**：对齐 CF 详情页（信息卡 + 8 种图表 + 三网 ping，7 档时间范围）。
- **小组件**：Android 2x2（读数）/4x2（图表），Kotlin 原生；**每个实例绑定一台节点**，
  以 CF 站点 URL + 节点 id 拉取 API。公开站点免凭据；私有站点由 app 登录后将站点配置与
  token 发布到小组件可读的安全存储（见"新增工作"第 3 条）。
- **设置页**：站点配置（URL + 可选的用户名/密码）、主题、小组件相关设置；删除已裁功能的设置项。
- **通知**：Android 本地通知 —— 流量阈值告警与续费提醒，app 被杀仍生效（原生周期任务），
  详见"新增工作"第 4 条。
- **实时刷新**：`/api/ws` WebSocket 优先，断线/后台降级轮询。

## 保留清单

| 范围 | 内容 |
|---|---|
| `packages/fl_lib` | 主题、通用组件、KV 设置（共享库，只减使用不改代码） |
| fl_chart | 详情页图表渲染 |
| Android 原生 widget 框架 | `android/.../widget/*`（两个 widget、配置页）、ForegroundService 是否保留以 widget 刷新实际需要为准（批次 3 核对） |
| 主题系统 | fl_lib 主题 + 本仓库 ThemeHost |
| `monitor/` 目录 | 上游仓库整体的一部分，本次不碰（app 不再使用它） |

## 删除清单（按功能域）

| 功能域 | 主要删除物 |
|---|---|
| AI Agent | `lib/view/page/agent/`、`lib/core/llm/`、fl_pi_llm(_ui) 子模块、`.claude/skills` 资产、相关 dependency_overrides |
| 虚拟化 | `lib/view/page/virt/`、`lib/data/model/virt/`、`docs/dev/virt.md` |
| 远程桌面 | `lib/view/page/remote_desktop/`、`third_party/ironrdp` |
| 基准测试 | benchmark 页、`lib/data/model/server/benchmark/`、`assets/yabs.b64` |
| Snippet | `lib/view/page/snippet/` 及数据层 |
| SSH 终端 | `lib/view/page/ssh/`、xterm 包、flutter_pty 包、wakelock_plus、iSH 相关代码 |
| SFTP/文件 | `lib/view/page/storage/`、`lib/data/model/file/`、desktop_drop、Android `LinuxDocumentsProvider` |
| SSH/monitor 连接层 | dartssh2、Spi 模型、SSH 密钥管理（页面/模型）、`lib/data/provider/server/monitor_http.dart`、ServerTcpDialer、monitor_push 模型与渠道 UI |
| Rust 全套 | `crates/`（sbm_parser、sbm_ffi、sbm_native）、根 `Cargo.toml`/`Cargo.lock`、flutter_rust_bridge(+hooks)、`hook/build.dart` |
| 本地存储层 | drift/SQLite（`lib/data/store/`）、迁移与 fixture、`lib/hive/` 遗留适配、备份导入导出；设置与小组件配置收敛为轻量 KV（fl_lib 现有 KV，批次 7 核对载体） |
| 详情页残留入口 | BMC、iperf、端口转发、自定义命令等 |
| 平台目录 | ios/、macos/、linux/、windows/；watch_connectivity、plain_notification_token 包 |
| 导航 | AppTab 除 server 外全部枚举值（存量数据解析失败走现有 `parseAppTabsFromObj` 回退，无需 schema 迁移） |

## 新增工作

1. **CF API 适配层**（Dart，集中隔离）：站点配置模型（URL + 可选账号密码）+ CF 数据模型
   （节点、状态、历史、ping）+ HTTP 客户端 + WebSocket 实时 + 解析容错（未知字段忽略）。
   私有站点：登录换取 JWT 并安全存储，请求带 Bearer，token 临近过期或 401 时静默重登录
   （凭据永久存储，用户只输一次密码），密码在服务器侧变更时提示重新输入。
   payload 以 CF 仓库 `API.md` 与线上真实响应为准（联调站点：https://monitor.example.com/ ，
   公开可直接访问）。
2. **首页/详情页切换数据源**：卡片与图表改由 CF 适配层供数；本地不存历史。
3. **小组件改造**（Kotlin）：WidgetApi 从"agent URL + scoped token"改为"CF 站点 URL +
   节点 id"。公开站点免凭据；私有站点由 app 登录后将 JWT 发布到小组件可读的安全存储
   （复用现有 Keystore 封装机制的简化版），401 时提示回 app 重新登录。
   WidgetSync 的"自动发布全部 agent 服务器"逻辑删除，改为发布当前站点配置与 token；
   `scoped_token.dart`（monitor 的 scoped token 概念）删除。
   **显示内容自定义**：`WidgetConfig.kt` 按实例扩展字段/图表选择；`WidgetConfigureActivity`
   从"选节点"扩展为"选节点 + 选内容"；渲染用 RemoteViews 按配置切换可见性，不做动态布局。
4. **本地通知**（Android 原生，与小组件同栈）：WorkManager 周期任务拉 `/api/servers`，
   对每节点检查流量阈值（默认 90%，可配 80/90/95%）与到期天数（默认 7 天，可配），
   命中则经 NotificationManager 发通知。状态去重存轻量 KV：同一节点同一档阈值只通知一次，
   跨档升级再通知；续费提醒每天至多一次。设置页新增：通知总开关、流量阈值档位、
   续费提前天数。需处理 Android 13+ 通知运行时权限。

## 执行批次（渐进式，每批一个提交，批后可编译可测试可回滚）

| # | 批次 | 内容 |
|---|---|---|
| 0 | 基线 | 修复 git safe.directory 后打 tag；`make analyze` + 全量测试确认起点绿 |
| 1 | CF API 适配层 | 模型 + HTTP 客户端（`/api/servers` 起步；登录/Bearer/401 重登录）；首页卡片切 CF 数据，旧通道并行 |
| 2 | 详情页切 CF | `/api/server` + `/api/history/all`：信息卡、8 图表、三网 ping、7 档范围；WS 实时 + 轮询兜底 |
| 3 | 小组件切 CF + 自定义 | WidgetApi.kt 改造（公开直读 + 私有 token 发布）；2x2/4x2 显示内容可配置（4x2 图表/读数/组合三模式、字段/图表选择 + 配置页）；真机验证 2x2/4x2 |
| 4 | 本地通知 | 原生 WorkManager 周期任务 + NotificationManager（流量告警、续费提醒、去重、设置项、通知权限）；真机验证 |
| 5 | 删功能域 UI | AI Agent、虚拟化、远程桌面、基准测试、Snippet |
| 6 | 删终端 + SFTP | ssh 页、xterm、flutter_pty、wakelock；storage 页、file 模型、desktop_drop、LinuxDocumentsProvider |
| 7 | 删连接层 + Rust | dartssh2、Spi、密钥管理、monitor HTTP、monitor_push；crates/、Cargo、FRB、hook/ |
| 8 | 删存储层 + 平台目录 | drift/SQLite/迁移/fixture/备份；四个平台目录；watch/push token 包 |
| 9 | 对齐收尾 | 删残留入口（BMC、iperf、自定义命令…）、导航收缩单 tab、设置页瘦身 |
| 10 | 依赖与出包 | pubspec 删减、build_runner 重跑、全量验证、`make build PLATFORM=android` 真机验证 |

每批删页面时同步删该域的 AppTab 枚举值与 `test/unit/` 子目录，靠编译器保证无悬挂引用。

## 验证策略

- 每批 `make analyze` 清零 + 受影响单测；随域删除对应 `test/unit/` 子目录（保留 app/、theme 等）。
- 批次 1 起以 https://monitor.example.com/ 为真实数据源联调（公开站点，无需凭据）。
- 私有站点鉴权路径（登录、Bearer、401 重登录、widget 取数）需一台私有模式的站点联调：
  将你的站点临时切私有，或部署一个测试 Worker。
- 批次 3、4、10 需真机验证：小组件（添加、配置、刷新、断网表现）与通知（阈值触发、
  去重、权限拒绝后的表现）。
- 收尾：全量 `flutter test`、`./gradlew :app:testDebugUnitTest -x :app:compileFlutterBuildDebug`、
  出 Android 包真机验证。批次 7 后不再有 cargo 测试。

## 风险与回滚

- **CF API 无稳定性承诺**（第三方 MIT 项目）：适配层集中隔离 + 解析容错；以 `API.md` 与线上响应为准。
- **登录开启 Turnstile 的站点无法在 app 内登录**（人机验证无法在原生客户端完成）：
  文档明确的边界；你的站点若开启 Turnstile 登录需关闭。
- **JWT 7 天过期、无刷新端点**：客户端凭据永久存储 + 过期前/401 静默重登录实现"永久
  会话"体验；密码在服务器侧被修改时提示重新输入。
- **WebSocket 在移动网络下的断线重连**：轮询兜底，复用现有刷新调度。
- **小组件 Kotlin 改造**：必须真机验证。
- **git**：本机 checkout 有 `dubious ownership`，需先
  `git config --global --add safe.directory D:/flutter_server_box` 才能打 tag/提交。
- 回滚：每批一个 commit，revert 单个提交；批次 0 打 tag。

## 待计划阶段核对的细节（不阻塞设计）

- CF API 具体响应结构：`API.md` + 对公开站点实际抓包；WS 消息格式与重连协议。
- `ForegroundService` 的实际服务对象（SSH 会话通知 vs widget 刷新），决定整体删除还是瘦身。
- 设置页各项与 fl_lib KV 的实际载体（`SettingStore` 底层存储），确认删 SQLite 后设置仍可用。
- fl_chart 图表基建与 CF 历史数据结构的对接方式。
- pubspec 依赖逐个 grep 确认消费者后再删（`circle_chart`、`webdav_client_plus`、`file_picker`、
  `extended_image` 等）。
- 主题系统（ThemeHost、store 主题）在裁剪后的保留形态。
