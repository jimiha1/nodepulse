// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get privacy => 'Privacidad';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get crashLastRunFailed =>
      'NodePulse se cerró inesperadamente durante la última ejecución.';

  @override
  String get crashReportTitle => 'Informe de fallo';

  @override
  String get crashReportHint =>
      'Este es el registro de la ejecución anterior. Los nombres y direcciones de servidor conocidos se han sustituido por marcadores, pero pueden quedar otros datos. Lee el informe detenidamente antes de enviarlo.';

  @override
  String get crashReportSubmit => 'Copiar e informar';

  @override
  String get preReleaseUpdates => 'Recibir actualizaciones preliminares';

  @override
  String get autoUpdateHomeWidget =>
      'Actualizar automáticamente el widget del escritorio';

  @override
  String get backupPassword => 'Contraseña de respaldo';

  @override
  String get backupPasswordSet => 'Contraseña de respaldo establecida';

  @override
  String get backupPasswordTip =>
      'Establece una contraseña para encriptar archivos de respaldo. Déjalo vacío para desactivar la encriptación.';

  @override
  String get distIcon => 'Marcas de distribución';

  @override
  String get distNameMap => 'Correspondencia de nombres';

  @override
  String get globe => 'Globo';

  @override
  String get navTabMenuTip =>
      'Mantén pulsada una pestaña, o haz clic derecho en ella, para conectar o desconectar de una vez todo lo que contiene.';

  @override
  String get remoteBackupPasswordRequired =>
      'Las copias de seguridad remotas requieren una contraseña de copia no vacía';

  @override
  String get backupTip =>
      'Los datos exportados pueden ser encriptados con contraseña. \nPor favor guárdalos en un lugar seguro.';

  @override
  String get bgRun => 'Ejecución en segundo plano';

  @override
  String get bgRunTip =>
      'Este interruptor solo indica que la aplicación intentará correr en segundo plano, si puede hacerlo o no depende de si tiene el permiso correspondiente. En Android puro, por favor desactiva la “optimización de batería” para esta app, en MIUI por favor cambia la estrategia de ahorro de energía a “Sin restricciones”.';

  @override
  String get bgRunNeedsNotification =>
      'Para ejecutarse en segundo plano hace falta una notificación permanente, y esta app no tiene permiso de notificaciones. Toca para concederlo.';

  @override
  String get closeAfterSave => 'Guardar y cerrar';

  @override
  String get collapseUITip =>
      '¿Colapsar por defecto las listas largas en la UI?';

  @override
  String get distro => 'Distribución';

  @override
  String get envVars => 'Variable de entorno';

  @override
  String get fullScreen => 'Pantalla completa';

  @override
  String get fullScreenJitter => 'Temblores en modo pantalla completa';

  @override
  String get fullScreenJitterHelp => 'Prevención de quemaduras de pantalla';

  @override
  String get fullScreenTip =>
      '¿Debe habilitarse el modo de pantalla completa cuando el dispositivo se rote al modo horizontal? Esta opción solo se aplica a la pestaña del servidor.';

  @override
  String get homeTabs => 'Pestañas de inicio';

  @override
  String get image => 'Imagen';

  @override
  String get sshKeyRecommended => 'Recomendado';

  @override
  String get unused => 'Sin usar';

  @override
  String get pull => 'Extraer';

  @override
  String get needRestart => 'Necesita reiniciar la app';

  @override
  String get restart => 'Reiniciar';

  @override
  String get liveActivity => 'Actividad en vivo';

  @override
  String get read => 'Leer';

  @override
  String get second => 'Segundo';

  @override
  String get back => 'Atrás';

  @override
  String get history => 'Historial';

  @override
  String get homeDir => 'Inicio';

  @override
  String selected(int count) {
    return '$count seleccionados';
  }

  @override
  String get syncAppSettings => 'Sincronizar los ajustes de la app';

  @override
  String get times => 'Veces';

  @override
  String get used => 'Usado';

  @override
  String get wakeLock => 'Mantener despierto';

  @override
  String get write => 'Escribir';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count procesos',
      one: '1 proceso',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Servicios';

  @override
  String get status => 'Estado';

  @override
  String get enable => 'Habilitar';

  @override
  String get disable => 'Deshabilitar';

  @override
  String get starting => 'Iniciando';

  @override
  String get stopping => 'Deteniendo';

  @override
  String get power => 'Energía';

  @override
  String get fan => 'Ventilador';

  @override
  String get vendor => 'Fabricante';

  @override
  String get agentLocalExec => 'Ejecutar comandos en este dispositivo';

  @override
  String get privacyBlur => 'Privacidad en segundo plano';

  @override
  String get privacyBlurTip => 'Ocultar el contenido de la app en el selector';

  @override
  String get benchmark => 'Prueba de rendimiento';

  @override
  String get peak => 'pico';

  @override
  String get hardware => 'Hardware';

  @override
  String get from => 'Desde';

  @override
  String get to => 'Hasta';

  @override
  String get samples => 'muestras';

  @override
  String get unavailable => 'no disponible';

  @override
  String get stored => 'almacenado';

  @override
  String get oldest => 'el más antiguo';

  @override
  String get attributes => 'atributos';

  @override
  String get cycle => 'Ciclos';

  @override
  String get window => 'ventana';

  @override
  String get connection => 'Conexión';

  @override
  String get behaviour => 'Comportamiento';

  @override
  String get optional => 'Opcional';

  @override
  String get alerts => 'Alertas';

  @override
  String get online => 'en línea';

  @override
  String get connect => 'Conectar';

  @override
  String get move => 'Mover';

  @override
  String get reduceMotion => 'Reducir movimiento';

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
