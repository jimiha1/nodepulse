// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get crashCollect => 'Diaqnostika məlumatları';

  @override
  String get crashCollectIntro =>
      'NodePulse problemləri aradan qaldırmaq üçün işləyərkən baş verənləri qeydə alır. Göndəriləcək məlumatın həcmini seç.';

  @override
  String get crashCollectNone => 'Heç nə';

  @override
  String get crashCollectNoneTip =>
      'Hesabatlar bu cihazda qalır; qəza baş verdikdən sonra hesabatı əl ilə göndərə bilərsən.';

  @override
  String get crashCollectBasic => 'Əsas məlumatlar';

  @override
  String get crashCollectBasicTip =>
      'Yalnız qəza məlumatları daxil edilir; jurnallar və məhsuldarlıq məlumatları daxil edilmir. **Bu, tətbiqi təkmilləşdirməyimizə və xətaları düzəltməyimizə kömək edir.**';

  @override
  String get crashCollectFull => 'Tam məlumatlar';

  @override
  String get crashCollectFullTip =>
      'Qəza jurnalı ilə yanaşı məhsuldarlıq məlumatları və hansı funksiyaların istifadə olunduğu da daxil edilir: **bunlar nəyin yavaş işlədiyini və hansı funksiyaları saxlamağa dəyər olduğunu göstərir.**';

  @override
  String get crashCollectFooter =>
      'Bütün səviyyələrdə məlum server adları, ünvanlar və istifadəçi adları qeydə alınarkən yer tutucularla əvəz olunur. Məlumat toplama səviyyəsini daha sonra parametrlərdə dəyişə bilərsən.';

  @override
  String get privacy => 'Məxfilik';

  @override
  String get privacyPolicy => 'Məxfilik siyasəti';

  @override
  String get crashLastRunFailed =>
      'NodePulse son dəfə işləyərkən gözlənilmədən bağlandı.';

  @override
  String get crashReportTitle => 'Qəza hesabatı';

  @override
  String get crashReportHint =>
      'Bu, əvvəlki işə salınmanın jurnalıdır. Məlum server adları və ünvanları yer tutucularla əvəz olunub, lakin başqa təfərrüatlar qala bilər. Göndərməzdən əvvəl diqqətlə oxu.';

  @override
  String get crashReportSubmit => 'Kopyala və bildir';

  @override
  String get preReleaseUpdates => 'Önizləmə versiyası yeniləmələrini qəbul et';

  @override
  String get autoUpdateHomeWidget =>
      'Ana ekran vidcetinin avtomatik yenilənməsi';

  @override
  String get backupPassword => 'Ehtiyat nüsxə parolu';

  @override
  String get backupPasswordSet => 'Ehtiyat nüsxə parolu təyin edildi';

  @override
  String get backupPasswordTip =>
      'Ehtiyat nüsxə fayllarını şifrələmək üçün parol təyin et. Şifrələməni söndürmək üçün boş saxla.';

  @override
  String get distIcon => 'Distributiv nişanları';

  @override
  String get distNameMap => 'Ad əvəzləmələri';

  @override
  String get globe => 'Qlobus';

  @override
  String get navTabMenuTip =>
      'Vərəqdəki hər şeylə birdəfəyə əlaqə qurmaq və ya əlaqəni kəsmək üçün vərəqi basıb saxla və ya sağ kliklə.';

  @override
  String get remoteBackupPasswordRequired =>
      'Uzaq ehtiyat nüsxələr üçün boş olmayan ehtiyat nüsxə parolu tələb olunur';

  @override
  String get backupTip =>
      'İxrac edilən məlumatlar parolla şifrələnə bilər. \nOnları təhlükəsiz yerdə saxla.';

  @override
  String get bgRun => 'Arxa planda işlət';

  @override
  String get bgRunTip =>
      'Bu keçid yalnız proqramın arxa planda işləməyə cəhd edəcəyini bildirir. Arxa planda işləyə bilməsi müvafiq icazənin aktiv olub-olmamasından asılıdır. AOSP əsaslı Android ROM sistemlərində bu tətbiq üçün \"Batareya optimallaşdırması\" funksiyasını söndür. MIUI / HyperOS üçün enerjiyə qənaət siyasətini \"Məhdudiyyətsiz\" olaraq dəyiş.';

  @override
  String get bgRunNeedsNotification =>
      'Arxa planda işləmək üçün daimi bildiriş lazımdır, lakin tətbiqin bildiriş icazəsi yoxdur. Bildirişlərə icazə vermək üçün toxun.';

  @override
  String get closeAfterSave => 'Yadda saxla və bağla';

  @override
  String get collapseUITip =>
      'İnterfeysdəki uzun siyahıların standart olaraq yığılması';

  @override
  String get distro => 'Distributiv';

  @override
  String get dockerStatistics => 'Docker statistikası';

  @override
  String get envVars => 'Mühit dəyişəni';

  @override
  String get fdroidReleaseTip =>
      'Bu tətbiqi F-Droid vasitəsilə endirmisənsə, bu seçimi söndürmək tövsiyə olunur.';

  @override
  String get fullScreen => 'Tam ekran';

  @override
  String get fullScreenJitter => 'Tam ekranda kiçik yerdəyişmələr';

  @override
  String get fullScreenJitterHelp =>
      'Ekranda qalıcı iz yaranmasının qarşısını almaq üçün';

  @override
  String get fullScreenTip =>
      'Cihaz üfüqi vəziyyətə çevrildikdə tam ekran rejimi aktivləşdirilsin? Bu seçim yalnız server vərəqinə aiddir.';

  @override
  String get homeTabs => 'Ana səhifə vərəqləri';

  @override
  String get image => 'Obraz';

  @override
  String get sshKeyRecommended => 'Tövsiyə olunur';

  @override
  String get unused => 'İstifadə olunmur';

  @override
  String get pull => 'Çək';

  @override
  String get needRestart => 'Tətbiq yenidən başladılmalıdır';

  @override
  String get parseContainerStatsTip =>
      'Docker resurs istifadəsi vəziyyətinin təhlili nisbətən yavaşdır.';

  @override
  String get restart => 'Yenidən başlat';

  @override
  String get liveActivity => 'Canlı fəaliyyət';

  @override
  String get read => 'Oxu';

  @override
  String get second => 'san';

  @override
  String get back => 'Geri qayıt';

  @override
  String get history => 'Tarixçə';

  @override
  String get homeDir => 'Ev qovluğu';

  @override
  String selected(int count) {
    return '$count seçilib';
  }

  @override
  String get sftpRmrDirSummary =>
      'SFTP daxilində qovluğu silmək üçün `rm -r` istifadə et.';

  @override
  String get syncAppSettings => 'Tətbiq parametrlərini sinxronlaşdır';

  @override
  String get times => 'Dəfə';

  @override
  String get used => 'İstifadə olunur';

  @override
  String get wakeLock => 'Oyaq saxla';

  @override
  String get write => 'Yaz';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proses',
      one: '1 proses',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Servislər';

  @override
  String get status => 'Vəziyyət';

  @override
  String get enable => 'Aktivləşdir';

  @override
  String get disable => 'Söndür';

  @override
  String get starting => 'Başladılır';

  @override
  String get stopping => 'Dayandırılır';

  @override
  String get power => 'Güc';

  @override
  String get fan => 'Ventilyator';

  @override
  String get vendor => 'İstehsalçı';

  @override
  String get agentLocalExec => 'Bu cihazda əmrlər icra et';

  @override
  String get privacyBlur => 'Arxa planda məxfilik';

  @override
  String get privacyBlurTip =>
      'Tətbiqlər arasında keçid ekranında tətbiqin məzmununu gizlət';

  @override
  String get benchmark => 'Benchmark';

  @override
  String get peak => 'pik';

  @override
  String get hardware => 'Avadanlıq';

  @override
  String get from => 'Başlanğıc';

  @override
  String get to => 'Son';

  @override
  String get samples => 'ölçmə';

  @override
  String get unavailable => 'mövcud deyil';

  @override
  String get stored => 'saxlanılan';

  @override
  String get oldest => 'ən köhnə';

  @override
  String get attributes => 'atributlar';

  @override
  String get cycle => 'Dövr';

  @override
  String get window => 'pəncərə';

  @override
  String get connection => 'Bağlantı';

  @override
  String get behaviour => 'Davranış';

  @override
  String get optional => 'İstəyə bağlı';

  @override
  String get alerts => 'Xəbərdarlıqlar';

  @override
  String get online => 'onlayn';

  @override
  String get connect => 'Qoşul';

  @override
  String get move => 'Köçür';

  @override
  String get reduceMotion => 'Hərəkəti azalt';

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
