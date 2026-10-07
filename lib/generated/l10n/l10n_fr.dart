// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get privacy => 'Confidentialité';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get crashLastRunFailed =>
      'NodePulse s\'est fermé de manière inattendue lors de sa dernière exécution.';

  @override
  String get crashReportTitle => 'Rapport de plantage';

  @override
  String get crashReportHint =>
      'Ceci est le journal de l\'exécution précédente. Les noms et adresses de serveurs connus ont été remplacés par des espaces réservés, mais d\'autres informations peuvent subsister. Lisez-le attentivement avant de l\'envoyer.';

  @override
  String get crashReportSubmit => 'Copier et signaler';

  @override
  String get preReleaseUpdates => 'Recevoir les mises à jour préliminaires';

  @override
  String get autoUpdateHomeWidget =>
      'Mise à jour automatique du widget d\'accueil';

  @override
  String get backupPassword => 'Mot de passe de sauvegarde';

  @override
  String get backupPasswordSet => 'Mot de passe de sauvegarde défini';

  @override
  String get backupPasswordTip =>
      'Définissez un mot de passe pour chiffrer les fichiers de sauvegarde. Laissez vide pour désactiver le chiffrement.';

  @override
  String get distIcon => 'Marques de distribution';

  @override
  String get distNameMap => 'Correspondance des noms';

  @override
  String get globe => 'Globe';

  @override
  String get navTabMenuTip =>
      'Appuyez longuement sur un onglet — ou faites un clic droit — pour connecter ou déconnecter d\'un coup tout ce qu\'il contient.';

  @override
  String get remoteBackupPasswordRequired =>
      'Les sauvegardes distantes nécessitent un mot de passe de sauvegarde non vide';

  @override
  String get backupTip =>
      'Les données exportées peuvent être chiffrées avec un mot de passe. \nVeuillez les garder en sécurité.';

  @override
  String get bgRun => 'Exécution en arrière-plan';

  @override
  String get bgRunTip =>
      'Cette option signifie seulement que le programme essaiera de s\'exécuter en arrière-plan, que cela soit possible dépend de l\'autorisation activée ou non. Pour Android natif, veuillez désactiver l\'« Optimisation de la batterie » dans cette application, et pour MIUI, veuillez changer la politique d\'économie d\'énergie en « Illimité ».';

  @override
  String get bgRunNeedsNotification =>
      'Fonctionner en arrière-plan demande une notification permanente, et cette app n\'a pas la permission de notification. Touchez pour l\'accorder.';

  @override
  String get closeAfterSave => 'Enregistrer et fermer';

  @override
  String get collapseUITip =>
      'Indique si les longues listes présentées dans l\'interface utilisateur doivent être réduites par défaut.';

  @override
  String get distro => 'Distribution';

  @override
  String get dockerStatistics => 'Statistiques Docker';

  @override
  String get envVars => 'Variable d’environnement';

  @override
  String get fdroidReleaseTip =>
      'Si vous avez téléchargé cette application depuis F-Droid, il est recommandé de désactiver cette option.';

  @override
  String get fullScreen => 'Plein écran';

  @override
  String get fullScreenJitter => 'Secousse en plein écran';

  @override
  String get fullScreenJitterHelp => 'Pour éviter les brûlures d\'écran';

  @override
  String get fullScreenTip =>
      'Le mode plein écran doit-il être activé lorsque l\'appareil est orienté en mode paysage ? Cette option s\'applique uniquement à l\'onglet serveur.';

  @override
  String get homeTabs => 'Onglets d\'accueil';

  @override
  String get image => 'Image';

  @override
  String get sshKeyRecommended => 'Recommandé';

  @override
  String get unused => 'Inutilisé';

  @override
  String get pull => 'Tirer';

  @override
  String get needRestart => 'Nécessite un redémarrage de l\'application';

  @override
  String get parseContainerStatsTip =>
      'L\'analyse de l\'occupation des conteneurs Docker est relativement lente.';

  @override
  String get restart => 'Redémarrer';

  @override
  String get liveActivity => 'Activité en direct';

  @override
  String get read => 'Lire';

  @override
  String get second => 's';

  @override
  String get back => 'Retour';

  @override
  String get history => 'Historique';

  @override
  String get homeDir => 'Dossier personnel';

  @override
  String selected(int count) {
    return '$count sélectionnés';
  }

  @override
  String get sftpRmrDirSummary =>
      'Utilisez `rm -r` pour supprimer un dossier en SFTP.';

  @override
  String get syncAppSettings => 'Synchroniser les réglages de l\'app';

  @override
  String get times => 'Fois';

  @override
  String get used => 'Utilisé';

  @override
  String get wakeLock => 'Maintenir éveillé';

  @override
  String get write => 'Écrire';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processus',
      one: '1 processus',
      zero: '0 processus',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Services';

  @override
  String get status => 'État';

  @override
  String get enable => 'Activer';

  @override
  String get disable => 'Désactiver';

  @override
  String get starting => 'Démarrage en cours';

  @override
  String get stopping => 'Arrêt en cours';

  @override
  String get power => 'Alimentation';

  @override
  String get fan => 'Ventilateur';

  @override
  String get vendor => 'Fabricant';

  @override
  String get agentLocalExec => 'Exécuter des commandes sur cet appareil';

  @override
  String get privacyBlur => 'Confidentialité en arrière-plan';

  @override
  String get privacyBlurTip => 'Masquer le contenu dans le sélecteur d\'apps';

  @override
  String get benchmark => 'Test de performances';

  @override
  String get peak => 'pic';

  @override
  String get hardware => 'Matériel';

  @override
  String get from => 'Du';

  @override
  String get to => 'Au';

  @override
  String get samples => 'relevés';

  @override
  String get unavailable => 'indisponible';

  @override
  String get stored => 'stocké';

  @override
  String get oldest => 'le plus ancien';

  @override
  String get attributes => 'attributs';

  @override
  String get cycle => 'Cycles';

  @override
  String get window => 'fenêtre';

  @override
  String get connection => 'Connexion';

  @override
  String get behaviour => 'Comportement';

  @override
  String get optional => 'Facultatif';

  @override
  String get alerts => 'Alertes';

  @override
  String get online => 'en ligne';

  @override
  String get connect => 'Connecter';

  @override
  String get move => 'Déplacer';

  @override
  String get reduceMotion => 'Réduire les animations';

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
