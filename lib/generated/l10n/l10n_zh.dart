// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get privacy => '隐私';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get crashLastRunFailed => 'NodePulse 上次运行时异常退出。';

  @override
  String get crashReportTitle => '崩溃报告';

  @override
  String get crashReportHint =>
      '这是上次运行的日志。已知的服务器名称和地址已替换为占位符，但其中可能仍包含其他信息。提交前请仔细阅读。';

  @override
  String get crashReportSubmit => '复制并反馈';

  @override
  String get preReleaseUpdates => '接收预发布版本更新';

  @override
  String get autoUpdateHomeWidget => '自动更新桌面小部件';

  @override
  String get backupPassword => '备份密码';

  @override
  String get backupPasswordSet => '备份密码已设置';

  @override
  String get backupPasswordTip => '设置密码以加密备份文件。留空则禁用加密。';

  @override
  String get distIcon => '发行版标识';

  @override
  String get distNameMap => '名称映射';

  @override
  String get globe => '地球仪';

  @override
  String get navTabMenuTip => '长按标签栏图标（鼠标右键点击）可一次性连接或断开其中的全部内容。';

  @override
  String get remoteBackupPasswordRequired => '远程备份需要非空的备份密码';

  @override
  String get backupTip => '导出数据可通过密码加密，请妥善保管。';

  @override
  String get bgRun => '后台运行';

  @override
  String get bgRunTip =>
      '此开关只代表程序会尝试在后台运行，具体能否后台运行取决于是否开启了权限。原生 Android 请关闭本 App 的“电池优化”，MIUI / HyperOS 请将省电策略改为“无限制”。';

  @override
  String get bgRunNeedsNotification => '后台运行需要显示常驻通知，但 App 尚未获得通知权限。点击授权。';

  @override
  String get closeAfterSave => '保存后关闭';

  @override
  String get collapseUITip => '是否默认折叠 UI 中的长列表';

  @override
  String get distro => '发行版';

  @override
  String get dockerStatistics => 'Docker 统计';

  @override
  String get envVars => '环境变量';

  @override
  String get fdroidReleaseTip => '如果你是从 F-Droid 下载的本应用，推荐关闭此选项';

  @override
  String get fullScreen => '全屏';

  @override
  String get fullScreenJitter => '全屏模式抖动';

  @override
  String get fullScreenJitterHelp => '用于防止屏幕烧屏';

  @override
  String get fullScreenTip => '当设备旋转为横屏时，是否开启全屏模式。此选项仅作用于服务器 Tab 页。';

  @override
  String get homeTabs => '主页标签';

  @override
  String get image => '镜像';

  @override
  String get sshKeyRecommended => '推荐';

  @override
  String get unused => '未使用';

  @override
  String get pull => '拉取';

  @override
  String get needRestart => '需要重启 App';

  @override
  String get parseContainerStatsTip => 'Docker 解析占用状态较为缓慢';

  @override
  String get restart => '重启';

  @override
  String get liveActivity => '实时活动';

  @override
  String get read => '读';

  @override
  String get second => '秒';

  @override
  String get back => '返回';

  @override
  String get history => '历史';

  @override
  String get homeDir => '主目录';

  @override
  String selected(int count) {
    return '已选 $count 项';
  }

  @override
  String get sftpRmrDirSummary => '在 SFTP 中使用 `rm -r` 来删除文件夹';

  @override
  String get syncAppSettings => '同步应用设置';

  @override
  String get times => '次';

  @override
  String get used => '已用';

  @override
  String get wakeLock => '保持唤醒';

  @override
  String get write => '写';

  @override
  String processCount(int count) {
    return '$count 个进程';
  }

  @override
  String get services => '服务';

  @override
  String get status => '状态';

  @override
  String get enable => '启用';

  @override
  String get disable => '禁用';

  @override
  String get starting => '启动中';

  @override
  String get stopping => '停止中';

  @override
  String get power => '电源';

  @override
  String get fan => '风扇';

  @override
  String get vendor => '厂商';

  @override
  String get agentLocalExec => '在本机执行命令';

  @override
  String get privacyBlur => '后台隐私保护';

  @override
  String get privacyBlurTip => '在多任务界面隐藏应用内容';

  @override
  String get benchmark => '性能测试';

  @override
  String get peak => '峰值';

  @override
  String get hardware => '硬件';

  @override
  String get from => '起';

  @override
  String get to => '止';

  @override
  String get samples => '采样';

  @override
  String get unavailable => '不可用';

  @override
  String get stored => '已存储';

  @override
  String get oldest => '最久';

  @override
  String get attributes => '属性';

  @override
  String get cycle => '循环次数';

  @override
  String get window => '窗口';

  @override
  String get connection => '连接方式';

  @override
  String get behaviour => '行为';

  @override
  String get optional => '可选';

  @override
  String get alerts => '告警';

  @override
  String get online => '在线';

  @override
  String get connect => '连接';

  @override
  String get move => '移动';

  @override
  String get reduceMotion => '减少动态效果';

  @override
  String get cfSite => 'CF 监控站点';

  @override
  String get cfSiteUrlHint => 'https://status.example.com';

  @override
  String get cfSiteHttpsRequired => '站点地址必须是 HTTPS。使用 HTTP 时密码会以明文发送。';

  @override
  String get cfAuth => '站点需要登录';

  @override
  String get cfUsername => '用户名';

  @override
  String get cfPassword => '密码';

  @override
  String get cfTestConnection => '测试连接';

  @override
  String cfTestOk(int n) {
    return '连接成功，$n 台服务器';
  }

  @override
  String get cfTestFail => '连接失败';

  @override
  String get cfNeedLogin => '该站点需要登录';

  @override
  String get cfOpenSettings => '打开设置';

  @override
  String get cfNoSite => '还没有监控站点';

  @override
  String get cfNoSiteTip => '填写你的 CF-Server-Monitor 站点地址，这里就会显示节点。';

  @override
  String get cfOverviewOnline => '在线';

  @override
  String get cfOverviewBandwidth => '总带宽';

  @override
  String get cfLoad => '负载';

  @override
  String get cfTrafficRemaining => '剩余流量';

  @override
  String get cfExpire => '到期';

  @override
  String get cfRangeLive => '实时';

  @override
  String get cfRangeM30 => '30分钟';

  @override
  String get cfRangeH1 => '1小时';

  @override
  String get cfRangeH6 => '6小时';

  @override
  String get cfRangeD1 => '1天';

  @override
  String get cfRangeD2 => '2天';

  @override
  String get cfRangeD7 => '7天';

  @override
  String get cfChartCpu => 'CPU 使用率';

  @override
  String get cfChartMem => '内存与 Swap';

  @override
  String get cfChartDisk => '磁盘使用';

  @override
  String get cfChartNet => '网络速率';

  @override
  String get cfChartLoad => '系统负载';

  @override
  String get cfChartDiskIo => '磁盘 IO';

  @override
  String get cfChartConn => '连接数';

  @override
  String get cfChartProcess => '进程数';

  @override
  String get cfAlerts => '节点告警通知';

  @override
  String get cfAlertsTip => '后台定时轮询检测流量使用率与节点到期时间';

  @override
  String get cfAlertTrafficPct => '流量告警阈值';

  @override
  String get cfAlertExpiryDays => '到期提前通知天数';

  @override
  String cfAlertDaysFmt(int days) {
    return '$days 天';
  }

  @override
  String get cfResourceAlerts => '资源告警规则';

  @override
  String get cfResourceAlertsEmpty => '还没有规则。点右下角新建一条，例如「CPU 超过 80% 持续 5 分钟」。';

  @override
  String get cfResourceAlertsTip => '后台每 15 分钟检查一次，取站点历史数据判断窗口是否超标';

  @override
  String get cfResourceRuleNew => '新建规则';

  @override
  String get cfResourceRuleEdit => '编辑规则';

  @override
  String get cfResourceRuleDelete => '删除规则';

  @override
  String cfResourceRuleDeleteConfirm(String name) {
    return '删除规则「$name」？';
  }

  @override
  String get cfResourceRuleName => '名称';

  @override
  String get cfResourceRuleNameHint => '例如：CPU 过高（挖矿排查）';

  @override
  String get cfResourceRuleMetric => '监控项';

  @override
  String get cfResourceRuleThreshold => '阈值';

  @override
  String get cfResourceRuleServer => '服务器';

  @override
  String get cfResourceRuleServerAll => '全部服务器';

  @override
  String get cfResourceRuleWindow => '窗口时间';

  @override
  String get cfResourceRuleTrigger => '触发方式';

  @override
  String get cfResourceRuleThresholdRequired => '请填写阈值';

  @override
  String get cfResourceRuleThresholdPositive => '阈值必须大于 0';

  @override
  String get cfResourceRuleThresholdOver100 => '百分比阈值超过 100 将永远不会触发，确认要保存吗？';

  @override
  String get cfResourceRuleServerGone => '服务器已不存在';

  @override
  String cfResourceRuleSummaryAvg(String metric, int window, String threshold) {
    return '$metric · $window分钟窗口均值 > $threshold';
  }

  @override
  String cfResourceRuleSummaryAll(String metric, int window, String threshold) {
    return '$metric · $window分钟窗口全部样本 > $threshold';
  }

  @override
  String get cfResourceMetricCpu => 'CPU';

  @override
  String get cfResourceMetricRam => '内存';

  @override
  String get cfResourceMetricDisk => '磁盘';

  @override
  String get cfResourceMetricNetIn => '入站网速';

  @override
  String get cfResourceMetricNetOut => '出站网速';

  @override
  String get cfResourceTriggerAvg => '窗口平均值超过阈值';

  @override
  String get cfResourceTriggerAll => '窗口内全部样本超过阈值';

  @override
  String cfResourceWindowFmt(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get cfAlertCheckNow => '立即检查';

  @override
  String cfAlertCheckOk(int count, int notified) {
    return '已检查 $count 个节点，发送 $notified 条告警';
  }

  @override
  String get cfAlertCheckNoSite => '请先填写站点地址';

  @override
  String get cfAlertCheckNoToken => '请先登录站点，否则无法读取';

  @override
  String get cfAlertCheckAuth => '站点拒绝了已保存的登录，请重新打开本页登录';

  @override
  String get cfAlertCheckNetwork => '无法连接到站点';

  @override
  String cfAlertCheckClear(int count) {
    return '已检查 $count 个节点，一切正常';
  }

  @override
  String cfAlertCheckSuppressed(int count) {
    return '已检查 $count 个节点，今日已提醒过';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get privacy => '隱私';

  @override
  String get privacyPolicy => '隱私權政策';

  @override
  String get crashLastRunFailed => 'NodePulse 上次執行時異常結束。';

  @override
  String get crashReportTitle => '當機報告';

  @override
  String get crashReportHint =>
      '這是上次執行的日誌。已知的伺服器名稱和位址已替換為預留位置，但其中可能仍包含其他資訊。提交前請仔細閱讀。';

  @override
  String get crashReportSubmit => '複製並回報';

  @override
  String get preReleaseUpdates => '接收預發布版本更新';

  @override
  String get autoUpdateHomeWidget => '自動更新桌面小工具';

  @override
  String get backupPassword => '備份密碼';

  @override
  String get backupPasswordSet => '備份密碼已設定';

  @override
  String get backupPasswordTip => '設定密碼來加密備份檔案。留空則停用加密。';

  @override
  String get distIcon => '發行版標識';

  @override
  String get distNameMap => '名稱對應';

  @override
  String get globe => '地球儀';

  @override
  String get navTabMenuTip => '長按標籤列圖示（滑鼠右鍵點選）可一次連線或斷開其中的全部項目。';

  @override
  String get remoteBackupPasswordRequired => '遠端備份需要非空的備份密碼';

  @override
  String get backupTip => '匯出的資料可透過密碼加密，請妥善保管。';

  @override
  String get bgRun => '背景執行';

  @override
  String get bgRunTip =>
      '此開關僅代表程式會嘗試於背景執行，能否成功取決於系統權限。在原生 Android 上，請關閉本應用的「電池最佳化」；在 MIUI / HyperOS 上，請將省電策略調整為「無限制」。';

  @override
  String get bgRunNeedsNotification => '背景執行需要顯示常駐通知，但 App 尚未取得通知權限。點一下即可授權。';

  @override
  String get closeAfterSave => '儲存後關閉';

  @override
  String get collapseUITip => '是否預設折疊 UI 中存在的長列表';

  @override
  String get distro => '發行版';

  @override
  String get dockerStatistics => 'Docker 統計';

  @override
  String get envVars => '環境變數';

  @override
  String get fdroidReleaseTip => '如果你是從 F-Droid 下載的本App，推薦關閉此選項';

  @override
  String get fullScreen => '全螢幕';

  @override
  String get fullScreenJitter => '全螢幕模式抖動';

  @override
  String get fullScreenJitterHelp => '防止螢幕烙印';

  @override
  String get fullScreenTip => '當設備旋轉為橫向時，是否開啟全螢幕模式？此選項僅適用於伺服器分頁。';

  @override
  String get homeTabs => '主頁標籤';

  @override
  String get image => '映像檔';

  @override
  String get sshKeyRecommended => '推薦';

  @override
  String get unused => '未使用';

  @override
  String get pull => '拉取';

  @override
  String get needRestart => '需要重開 App';

  @override
  String get parseContainerStatsTip => 'Docker 解析消耗狀態較為緩慢';

  @override
  String get restart => '重新啟動';

  @override
  String get liveActivity => '即時動態';

  @override
  String get read => '讀取';

  @override
  String get second => '秒';

  @override
  String get back => '返回';

  @override
  String get history => '歷史';

  @override
  String get homeDir => '主目錄';

  @override
  String selected(int count) {
    return '已選 $count 項';
  }

  @override
  String get sftpRmrDirSummary => '在 SFTP 中使用 `rm -r` 來刪除檔案夾';

  @override
  String get syncAppSettings => '同步 App 設定';

  @override
  String get times => '次';

  @override
  String get used => '已使用';

  @override
  String get wakeLock => '保持喚醒';

  @override
  String get write => '寫入';

  @override
  String processCount(int count) {
    return '$count 個處理程序';
  }

  @override
  String get services => '服務';

  @override
  String get status => '狀態';

  @override
  String get enable => '啟用';

  @override
  String get disable => '停用';

  @override
  String get starting => '啟動中';

  @override
  String get stopping => '停止中';

  @override
  String get power => '電源';

  @override
  String get fan => '風扇';

  @override
  String get vendor => '廠商';

  @override
  String get agentLocalExec => '在本機執行命令';

  @override
  String get privacyBlur => '背景隱私保護';

  @override
  String get privacyBlurTip => '在多工介面隱藏應用內容';

  @override
  String get benchmark => '效能測試';

  @override
  String get peak => '峰值';

  @override
  String get hardware => '硬體';

  @override
  String get from => '起';

  @override
  String get to => '迄';

  @override
  String get samples => '取樣';

  @override
  String get unavailable => '無法取得';

  @override
  String get stored => '已儲存';

  @override
  String get oldest => '最久';

  @override
  String get attributes => '屬性';

  @override
  String get cycle => '循環次數';

  @override
  String get window => '視窗';

  @override
  String get connection => '連線方式';

  @override
  String get behaviour => '行為';

  @override
  String get optional => '選用';

  @override
  String get alerts => '警示';

  @override
  String get online => '線上';

  @override
  String get connect => '連線';

  @override
  String get move => '移動';

  @override
  String get reduceMotion => '減少動態效果';
}
