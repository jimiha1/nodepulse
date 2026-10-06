// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get crashCollect => 'Diagnostische gegevens';

  @override
  String get crashCollectIntro =>
      'NodePulse legt vast wat er tijdens het gebruik gebeurt, zodat problemen kunnen worden opgelost. Kies hoeveel informatie er wordt verstuurd.';

  @override
  String get crashCollectNone => 'Niets';

  @override
  String get crashCollectNoneTip =>
      'Rapporten blijven op dit apparaat; na een crash kun je er handmatig een versturen.';

  @override
  String get crashCollectBasic => 'Basisgegevens';

  @override
  String get crashCollectBasicTip =>
      'Bevat alleen informatie over de crash; logboeken en prestatiegegevens worden niet opgenomen. **Zo help je ons de app te verbeteren en bugs op te lossen.**';

  @override
  String get crashCollectFull => 'Volledige gegevens';

  @override
  String get crashCollectFullTip =>
      'Naast het crashlogboek bevat dit ook prestatiegegevens en het gebruik van functies: daarmee is te vinden wat traag is en welke functies echt worden gebruikt.';

  @override
  String get crashCollectFooter =>
      'Op elk niveau worden bekende servernamen, adressen en gebruikersnamen al bij het vastleggen vervangen door plaatsaanduidingen. Je kunt het verzamelingsniveau later wijzigen in de instellingen.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get crashLastRunFailed =>
      'NodePulse is tijdens de vorige uitvoering onverwacht afgesloten.';

  @override
  String get crashReportTitle => 'Crashrapport';

  @override
  String get crashReportHint =>
      'Dit is het logboek van de vorige uitvoering. Bekende servernamen en adressen zijn vervangen door plaatsaanduidingen, maar andere gegevens kunnen achterblijven. Lees het zorgvuldig door voordat je het indient.';

  @override
  String get crashReportSubmit => 'Kopiëren en melden';

  @override
  String get preReleaseUpdates => 'Pre-release-updates ontvangen';

  @override
  String get autoUpdateHomeWidget => 'Automatische update van home-widget';

  @override
  String get backupPassword => 'Back-up wachtwoord';

  @override
  String get backupPasswordSet => 'Back-up wachtwoord ingesteld';

  @override
  String get backupPasswordTip =>
      'Stel een wachtwoord in om back-upbestanden te versleutelen. Laat leeg om versleuteling uit te schakelen.';

  @override
  String get distIcon => 'Distributiemarkeringen';

  @override
  String get distNameMap => 'Naamtoewijzing';

  @override
  String get globe => 'Globe';

  @override
  String get navTabMenuTip =>
      'Houd een tabblad ingedrukt — of klik er met rechts op — om alles erin in één keer te verbinden of te verbreken.';

  @override
  String get remoteBackupPasswordRequired =>
      'Externe back-ups vereisen een niet-leeg back-upwachtwoord';

  @override
  String get backupTip =>
      'De geëxporteerde gegevens kunnen worden versleuteld met een wachtwoord. \nBewaar deze aub veilig.';

  @override
  String get bgRun => 'Uitvoeren op de achtergrond';

  @override
  String get bgRunTip =>
      'Deze schakelaar betekent alleen dat het programma zal proberen op de achtergrond uit te voeren, of het in de achtergrond kan worden uitgevoerd, hangt af van of de toestemming is ingeschakeld of niet. Voor native Android, schakel \"Batterijoptimalisatie\" uit in deze app, en voor miui, wijzig de energiebesparingsbeleid naar \"Onbeperkt\".';

  @override
  String get bgRunNeedsNotification =>
      'Op de achtergrond draaien vereist een permanente melding, en deze app heeft geen meldingsrechten. Tik om ze toe te staan.';

  @override
  String get closeAfterSave => 'Opslaan en sluiten';

  @override
  String get collapseUITip =>
      'Of lange lijsten in de UI standaard moeten worden ingeklapt';

  @override
  String get distro => 'Distributie';

  @override
  String get dockerStatistics => 'Docker-statistieken';

  @override
  String get envVars => 'Omgevingsvariabele';

  @override
  String get fdroidReleaseTip =>
      'Als u deze app van F-Droid heeft gedownload, wordt aanbevolen deze optie uit te schakelen.';

  @override
  String get fullScreen => 'Volledig scherm';

  @override
  String get fullScreenJitter => 'Volledig scherm trilling';

  @override
  String get fullScreenJitterHelp => 'Om inbranden van het scherm te voorkomen';

  @override
  String get fullScreenTip =>
      'Moet de volledig schermmodus worden ingeschakeld wanneer het apparaat naar de liggende modus wordt gedraaid? Deze optie is alleen van toepassing op het servertabblad.';

  @override
  String get homeTabs => 'Home-tabbladen';

  @override
  String get image => 'Afbeelding';

  @override
  String get sshKeyRecommended => 'Aanbevolen';

  @override
  String get unused => 'Ongebruikt';

  @override
  String get pull => 'Pull';

  @override
  String get needRestart => 'App moet opnieuw worden gestart';

  @override
  String get parseContainerStatsTip =>
      'Het parsen van de bezettingsstatus van Docker is relatief langzaam.';

  @override
  String get restart => 'Opnieuw starten';

  @override
  String get liveActivity => 'Live activiteit';

  @override
  String get read => 'Lezen';

  @override
  String get second => 's';

  @override
  String get back => 'Terug';

  @override
  String get history => 'Geschiedenis';

  @override
  String get homeDir => 'Home';

  @override
  String selected(int count) {
    return '$count geselecteerd';
  }

  @override
  String get sftpRmrDirSummary =>
      'Gebruik `rm -r` om een map te verwijderen in SFTP.';

  @override
  String get syncAppSettings => 'App-instellingen synchroniseren';

  @override
  String get times => 'Keer';

  @override
  String get used => 'Gebruikt';

  @override
  String get wakeLock => 'Wakker houden';

  @override
  String get write => 'Schrijven';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processen',
      one: '1 proces',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Diensten';

  @override
  String get status => 'Status';

  @override
  String get enable => 'Inschakelen';

  @override
  String get disable => 'Uitschakelen';

  @override
  String get starting => 'Bezig met starten';

  @override
  String get stopping => 'Bezig met stoppen';

  @override
  String get power => 'Energie';

  @override
  String get fan => 'Ventilator';

  @override
  String get vendor => 'Fabrikant';

  @override
  String get agentLocalExec => 'Opdrachten op dit apparaat uitvoeren';

  @override
  String get privacyBlur => 'Privacy op de achtergrond';

  @override
  String get privacyBlurTip => 'Verberg de app-inhoud in de app-switcher';

  @override
  String get benchmark => 'Benchmark';

  @override
  String get peak => 'piek';

  @override
  String get hardware => 'Hardware';

  @override
  String get from => 'Van';

  @override
  String get to => 'Tot';

  @override
  String get samples => 'metingen';

  @override
  String get unavailable => 'niet beschikbaar';

  @override
  String get stored => 'opgeslagen';

  @override
  String get oldest => 'het oudst';

  @override
  String get attributes => 'attributen';

  @override
  String get cycle => 'Cycli';

  @override
  String get window => 'venster';

  @override
  String get connection => 'Verbinding';

  @override
  String get behaviour => 'Gedrag';

  @override
  String get optional => 'Optioneel';

  @override
  String get alerts => 'Waarschuwingen';

  @override
  String get online => 'online';

  @override
  String get connect => 'Verbinden';

  @override
  String get move => 'Verplaatsen';

  @override
  String get reduceMotion => 'Beperk beweging';

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
