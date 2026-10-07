// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get privacy => 'Gizlilik';

  @override
  String get privacyPolicy => 'Gizlilik politikası';

  @override
  String get crashLastRunFailed =>
      'NodePulse son çalıştırmada beklenmedik şekilde kapandı.';

  @override
  String get crashReportTitle => 'Çökme raporu';

  @override
  String get crashReportHint =>
      'Bu, önceki çalıştırmanın günlüğüdür. Bilinen sunucu adları ve adresleri yer tutucularla değiştirilmiştir, ancak başka ayrıntılar kalmış olabilir. Göndermeden önce dikkatlice okuyun.';

  @override
  String get crashReportSubmit => 'Kopyala ve bildir';

  @override
  String get preReleaseUpdates => 'Ön sürüm güncellemelerini al';

  @override
  String get autoUpdateHomeWidget => 'Ana ekran bileşenini otomatik güncelle';

  @override
  String get backupPassword => 'Yedekleme parolası';

  @override
  String get backupPasswordSet => 'Yedekleme parolası ayarlandı';

  @override
  String get backupPasswordTip =>
      'Yedekleme dosyalarını şifrelemek için bir parola belirleyin. Şifrelemeyi devre dışı bırakmak için boş bırakın.';

  @override
  String get distIcon => 'Dağıtım işaretleri';

  @override
  String get distNameMap => 'Ad eşleştirme';

  @override
  String get globe => 'Küre';

  @override
  String get navTabMenuTip =>
      'İçindeki her şeyi tek seferde bağlamak veya bağlantısını kesmek için bir sekmeye uzun basın ya da sağ tıklayın.';

  @override
  String get remoteBackupPasswordRequired =>
      'Uzak yedeklemeler için boş olmayan bir yedekleme parolası gerekir';

  @override
  String get backupTip =>
      'Dışa aktarılan veriler parola ile şifrelenebilir. \nLütfen güvenli bir şekilde saklayın.';

  @override
  String get bgRun => 'Arka planda çalıştır';

  @override
  String get bgRunTip =>
      'Bu anahtar yalnızca programın arka planda çalışmayı deneyeceği anlamına gelir. Arka planda çalışıp çalışamayacağı, iznin etkinleştirilip etkinleştirilmediğine bağlıdır. AOSP tabanlı Android ROM\'lar için lütfen bu uygulamada \"Pil Optimizasyonu\"nu devre dışı bırakın. MIUI / HyperOS için lütfen güç tasarrufu politikasını \"Sınırsız\" olarak değiştirin.';

  @override
  String get bgRunNeedsNotification =>
      'Arka planda çalışmak kalıcı bir bildirim gerektirir ve bu uygulamanın bildirim izni yok. İzin vermek için dokunun.';

  @override
  String get closeAfterSave => 'Kaydet ve kapat';

  @override
  String get collapseUITip =>
      'Arayüzde uzun listelerin varsayılan olarak daraltılıp daraltılmayacağı';

  @override
  String get distro => 'Dağıtım';

  @override
  String get dockerStatistics => 'Docker İstatistikleri';

  @override
  String get envVars => 'Ortam değişkeni';

  @override
  String get fdroidReleaseTip =>
      'Bu uygulamayı F-Droid\'den indirdiyseniz, bu seçeneği kapatmanız önerilir.';

  @override
  String get fullScreen => 'Tam ekran';

  @override
  String get fullScreenJitter => 'Tam ekran titreşim';

  @override
  String get fullScreenJitterHelp => 'Ekran yanmasını önlemek için';

  @override
  String get fullScreenTip =>
      'Cihaz yatay moda döndürüldüğünde tam ekran modu etkinleştirilsin mi? Bu seçenek yalnızca sunucu sekmesi için geçerlidir.';

  @override
  String get homeTabs => 'Ana Sayfa Sekmeleri';

  @override
  String get image => 'Görüntü';

  @override
  String get sshKeyRecommended => 'Önerilen';

  @override
  String get unused => 'Kullanılmıyor';

  @override
  String get pull => 'Çek';

  @override
  String get needRestart => 'Uygulamanın yeniden başlatılması gerekiyor';

  @override
  String get parseContainerStatsTip =>
      'Docker\'ın doluluk durumunu ayrıştırmak oldukça yavaş.';

  @override
  String get restart => 'Yeniden başlat';

  @override
  String get liveActivity => 'Canlı Etkinlik';

  @override
  String get read => 'Oku';

  @override
  String get second => 's';

  @override
  String get back => 'Geri';

  @override
  String get history => 'Geçmiş';

  @override
  String get homeDir => 'Ana klasör';

  @override
  String selected(int count) {
    return '$count seçildi';
  }

  @override
  String get sftpRmrDirSummary =>
      'SFTP\'de bir klasörü silmek için `rm -r` kullan.';

  @override
  String get syncAppSettings => 'Uygulama ayarlarını eşitle';

  @override
  String get times => 'Kez';

  @override
  String get used => 'Kullanılan';

  @override
  String get wakeLock => 'Uyanık tut';

  @override
  String get write => 'Yaz';

  @override
  String processCount(int count) {
    return '$count işlem';
  }

  @override
  String get services => 'Hizmetler';

  @override
  String get status => 'Durum';

  @override
  String get enable => 'Etkinleştir';

  @override
  String get disable => 'Devre dışı bırak';

  @override
  String get starting => 'Başlatılıyor';

  @override
  String get stopping => 'Durduruluyor';

  @override
  String get power => 'Güç';

  @override
  String get fan => 'Fan';

  @override
  String get vendor => 'Üretici';

  @override
  String get agentLocalExec => 'Bu cihazda komut çalıştır';

  @override
  String get privacyBlur => 'Arka planda gizlilik';

  @override
  String get privacyBlurTip => 'Uygulama değiştiricide içeriği gizle';

  @override
  String get benchmark => 'Performans testi';

  @override
  String get peak => 'tepe';

  @override
  String get hardware => 'Donanım';

  @override
  String get from => 'Başlangıç';

  @override
  String get to => 'Bitiş';

  @override
  String get samples => 'ölçüm';

  @override
  String get unavailable => 'kullanılamıyor';

  @override
  String get stored => 'saklanan';

  @override
  String get oldest => 'en eski';

  @override
  String get attributes => 'öznitelikler';

  @override
  String get cycle => 'Çevrim';

  @override
  String get window => 'pencere';

  @override
  String get connection => 'Bağlantı';

  @override
  String get behaviour => 'Davranış';

  @override
  String get optional => 'İsteğe bağlı';

  @override
  String get alerts => 'Uyarılar';

  @override
  String get online => 'çevrimiçi';

  @override
  String get connect => 'Bağlan';

  @override
  String get move => 'Taşı';

  @override
  String get reduceMotion => 'Hareketi azalt';

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
