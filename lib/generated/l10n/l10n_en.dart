// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get crashCollect => 'Diagnostic data';

  @override
  String get crashCollectIntro =>
      'NodePulse records what happens while it runs so problems can be fixed. Choose how much information to send.';

  @override
  String get crashCollectNone => 'Nothing';

  @override
  String get crashCollectNoneTip =>
      'Reports remain on this device; after a crash, you can send one manually.';

  @override
  String get crashCollectBasic => 'Basic information';

  @override
  String get crashCollectBasicTip =>
      'Only crash information is included; logs and performance data are not. **This helps us improve the app and fix bugs.**';

  @override
  String get crashCollectFull => 'Full information';

  @override
  String get crashCollectFullTip =>
      'Along with the crash log, performance data and which features are used are included: **they show what is slow, and which features are worth keeping.**';

  @override
  String get crashCollectFooter =>
      'At every level, known server names, addresses and usernames are replaced with placeholders when recorded. You can change the collection level later in Settings.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get crashLastRunFailed =>
      'NodePulse exited unexpectedly during its last run.';

  @override
  String get crashReportTitle => 'Crash report';

  @override
  String get crashReportHint =>
      'This is the log from the previous run. Known server names and addresses have been replaced with placeholders, but other details may remain. Please read it carefully before submitting.';

  @override
  String get crashReportSubmit => 'Copy & report';

  @override
  String get preReleaseUpdates => 'Receive pre-release updates';

  @override
  String get autoUpdateHomeWidget => 'Automatic home widget update';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupPasswordSet => 'Backup password set';

  @override
  String get backupPasswordTip =>
      'Set a password to encrypt backup files. Leave empty to disable encryption.';

  @override
  String get distIcon => 'Distribution marks';

  @override
  String get distNameMap => 'Name overrides';

  @override
  String get globe => 'Globe';

  @override
  String get navTabMenuTip =>
      'Long press a tab — or right-click it — to connect or disconnect everything on it at once.';

  @override
  String get remoteBackupPasswordRequired =>
      'Remote backups require a non-empty backup password';

  @override
  String get backupTip =>
      'The exported data can be encrypted with password. \nPlease keep it safe.';

  @override
  String get bgRun => 'Run in background';

  @override
  String get bgRunTip =>
      'This switch only means the program will try to run in the background. Whether it can run in the background depends on whether the permission is enabled or not. For AOSP-based Android ROMs, please disable \"Battery Optimization\" in this app. For MIUI / HyperOS, please change the power saving policy to \"Unlimited\".';

  @override
  String get bgRunNeedsNotification =>
      'Running in the background needs an ongoing notification, and this app has no notification permission. Tap to allow notifications.';

  @override
  String get closeAfterSave => 'Save and close';

  @override
  String get collapseUITip =>
      'Whether to collapse long lists present in the UI by default';

  @override
  String get distro => 'Distribution';

  @override
  String get dockerStatistics => 'Docker Statistics';

  @override
  String get envVars => 'Environment variable';

  @override
  String get fdroidReleaseTip =>
      'If you downloaded this app from F-Droid, it is recommended to turn off this option.';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get fullScreenJitter => 'Full screen jitter';

  @override
  String get fullScreenJitterHelp => 'To avoid screen burn-in';

  @override
  String get fullScreenTip =>
      'Should full-screen mode be enabled when the device is rotated to landscape mode? This option only applies to the server tab.';

  @override
  String get homeTabs => 'Home Tabs';

  @override
  String get image => 'Image';

  @override
  String get sshKeyRecommended => 'Recommended';

  @override
  String get unused => 'Unused';

  @override
  String get pull => 'Pull';

  @override
  String get needRestart => 'App needs to be restarted';

  @override
  String get parseContainerStatsTip =>
      'Parsing the occupancy status of Docker is relatively slow.';

  @override
  String get restart => 'Restart';

  @override
  String get liveActivity => 'Live Activity';

  @override
  String get read => 'Read';

  @override
  String get second => 's';

  @override
  String get back => 'Back';

  @override
  String get history => 'History';

  @override
  String get homeDir => 'Home';

  @override
  String selected(int count) {
    return '$count selected';
  }

  @override
  String get sftpRmrDirSummary => 'Use `rm -r` to delete a folder in SFTP.';

  @override
  String get syncAppSettings => 'Sync app settings';

  @override
  String get times => 'Times';

  @override
  String get used => 'Used';

  @override
  String get wakeLock => 'Keep awake';

  @override
  String get write => 'Write';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processes',
      one: '1 process',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Services';

  @override
  String get status => 'Status';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get starting => 'Starting';

  @override
  String get stopping => 'Stopping';

  @override
  String get power => 'Power';

  @override
  String get fan => 'Fan';

  @override
  String get vendor => 'Vendor';

  @override
  String get agentLocalExec => 'Run commands on this device';

  @override
  String get privacyBlur => 'Background privacy';

  @override
  String get privacyBlurTip => 'Hide app content in the app switcher';

  @override
  String get benchmark => 'Benchmark';

  @override
  String get peak => 'peak';

  @override
  String get hardware => 'Hardware';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get samples => 'samples';

  @override
  String get unavailable => 'unavailable';

  @override
  String get stored => 'stored';

  @override
  String get oldest => 'oldest';

  @override
  String get attributes => 'attributes';

  @override
  String get cycle => 'Cycle';

  @override
  String get window => 'window';

  @override
  String get connection => 'Connection';

  @override
  String get behaviour => 'Behaviour';

  @override
  String get optional => 'Optional';

  @override
  String get alerts => 'Alerts';

  @override
  String get online => 'online';

  @override
  String get connect => 'Connect';

  @override
  String get move => 'Move';

  @override
  String get reduceMotion => 'Reduce motion';

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
