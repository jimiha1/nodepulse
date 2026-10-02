# ServerBox → CF-Server-Monitor Android 客户端 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 ServerBox 硬裁剪为 CF-Server-Monitor（https://github.com/huilang-me/CF-Server-Monitor）的 Android 客户端：多节点查询（列表+详情图表+三网 ping）、公开/账号密码双模式鉴权（永久会话体验）、可自定义内容的桌面小组件（2x2 字段 / 4x2 图表·读数·组合）、流量与续费本地通知；删除其余全部功能。

**Architecture:** 新建 Dart 侧 `CfApi` 适配层（站点配置 + JWT 鉴权 + `/api/servers`、`/api/server`、`/api/history/all`、`/api/ws`）与 Riverpod `cfServersProvider`，首页/详情页切换到该数据源；Kotlin 小组件改为拉 CF API（凭据仍由 app 发布、Keystore 加密），增加内容自定义；新增 WorkManager 周期任务做本地通知。随后按域删除：旧功能 UI → SSH/monitor 连接层与全部 Rust → 实体存储层与非 Android 平台目录。

**Tech Stack:** Flutter/Dart (Riverpod, dio, fl_chart, fl_lib submodule), Kotlin (HttpURLConnection, RemoteViews, WorkManager), CF-Server-Monitor HTTP/WS API。

**Spec:** `docs/superpowers/specs/2026-10-02-feature-trim-design.md`（字段清单、决策 1-8、批次表）

## Global Constraints

- **永不运行代码格式化器**；提交信息：小写前缀 + 英文祈使句（`feat:` `fix:` `rm:` `refactor:` `chore:`…）。
- 永不手改 `*.g.dart` / `*.freezed.dart`；改注解模型后 `make gen`（build_runner + gen-l10n）。
- 新 UI 字符串进 `lib/l10n/app_en.arb` + `lib/l10n/app_zh.arb`，然后 `flutter gen-l10n`；通用词先查 fl_lib `libL10n`。
- 每个任务结束必须 `make analyze` 清零 + 相关测试绿，才允许提交。
- CF API 响应解析一律容错：未知字段忽略，缺字段给默认值（第三方 API 无稳定性承诺）。
- CF `/api/history/all` 的 `hours` 只接受 `0.167, 0.5, 1, 6, 12, 24, 48, 96, 168`。
- CF 字段语义：`ping_*`/`loss_*` 为 `number | null | false`（`false`=未配置不显示，`null`=超时）；流量限额 `traffic_limit` 是字符串（如 "1TB"），`traffic_calc_type` 决定只算下行还是上行+下行。
- 本计划所有 CF 请求默认站点：`https://monitor.example.com/`（公开，可作联调数据源）。
- 移动端目标仅 Android；每批一个 commit，可 revert。

---

### Task 0: 基线与安全网

**Files:** 无代码改动（环境与 git 状态）

- [ ] **Step 1: 修复 git 并补齐子模块**

```bash
git config --global --add safe.directory D:/flutter_server_box
cd /d/flutter_server_box && git status
git submodule update --init --recursive
```

Expected: `git status` 正常输出（不再报 dubious ownership）；`packages/fl_lib`、`packages/fl_build` 等子模块目录非空。**fl_lib 必须非空**，后续所有任务依赖它编译。

- [ ] **Step 2: 依赖与生成物**

```bash
make deps && make gen
```

Expected: `pub get` 成功、build_runner 与 gen-l10n 完成。

- [ ] **Step 3: 基线验证**

```bash
make analyze
make test
```

Expected: analyze 无 error；`flutter test` 全绿（如基线本身有失败，记录失败清单到 `docs/superpowers/plans/baseline-notes.md`，只把与本计划无关的预存失败当已知噪音）。

- [ ] **Step 4: 打基线 tag**

```bash
git tag pre-cf-trim && git log --oneline -1
```

- [ ] **Step 5: Commit（如有生成物差异）**

```bash
git add -A && git commit -m "chore: baseline before cf trim" || echo "nothing to commit"
```

---

### Task 1: CF API 适配层 — 模型 + 客户端 + 鉴权（含测试）

**Files:**
- Create: `lib/data/model/cf/cf_server.dart`（节点模型 + JSON 解析）
- Create: `lib/data/model/cf/cf_history.dart`（历史行模型）
- Create: `lib/data/provider/server/cf/cf_api.dart`（HTTP 客户端 + JWT 鉴权）
- Create: `lib/data/provider/server/cf/cf_credentials.dart`（凭据安全存储）
- Modify: `pubspec.yaml`（`flutter_secure_storage` 从 dev_dependencies 移到 dependencies）
- Test: `test/unit/server/cf/cf_server_test.dart`、`test/unit/server/cf/cf_api_test.dart`

**Interfaces（后续任务依赖，签名冻结）:**

```dart
class CfServer {           // 解析自 /api/servers 的一个元素
  final String id, name;
  final String? group, region, os, arch, price, billingCycle, expireDate, trafficLimit;
  final String? trafficCalcType;          // down-only / up-down（未知按 up-down）
  final bool online;                      // 由 last_updated 推导
  final double cpu;                       // %
  final int? cpuCores;  final String? cpuInfo;
  final int ramUsed, ramTotal, swapUsed, swapTotal, diskUsed, diskTotal; // MB
  final double load1, load5, load15;      // 解析自 load_avg "x x x"，失败为 0
  final int netInSpeed, netOutSpeed;      // B/s
  final int netRxMonthly, netTxMonthly, netRx, netTx; // bytes
  final int tcpConn, udpConn, processes;
  final double? pingCt, pingCu, pingCm;   // null=超时，false→null(未配置与超时同显示)，ms
  final double? lossCt, lossCu, lossCm;   // %
  final int? bootTime;                    // 秒，在线时长 = now - bootTime
  final List<CfGpu> gpus;
  static CfServer fromJson(Map<String, dynamic> j) {...}
  double get trafficUsedRatio;            // 0..1 或 -1（无限额），calcType 决定 rx 还是 rx+tx
}

class CfServersSnapshot {
  final List<CfServer> servers;
  final int total, online;
  final double globalSpeedIn, globalSpeedOut; // B/s
  final int globalNetRx, globalNetTx;         // bytes
  final bool showExpire, showPrice;
}

class CfHistoryRow {  // /api/history/all 一行；字段同 API.md 固定列表，容错缺省
  final int timestamp; final double cpu;
  final int ramUsed, ramTotal, diskUsed, diskTotal;
  final int netInSpeed, netOutSpeed, tcpConn, udpConn, processes;
  final int diskReadBps, diskWriteBps;
  final int swapUsed, swapTotal; final String loadAvg;
  final double? pingCt, pingCu, pingCm, lossCt, lossCu, lossCm;
}

class CfApi {
  CfApi({required String baseUrl, String? Function() tokenProvider, ...});
  Future<void> login(String username, String password); // POST /admin/api {"action":"login",...} → token
  Future<CfServersSnapshot> fetchServers();
  Future<Map<String, dynamic>> fetchServerRaw(String id);
  Future<List<CfHistoryRow>> fetchHistory({required String id, required double hours}); // hours ∈ {0.5,1,6,24,48,168}
  void close();
}
```

- [ ] **Step 1: 移依赖 + 写解析测试（先失败）**

`pubspec.yaml`：把 `flutter_secure_storage: ^10.3.1` 从 `dev_dependencies:` 段移到 `dependencies:` 段（保留同一版本约束）。运行 `make deps`。

写 `test/unit/server/cf/cf_server_test.dart`（fixture 用真实线上响应的最小代表集，字段名以 API.md 为准）：

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/cf/cf_server.dart';

const _raw = '''
{"servers":[{
  "id":"fd978320-c32c-474d-857a-3412a7526a7b","name":"日本节点","server_group":"Default",
  "region":"JP","os":"Debian GNU/Linux 13 (trixie)","arch":"arm64","cpu_info":"arm64 (x2)",
  "cpu":3.23,"cpu_cores":2,"load_avg":"0.22 | 0.17 | 0.17",
  "ram_total":12268,"ram_used":4987,"swap_total":0,"swap_used":0,
  "disk_total":100454,"disk_used":54886,
  "net_in_speed":13200,"net_out_speed":2980,"net_rx":3160000000,"net_tx":4500000000,
  "net_rx_monthly":3160000000,"net_tx_monthly":4500000000,
  "tcp_conn":34,"udp_conn":8,"processes":347,
  "ping_ct":165.0,"ping_cu":78.0,"ping_cm":310.0,"loss_ct":0.0,"loss_cu":0.0,"loss_cm":0.0,
  "boot_time":1756000000,"expire_date":"2027-10-02","price":"39.90","billing_cycle":"year",
  "traffic_limit":"10TB","traffic_calc_type":"down","last_updated":1759410000000
}],
"stats":{"total":1,"online":1,"globalSpeedIn":13200,"globalSpeedOut":2980,
 "globalNetRx":3160000000,"globalNetTx":4500000000},
"sysConfig":{"show_price":true,"show_expire":true,"show_tf":true}}''';

void main() {
  test('parses a CF server node', () {
    final s = CfServersSnapshot.fromJson(jsonDecode(_raw) as Map<String, dynamic>);
    final n = s.servers.single;
    expect(n.id, 'fd978320-c32c-474d-857a-3412a7526a7b');
    expect(n.name, '日本节点');
    expect(n.cpu, 3.23);
    expect(n.load1, 0.22); expect(n.load15, 0.17);
    expect(n.pingCt, 165.0); expect(n.pingCm, 310.0);
    expect(n.trafficUsedRatio, closeTo(3160000000 / 10995116277760, 1e-9)); // down-only
    expect(n.expireDate, '2027-10-02');
    expect(s.online, 1);
  });
  test('tolerates missing and false fields', () {
    final j = jsonDecode('{"servers":[{"id":"x","name":"n","ping_ct":false,"loss_cu":null,'
        '"traffic_limit":"500GB","traffic_calc_type":"up_down","net_rx_monthly":1000000000,'
        '"net_tx_monthly":2000000000}],"stats":{},"sysConfig":{}}') as Map<String, dynamic>;
    final n = CfServersSnapshot.fromJson(j).servers.single;
    expect(n.pingCt, isNull); expect(n.lossCu, isNull);
    expect(n.trafficUsedRatio, closeTo(3e9 / (500 * 1024 * 1024 * 1024.0), 1e-9));
    expect(n.expireDate, isNull);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `make test-one TEST=test/unit/server/cf/cf_server_test.dart`
Expected: FAIL（`cf_server.dart` 不存在）。

- [ ] **Step 3: 实现 CfServer/CfServersSnapshot**

`lib/data/model/cf/cf_server.dart` — 纯手写解析类（**不用** freezed/json_serializable：第三方 API 字段松散，容错解析手写更直接；不进 codegen）。要点：所有 `num?`/`String?` 读取走本地 `_d(num?, fallback)` 帮助函数；`load_avg` 用 `split('|')` 再 tryParse；`ping_*/loss_*`：`false`→null、`null`→null、数字→toDouble；`online` = `DateTime.now().millisecondsSinceEpoch - (last_updated ?? 0) < 90_000`；`boot_time` 是秒；`trafficUsedRatio`：无 `traffic_limit` → -1，`calcType` 含 `"down"` 且不含 `"up"` → `rxMonthly`，否则 `rxMonthly+txMonthly`；限额解析 `"10TB"/"500GB"/"1MB"` 走 `_limitToBytes`（KB/MB/GB/TB/PB，二进制 1024 与十进制都试：优先 1024）。`CfHistoryRow.fromJson` 同风格（`lib/data/model/cf/cf_history.dart`），字段见 Interfaces。

- [ ] **Step 4: 测试通过**

Run: `make test-one TEST=test/unit/server/cf/cf_server_test.dart`
Expected: PASS (2 tests)。

- [ ] **Step 5: 写 CfApi 鉴权/解析测试**

`test/unit/server/cf/cf_api_test.dart`，用现有测试基建 `test/helpers/local_http.dart` 起本地服务：

```dart
test('login stores token and fetchServers sends Bearer', () async {
  await withLocalHttp((server) async {   // helper 暴露的形态以 local_http.dart 实际签名为准
    server.on('POST', '/admin/api').respondJson(
      {'success': true, 'token': 'jwt-1', 'message': 'loginSuccessful'});
    server.on('GET', '/api/servers').check((req) =>
        expect(req.headers['authorization'], 'Bearer jwt-1')
    ).respondJson(jsonDecode(_raw) as Map<String, dynamic>);
    final api = CfApi(baseUrl: server.url);
    await api.login('admin', 'pw');
    final snap = await api.fetchServers();
    expect(snap.servers.single.name, '日本节点');
  });
});
```

（如 `local_http.dart` 的 API 与上面假设不符，按其实际签名改写测试骨架，语义不变：登录→带 Bearer 拉列表。）

- [ ] **Step 6: 实现 CfApi + 凭据存储**

`cf_api.dart`：用 `dio`（已是依赖）。`BaseOptions(baseUrl:, connectTimeout: 8s, receiveTimeout: 15s)`；拦截器：有 token 则加 `Authorization: Bearer`；`DioException` 401/403 且有存储凭据 → 自动 `login()` 重放一次（防死循环：重试标志位）；WS 的 token 由 `tokenProvider` 给出。`fetchServers()`→`CfServersSnapshot.fromJson`；`fetchHistory(id:, hours:)`→`GET /api/history/all?id=$id&hours=$hours` → `List<CfHistoryRow>`。

`cf_credentials.dart`：`flutter_secure_storage` 的 `FlutterSecureStorage` 存 `cf_username`/`cf_password`/`cf_token`/`cf_token_exp`（读 JWT 的 `exp` 字段，Base64 解 payload）；`Future<String?> token()`：无 token 或 `exp` 距现在 <1h → 用存好的凭据静默 `login()` 换新（实现"永久会话"）；凭据缺失→返回 null（公开站点路径）。

- [ ] **Step 7: 测试通过 + analyze**

Run: `make test-one TEST=test/unit/server/cf/cf_api_test.dart && make analyze`
Expected: PASS；analyze 无新增 error。

- [ ] **Step 8: 真实站点冒烟（手动，不进 CI）**

写 `tool/cf_smoke.dart`（`dart run tool/cf_smoke.dart`）：`CfApi(baseUrl: 'https://monitor.example.com').fetchServers()` 打印节点名/CPU/流量比。对真实站点跑一次确认字段假设成立（若字段名与 API.md 有出入，以真实响应为准回改 `cf_server.dart` 并同步测试 fixture）。

- [ ] **Step 9: Commit**

```bash
git add lib/data/model/cf lib/data/provider/server/cf test/unit/server/cf tool/cf_smoke.dart pubspec.yaml pubspec.lock
git commit -m "feat: cf monitor api client with jwt auth"
```

---

### Task 2: cfServersProvider + 站点设置

**Files:**
- Create: `lib/data/provider/server/cf/cf_servers_provider.dart`（Riverpod codegen）
- Modify: `lib/data/store/setting.dart`（新增 4 个设置项）
- Create: `lib/view/page/setting/entries/cf_site.dart`（站点配置 UI，entry.dart 的 part）
- Modify: `lib/view/page/setting/entry.dart`、`lib/view/page/setting/nodes.dart`（挂入口）
- Modify: `lib/l10n/app_en.arb`、`lib/l10n/app_zh.arb`
- Test: `test/unit/server/cf/cf_servers_provider_test.dart`

**Interfaces:**

```dart
// cf_servers_provider.dart
@Riverpod(keepAlive: true)
class CfServers extends _$CfServers {
  // state: AsyncValue<CfServersSnapshot>
  Future<void> refresh();          // 立即拉一次
  void startAutoRefresh();         // Timer 周期 = Stores.setting.cfUpdateInterval 秒，默认 10
  StreamSubscription<void> watchWs(); // Task 5 接入；本任务先返回空流
}
// setting.dart 新增
late final cfSiteUrl = propertyDefault('cfSiteUrl', '');
late final cfUpdateInterval = propertyDefault('cfUpdateInterval', 10);
late final cfAuthEnabled = propertyDefault('cfAuthEnabled', false);
// 用户名/密码不进 SettingStore（SQLite 明文），进 CfCredentials（flutter_secure_storage）
```

- [ ] **Step 1: 设置项 + ARB 字符串**

`setting.dart` 加上面 3 行（密码凭据不在这里）。ARB 加：`cfSite`("CF Monitor Site"/"CF 监控站点")、`cfSiteUrlHint`、`cfAuth`("Login required"/"站点需要登录")、`cfUsername`、`cfPassword`、`cfTestConnection`("Test connection"/"测试连接")、`cfTestOk`("Connected, {n} servers"/"连接成功，{n} 台服务器")、`cfTestFail`("Connection failed"/"连接失败")。跑 `make gen-l10n`。

- [ ] **Step 2: 写 provider 测试（先失败）**

```dart
test('refresh parses snapshot and stores it', () async {
  final container = ProviderContainer(overrides: [/* CfApi 注入点 */]);
  // cfServersProvider 需支持注入 CfApi（构造参数或 provider 覆盖），测试塞 fake 返回上面 _raw 解析结果
  await container.read(cfServersProvider.notifier).refresh();
  expect(container.read(cfServersProvider).value?.servers.length, 1);
});
```

（fake CfApi 实现 `fetchServers` 返回固定 snapshot；provider 用 `ref.watch(cfApiProvider)` 取得，测试覆盖 `cfApiProvider`。）

- [ ] **Step 3: 实现 provider**

`CfApi` 实例化放在 `@Riverpod(keepAlive: true) CfApi cfApi(ref)`：读 `Stores.setting.cfSiteUrl`，`tokenProvider` 接 `CfCredentials`；`cfSiteUrl` 变化时重建（`ref.listen`）。`CfServers.refresh()`：`state = AsyncValue.fromPromise(api.fetchServers())`；`startAutoRefresh()` 复制 `all.dart:251-279` 的递归 Timer 模式（读 `cfUpdateInterval`）。

- [ ] **Step 4: 站点配置 UI**

`entries/cf_site.dart`：`Input`（URL，`onSubmitted: put`）、`StoreSwitch(prop: cfAuthEnabled)`、启用时 `Input` 用户名 + `Input` 密码（`obscure:true`，保存进 `CfCredentials`）、`Btn` 测试连接（调 `CfApi.login?+fetchServers`，`context.showRoundDialog` 显示结果）。在 `nodes.dart` 设置树的服务器分组上方插入。参考现有 `generalWakeLock` 三步模式（setting.dart:619 → entries/app.dart:404）。

- [ ] **Step 5: 验证 + Commit**

Run: `make test-one TEST=test/unit/server/cf/cf_servers_provider_test.dart && make analyze && make gen`
Expected: PASS、analyze 清零。Commit: `feat: cf servers provider and site settings`

---

### Task 3: 首页切换 CF 数据（卡片 + 总览）

**Files:**
- Create: `lib/view/page/server/cf_tab.dart`（新首页：总览行 + 节点卡片列表）
- Create: `lib/view/page/server/cf_card.dart`（CF 卡片）
- Modify: `lib/data/model/app/tab.dart`（`defaultOrder` 改 `[server]`）
- Modify: `lib/view/page/home_tab.dart`（`AppTab.server => const CfHomePage()`，其余 case 暂留）
- Modify: `lib/l10n/app_en.arb`、`lib/l10n/app_zh.arb`
- Test: `test/unit/server/cf/cf_card_test.dart`（widget test：快照状态渲染卡片字段）

**Interfaces:** `CfHomePage extends ConsumerStatefulWidget`（route path `/cf`）；卡片显示：旗帜(region)、名称、分组、OS 图标（复用现有 distro 图标逻辑，匹配不到用通用）、在线状态、CPU%+核数、内存%+用量、磁盘%+用量、负载 load1、↑↓实时速率、累计出入站、剩余流量（`trafficUsedRatio`≥0 时）、TCP/UDP、三网延迟（`ping_ct/cu/cm` 非 false）、在线时长、到期（`showExpire` 时）。总览行：在线 x/y、总带宽、累计流量（`stats`）。

- [ ] **Step 1: 卡片 widget test（先失败）** — 构造 `CfServer` fixture，`pumpWidget(CfServerCard(node: n))`，expect 找到 "日本节点"、"3.2%"、"165ms" 文本。
- [ ] **Step 2: 实现 CfServerCard + CfHomePage** — `CfHomePage` watch `cfServersProvider`；`RefreshIndicator` + `ListView`；顶部总览行三张小卡；点击卡片 → `CfDetailPage(id: node.id).push(context)`（Task 4 的页面，本任务先建空壳路由）。刷新：下拉 + `startAutoRefresh()` 在 `initState`。
- [ ] **Step 3: 切换入口** — `home_tab.dart` 的 `AppTab.server => const CfHomePage()`；`tab.dart` `defaultOrder = [server]`。旧 `ServerPage` 与旧数据链**不删**（Task 11 统一删），但不再被导航到达。
- [ ] **Step 4: 验证** — `make test-one TEST=test/unit/server/cf/cf_card_test.dart && make analyze`；`make run` 手动确认：真实站点 2 个节点、字段显示正确。
- [ ] **Step 5: Commit** — `feat: cf home list with overview and node cards`

---

### Task 4: CF 详情页（信息卡 + 8 图表 + 三网 ping + 时间范围）

**Files:**
- Create: `lib/view/page/server/cf_detail/view.dart`（详情页骨架 + 信息卡）
- Create: `lib/view/page/server/cf_detail/charts.dart`（8 图表 + ping 图，复用 `MetricChart`/`MetricChartSpec`，chart.dart:62/129）
- Modify: `lib/view/page/server/cf_tab.dart`（路由接入）
- Modify: `lib/data/provider/server/cf/cf_servers_provider.dart`（加 `fetchHistory(id, hours)` 转发 + `CfHistoryRange` 枚举）
- Modify: `lib/l10n/*.arb`
- Test: `test/unit/server/cf/cf_history_test.dart`（范围→hours 映射 + 行解析已在 Task 1 覆盖，这里测映射与图表数据装配）

**Interfaces:**

```dart
enum CfHistoryRange { live, m30, h1, h6, d1, d2, d7 }
extension CfHistoryRangeX on CfHistoryRange {
  double? get hours => switch (this) { CfHistoryRange.live => null, _ => 0.5/1/6/24/48/168 };
  String get label; // l10n
}
// 图表 8 种：CPU、内存(+Swap 双线)、磁盘已用、网络(双线 in/out)、系统负载(3 线)、磁盘IO(读/写双线)、连接数(TCP/UDP 双线)、进程数
// ping 图：3 条线（电信/联通/移动）延迟 + 丢包，数据来自同一 history rows 的 ping_*/loss_*
```

- [ ] **Step 1: 映射测试（先失败）** — `expect(CfHistoryRange.d7.hours, 168)`；`rowsToSeries(rows, metric: .network)` 返回双系列且点数正确。
- [ ] **Step 2: 实现详情页** — 信息卡（架构/系统/GPU/内存/Swap/磁盘/负载 1/5/15/运行时长/最近更新/总流量/剩余流量/到期+价格）；live 模式：直接用 provider 里该节点的实时值 + 滚动缓冲（provider 内存保留最近 ~120 个 sample：每次 refresh 后 push）；非 live：`fetchHistory` → `MetricChart` 渲染。范围切换条：`Choice`（复用 choice 包）横排 7 档。ping 图固定显示（`ping_ct` 全 false 时隐藏）。
- [ ] **Step 3: 验证** — 测试绿 + analyze 清零 + `make run` 手动过 7 档范围、与网站同节点数值对拍（CPU%、内存 used/total 一致）。
- [ ] **Step 4: Commit** — `feat: cf server detail with history charts and ping`

---

### Task 5: WebSocket 实时 + 轮询兜底

**Files:**
- Create: `lib/data/provider/server/cf/cf_ws.dart`
- Modify: `lib/data/provider/server/cf/cf_servers_provider.dart`（WS 样本合入 state）
- Modify: `lib/data/model/cf/cf_server.dart`（`CfServer.copyWithMetrics(...)`：用增量样本更新数值字段）
- Test: `test/unit/server/cf/cf_ws_test.dart`（合并逻辑：`batchUpdate` 样本覆盖对应节点字段）

**Interfaces:** `CfWs.connect({required String url, String? token, required void Function(String serverId, Map<String,dynamic> data) onSample})`；协议：连上发 `{"type":"subscribe","scope":"all"}`；心跳 30s 发 `{"type":"ping"}` 期待精确 `{"type":"pong"}`；`batchUpdate.updates[].samples[]` → 逐样本回调；断线指数退避重连（1s 起、上限 60s）；私有站点 token 走 `?token=` 查询参数。Provider 侧：WS 连接成功 → 停轮询 Timer；断开 → 恢复轮询。

- [ ] **Step 1: 合并单测（先失败）** — fake 样本 `{"cpu": 55.5, "net_in_speed": 100}` → `copyWithMetrics` 后 `cpu==55.5` 且未提及字段不变。
- [ ] **Step 2: 实现 CfWs** — 用 `web_socket_channel`（查 pubspec：若无则 `make deps` 前先加入 dependencies，^3.x）。重连与心跳实现照 Interfaces。
- [ ] **Step 3: 验证** — 单测绿 + analyze；`make run` 打开首页，在 CF 面板观察 agent 上报后 app 数值秒级跳动（网站与 app 同时看同一节点）；飞行模式开/关验证回落轮询。
- [ ] **Step 4: Commit** — `feat: cf websocket realtime with polling fallback`

---

### Task 6: 小组件切 CF 数据（Kotlin 数据路径）

**Files:**
- Modify: `android/.../widget/WidgetApi.kt`（端点/字段换 CF）
- Modify: `android/.../widget/WidgetStore.kt`（payload 结构：站点 + 节点列表 + token）
- Modify: `lib/core/service/widget_sync.dart`（重写为发布站点配置 + token）
- Delete: `lib/core/service/scoped_token.dart`（monitor scoped token 概念）
- Modify: `android/.../MainActivity.kt`（`publishWidgetServers` payload 不变格式、`widgetTokenState` 保留）
- Test: `android/app/src/test/.../CfWidgetParseTest.kt`（JVM 单测：CF JSON → 显示值）

**Interfaces（Kotlin 侧新契约）:**

```kotlin
// WidgetStore.publish 的新 payload（Dart → native，JSON 字符串）：
// {"siteUrl":"https://...","token":"jwt-or-null","tokenExpiresAt":ms,
//  "nodes":[{"id":"uuid","name":"日本节点","region":"JP"}]}
// WidgetApi: GET {siteUrl}/api/v1/→ 改为 GET {siteUrl}/api/servers
//   token 非空时带 Bearer；解析取 servers[]. 中 config.serverId 对应节点
// WidgetServer 字段变为 id/name/region（addr/ignoreCert/allowInsecure 删除）
```

- [ ] **Step 1: JVM 解析测试（先失败）** — CF `/api/servers` fixture JSON → 解析出节点 CPU%/内存文本/剩余流量文本。
- [ ] **Step 2: 改 WidgetApi.kt** — `load()` 改单请求 `/api/servers`；字段映射：`cpu`、`ram_used/ram_total`、`disk_used/disk_total`、`net_in_speed/net_out_speed`、`ping_ct/cu/cm`；history 不再单独拉（Task 7 组合模式需要历史：同请求加 `GET /api/history/all?id=<id>&hours=24`，解析 `cpu/net_in_speed/net_out_speed` 数组）。401 → `RejectedTokenException` 保留（widget 显示错误态，等 app 重发 token）。
- [ ] **Step 3: 改 WidgetStore.kt + widget_sync.dart** — `WidgetServer` 字段缩减；`publish` 解析新 payload；Dart 侧 `WidgetSync.push()`：登录态变化/token 刷新/站点配置变化时发布 `{siteUrl, token, nodes}`（nodes 来自最近一次 `CfServersSnapshot`）；`scoped_token.dart` 删除并清理 import。
- [ ] **Step 4: 验证** — `cd android && ./gradlew :app:testDebugUnitTest`；`make build PLATFORM=android` 装真机：添加 widget → 选节点 → 显示与 app 一致；公开站点无 token 也工作。
- [ ] **Step 5: Commit** — `feat: widget fetches cf monitor api`

---

### Task 7: 小组件内容自定义（三模式）

**Files:**
- Modify: `android/.../widget/WidgetConfig.kt`（SMALL: `fields: List<WidgetField>`；MEDIUM: `mode: chart|reading|combined` + `chartMetric` + `fields` + `chart2Metric`）
- Modify: `android/.../widget/WidgetConfigureActivity.kt` + `res/layout/widget_configure.xml`（模式单选 + 字段多选 checkbox 列表）
- Modify: `res/layout/home_widget.xml`（扩展为：头行 + 两个 chart 槽 + 8 个可复用读数行，全部默认 gone，由渲染端按配置点亮）
- Modify: `android/.../widget/HomeWidget.kt`（按配置构建 RemoteViews：字段行 `setViewVisibility` + 文本；combined 模式两个 chart bitmap）
- Modify: `android/.../widget/WidgetChart.kt`（支持单系列小图渲染入 combined 槽位）
- Test: `android/app/src/test/.../WidgetConfigTest.kt`

**Interfaces:**

```kotlin
enum class WidgetField(val key: String) { CPU("cpu"), MEM("mem"), DISK("disk"), LOAD("load"),
  NET_SPEED("net"), NET_TOTAL("total"), TRAFFIC_LEFT("quota"), CONN("conn"),
  PING("ping"), UPTIME("uptime"), EXPIRE("expire") }   // key 即 prefs 存储名
// WidgetConfig 读取：widget_${id}_mode / _fields(逗号分隔 key) / _chart / _chart2
// 上限：SMALL 4 行、MEDIUM reading 6 行、combined 上 2 图 + 下 3 行（超出截断）
// 默认：SMALL=[CPU,MEM,DISK,NET_SPEED]；MEDIUM mode=chart, chart=net
```

- [ ] **Step 1: 配置读写 JVM 测试（先失败）** — save/load round-trip：mode、fields 截断到上限、未知 key 忽略。
- [ ] **Step 2: 扩展 WidgetConfig + 配置页** — SMALL：字段多选（默认 4 项）；MEDIUM：模式单选 → chart（指标 spinner，8 种）/ reading（多选）/ combined（两个指标 spinner + 多选）。配置页布局加 `RadioGroup#mode_group`、`LinearLayout#field_checks`。
- [ ] **Step 3: 渲染** — `HomeWidget.kt` 按模式生成 RemoteViews：reading 行文本（CPU "3.2%"、MEM "4.8/11.7GB"、NET "↑2.9KB/s ↓13.2KB/s"、QUOTA "3.2GB/9.77TB"、PING "165/78/310ms"、EXPIRE "2027-10-02" 等，格式化函数集中一处 + JVM 测试）；combined：`WidgetChart.render` 两个单系列小图 + 下行读数。
- [ ] **Step 4: 验证** — gradle 测试 + 真机：三种模式各配一个 widget，刷新按钮、30 分钟系统刷新、断网错误态都看一遍。
- [ ] **Step 5: Commit** — `feat: widget content customization with three medium modes`

---

### Task 8: 本地通知（流量 + 续费）

**Files:**
- Modify: `android/app/build.gradle`（+`androidx.work:work-runtime-ktx:2.10.0`）
- Create: `android/.../alert/AlertWorker.kt`、`android/.../alert/AlertSettings.kt`、`android/.../alert/CfAlertParser.kt`
- Modify: `android/.../MainActivity.kt`（+`publishAlertSettings` channel 方法）
- Modify: `lib/core/service/widget_sync.dart`（发布时一并带通知设置）或新建 `lib/core/service/alert_sync.dart`
- Modify: `lib/view/page/setting/entries/cf_site.dart`（通知开关/阈值/天数 + 权限申请复用 `notificationsAllowed`/`openNotificationSettings`，MainActivity.kt:207-225）
- Test: `android/app/src/test/.../CfAlertParserTest.kt`

**Interfaces:**

```kotlin
// publishAlertSettings payload: {"enabled":bool,"trafficPct":90,"expiryDays":7,
//   "siteUrl":..., "token":..., "tokenExpiresAt":...}
// AlertWorker: PeriodicWorkRequest(15min, KEEP)，约束 NetworkType.CONNECTED
// CfAlertParserInput: /api/servers JSON + 已存 dedup 状态 prefs
// 输出: List<Alert {nodeId, node, kind: TRAFFIC|EXPIRE|EXPIRED, tierOrDays, title, text}>
// 去重: prefs key alert_<nodeId>_traffic = 已通知的最高档(80/90/95)；alert_<nodeId>_expire = 最近通知日期
// 通道: NotificationManager channel "server_alerts"（IMPORTANCE_DEFAULT）
```

- [ ] **Step 1: 解析/去重 JVM 测试（先失败）** — `traffic_limit="10TB", calc down, rx=9.9TB` → 99% → 命中 95 档；已存档 90 → 触发；已存档 95 → 不重复。`expire_date`距今 5 天、expiryDays=7 → EXPIRE（当天已通知过则不重复）；`expire_date` 已过 → EXPIRED。
- [ ] **Step 2: 实现 CfAlertParser + AlertSettings + AlertWorker** — Worker 里 `Firebase`无、纯 HttpURLConnection 复用 WidgetApi 的 fetch（抽公共 `CfHttp` 小对象或直接内联）；限额字节解析与 Dart `cf_server.dart` 同规则（1024 优先）。注意 WorkManager 默认初始化即可用（无自定义 Configuration）。
- [ ] **Step 3: 设置 UI + 发布** — 通知分组：总开关（开启时申请 POST_NOTIFICATIONS）、流量阈值 `Choice`(80/90/95)、提前天数 `Input`(数字)；变更即 `publishAlertSettings`，Worker `enqueueUniquePeriodicWork(REPLACE)`。
- [ ] **Step 4: 验证** — gradle 测试；真机：把阈值设 80 → 用站点上流量最多的节点触发 → 收到通知；再触发不重复；关开关后无通知。**私有站点路径**：切站点私有 → app 登录 → 通知任务带 token 正常（与 Task 9 的私有联调合并做）。
- [ ] **Step 5: Commit** — `feat: local traffic and expiry alerts via workmanager`

---

### Task 9: 删功能域 UI（Agent/虚拟化/远程桌面/基准/Snippet）

**Files（删除）:**
- `lib/view/page/agent/`、`lib/core/llm/`、`lib/data/model/ai/`、`lib/data/provider/` 下 agent 相关、`lib/view/page/virt/`、`lib/data/model/virt/`、`lib/view/page/remote_desktop/`、`lib/data/model/remote_desktop*`（含 store 注册 `RemoteDesktopStore`）、`lib/view/page/benchmark/`、`lib/data/model/server/benchmark/`、`lib/view/page/snippet/`、`lib/data/model/snippet*`、`lib/data/store/` 里 SnippetStore/BmcCredentialStore/PveStore 等（能编译通过的范围内）
- `third_party/ironrdp/`、`.gitmodules` 中对应条目（若有）
- `test/unit/ai/`、`test/unit/virt/`、`test/unit/remote_desktop/`、`test/unit/benchmark/`（若有）、`test/unit/` 下 snippet 相关
- `packages/fl_pi_llm`、`packages/fl_pi_llm/ui` 子模块目录 + `.gitmodules` 条目 + `git rm --cached`
- 资产：`assets/yabs.b64`、pubspec assets 段对应行、`.claude/skills/serverbox-help` 的 pubspec assets 引用（agent 用）
- Modify: `lib/data/model/app/tab.dart`（删 `agent`/`benchmark`/`remoteDesktop`/`virt` 枚举值 + `home_tab.dart` switch 对应 case）、`pubspec.yaml`（`fl_pi_llm`、`fl_pi_llm_ui`、`redfish`、`dependency_overrides.flutter_math_fork`）、`lib/data/res/store.dart`（Stores 注册处去掉对应 store）、`lib/main.dart`（`LlmHost` 等初始化调用）

- [ ] **Step 1: 删文件/目录**（上面清单；`git rm -r`）
- [ ] **Step 2: 编译器驱动清理** — `make analyze`，逐个修复 error：`home_tab.dart` switch case、`Stores` 注册、`main.dart` 初始化、`pubspec` 依赖与 assets、`nodes.dart` 设置入口（ai 等）。每轮 `make analyze` 直到清零。
- [ ] **Step 3: 测试** — `make test`（被删域的测试已随目录删除；其余必须绿）。
- [ ] **Step 4: Commit** — `rm: agent, virt, remote desktop, benchmark, snippet domains`

---

### Task 10: 删终端 + SFTP

**Files（删除）:**
- `lib/view/page/ssh/`、`lib/view/page/storage/`、`lib/data/model/file/`、`test/unit/terminal/`、`test/unit/file/`
- `lib/data/model/app/port_forward*`、`lib/view/page/port_forward.dart`、`lib/view/page/iperf.dart`（端口转发/iperf 依赖 SSH 通道）
- `lib/core/utils/ish_shell.dart`、`lib/core/utils/ish_exec.dart`（iSH，iOS 专属）
- `android/.../linux/`（GuestPath、LinuxDocumentsProvider）+ Manifest provider 声明（AndroidManifest.xml:186-195）
- Modify: `pubspec.yaml`（`xterm`、`flutter_pty`、`wakelock_plus`、`desktop_drop`、`flutter_gbk2utf8`——grep 确认无其他消费者再删）
- Modify: `AndroidManifest.xml`（`updateSessions`/`stopService` 相关：`ForegroundService` service 声明 L176-180、`STOP_ALL` 自定义权限 L27-30、`READ/WRITE_EXTERNAL_STORAGE` L5-15、`VIBRATE` 视残留引用）
- Delete: `android/.../ForegroundService.kt` + MainActivity 中 `updateSessions`/`stopService`/`isServiceRunning`/`disconnectSession`/`stopAllConnections` 方法（L238-296、L562-586）+ Dart 侧 `MethodChans` 对应调用（`lib/core/chan.dart`）
- Modify: `home_tab.dart`（删 `ssh`/`file` case + `AppTab.ssh/file` 枚举值）

- [ ] **Step 1: 删除 + 编译器驱动清理**（同 Task 9 模式）
- [ ] **Step 2: Android 原生瘦身** — 删 ForegroundService 及其 channel 方法；`make analyze` + `cd android && ./gradlew :app:testDebugUnitTest`
- [ ] **Step 3: 验证** — `make test`；真机快速过一遍首页/详情不回归。
- [ ] **Step 4: Commit** — `rm: ssh terminal and sftp domains with native leftovers`

---

### Task 11: 删旧服务器栈 + 连接层 + 全部 Rust

**Files（删除）:**
- 旧 Spi UI：`lib/view/page/server/detail/`（旧详情，Task 4 已有 CF 详情替代）、`lib/view/page/server/edit/`、`lib/view/page/server/card/`（旧卡片，CF 卡片在 cf_card.dart）、`lib/view/page/server/tab/`、`lib/view/page/server/monitor_settings/`、`lib/view/page/private_key/`、`lib/view/page/user_detail.dart`、`lib/view/page/users.dart`、`lib/view/page/service_detail.dart`、`lib/view/page/services.dart`、`lib/view/page/process.dart`、`lib/view/page/connection_stats.dart`、`lib/view/page/custom_cmds.dart`、`lib/view/page/floating_panels.dart`（核对：仅 SSH 会话浮窗则删）、`lib/view/page/macos_menu_bar.dart`
- 连接层：`packages/dartssh2`（子模块）、`lib/data/provider/server/script_source.dart`、`monitor_http_source.dart`、`monitor_http.dart`、`lib/data/model/server/monitor_http_credential.dart`、`monitor_push.dart`、`monitor_settings.dart`、`lib/data/model/server/server_private_info.dart`（Spi 全家）、`lib/core/utils/server_tcp.dart`（ServerTcpDialer，仅 rdp/pve 消费，应已无引用）
- 存储：`PrivateKeyStore`、`HistoryStore`、`ConnectionStatsStore`、`PortForwardStore`、`SelfAddrStore` 等 Spi 系 store（`lib/data/res/store.dart` 注册处 + `lib/data/store/` 对应文件）
- Rust：`crates/` 整目录、根 `Cargo.toml`、`Cargo.lock`、`rust-toolchain.toml`（若在根）、`.gitmodules` 里 dartssh2 条目
- Modify: `pubspec.yaml`（`dartssh2`、`flutter_rust_bridge`、`flutter_rust_bridge_hooks`、`hooks.user_defines.sqlite3` 段——**先看 fl_lib 的 SqliteStore.openDatabase 是否依赖 hook 编译的 sqlite3mc**，是则保留 hooks 段直到 Task 12 一并处理、`pinenacl`/`pointycastle`/`crypto` grep 确认）、`lib/main.dart`（删 `RustLib.init`、`_doDbMigrate` 中 Hive→SQLite 之外的 Rust 逻辑）
- Test: `test/helpers/rust_lib_helper.dart` 删除；`test/unit/ssh/` 中纯 dartssh2 传输层测试一并删（SSH 通道不复存在）；`test/unit/server/` 保留（CF 测试在其中）

- [ ] **Step 1: 删除 + 编译器驱动清理** — 重点：`Stores.init`、`main.dart`、`data_source.dart`（删 script/monitor 两实现与接口本体的 Spi 参数化——`ServerDataSource` 若只剩 CF 用，直接删接口，`cf_api.dart` 不依赖它）、`selection.dart`
- [ ] **Step 2: 验证** — `make analyze && make test`（cargo 测试从此不存在）；`cd android && ./gradlew :app:testDebugUnitTest`
- [ ] **Step 3: 真机回归** — 首页/详情/小组件全过一遍。
- [ ] **Step 4: Commit** — `rm: legacy server stack, transports and rust workspace`

---

### Task 12: 删实体存储层 + 非 Android 平台目录

**Files:**
- Spike 先行：读 `packages/fl_lib` 的 `SqliteStore`/`PrefStore` 源码，回答：**SettingStore（含 ThemeSettings mixin）能否脱离 app 内 SQLite，跑在 fl_lib 的非 SQLite KV 上？**
  - 能 → 分支 A：删 `lib/data/store/` 全部（保留 `setting.dart` 改 extends PrefStore 系基类）、删 drift 依赖与 DDL、删迁移/Hive/备份。
  - 不能（ThemeSettings 强绑 SqliteStore）→ 分支 B：**保留** sqlite3 + fl_lib KV（`kv` 表），只删实体层：`lib/data/store/entity_store.dart`、ServerStore/SnippetStore 等已删剩的实体 store、`lib/data/store/migrations/`、drift DDL（`lib/data/store/` 中 Drift 部分——若 `createTables` 只建 kv 表则 drift 可删）、`lib/hive/`、`lib/data/model/app/bak/`（备份）、`test/fixtures/`、`test/migration/`、`test/unit/store/` 中实体相关。**默认走分支 B**（改动小、加密 KV 照旧、备份功能随实体数据消失自然删除）。
- 平台目录：`ios/`、`macos/`、`linux/`、`windows/`、`third_party/ish-arm64/`、`third_party/proto` **保留**（Android tombstone 解析）
- Modify: `pubspec.yaml`（`drift`/`drift_dev`/分支 A 时 `sqlite3`、`webdav_client_plus`+`icloud_storage_plus`+`watch_connectivity`+`plain_notification_token`+`file_picker`+`archive` 等 grep 后删、`flutter_native_splash` 的 `info_plist_files` 段删 ios 行）、`android/.../MainActivity.kt`（`lastExitInfo`/tombstone 保留；`linuxSystemsChanged`/`nativeLibDir`/proot 相关删）、`fastlane/`/`fdroid/`/`scripts/` 中 iOS/macOS 脚本本次不动（外围）

- [ ] **Step 1: Spike 结论写进本文件勾选处，按分支执行删除**
- [ ] **Step 2: 编译器驱动清理** — `Stores.init`/`main.dart`/`intro.dart`（intro 里 SqliteStore.transact 若分支 B 仍可用则保留）
- [ ] **Step 3: 验证** — `make analyze && make test`；真机：设置改一项 → 杀进程重开 → 设置仍在；小组件/通知不回归。
- [ ] **Step 4: Commit** — `rm: entity storage, migrations, backup and non-android platforms`

---

### Task 13: 导航收缩 + 设置瘦身 + 收尾对齐

**Files:**
- Modify: `lib/data/model/app/tab.dart`（枚举只剩 `server`；`_retiredIndices`/`overflowOf` 简化；`defaultOrder=[server]`）
- Modify: `lib/view/page/home.dart` + `home/nav.dart` + `home/tabs.dart`（单页形态：PageView 保留但只有 1 页；bar 只剩 server 项 + settings trailing；`homeTabs` 设置项删除读取处）
- Modify: `lib/view/page/setting/`（`nodes.dart` 删已裁功能分组：ssh、sftp、container、editor、full_screen、globe、remote_desktop、linux、home_tabs 等 entries part 文件与引用）
- Modify: `lib/intro.dart`（引导步骤删已裁功能项）
- Modify: `lib/data/store/setting.dart`（删除无引用设置项——`grep -rn "setting.<key>" lib` 逐个确认后删行）
- Test: `test/unit/app/` 下 tab/导航相关测试更新

- [ ] **Step 1: AppTab 收缩 + home 三文件简化**（存量数据里旧的 tab 列表解析失败走 `parseAppTabsFromObj` 回退 `defaultOrder=[server]`，无需迁移）
- [ ] **Step 2: 设置瘦身 + intro 修剪**
- [ ] **Step 3: 验证** — `make analyze && make test`；真机：单 tab、设置页无死项、`serverbox://` deep link 不崩。
- [ ] **Step 4: Commit** — `refactor: single tab navigation and slim settings`

---

### Task 14: 依赖清理 + 全量验证 + 出包

**Files:**
- Modify: `pubspec.yaml`（按 `grep -rn "package:xxx" lib test` 逐个确认后删：预期可删 `xterm/flutter_pty/wakelock_plus/desktop_drop/dartssh2/fl_pi_llm*/redfish/watch_connectivity/plain_notification_token/webdav_client_plus/icloud_storage_plus/file_picker/extended_image/flutter_highlight/flutter_markdown_plus/flutter_svg/material_ui/window_manager/easy_isolate/choice(若详情页未用)/responsive_framework(核对)/sentry(或保留崩溃上报——保留)/aptabase(保留)…` 以 grep 结果为准）
- Modify: `assets/`（`distro/` 保留 OS 图标、`geo/` 删 globe 相关代码与资产——globe 页属被裁功能；`catalog/`、`store_themes/` 主题商店保留）
- Modify: `AGENTS.md`、根 `CLAUDE.md`（一句话注明 fork 定位与 CF 数据源；删除指向已裁功能的规则段——最小改动）

- [ ] **Step 1: 依赖逐个 grep 确认后删 + `make deps && make gen`**
- [ ] **Step 2: 全量验证**

```bash
make analyze && make test
cd android && ./gradlew :app:testDebugUnitTest -x :app:compileFlutterBuildDebug && cd ..
make build PLATFORM=android
```

Expected: 全绿；APK 产物生成。

- [ ] **Step 3: 真机验收清单** — 公开站点：列表/详情 7 档/WS 实时/下拉刷新；私有站点（临时切私有）：登录、永久会话（杀进程重开不弹登录）、小组件带 token 取数；三种 4x2 模式 + 2x2 字段自定义；流量/续费通知触发与去重；断网降级与恢复。
- [ ] **Step 4: Commit** — `chore: dependency cleanup and release verification`

---

## Self-Review 记录

- **Spec 覆盖**：决策 1-8 ↔ Task 0-14（硬裁剪=9-12；仅 Android=12；CF 数据源+双模式鉴权=1/2/5；详情对齐=4；通知=8；小组件三模式=6/7；单站点=2 的单 URL 配置；永久会话=Task 1 Step 6 的 exp 前置刷新 + 401 重登录）✓
- **占位符扫描**：无 TBD；Task 12 分支 A/B 是显式 spike 决策点而非占位符（两分支动作都已写明）✓
- **类型一致性**：`CfServersSnapshot/CfServer/CfHistoryRow/CfApi` 在 Task 1 定义、Task 2-5 使用一致；`WidgetField/mode` Task 7 定义、Task 8 复用 publish 通道（不同 payload key，不冲突）✓
