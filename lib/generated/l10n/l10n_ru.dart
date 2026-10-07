// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get crashLastRunFailed =>
      'NodePulse неожиданно завершил работу во время последнего запуска.';

  @override
  String get crashReportTitle => 'Отчёт о сбое';

  @override
  String get crashReportHint =>
      'Это журнал предыдущего запуска. Известные имена и адреса серверов заменены заполнителями, но другие данные могут остаться. Внимательно прочитайте отчёт перед отправкой.';

  @override
  String get crashReportSubmit => 'Копировать и сообщить';

  @override
  String get preReleaseUpdates => 'Получать обновления предварительных версий';

  @override
  String get autoUpdateHomeWidget =>
      'Автоматическое обновление виджета на главном экране';

  @override
  String get backupPassword => 'Пароль резервной копии';

  @override
  String get backupPasswordSet => 'Пароль резервной копии установлен';

  @override
  String get backupPasswordTip =>
      'Установите пароль для шифрования файлов резервных копий. Оставьте пустым, чтобы отключить шифрование.';

  @override
  String get distIcon => 'Значки дистрибутивов';

  @override
  String get distNameMap => 'Сопоставление имён';

  @override
  String get globe => 'Глобус';

  @override
  String get navTabMenuTip =>
      'Нажмите и удерживайте вкладку — или щёлкните правой кнопкой — чтобы подключить или отключить всё сразу.';

  @override
  String get remoteBackupPasswordRequired =>
      'Для удалённых резервных копий требуется непустой пароль резервного копирования';

  @override
  String get backupTip =>
      'Экспортированные данные могут быть зашифрованы паролем. \nПожалуйста, храните их в безопасности.';

  @override
  String get bgRun => 'Работа в фоновом режиме';

  @override
  String get bgRunTip =>
      'Этот переключатель означает, что программа будет пытаться работать в фоновом режиме, но фактическое выполнение зависит от того, включено ли разрешение. Для нативного Android отключите «Оптимизацию батареи» для этого приложения, для MIUI измените контроль активности на «Нет ограничений».';

  @override
  String get bgRunNeedsNotification =>
      'Для работы в фоне нужно постоянное уведомление, а у приложения нет разрешения на уведомления. Нажмите, чтобы разрешить.';

  @override
  String get closeAfterSave => 'Сохранить и закрыть';

  @override
  String get collapseUITip => 'Свернуть длинные списки в UI по умолчанию';

  @override
  String get distro => 'Дистрибутив';

  @override
  String get dockerStatistics => 'Статистика Docker';

  @override
  String get envVars => 'Переменная окружения';

  @override
  String get fdroidReleaseTip =>
      'Если вы скачали это приложение с F-Droid, рекомендуется отключить эту опцию.';

  @override
  String get fullScreen => 'Полный экран';

  @override
  String get fullScreenJitter => 'Вибрация в полноэкранном режиме';

  @override
  String get fullScreenJitterHelp => 'Предотвращение выгорания экрана';

  @override
  String get fullScreenTip =>
      'Следует ли включить полноэкранный режим, когда устройство поворачивается в альбомный режим? Эта опция применяется только к вкладке сервера.';

  @override
  String get homeTabs => 'Вкладки дома';

  @override
  String get image => 'Образ';

  @override
  String get sshKeyRecommended => 'Рекомендуется';

  @override
  String get unused => 'Не используется';

  @override
  String get pull => 'Pull';

  @override
  String get needRestart => 'Требуется перезапуск приложения';

  @override
  String get parseContainerStatsTip =>
      'Анализ статуса использования Docker может быть медленным';

  @override
  String get restart => 'Перезапустить';

  @override
  String get liveActivity => 'Активность в реальном времени';

  @override
  String get read => 'Чтение';

  @override
  String get second => 'с';

  @override
  String get back => 'Назад';

  @override
  String get history => 'История';

  @override
  String get homeDir => 'Домашняя папка';

  @override
  String selected(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get sftpRmrDirSummary =>
      'Использовать `rm -r` в SFTP для удаления папок';

  @override
  String get syncAppSettings => 'Синхронизировать настройки приложения';

  @override
  String get times => 'Раз';

  @override
  String get used => 'Использовано';

  @override
  String get wakeLock => 'Держать включенным';

  @override
  String get write => 'Запись';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count процесса',
      many: '$count процессов',
      few: '$count процесса',
      one: '$count процесс',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Службы';

  @override
  String get status => 'Состояние';

  @override
  String get enable => 'Включить';

  @override
  String get disable => 'Отключить';

  @override
  String get starting => 'Запускается';

  @override
  String get stopping => 'Останавливается';

  @override
  String get power => 'Питание';

  @override
  String get fan => 'Вентилятор';

  @override
  String get vendor => 'Производитель';

  @override
  String get agentLocalExec => 'Выполнять команды на этом устройстве';

  @override
  String get privacyBlur => 'Приватность в фоне';

  @override
  String get privacyBlurTip => 'Скрывать содержимое приложения в переключателе';

  @override
  String get benchmark => 'Тест производительности';

  @override
  String get peak => 'пик';

  @override
  String get hardware => 'Оборудование';

  @override
  String get from => 'С';

  @override
  String get to => 'По';

  @override
  String get samples => 'замеров';

  @override
  String get unavailable => 'недоступно';

  @override
  String get stored => 'сохранено';

  @override
  String get oldest => 'самый старый';

  @override
  String get attributes => 'атрибуты';

  @override
  String get cycle => 'Циклы';

  @override
  String get window => 'окно';

  @override
  String get connection => 'Подключение';

  @override
  String get behaviour => 'Поведение';

  @override
  String get optional => 'Необязательное';

  @override
  String get alerts => 'Оповещения';

  @override
  String get online => 'в сети';

  @override
  String get connect => 'Подключиться';

  @override
  String get move => 'Переместить';

  @override
  String get reduceMotion => 'Уменьшение движения';

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
