// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get privacy => 'Datenschutz';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get crashLastRunFailed =>
      'NodePulse wurde beim letzten Ausführen unerwartet beendet.';

  @override
  String get crashReportTitle => 'Absturzbericht';

  @override
  String get crashReportHint =>
      'Dies ist das Protokoll des vorherigen Laufs. Bekannte Servernamen und -adressen wurden durch Platzhalter ersetzt, andere Angaben können jedoch verbleiben. Bitte lesen Sie es vor dem Absenden sorgfältig durch.';

  @override
  String get crashReportSubmit => 'Kopieren & melden';

  @override
  String get preReleaseUpdates => 'Vorabversions-Updates erhalten';

  @override
  String get autoUpdateHomeWidget => 'Home-Widget automatisch aktualisieren';

  @override
  String get backupPassword => 'Backup-Passwort';

  @override
  String get backupPasswordSet => 'Backup-Passwort gesetzt';

  @override
  String get backupPasswordTip =>
      'Setzen Sie ein Passwort, um Backup-Dateien zu verschlüsseln. Leer lassen, um Verschlüsselung zu deaktivieren.';

  @override
  String get distIcon => 'Distributions-Kennzeichen';

  @override
  String get distNameMap => 'Namenszuordnung';

  @override
  String get globe => 'Globus';

  @override
  String get navTabMenuTip =>
      'Tippe lange auf einen Tab – oder klicke ihn mit der rechten Maustaste an –, um alles darin auf einmal zu verbinden oder zu trennen.';

  @override
  String get remoteBackupPasswordRequired =>
      'Für entfernte Backups ist ein nicht leeres Backup-Passwort erforderlich';

  @override
  String get backupTip =>
      'Die exportierten Daten können mit einem Passwort verschlüsselt werden. \nBitte sicher aufbewahren.';

  @override
  String get bgRun => 'Hintergrundaktualisierung';

  @override
  String get bgRunTip =>
      'Dieser Schalter bedeutet nur, dass die App versuchen wird, im Hintergrund zu laufen. Ob sie im Hintergrund laufen kann, hängt davon ab, ob die Berechtigungen aktiviert sind oder nicht. Bei nativem Android deaktivieren Sie bitte \"Batterieoptimierung\" in dieser App, und bei miui ändern Sie bitte die Energiesparrichtlinie auf \"Unbegrenzt\".';

  @override
  String get bgRunNeedsNotification =>
      'Das Laufen im Hintergrund braucht eine dauerhafte Benachrichtigung, und diese App hat keine Benachrichtigungsberechtigung. Zum Erlauben antippen.';

  @override
  String get closeAfterSave => 'Speichern und schließen';

  @override
  String get collapseUITip =>
      'Ob lange Listen in der Benutzeroberfläche standardmäßig eingeklappt werden sollen oder nicht';

  @override
  String get distro => 'Distribution';

  @override
  String get envVars => 'Umgebungsvariable';

  @override
  String get fullScreen => 'Vollbild';

  @override
  String get fullScreenJitter => 'Jitter im Vollbildmodus';

  @override
  String get fullScreenJitterHelp => 'Einbrennen des Bildschirms verhindern';

  @override
  String get fullScreenTip =>
      'Soll der Vollbildmodus aktiviert werden, wenn das Gerät in den Quermodus gedreht wird? Diese Option gilt nur für die Server-Registerkarte.';

  @override
  String get homeTabs => 'Home-Tabs';

  @override
  String get image => 'Image';

  @override
  String get sshKeyRecommended => 'Empfohlen';

  @override
  String get unused => 'Ungenutzt';

  @override
  String get pull => 'Pull';

  @override
  String get needRestart => 'App muss neugestartet werden';

  @override
  String get restart => 'Neu starten';

  @override
  String get liveActivity => 'Live-Aktivität';

  @override
  String get read => 'Lesen';

  @override
  String get second => 's';

  @override
  String get back => 'Zurück';

  @override
  String get history => 'Verlauf';

  @override
  String get homeDir => 'Persönlicher Ordner';

  @override
  String selected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get syncAppSettings => 'App-Einstellungen synchronisieren';

  @override
  String get times => 'x';

  @override
  String get used => 'Gebraucht';

  @override
  String get wakeLock => 'Wach halten';

  @override
  String get write => 'Schreiben';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Prozesse',
      one: '1 Prozess',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Dienste';

  @override
  String get status => 'Status';

  @override
  String get enable => 'Aktivieren';

  @override
  String get disable => 'Deaktivieren';

  @override
  String get starting => 'Wird gestartet';

  @override
  String get stopping => 'Wird gestoppt';

  @override
  String get power => 'Energie';

  @override
  String get fan => 'Lüfter';

  @override
  String get vendor => 'Hersteller';

  @override
  String get agentLocalExec => 'Befehle auf diesem Gerät ausführen';

  @override
  String get privacyBlur => 'Datenschutz im Hintergrund';

  @override
  String get privacyBlurTip => 'App-Inhalt in der App-Übersicht verbergen';

  @override
  String get benchmark => 'Benchmark';

  @override
  String get peak => 'Spitze';

  @override
  String get hardware => 'Hardware';

  @override
  String get from => 'Von';

  @override
  String get to => 'Bis';

  @override
  String get samples => 'Messungen';

  @override
  String get unavailable => 'nicht verfügbar';

  @override
  String get stored => 'gespeichert';

  @override
  String get oldest => 'am ältesten';

  @override
  String get attributes => 'Attribute';

  @override
  String get cycle => 'Zyklen';

  @override
  String get window => 'Zeitfenster';

  @override
  String get connection => 'Verbindung';

  @override
  String get behaviour => 'Verhalten';

  @override
  String get optional => 'Optional';

  @override
  String get alerts => 'Warnungen';

  @override
  String get online => 'online';

  @override
  String get connect => 'Verbinden';

  @override
  String get move => 'Verschieben';

  @override
  String get reduceMotion => 'Bewegung reduzieren';

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
