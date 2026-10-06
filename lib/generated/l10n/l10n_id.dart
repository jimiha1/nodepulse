// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get crashCollect => 'Data diagnostik';

  @override
  String get crashCollectIntro =>
      'NodePulse mencatat apa yang terjadi saat berjalan agar masalah dapat diperbaiki. Pilih jumlah informasi yang dikirim.';

  @override
  String get crashCollectNone => 'Tidak ada';

  @override
  String get crashCollectNoneTip =>
      'Laporan tetap tersimpan di perangkat ini; setelah terjadi kerusakan, Anda dapat mengirimkannya secara manual.';

  @override
  String get crashCollectBasic => 'Informasi dasar';

  @override
  String get crashCollectBasicTip =>
      'Hanya informasi kerusakan yang disertakan; log dan data performa tidak disertakan. **Ini membantu kami menyempurnakan aplikasi dan memperbaiki bug.**';

  @override
  String get crashCollectFull => 'Informasi lengkap';

  @override
  String get crashCollectFullTip =>
      'Selain log kerusakan, data performa dan penggunaan fitur juga disertakan: **Berguna untuk menemukan apa yang lambat dan fitur mana yang benar-benar dipakai.**';

  @override
  String get crashCollectFooter =>
      'Pada tingkat apa pun, nama server yang dikenal beserta alamat dan nama penggunanya diganti dengan placeholder saat dicatat. Tingkat pengumpulan dapat diubah nanti di Pengaturan.';

  @override
  String get privacy => 'Privasi';

  @override
  String get privacyPolicy => 'Kebijakan privasi';

  @override
  String get crashLastRunFailed =>
      'NodePulse berhenti secara tak terduga saat terakhir dijalankan.';

  @override
  String get crashReportTitle => 'Laporan kerusakan';

  @override
  String get crashReportHint =>
      'Ini adalah log dari sesi sebelumnya. Nama dan alamat server yang dikenal telah diganti dengan placeholder, tetapi detail lain mungkin tersisa. Baca dengan saksama sebelum mengirimkannya.';

  @override
  String get crashReportSubmit => 'Salin & laporkan';

  @override
  String get preReleaseUpdates => 'Terima pembaruan pra-rilis';

  @override
  String get autoUpdateHomeWidget => 'Widget Rumah Pembaruan Otomatis';

  @override
  String get backupPassword => 'Kata sandi cadangan';

  @override
  String get backupPasswordSet => 'Kata sandi cadangan ditetapkan';

  @override
  String get backupPasswordTip =>
      'Setel kata sandi untuk mengenkripsi file cadangan. Biarkan kosong untuk menonaktifkan enkripsi.';

  @override
  String get distIcon => 'Tanda distribusi';

  @override
  String get distNameMap => 'Pemetaan nama';

  @override
  String get globe => 'Bola dunia';

  @override
  String get navTabMenuTip =>
      'Tekan lama sebuah tab — atau klik kanan — untuk menghubungkan atau memutuskan semuanya sekaligus.';

  @override
  String get remoteBackupPasswordRequired =>
      'Cadangan jarak jauh memerlukan kata sandi cadangan yang tidak kosong';

  @override
  String get backupTip =>
      'Data yang diekspor dapat dienkripsi dengan kata sandi. \nHarap jaga keamanannya.';

  @override
  String get bgRun => 'Jalankan di Backgroud';

  @override
  String get bgRunTip =>
      'Sakelar ini hanya berarti aplikasi akan mencoba berjalan di latar belakang, apakah aplikasi dapat berjalan di latar belakang tergantung pada apakah izin diaktifkan atau tidak. Untuk Android asli, nonaktifkan \"Pengoptimalan Baterai\" di aplikasi ini, dan untuk miui, ubah kebijakan penghematan daya ke \"Tidak Terbatas\".';

  @override
  String get bgRunNeedsNotification =>
      'Berjalan di latar belakang butuh notifikasi permanen, dan aplikasi ini tidak punya izin notifikasi. Ketuk untuk memberikannya.';

  @override
  String get closeAfterSave => 'Simpan dan tutup';

  @override
  String get collapseUITip =>
      'Apakah akan menciutkan daftar panjang yang ada di UI secara default atau tidak';

  @override
  String get distro => 'Distribusi';

  @override
  String get dockerStatistics => 'Statistik Docker';

  @override
  String get envVars => 'Variabel lingkungan';

  @override
  String get fdroidReleaseTip =>
      'Jika Anda mengunduh aplikasi ini dari F-Droid, disarankan untuk mematikan opsi ini.';

  @override
  String get fullScreen => 'Layar penuh';

  @override
  String get fullScreenJitter => 'Jitter layar penuh';

  @override
  String get fullScreenJitterHelp => 'Untuk menghindari pembakaran layar';

  @override
  String get fullScreenTip =>
      'Apakah mode layar penuh diaktifkan ketika perangkat diputar ke modus lanskap? Opsi ini hanya berlaku untuk tab server.';

  @override
  String get homeTabs => 'Tab Beranda';

  @override
  String get image => 'Gambar';

  @override
  String get sshKeyRecommended => 'Disarankan';

  @override
  String get unused => 'Tidak terpakai';

  @override
  String get pull => 'Tarik';

  @override
  String get needRestart => 'Perlu memulai ulang aplikasi';

  @override
  String get parseContainerStatsTip =>
      'Parsing status okupansi oleh Docker agak lambat';

  @override
  String get restart => 'Mulai ulang';

  @override
  String get liveActivity => 'Aktivitas Live';

  @override
  String get read => 'Baca';

  @override
  String get second => 'S';

  @override
  String get back => 'Kembali';

  @override
  String get history => 'Riwayat';

  @override
  String get homeDir => 'Beranda';

  @override
  String selected(int count) {
    return '$count dipilih';
  }

  @override
  String get sftpRmrDirSummary => 'Gunakan `rm -r` untuk menghapus dir di SFTP';

  @override
  String get syncAppSettings => 'Sinkronkan pengaturan aplikasi';

  @override
  String get times => 'Waktu';

  @override
  String get used => 'Digunakan';

  @override
  String get wakeLock => 'Tetap terjaga';

  @override
  String get write => 'Tulis';

  @override
  String processCount(int count) {
    return '$count proses';
  }

  @override
  String get services => 'Layanan';

  @override
  String get status => 'Status';

  @override
  String get enable => 'Aktifkan';

  @override
  String get disable => 'Nonaktifkan';

  @override
  String get starting => 'Memulai';

  @override
  String get stopping => 'Menghentikan';

  @override
  String get power => 'Daya';

  @override
  String get fan => 'Kipas';

  @override
  String get vendor => 'Vendor';

  @override
  String get agentLocalExec => 'Jalankan perintah di perangkat ini';

  @override
  String get privacyBlur => 'Privasi latar belakang';

  @override
  String get privacyBlurTip =>
      'Sembunyikan konten aplikasi di pengalih aplikasi';

  @override
  String get benchmark => 'Uji performa';

  @override
  String get peak => 'puncak';

  @override
  String get hardware => 'Perangkat keras';

  @override
  String get from => 'Dari';

  @override
  String get to => 'Sampai';

  @override
  String get samples => 'sampel';

  @override
  String get unavailable => 'tidak tersedia';

  @override
  String get stored => 'tersimpan';

  @override
  String get oldest => 'paling lama';

  @override
  String get attributes => 'atribut';

  @override
  String get cycle => 'Siklus';

  @override
  String get window => 'jendela';

  @override
  String get connection => 'Koneksi';

  @override
  String get behaviour => 'Perilaku';

  @override
  String get optional => 'Opsional';

  @override
  String get alerts => 'Peringatan';

  @override
  String get online => 'online';

  @override
  String get connect => 'Hubungkan';

  @override
  String get move => 'Pindahkan';

  @override
  String get reduceMotion => 'Kurangi gerakan';

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
