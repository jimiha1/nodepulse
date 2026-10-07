// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get privacy => 'Privacidade';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get crashLastRunFailed =>
      'O NodePulse fechou inesperadamente durante a última execução.';

  @override
  String get crashReportTitle => 'Relatório de falha';

  @override
  String get crashReportHint =>
      'Este é o registro da execução anterior. Nomes e endereços de servidor conhecidos foram substituídos por marcadores, mas outros detalhes podem permanecer. Leia-o com atenção antes de enviá-lo.';

  @override
  String get crashReportSubmit => 'Copiar e relatar';

  @override
  String get preReleaseUpdates => 'Receber atualizações de pré-lançamento';

  @override
  String get autoUpdateHomeWidget =>
      'Atualização automática do widget da tela inicial';

  @override
  String get backupPassword => 'Senha de backup';

  @override
  String get backupPasswordSet => 'Senha de backup definida';

  @override
  String get backupPasswordTip =>
      'Defina uma senha para criptografar arquivos de backup. Deixe vazio para desabilitar a criptografia.';

  @override
  String get distIcon => 'Marcas de distribuição';

  @override
  String get distNameMap => 'Correspondência de nomes';

  @override
  String get globe => 'Globo';

  @override
  String get navTabMenuTip =>
      'Toque e segure uma aba — ou clique com o botão direito — para conectar ou desconectar tudo nela de uma vez.';

  @override
  String get remoteBackupPasswordRequired =>
      'Backups remotos exigem uma senha de backup não vazia';

  @override
  String get backupTip =>
      'Os dados exportados podem ser criptografados com senha. \nPor favor, guarde-os com segurança.';

  @override
  String get bgRun => 'Execução em segundo plano';

  @override
  String get bgRunTip =>
      'Este interruptor indica que o programa tentará rodar em segundo plano, mas a capacidade de fazer isso depende das permissões concedidas. No Android nativo, desative a \'Otimização de bateria\' para este app, no MIUI, altere a estratégia de economia de energia para \'Sem restrições\'.';

  @override
  String get bgRunNeedsNotification =>
      'Correr em segundo plano precisa de uma notificação permanente, e esta app não tem permissão de notificações. Toca para a conceder.';

  @override
  String get closeAfterSave => 'Salvar e fechar';

  @override
  String get collapseUITip => 'Deve colapsar listas longas na UI por padrão?';

  @override
  String get distro => 'Distribuição';

  @override
  String get envVars => 'Variável de ambiente';

  @override
  String get fullScreen => 'Tela cheia';

  @override
  String get fullScreenJitter => 'Tremulação em tela cheia';

  @override
  String get fullScreenJitterHelp => 'Prevenir burn-in de tela';

  @override
  String get fullScreenTip =>
      'Deve ser ativado o modo de tela cheia quando o dispositivo é girado para o modo paisagem? Esta opção aplica-se apenas à aba do servidor.';

  @override
  String get homeTabs => 'Abas iniciais';

  @override
  String get image => 'Imagem';

  @override
  String get sshKeyRecommended => 'Recomendado';

  @override
  String get unused => 'Não utilizado';

  @override
  String get pull => 'Puxar';

  @override
  String get needRestart => 'Necessita reiniciar o app';

  @override
  String get restart => 'Reiniciar';

  @override
  String get liveActivity => 'Atividade ao vivo';

  @override
  String get read => 'Leitura';

  @override
  String get second => 'Segundo';

  @override
  String get back => 'Voltar';

  @override
  String get history => 'Histórico';

  @override
  String get homeDir => 'Pasta pessoal';

  @override
  String selected(int count) {
    return '$count selecionados';
  }

  @override
  String get syncAppSettings => 'Sincronizar as configurações do app';

  @override
  String get times => 'Vezes';

  @override
  String get used => 'Usado';

  @override
  String get wakeLock => 'Manter acordado';

  @override
  String get write => 'Escrita';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processos',
      one: '1 processo',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Serviços';

  @override
  String get status => 'Estado';

  @override
  String get enable => 'Ativar';

  @override
  String get disable => 'Desativar';

  @override
  String get starting => 'A iniciar';

  @override
  String get stopping => 'A parar';

  @override
  String get power => 'Energia';

  @override
  String get fan => 'Ventoinha';

  @override
  String get vendor => 'Fabricante';

  @override
  String get agentLocalExec => 'Executar comandos neste dispositivo';

  @override
  String get privacyBlur => 'Privacidade em segundo plano';

  @override
  String get privacyBlurTip => 'Ocultar o conteúdo do app no alternador';

  @override
  String get benchmark => 'Teste de desempenho';

  @override
  String get peak => 'pico';

  @override
  String get hardware => 'Hardware';

  @override
  String get from => 'De';

  @override
  String get to => 'Até';

  @override
  String get samples => 'amostras';

  @override
  String get unavailable => 'indisponível';

  @override
  String get stored => 'armazenado';

  @override
  String get oldest => 'o mais antigo';

  @override
  String get attributes => 'atributos';

  @override
  String get cycle => 'Ciclos';

  @override
  String get window => 'janela';

  @override
  String get connection => 'Conexão';

  @override
  String get behaviour => 'Comportamento';

  @override
  String get optional => 'Opcional';

  @override
  String get alerts => 'Alertas';

  @override
  String get online => 'online';

  @override
  String get connect => 'Ligar';

  @override
  String get move => 'Mover';

  @override
  String get reduceMotion => 'Reduzir movimento';

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
