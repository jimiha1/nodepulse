// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get crashCollect => 'Діагностичні дані';

  @override
  String get crashCollectIntro =>
      'NodePulse записує те, що відбувається під час роботи, щоб можна було виправляти проблеми. Виберіть, скільки даних надсилати.';

  @override
  String get crashCollectNone => 'Нічого';

  @override
  String get crashCollectNoneTip =>
      'Звіти залишаються на цьому пристрої; після збою ви можете надіслати один вручну.';

  @override
  String get crashCollectBasic => 'Основні дані';

  @override
  String get crashCollectBasicTip =>
      'Містить лише відомості про збій; журнали й дані про продуктивність не включаються. **Це допомагає нам покращувати застосунок і виправляти помилки.**';

  @override
  String get crashCollectFull => 'Повні дані';

  @override
  String get crashCollectFullTip =>
      'Окрім журналу збою, містить дані про продуктивність і відомості про те, які функції використовуються: вони допомагають знайти, що працює повільно та які функції справді потрібні.';

  @override
  String get crashCollectFooter =>
      'На всіх рівнях відомі імена серверів, адреси та імена користувачів замінюються заповнювачами вже під час запису. Пізніше рівень збору можна змінити в налаштуваннях.';

  @override
  String get privacy => 'Конфіденційність';

  @override
  String get privacyPolicy => 'Політика конфіденційності';

  @override
  String get crashLastRunFailed =>
      'NodePulse несподівано завершив роботу під час останнього запуску.';

  @override
  String get crashReportTitle => 'Звіт про збій';

  @override
  String get crashReportHint =>
      'Це журнал попереднього запуску. Відомі імена та адреси серверів замінено заповнювачами, але інші дані можуть залишитися. Уважно прочитайте звіт перед надсиланням.';

  @override
  String get crashReportSubmit => 'Копіювати та повідомити';

  @override
  String get preReleaseUpdates => 'Отримувати оновлення попередніх версій';

  @override
  String get autoUpdateHomeWidget =>
      'Автоматичне оновлення віджетів на головному екрані';

  @override
  String get backupPassword => 'Пароль резервного копіювання';

  @override
  String get backupPasswordSet => 'Пароль резервного копіювання встановлено';

  @override
  String get backupPasswordTip =>
      'Встановіть пароль для шифрування файлів резервного копіювання. Залиште порожнім для відключення шифрування.';

  @override
  String get distIcon => 'Позначки дистрибутивів';

  @override
  String get distNameMap => 'Зіставлення імен';

  @override
  String get globe => 'Глобус';

  @override
  String get navTabMenuTip =>
      'Натисніть і утримуйте вкладку — або клацніть правою кнопкою — щоб підключити чи відключити все одразу.';

  @override
  String get remoteBackupPasswordRequired =>
      'Для віддалених резервних копій потрібен непорожній пароль резервного копіювання';

  @override
  String get backupTip =>
      'Експортовані дані можуть бути зашифровані паролем. \nБудь ласка, зберігайте їх у безпеці.';

  @override
  String get bgRun => 'Запуск у фоновому режимі';

  @override
  String get bgRunTip =>
      'Цей перемикач лише вказує на те, що програма намагатиметься працювати у фоновому режимі. Чи може вона працювати у фоновому режимі, залежить від прав доступу. Для AOSP-орієнтованих Android ROM, будь ласка, вимкніть \"Оптимізацію акумулятора\" в цьому додатку. Для MIUI / HyperOS, будь ласка, змініть політику економії енергії на \"Нескінченна\".';

  @override
  String get bgRunNeedsNotification =>
      'Робота у фоні потребує постійного сповіщення, а застосунок не має дозволу на сповіщення. Натисніть, щоб дозволити.';

  @override
  String get closeAfterSave => 'Зберегти та закрити';

  @override
  String get collapseUITip =>
      'Сховати довгі списки, що є у UI за замовчуванням';

  @override
  String get distro => 'Дистрибутив';

  @override
  String get dockerStatistics => 'Статистика Docker';

  @override
  String get envVars => 'Змінні середовища';

  @override
  String get fdroidReleaseTip =>
      'Якщо ви завантажили цей застосунок з F-Droid, рекомендується відключити цю опцію.';

  @override
  String get fullScreen => 'Повний екран';

  @override
  String get fullScreenJitter => 'Тремтіння в повноекранному режимі';

  @override
  String get fullScreenJitterHelp => 'Щоб уникнути вигоряння екрану';

  @override
  String get fullScreenTip =>
      'Чи слід увімкнути повноекранний режим під час повороту пристрою в горизонтальне положення? Ця опція стосується лише вкладки сервера.';

  @override
  String get homeTabs => 'Домашні вкладки';

  @override
  String get image => 'Зображення';

  @override
  String get sshKeyRecommended => 'Рекомендовано';

  @override
  String get unused => 'Не використовується';

  @override
  String get pull => 'Pull';

  @override
  String get needRestart => 'Необхідно перезапустити застосунок';

  @override
  String get parseContainerStatsTip =>
      'Парсинг статусу зайнятості Docker є відносно повільним.';

  @override
  String get restart => 'Перезапустити';

  @override
  String get liveActivity => 'Активність у реальному часі';

  @override
  String get read => 'Читати';

  @override
  String get second => 'сек.';

  @override
  String get back => 'Назад';

  @override
  String get history => 'Історія';

  @override
  String get homeDir => 'Домівка';

  @override
  String selected(int count) {
    return 'Вибрано: $count';
  }

  @override
  String get sftpRmrDirSummary =>
      'Використовуйте `rm -r`, щоб видалити папку в SFTP.';

  @override
  String get syncAppSettings => 'Синхронізувати налаштування застосунку';

  @override
  String get times => 'Рази';

  @override
  String get used => 'Використано';

  @override
  String get wakeLock => 'Залишити активним';

  @override
  String get write => 'Записати';

  @override
  String processCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count процесу',
      many: '$count процесів',
      few: '$count процеси',
      one: '$count процес',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Служби';

  @override
  String get status => 'Стан';

  @override
  String get enable => 'Увімкнути';

  @override
  String get disable => 'Вимкнути';

  @override
  String get starting => 'Запускається';

  @override
  String get stopping => 'Зупиняється';

  @override
  String get power => 'Живлення';

  @override
  String get fan => 'Вентилятор';

  @override
  String get vendor => 'Виробник';

  @override
  String get agentLocalExec => 'Виконувати команди на цьому пристрої';

  @override
  String get privacyBlur => 'Приватність у фоні';

  @override
  String get privacyBlurTip => 'Приховувати вміст програми в перемикачі';

  @override
  String get benchmark => 'Тест продуктивності';

  @override
  String get peak => 'пік';

  @override
  String get hardware => 'Обладнання';

  @override
  String get from => 'Від';

  @override
  String get to => 'До';

  @override
  String get samples => 'замірів';

  @override
  String get unavailable => 'недоступно';

  @override
  String get stored => 'збережено';

  @override
  String get oldest => 'найстаріший';

  @override
  String get attributes => 'атрибути';

  @override
  String get cycle => 'Цикли';

  @override
  String get window => 'вікно';

  @override
  String get connection => 'З\'єднання';

  @override
  String get behaviour => 'Поведінка';

  @override
  String get optional => 'Необов\'язкове';

  @override
  String get alerts => 'Сповіщення';

  @override
  String get online => 'онлайн';

  @override
  String get connect => 'Підключити';

  @override
  String get move => 'Перемістити';

  @override
  String get reduceMotion => 'Зменшення руху';

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
