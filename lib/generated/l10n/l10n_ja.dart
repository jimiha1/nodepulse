// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get privacy => 'プライバシー';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get crashLastRunFailed => 'NodePulse は前回の実行中に予期せず終了しました。';

  @override
  String get crashReportTitle => 'クラッシュレポート';

  @override
  String get crashReportHint =>
      'これは前回の実行ログです。既知のサーバー名とアドレスはプレースホルダーに置き換えられていますが、他の情報が残っている場合があります。送信する前によく読んでください。';

  @override
  String get crashReportSubmit => 'コピーして報告';

  @override
  String get preReleaseUpdates => 'プレリリース版の更新を受け取る';

  @override
  String get autoUpdateHomeWidget => 'ホームウィジェットを自動更新';

  @override
  String get backupPassword => 'バックアップパスワード';

  @override
  String get backupPasswordSet => 'バックアップパスワードが設定されました';

  @override
  String get backupPasswordTip =>
      'バックアップファイルを暗号化するためのパスワードを設定してください。暗号化を無効にするには空白のままにしてください。';

  @override
  String get distIcon => 'ディストリビューション標識';

  @override
  String get distNameMap => '名前の対応付け';

  @override
  String get globe => '地球儀';

  @override
  String get navTabMenuTip => 'タブを長押し（マウスは右クリック）すると、その中のすべてをまとめて接続・切断できます。';

  @override
  String get remoteBackupPasswordRequired => 'リモートバックアップには空でないバックアップパスワードが必要です';

  @override
  String get backupTip => 'エクスポートされたデータはパスワードで暗号化できます。 \n適切に保管してください。';

  @override
  String get bgRun => 'バックグラウンド実行';

  @override
  String get bgRunTip =>
      'このスイッチはプログラムがバックグラウンドで実行を試みることを意味しますが、実際にバックグラウンドで実行できるかどうかは、権限が有効になっているかに依存します。AOSPベースのAndroid ROMでは、このアプリの「バッテリー最適化」をオフにしてください。MIUIでは、省エネモードを「無制限」に変更してください。';

  @override
  String get bgRunNeedsNotification =>
      'バックグラウンド実行には常駐通知が必要ですが、このアプリには通知の許可がありません。タップして通知を許可してください。';

  @override
  String get closeAfterSave => '保存して閉じる';

  @override
  String get collapseUITip => 'UIの長いリストをデフォルトで折りたたむかどうか';

  @override
  String get distro => 'ディストリビューション';

  @override
  String get dockerStatistics => 'Docker 統計';

  @override
  String get envVars => '環境変数';

  @override
  String get fdroidReleaseTip =>
      'このアプリをF-Droidからダウンロードした場合、このオプションをオフにすることをお勧めします。';

  @override
  String get fullScreen => 'フルスクリーン';

  @override
  String get fullScreenJitter => 'フルスクリーンモードのジッター';

  @override
  String get fullScreenJitterHelp => '焼き付き防止';

  @override
  String get fullScreenTip =>
      'デバイスが横向きに回転したときにフルスクリーンモードを有効にしますか？このオプションはサーバータブにのみ適用されます。';

  @override
  String get homeTabs => 'ホームタブ';

  @override
  String get image => 'イメージ';

  @override
  String get sshKeyRecommended => '推奨';

  @override
  String get unused => '未使用';

  @override
  String get pull => 'プル';

  @override
  String get needRestart => 'アプリを再起動する必要があります';

  @override
  String get parseContainerStatsTip => 'Dockerの使用状況の解析は比較的遅いです';

  @override
  String get restart => '再起動';

  @override
  String get liveActivity => 'ライブアクティビティ';

  @override
  String get read => '読み取り';

  @override
  String get second => '秒';

  @override
  String get back => '戻る';

  @override
  String get history => '履歴';

  @override
  String get homeDir => 'ホーム';

  @override
  String selected(int count) {
    return '$count 件選択';
  }

  @override
  String get sftpRmrDirSummary => 'SFTPで`rm -r`を使用してフォルダーを削除';

  @override
  String get syncAppSettings => 'アプリ設定を同期';

  @override
  String get times => '回';

  @override
  String get used => '使用済み';

  @override
  String get wakeLock => '起動を保つ';

  @override
  String get write => '書き込み';

  @override
  String processCount(int count) {
    return '$count 件のプロセス';
  }

  @override
  String get services => 'サービス';

  @override
  String get status => '状態';

  @override
  String get enable => '有効化';

  @override
  String get disable => '無効化';

  @override
  String get starting => '起動中';

  @override
  String get stopping => '停止中';

  @override
  String get power => '電源';

  @override
  String get fan => 'ファン';

  @override
  String get vendor => 'ベンダー';

  @override
  String get agentLocalExec => 'このデバイスでコマンドを実行';

  @override
  String get privacyBlur => 'バックグラウンドのプライバシー';

  @override
  String get privacyBlurTip => 'Appスイッチャーで内容を隠す';

  @override
  String get benchmark => 'ベンチマーク';

  @override
  String get peak => 'ピーク';

  @override
  String get hardware => 'ハードウェア';

  @override
  String get from => '開始';

  @override
  String get to => '終了';

  @override
  String get samples => 'サンプル';

  @override
  String get unavailable => '取得できません';

  @override
  String get stored => '保存済み';

  @override
  String get oldest => '最長';

  @override
  String get attributes => '属性';

  @override
  String get cycle => 'サイクル';

  @override
  String get window => '期間';

  @override
  String get connection => '接続';

  @override
  String get behaviour => '動作';

  @override
  String get optional => '任意';

  @override
  String get alerts => 'アラート';

  @override
  String get online => 'オンライン';

  @override
  String get connect => '接続';

  @override
  String get move => '移動';

  @override
  String get reduceMotion => '視差効果を減らす';

  @override
  String get cfSite => 'CF Monitor Site';

  @override
  String get cfSiteUrlHint => 'https://status.example.com';

  @override
  String get cfSiteHttpsRequired =>
      'The site must be an HTTPS address. A password sent over HTTP travels in the clear.';

  @override
  String get cfAuth => 'Login required';

  @override
  String get cfUsername => 'Username';

  @override
  String get cfPassword => 'Password';

  @override
  String get cfTestConnection => 'Test connection';

  @override
  String cfTestOk(int n) {
    return 'Connected, $n servers';
  }

  @override
  String get cfTestFail => 'Connection failed';

  @override
  String get cfNeedLogin => 'This site needs a login';

  @override
  String get cfOpenSettings => 'Open settings';

  @override
  String get cfNoSite => 'No monitor site yet';

  @override
  String get cfNoSiteTip =>
      'Add the address of your CF-Server-Monitor site to see its nodes here.';

  @override
  String get cfOverviewOnline => 'Online';

  @override
  String get cfOverviewBandwidth => 'Bandwidth';

  @override
  String get cfLoad => 'Load';

  @override
  String get cfTrafficRemaining => 'Traffic left';

  @override
  String get cfExpire => 'Expires';

  @override
  String get cfRangeLive => 'Live';

  @override
  String get cfRangeM30 => '30m';

  @override
  String get cfRangeH1 => '1h';

  @override
  String get cfRangeH6 => '6h';

  @override
  String get cfRangeD1 => '1d';

  @override
  String get cfRangeD2 => '2d';

  @override
  String get cfRangeD7 => '7d';

  @override
  String get cfChartCpu => 'CPU Usage';

  @override
  String get cfChartMem => 'Memory & Swap';

  @override
  String get cfChartDisk => 'Disk Used';

  @override
  String get cfChartNet => 'Network Speed';

  @override
  String get cfChartLoad => 'System Load';

  @override
  String get cfChartDiskIo => 'Disk IO';

  @override
  String get cfChartConn => 'Connections';

  @override
  String get cfChartProcess => 'Processes';

  @override
  String get cfAlerts => 'Node alerts';

  @override
  String get cfAlertsTip =>
      'Periodic checks for traffic usage and node expiration';

  @override
  String get cfAlertTrafficPct => 'Traffic alert threshold';

  @override
  String get cfAlertExpiryDays => 'Advance expiration notice';

  @override
  String cfAlertDaysFmt(int days) {
    return '$days days';
  }

  @override
  String get cfResourceAlerts => 'Resource alert rules';

  @override
  String get cfResourceAlertsEmpty =>
      'No rules yet. Tap + to add one, for example \"CPU over 80% for 5 minutes\".';

  @override
  String get cfResourceAlertsTip =>
      'Checked in the background every 15 minutes against the site\'s history';

  @override
  String get cfResourceRuleNew => 'New rule';

  @override
  String get cfResourceRuleEdit => 'Edit rule';

  @override
  String get cfResourceRuleDelete => 'Delete rule';

  @override
  String cfResourceRuleDeleteConfirm(String name) {
    return 'Delete the rule \"$name\"?';
  }

  @override
  String get cfResourceRuleName => 'Name';

  @override
  String get cfResourceRuleNameHint => 'e.g. CPU too high';

  @override
  String get cfResourceRuleMetric => 'Metric';

  @override
  String get cfResourceRuleThreshold => 'Threshold';

  @override
  String get cfResourceRuleServer => 'Server';

  @override
  String get cfResourceRuleServerAll => 'All servers';

  @override
  String get cfResourceRuleWindow => 'Window';

  @override
  String get cfResourceRuleTrigger => 'Trigger';

  @override
  String get cfResourceRuleThresholdRequired => 'Enter a threshold';

  @override
  String get cfResourceRuleThresholdPositive =>
      'The threshold must be greater than 0';

  @override
  String get cfResourceRuleThresholdOver100 =>
      'A percentage threshold over 100 can never fire. Save anyway?';

  @override
  String get cfResourceRuleServerGone => 'Server no longer exists';

  @override
  String cfResourceRuleSummaryAvg(String metric, int window, String threshold) {
    return '$metric · mean over $window min > $threshold';
  }

  @override
  String cfResourceRuleSummaryAll(String metric, int window, String threshold) {
    return '$metric · every sample in $window min > $threshold';
  }

  @override
  String get cfResourceMetricCpu => 'CPU';

  @override
  String get cfResourceMetricRam => 'Memory';

  @override
  String get cfResourceMetricDisk => 'Disk';

  @override
  String get cfResourceMetricNetIn => 'Net in';

  @override
  String get cfResourceMetricNetOut => 'Net out';

  @override
  String get cfResourceTriggerAvg => 'Window average over threshold';

  @override
  String get cfResourceTriggerAll => 'Every sample over threshold';

  @override
  String cfResourceWindowFmt(int minutes) {
    return '$minutes min';
  }

  @override
  String get cfAlertCheckNow => 'Check now';

  @override
  String cfAlertCheckOk(int count, int notified) {
    return 'Checked $count nodes, $notified alert(s) sent';
  }

  @override
  String get cfAlertCheckNoSite => 'Set the site address first';

  @override
  String get cfAlertCheckNoToken =>
      'Log in to the site first, so the check can read it';

  @override
  String get cfAlertCheckAuth =>
      'The site rejected the stored login — reopen this page to sign in again';

  @override
  String get cfAlertCheckNetwork => 'Could not reach the site';

  @override
  String cfAlertCheckClear(int count) {
    return 'Checked $count nodes, nothing to alert about';
  }

  @override
  String cfAlertCheckSuppressed(int count) {
    return 'Checked $count nodes, already reminded today';
  }
}
