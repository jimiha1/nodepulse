import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_az.dart';
import 'l10n_de.dart';
import 'l10n_en.dart';
import 'l10n_es.dart';
import 'l10n_fr.dart';
import 'l10n_id.dart';
import 'l10n_it.dart';
import 'l10n_ja.dart';
import 'l10n_ko.dart';
import 'l10n_nl.dart';
import 'l10n_pt.dart';
import 'l10n_ru.dart';
import 'l10n_tr.dart';
import 'l10n_uk.dart';
import 'l10n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// User-facing label or message for crash collect.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic data'**
  String get crashCollect;

  /// Introductory text for the crash collect screen or section.
  ///
  /// In en, this message translates to:
  /// **'NodePulse records what happens while it runs so problems can be fixed. Choose how much information to send.'**
  String get crashCollectIntro;

  /// Empty-state message for crash collect none.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get crashCollectNone;

  /// Help text for the crash collect none setting or action.
  ///
  /// In en, this message translates to:
  /// **'Reports remain on this device; after a crash, you can send one manually.'**
  String get crashCollectNoneTip;

  /// User-facing label or message for crash collect basic.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get crashCollectBasic;

  /// Help text for the crash collect basic setting or action.
  ///
  /// In en, this message translates to:
  /// **'Only crash information is included; logs and performance data are not. **This helps us improve the app and fix bugs.**'**
  String get crashCollectBasicTip;

  /// User-facing label or message for crash collect full.
  ///
  /// In en, this message translates to:
  /// **'Full information'**
  String get crashCollectFull;

  /// Help text for the crash collect full setting or action.
  ///
  /// In en, this message translates to:
  /// **'Along with the crash log, performance data and which features are used are included: **they show what is slow, and which features are worth keeping.**'**
  String get crashCollectFullTip;

  /// User-facing label or message for crash collect footer.
  ///
  /// In en, this message translates to:
  /// **'At every level, known server names, addresses and usernames are replaced with placeholders when recorded. You can change the collection level later in Settings.'**
  String get crashCollectFooter;

  /// User-facing label or message for privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// User-facing label or message for privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Error message shown when crash last run failed.
  ///
  /// In en, this message translates to:
  /// **'NodePulse exited unexpectedly during its last run.'**
  String get crashLastRunFailed;

  /// Title shown for the crash report dialog or section.
  ///
  /// In en, this message translates to:
  /// **'Crash report'**
  String get crashReportTitle;

  /// Hint shown in the crash report field or section.
  ///
  /// In en, this message translates to:
  /// **'This is the log from the previous run. Known server names and addresses have been replaced with placeholders, but other details may remain. Please read it carefully before submitting.'**
  String get crashReportHint;

  /// User-facing label or message for crash report submit.
  ///
  /// In en, this message translates to:
  /// **'Copy & report'**
  String get crashReportSubmit;

  /// User-facing label or message for pre release updates.
  ///
  /// In en, this message translates to:
  /// **'Receive pre-release updates'**
  String get preReleaseUpdates;

  /// User-facing label or message for auto update home widget.
  ///
  /// In en, this message translates to:
  /// **'Automatic home widget update'**
  String get autoUpdateHomeWidget;

  /// User-facing label or message for backup password.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPassword;

  /// User-facing label or message for backup password set.
  ///
  /// In en, this message translates to:
  /// **'Backup password set'**
  String get backupPasswordSet;

  /// Help text for the backup password setting or action.
  ///
  /// In en, this message translates to:
  /// **'Set a password to encrypt backup files. Leave empty to disable encryption.'**
  String get backupPasswordTip;

  /// User-facing label or message for dist icon.
  ///
  /// In en, this message translates to:
  /// **'Distribution marks'**
  String get distIcon;

  /// User-facing label or message for dist name map.
  ///
  /// In en, this message translates to:
  /// **'Name overrides'**
  String get distNameMap;

  /// User-facing label or message for globe.
  ///
  /// In en, this message translates to:
  /// **'Globe'**
  String get globe;

  /// Help text for the nav tab menu setting or action.
  ///
  /// In en, this message translates to:
  /// **'Long press a tab — or right-click it — to connect or disconnect everything on it at once.'**
  String get navTabMenuTip;

  /// User-facing label or message for remote backup password required.
  ///
  /// In en, this message translates to:
  /// **'Remote backups require a non-empty backup password'**
  String get remoteBackupPasswordRequired;

  /// Help text for the backup setting or action.
  ///
  /// In en, this message translates to:
  /// **'The exported data can be encrypted with password. \nPlease keep it safe.'**
  String get backupTip;

  /// User-facing label or message for bg run.
  ///
  /// In en, this message translates to:
  /// **'Run in background'**
  String get bgRun;

  /// Help text for the bg run setting or action.
  ///
  /// In en, this message translates to:
  /// **'This switch only means the program will try to run in the background. Whether it can run in the background depends on whether the permission is enabled or not. For AOSP-based Android ROMs, please disable \"Battery Optimization\" in this app. For MIUI / HyperOS, please change the power saving policy to \"Unlimited\".'**
  String get bgRunTip;

  /// User-facing label or message for bg run needs notification.
  ///
  /// In en, this message translates to:
  /// **'Running in the background needs an ongoing notification, and this app has no notification permission. Tap to allow notifications.'**
  String get bgRunNeedsNotification;

  /// Action label for close after save.
  ///
  /// In en, this message translates to:
  /// **'Save and close'**
  String get closeAfterSave;

  /// Help text for the collapse UI setting or action.
  ///
  /// In en, this message translates to:
  /// **'Whether to collapse long lists present in the UI by default'**
  String get collapseUITip;

  /// User-facing label or message for distro.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distro;

  /// User-facing label or message for docker statistics.
  ///
  /// In en, this message translates to:
  /// **'Docker Statistics'**
  String get dockerStatistics;

  /// User-facing label or message for env vars.
  ///
  /// In en, this message translates to:
  /// **'Environment variable'**
  String get envVars;

  /// Help text for the F-Droid release setting or action.
  ///
  /// In en, this message translates to:
  /// **'If you downloaded this app from F-Droid, it is recommended to turn off this option.'**
  String get fdroidReleaseTip;

  /// User-facing label or message for full screen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// User-facing label or message for full screen jitter.
  ///
  /// In en, this message translates to:
  /// **'Full screen jitter'**
  String get fullScreenJitter;

  /// User-facing label or message for full screen jitter help.
  ///
  /// In en, this message translates to:
  /// **'To avoid screen burn-in'**
  String get fullScreenJitterHelp;

  /// Help text for the full screen setting or action.
  ///
  /// In en, this message translates to:
  /// **'Should full-screen mode be enabled when the device is rotated to landscape mode? This option only applies to the server tab.'**
  String get fullScreenTip;

  /// User-facing label or message for home tabs.
  ///
  /// In en, this message translates to:
  /// **'Home Tabs'**
  String get homeTabs;

  /// A container image, as in Docker. NOT a picture — do not replace this with libL10n.image, whose German is "Bild" and Japanese "画像".
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// User-facing label or message for SSH key recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sshKeyRecommended;

  /// User-facing label or message for unused.
  ///
  /// In en, this message translates to:
  /// **'Unused'**
  String get unused;

  /// User-facing label or message for pull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get pull;

  /// User-facing label or message for need restart.
  ///
  /// In en, this message translates to:
  /// **'App needs to be restarted'**
  String get needRestart;

  /// Help text for the parse container stats setting or action.
  ///
  /// In en, this message translates to:
  /// **'Parsing the occupancy status of Docker is relatively slow.'**
  String get parseContainerStatsTip;

  /// Action label for restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// User-facing label or message for live activity.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get liveActivity;

  /// User-facing label or message for read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// User-facing label or message for second.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get second;

  /// User-facing label or message for back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// User-facing label or message for history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// User-facing label or message for home dir.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeDir;

  /// User-facing label or message for selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(int count);

  /// User-facing label or message for sftp rmr dir summary.
  ///
  /// In en, this message translates to:
  /// **'Use `rm -r` to delete a folder in SFTP.'**
  String get sftpRmrDirSummary;

  /// User-facing label or message for sync app settings.
  ///
  /// In en, this message translates to:
  /// **'Sync app settings'**
  String get syncAppSettings;

  /// User-facing label or message for times.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get times;

  /// User-facing label or message for used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// User-facing label or message for wake lock.
  ///
  /// In en, this message translates to:
  /// **'Keep awake'**
  String get wakeLock;

  /// User-facing label or message for write.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get write;

  /// User-facing label or message for process count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 process} other{{count} processes}}'**
  String processCount(int count);

  /// User-facing label or message for services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// User-facing label or message for status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Action label for enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// User-facing label or message for disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// Action label for starting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get starting;

  /// Action label for stopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get stopping;

  /// User-facing label or message for power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// User-facing label or message for fan.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get fan;

  /// User-facing label or message for vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// User-facing label or message for agent local exec.
  ///
  /// In en, this message translates to:
  /// **'Run commands on this device'**
  String get agentLocalExec;

  /// User-facing label or message for privacy blur.
  ///
  /// In en, this message translates to:
  /// **'Background privacy'**
  String get privacyBlur;

  /// Help text for the privacy blur setting or action.
  ///
  /// In en, this message translates to:
  /// **'Hide app content in the app switcher'**
  String get privacyBlurTip;

  /// User-facing label or message for benchmark.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get benchmark;

  /// User-facing label or message for peak.
  ///
  /// In en, this message translates to:
  /// **'peak'**
  String get peak;

  /// User-facing label or message for hardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get hardware;

  /// User-facing label or message for from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// User-facing label or message for to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// User-facing label or message for samples.
  ///
  /// In en, this message translates to:
  /// **'samples'**
  String get samples;

  /// User-facing label or message for unavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get unavailable;

  /// User-facing label or message for stored.
  ///
  /// In en, this message translates to:
  /// **'stored'**
  String get stored;

  /// User-facing label or message for oldest.
  ///
  /// In en, this message translates to:
  /// **'oldest'**
  String get oldest;

  /// User-facing label or message for attributes.
  ///
  /// In en, this message translates to:
  /// **'attributes'**
  String get attributes;

  /// User-facing label or message for cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// User-facing label or message for window.
  ///
  /// In en, this message translates to:
  /// **'window'**
  String get window;

  /// Action label for connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// User-facing label or message for behaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get behaviour;

  /// User-facing label or message for optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// User-facing label or message for alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// User-facing label or message for online.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get online;

  /// Action label for connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// User-facing label or message for move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// The settings entry and page title for the CF-Server-Monitor site.
  ///
  /// In en, this message translates to:
  /// **'CF Monitor Site'**
  String get cfSite;

  /// Placeholder of the input for the CF site's address.
  ///
  /// In en, this message translates to:
  /// **'https://status.example.com'**
  String get cfSiteUrlHint;

  /// Refusal shown when the CF site's address is not HTTPS, since the login password is posted to it.
  ///
  /// In en, this message translates to:
  /// **'The site must be an HTTPS address. A password sent over HTTP travels in the clear.'**
  String get cfSiteHttpsRequired;

  /// Whether the CF site's read endpoints need a login.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get cfAuth;

  /// Label of the CF site's login username input.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get cfUsername;

  /// Label of the CF site's login password input.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get cfPassword;

  /// Button: log in to the CF site as needed and read its node list once.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get cfTestConnection;

  /// Shown when the CF site connection test succeeded.
  ///
  /// In en, this message translates to:
  /// **'Connected, {n} servers'**
  String cfTestOk(int n);

  /// Shown when the CF site connection test failed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get cfTestFail;

  /// Shown on the CF home page in place of the raw 401 the site answered with, since the fix is to enter credentials in the settings.
  ///
  /// In en, this message translates to:
  /// **'This site needs a login'**
  String get cfNeedLogin;

  /// Button on the CF home page's error state, which otherwise has no way into the settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get cfOpenSettings;

  /// Shown on the CF home page when the app has never been pointed at a CF-Server-Monitor site, so the page has no error to report and only needs to say where to set one.
  ///
  /// In en, this message translates to:
  /// **'No monitor site yet'**
  String get cfNoSite;

  /// Second line under cfNoSite, naming what the settings entry is for.
  ///
  /// In en, this message translates to:
  /// **'Add the address of your CF-Server-Monitor site to see its nodes here.'**
  String get cfNoSiteTip;

  /// Label of the CF home overview's online-count cell.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get cfOverviewOnline;

  /// Label of the CF home overview's total-bandwidth cell.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get cfOverviewBandwidth;

  /// Label of a CF node card's one-minute load average.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get cfLoad;

  /// Label of what is left of a CF node's monthly traffic quota.
  ///
  /// In en, this message translates to:
  /// **'Traffic left'**
  String get cfTrafficRemaining;

  /// Label of a CF node's expiry date.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get cfExpire;

  /// CF server history live range
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get cfRangeLive;

  /// CF server history 30 minutes range
  ///
  /// In en, this message translates to:
  /// **'30m'**
  String get cfRangeM30;

  /// CF server history 1 hour range
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get cfRangeH1;

  /// CF server history 6 hours range
  ///
  /// In en, this message translates to:
  /// **'6h'**
  String get cfRangeH6;

  /// CF server history 1 day range
  ///
  /// In en, this message translates to:
  /// **'1d'**
  String get cfRangeD1;

  /// CF server history 2 days range
  ///
  /// In en, this message translates to:
  /// **'2d'**
  String get cfRangeD2;

  /// CF server history 7 days range
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get cfRangeD7;

  /// CF server detail CPU chart title
  ///
  /// In en, this message translates to:
  /// **'CPU Usage'**
  String get cfChartCpu;

  /// CF server detail memory and swap chart title
  ///
  /// In en, this message translates to:
  /// **'Memory & Swap'**
  String get cfChartMem;

  /// CF server detail disk used chart title
  ///
  /// In en, this message translates to:
  /// **'Disk Used'**
  String get cfChartDisk;

  /// CF server detail network speed chart title
  ///
  /// In en, this message translates to:
  /// **'Network Speed'**
  String get cfChartNet;

  /// CF server detail system load chart title
  ///
  /// In en, this message translates to:
  /// **'System Load'**
  String get cfChartLoad;

  /// CF server detail disk IO chart title
  ///
  /// In en, this message translates to:
  /// **'Disk IO'**
  String get cfChartDiskIo;

  /// CF server detail connections chart title
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get cfChartConn;

  /// CF server detail processes chart title
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get cfChartProcess;

  /// CF node alerts toggle title
  ///
  /// In en, this message translates to:
  /// **'Node alerts'**
  String get cfAlerts;

  /// CF node alerts toggle description
  ///
  /// In en, this message translates to:
  /// **'Periodic checks for traffic usage and node expiration'**
  String get cfAlertsTip;

  /// Threshold percentage of monthly traffic to trigger an alert
  ///
  /// In en, this message translates to:
  /// **'Traffic alert threshold'**
  String get cfAlertTrafficPct;

  /// Days before expiration to trigger an alert
  ///
  /// In en, this message translates to:
  /// **'Advance expiration notice'**
  String get cfAlertExpiryDays;

  /// Days format for alert settings
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String cfAlertDaysFmt(int days);

  /// Settings row that opens the resource alert rule list
  ///
  /// In en, this message translates to:
  /// **'Resource alert rules'**
  String get cfResourceAlerts;

  /// Empty state on the resource alert rule list
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Tap + to add one, for example \"CPU over 80% for 5 minutes\".'**
  String get cfResourceAlertsEmpty;

  /// Description under the resource alert rules row
  ///
  /// In en, this message translates to:
  /// **'Checked in the background every 15 minutes against the site\'s history'**
  String get cfResourceAlertsTip;

  /// Title of the resource alert rule editor when creating
  ///
  /// In en, this message translates to:
  /// **'New rule'**
  String get cfResourceRuleNew;

  /// Title of the resource alert rule editor when editing
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get cfResourceRuleEdit;

  /// Delete action on a resource alert rule
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get cfResourceRuleDelete;

  /// Confirmation before deleting a resource alert rule
  ///
  /// In en, this message translates to:
  /// **'Delete the rule \"{name}\"?'**
  String cfResourceRuleDeleteConfirm(String name);

  /// Name field label in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cfResourceRuleName;

  /// Name field hint in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'e.g. CPU too high'**
  String get cfResourceRuleNameHint;

  /// Metric picker label in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get cfResourceRuleMetric;

  /// Threshold field label in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get cfResourceRuleThreshold;

  /// Server picker label in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get cfResourceRuleServer;

  /// Server picker entry that watches every node
  ///
  /// In en, this message translates to:
  /// **'All servers'**
  String get cfResourceRuleServerAll;

  /// Window length picker label in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get cfResourceRuleWindow;

  /// Trigger mode picker label in the resource alert rule editor
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get cfResourceRuleTrigger;

  /// Validation message when the threshold is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a threshold'**
  String get cfResourceRuleThresholdRequired;

  /// Validation message when the threshold is zero or negative
  ///
  /// In en, this message translates to:
  /// **'The threshold must be greater than 0'**
  String get cfResourceRuleThresholdPositive;

  /// Confirmation when a percentage threshold exceeds 100
  ///
  /// In en, this message translates to:
  /// **'A percentage threshold over 100 can never fire. Save anyway?'**
  String get cfResourceRuleThresholdOver100;

  /// Marked on a rule whose server is not in the site's node list
  ///
  /// In en, this message translates to:
  /// **'Server no longer exists'**
  String get cfResourceRuleServerGone;

  /// One-line summary of a rule that fires on the window average
  ///
  /// In en, this message translates to:
  /// **'{metric} · mean over {window} min > {threshold}'**
  String cfResourceRuleSummaryAvg(String metric, int window, String threshold);

  /// One-line summary of a rule that fires when every sample is over
  ///
  /// In en, this message translates to:
  /// **'{metric} · every sample in {window} min > {threshold}'**
  String cfResourceRuleSummaryAll(String metric, int window, String threshold);

  /// Resource alert metric name
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cfResourceMetricCpu;

  /// Resource alert metric name
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get cfResourceMetricRam;

  /// Resource alert metric name
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get cfResourceMetricDisk;

  /// Resource alert metric name
  ///
  /// In en, this message translates to:
  /// **'Net in'**
  String get cfResourceMetricNetIn;

  /// Resource alert metric name
  ///
  /// In en, this message translates to:
  /// **'Net out'**
  String get cfResourceMetricNetOut;

  /// Resource alert trigger mode
  ///
  /// In en, this message translates to:
  /// **'Window average over threshold'**
  String get cfResourceTriggerAvg;

  /// Resource alert trigger mode
  ///
  /// In en, this message translates to:
  /// **'Every sample over threshold'**
  String get cfResourceTriggerAll;

  /// Window length in the rule editor
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String cfResourceWindowFmt(int minutes);

  /// Runs one node alert check immediately instead of waiting for the periodic worker
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get cfAlertCheckNow;

  /// Result of a manual alert check
  ///
  /// In en, this message translates to:
  /// **'Checked {count} nodes, {notified} alert(s) sent'**
  String cfAlertCheckOk(int count, int notified);

  /// Manual alert check failed because no site URL is configured
  ///
  /// In en, this message translates to:
  /// **'Set the site address first'**
  String get cfAlertCheckNoSite;

  /// Manual alert check failed because no credential is stored
  ///
  /// In en, this message translates to:
  /// **'Log in to the site first, so the check can read it'**
  String get cfAlertCheckNoToken;

  /// Manual alert check failed because the site answered 401/403
  ///
  /// In en, this message translates to:
  /// **'The site rejected the stored login — reopen this page to sign in again'**
  String get cfAlertCheckAuth;

  /// Manual alert check failed on the network
  ///
  /// In en, this message translates to:
  /// **'Could not reach the site'**
  String get cfAlertCheckNetwork;

  /// Manual alert check found no condition met
  ///
  /// In en, this message translates to:
  /// **'Checked {count} nodes, nothing to alert about'**
  String cfAlertCheckClear(int count);

  /// Manual alert check found alerts that were already sent today
  ///
  /// In en, this message translates to:
  /// **'Checked {count} nodes, already reminded today'**
  String cfAlertCheckSuppressed(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'az',
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'ko',
    'nl',
    'pt',
    'ru',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
