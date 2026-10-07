// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get crashLastRunFailed =>
      'NodePulse si è chiuso inaspettatamente durante l\'ultima esecuzione.';

  @override
  String get crashReportTitle => 'Rapporto di arresto anomalo';

  @override
  String get crashReportHint =>
      'Questo è il registro dell\'esecuzione precedente. I nomi e gli indirizzi dei server noti sono stati sostituiti da segnaposto, ma altri dettagli possono rimanere. Leggilo attentamente prima di inviarlo.';

  @override
  String get crashReportSubmit => 'Copia e segnala';

  @override
  String get preReleaseUpdates => 'Ricevi aggiornamenti pre-release';

  @override
  String get autoUpdateHomeWidget => 'Aggiornamento automatico widget home';

  @override
  String get backupPassword => 'Password di backup';

  @override
  String get backupPasswordSet => 'Password di backup impostata';

  @override
  String get backupPasswordTip =>
      'Imposta una password per crittografare i file di backup. Lascia vuoto per disabilitare la crittografia.';

  @override
  String get distIcon => 'Contrassegni di distribuzione';

  @override
  String get distNameMap => 'Corrispondenza dei nomi';

  @override
  String get globe => 'Globo';

  @override
  String get navTabMenuTip =>
      'Tieni premuta una scheda — o fai clic destro — per connettere o disconnettere in una volta tutto ciò che contiene.';

  @override
  String get remoteBackupPasswordRequired =>
      'I backup remoti richiedono una password di backup non vuota';

  @override
  String get backupTip =>
      'I dati esportati possono essere crittografati con password.\nConservali al sicuro.';

  @override
  String get bgRun => 'Esegui in background';

  @override
  String get bgRunTip =>
      'Questa opzione significa solo che il programma cercherà di eseguire in background. Se può eseguire in background dipende dal fatto che il permesso sia abilitato o meno. Per le ROM Android basate su AOSP, disabilita \"Ottimizzazione batteria\" in questa app. Per MIUI/HyperOS, cambia la politica di risparmio energetico su \"Illimitato\".';

  @override
  String get bgRunNeedsNotification =>
      'Restare in esecuzione in background richiede una notifica permanente, e questa app non ha il permesso per le notifiche. Tocca per concederlo.';

  @override
  String get closeAfterSave => 'Salva e chiudi';

  @override
  String get collapseUITip =>
      'Se comprimere le liste lunghe presenti nell\'interfaccia utente per impostazione predefinita';

  @override
  String get distro => 'Distribuzione';

  @override
  String get envVars => 'Variabile d\'ambiente';

  @override
  String get fullScreen => 'Schermo intero';

  @override
  String get fullScreenJitter => 'Jitter schermo intero';

  @override
  String get fullScreenJitterHelp => 'Per evitare il burn-in dello schermo';

  @override
  String get fullScreenTip =>
      'La modalità a schermo intero deve essere abilitata quando il dispositivo viene ruotato in modalità orizzontale? Questa opzione si applica solo alla scheda server.';

  @override
  String get homeTabs => 'Schede home';

  @override
  String get image => 'Immagine';

  @override
  String get sshKeyRecommended => 'Consigliato';

  @override
  String get unused => 'Inutilizzato';

  @override
  String get pull => 'Pull';

  @override
  String get needRestart => 'L\'app deve essere riavviata';

  @override
  String get restart => 'Riavvia';

  @override
  String get liveActivity => 'Attività live';

  @override
  String get read => 'Leggi';

  @override
  String get second => 's';

  @override
  String get back => 'Indietro';

  @override
  String get history => 'Cronologia';

  @override
  String get homeDir => 'Home';

  @override
  String selected(int count) {
    return '$count selezionati';
  }

  @override
  String get syncAppSettings => 'Sincronizza le impostazioni dell\'app';

  @override
  String get times => 'Volte';

  @override
  String get used => 'Usato';

  @override
  String get wakeLock => 'Mantieni sveglio';

  @override
  String get write => 'Scrivi';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processi',
      one: '1 processo',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Servizi';

  @override
  String get status => 'Stato';

  @override
  String get enable => 'Abilita';

  @override
  String get disable => 'Disabilita';

  @override
  String get starting => 'Avvio in corso';

  @override
  String get stopping => 'Arresto in corso';

  @override
  String get power => 'Alimentazione';

  @override
  String get fan => 'Ventola';

  @override
  String get vendor => 'Produttore';

  @override
  String get agentLocalExec => 'Esegui comandi su questo dispositivo';

  @override
  String get privacyBlur => 'Privacy in background';

  @override
  String get privacyBlurTip =>
      'Nascondi il contenuto dell\'app nel selettore app';

  @override
  String get benchmark => 'Benchmark';

  @override
  String get peak => 'picco';

  @override
  String get hardware => 'Hardware';

  @override
  String get from => 'Da';

  @override
  String get to => 'A';

  @override
  String get samples => 'campioni';

  @override
  String get unavailable => 'non disponibile';

  @override
  String get stored => 'memorizzato';

  @override
  String get oldest => 'il più vecchio';

  @override
  String get attributes => 'attributi';

  @override
  String get cycle => 'Cicli';

  @override
  String get window => 'finestra';

  @override
  String get connection => 'Connessione';

  @override
  String get behaviour => 'Comportamento';

  @override
  String get optional => 'Facoltativo';

  @override
  String get alerts => 'Avvisi';

  @override
  String get online => 'online';

  @override
  String get connect => 'Connetti';

  @override
  String get move => 'Sposta';

  @override
  String get reduceMotion => 'Riduci movimento';

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
