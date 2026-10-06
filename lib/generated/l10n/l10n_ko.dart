// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get crashCollect => '진단 데이터';

  @override
  String get crashCollectIntro =>
      'NodePulse는 문제를 해결할 수 있도록 실행 중 발생한 일을 기록합니다. 전송할 정보의 양을 선택할 수 있습니다.';

  @override
  String get crashCollectNone => '전송 안 함';

  @override
  String get crashCollectNoneTip => '보고서는 이 기기에 남아 있으며, 충돌 후 직접 보낼 수도 있습니다.';

  @override
  String get crashCollectBasic => '기본 정보';

  @override
  String get crashCollectBasicTip =>
      '충돌 정보만 포함하며 로그와 성능 데이터는 포함하지 않습니다. **앱을 개선하고 버그를 수정하는 데 도움이 됩니다.**';

  @override
  String get crashCollectFull => '전체 정보';

  @override
  String get crashCollectFullTip =>
      '충돌 로그와 함께 성능 데이터와 기능 사용 현황도 포함합니다. **느린 부분을 찾고, 어떤 기능이 실제로 쓰이는지 파악하는 데 사용됩니다.**';

  @override
  String get crashCollectFooter =>
      '모든 수준에서 알려진 서버 이름, 주소, 사용자 이름은 기록할 때 자리 표시자로 대체됩니다. 나중에 설정에서 수집 수준을 변경할 수 있습니다.';

  @override
  String get privacy => '개인정보';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get crashLastRunFailed => 'NodePulse가 마지막 실행 중 예기치 않게 종료되었습니다.';

  @override
  String get crashReportTitle => '충돌 보고서';

  @override
  String get crashReportHint =>
      '이전 실행의 로그입니다. 알려진 서버 이름과 주소는 자리 표시자로 대체되었지만 다른 정보가 남아 있을 수 있습니다. 제출하기 전에 주의 깊게 읽어 보세요.';

  @override
  String get crashReportSubmit => '복사 후 보고';

  @override
  String get preReleaseUpdates => '프리릴리스 업데이트 받기';

  @override
  String get autoUpdateHomeWidget => '홈 위젯 자동 업데이트';

  @override
  String get backupPassword => '백업 비밀번호';

  @override
  String get backupPasswordSet => '백업 비밀번호가 설정되었습니다';

  @override
  String get backupPasswordTip =>
      '백업 파일을 암호화하기 위한 비밀번호를 설정하세요. 암호화를 비활성화하려면 비워 두세요.';

  @override
  String get distIcon => '배포판 표시';

  @override
  String get distNameMap => '이름 매핑';

  @override
  String get globe => '지구본';

  @override
  String get navTabMenuTip =>
      '탭을 길게 누르거나 마우스 오른쪽 버튼으로 누르면 그 안의 모든 항목을 한 번에 연결하거나 끊을 수 있습니다.';

  @override
  String get remoteBackupPasswordRequired => '원격 백업에는 비어 있지 않은 백업 비밀번호가 필요합니다';

  @override
  String get backupTip => '내보낸 데이터는 비밀번호로 암호화할 수 있습니다.\n안전하게 보관해 주세요.';

  @override
  String get bgRun => '백그라운드 실행';

  @override
  String get bgRunTip =>
      '이 스위치는 프로그램이 백그라운드에서 실행을 시도한다는 의미입니다. 실제 백그라운드 실행 가능 여부는 권한 활성화 여부에 따라 다릅니다. AOSP 기반 Android ROM의 경우, 이 앱의 \"배터리 최적화\"를 비활성화해 주세요. MIUI / HyperOS의 경우, 절전 정책을 \"무제한\"으로 변경해 주세요.';

  @override
  String get bgRunNeedsNotification =>
      '백그라운드 실행에는 상주 알림이 필요하지만, 이 앱에는 알림 권한이 없습니다. 눌러서 알림을 허용하세요.';

  @override
  String get closeAfterSave => '저장 후 닫기';

  @override
  String get collapseUITip => 'UI의 긴 목록을 기본적으로 접을지 여부';

  @override
  String get distro => '배포판';

  @override
  String get dockerStatistics => 'Docker 통계';

  @override
  String get envVars => '환경 변수';

  @override
  String get fdroidReleaseTip => 'F-Droid에서 이 앱을 다운로드한 경우, 이 옵션을 끄는 것을 권장합니다.';

  @override
  String get fullScreen => '전체 화면';

  @override
  String get fullScreenJitter => '전체 화면 지터';

  @override
  String get fullScreenJitterHelp => '화면 번인 방지';

  @override
  String get fullScreenTip =>
      '기기를 가로 모드로 회전할 때 전체 화면 모드를 활성화하시겠습니까? 이 옵션은 서버 탭에만 적용됩니다.';

  @override
  String get homeTabs => '홈 탭';

  @override
  String get image => '이미지';

  @override
  String get sshKeyRecommended => '권장';

  @override
  String get unused => '미사용';

  @override
  String get pull => '풀';

  @override
  String get needRestart => '앱을 다시 시작해야 합니다';

  @override
  String get parseContainerStatsTip => 'Docker 점유 상태 파싱이 비교적 느립니다.';

  @override
  String get restart => '재시작';

  @override
  String get liveActivity => '실시간 활동';

  @override
  String get read => '읽기';

  @override
  String get second => '초';

  @override
  String get back => '뒤로';

  @override
  String get history => '기록';

  @override
  String get homeDir => '홈';

  @override
  String selected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get sftpRmrDirSummary => 'SFTP에서 `rm -r`을 사용하여 폴더를 삭제합니다.';

  @override
  String get syncAppSettings => '앱 설정 동기화';

  @override
  String get times => '회';

  @override
  String get used => '사용됨';

  @override
  String get wakeLock => '화면 깨우기 유지';

  @override
  String get write => '쓰기';

  @override
  String processCount(int count) {
    return '프로세스 $count개';
  }

  @override
  String get services => '서비스';

  @override
  String get status => '상태';

  @override
  String get enable => '활성화';

  @override
  String get disable => '비활성화';

  @override
  String get starting => '시작 중';

  @override
  String get stopping => '중지 중';

  @override
  String get power => '전원';

  @override
  String get fan => '팬';

  @override
  String get vendor => '제조사';

  @override
  String get agentLocalExec => '이 기기에서 명령 실행';

  @override
  String get privacyBlur => '백그라운드 개인정보 보호';

  @override
  String get privacyBlurTip => '앱 전환기에서 앱 내용 숨기기';

  @override
  String get benchmark => '벤치마크';

  @override
  String get peak => '최고';

  @override
  String get hardware => '하드웨어';

  @override
  String get from => '시작';

  @override
  String get to => '끝';

  @override
  String get samples => '샘플';

  @override
  String get unavailable => '사용할 수 없음';

  @override
  String get stored => '저장됨';

  @override
  String get oldest => '최장';

  @override
  String get attributes => '속성';

  @override
  String get cycle => '사이클';

  @override
  String get window => '기간';

  @override
  String get connection => '연결';

  @override
  String get behaviour => '동작';

  @override
  String get optional => '선택';

  @override
  String get alerts => '알림';

  @override
  String get online => '온라인';

  @override
  String get connect => '연결';

  @override
  String get move => '이동';

  @override
  String get reduceMotion => '동작 줄이기';

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
