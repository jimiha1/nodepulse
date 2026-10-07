import 'dart:async';

import 'package:computer/computer.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/theme.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/app.dart';
import 'package:nodepulse/core/chan.dart';
import 'package:nodepulse/core/diag.dart';
import 'package:nodepulse/core/motion.dart';
import 'package:nodepulse/core/service/alert_sync.dart';
import 'package:nodepulse/core/service/crash_report.dart';
import 'package:nodepulse/core/service/native_exit.dart';
import 'package:nodepulse/core/service/theme_host.dart';
import 'package:nodepulse/core/service/widget_sync.dart';
import 'package:nodepulse/data/model/server/dist_license.dart';
import 'package:nodepulse/data/res/build_data.dart';
import 'package:nodepulse/data/res/misc.dart';
import 'package:nodepulse/data/res/store.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  await _runInZone(() async {
    final container = ProviderContainer();
    await _initApp(container);
    runApp(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
  });
}

Future<void> _runInZone(Future<void> Function() body) async {
  final zoneSpec = ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      parent.print(zone, line);
    },
  );

  await runZonedGuarded(body, (e, s) {
    if (CrashReport.isAppFault(e)) CrashLog.markUnhandled(e, s);
  }, zoneSpecification: zoneSpec);
}

Future<void> _initApp(ProviderContainer container) async {
  AppBinding();
  _setupDebug();

  await Paths.init(
    BuildData.name,
    bakName: Miscs.bakFileName,
    dirs: const {PathDir.img, PathDir.font},
    fileInUserDocuments: false,
  );
  await CrashLog.attach(Paths.doc.joinPath('logs'));
  Diag.tag(SbDiagTag.build, '${BuildData.build}');
  Diag.crumb(DiagCategory.lifecycle, 'launch');

  registerDistMarkLicenses();
  await _initData();
  await AppMotion.init();
  await _initWindow();
  await _doPlatformRelated(container);
}

Future<void> _initData() async {
  await (await getTemporaryDirectory()).create(recursive: true);

  await PrefStore.shared.init();
  await Stores.init();

  if (Stores.setting.betaTest.fetch()) AppUpdate.chan = AppUpdateChan.beta;

  initThemeHost();
  StoredPaths.repair(alsoRepair: [Stores.setting.fontPath]);

  final fontPath = Stores.setting.fontPath.fetch();
  unawaited(
    FontUtils.loadFrom(fontPath).catchError((Object e, StackTrace s) {
      Loggers.app.warning('Could not load the terminal font', e, s);
    }),
  );
  await ThemePackages.prepareSelectedTheme();
  ThemePackages.reconcileSelection();
  unawaited(ThemePackages.seedBundled());
  await AppFont.loadStored();
}

void _setupDebug() {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    DebugProvider.addLog(record);
  });
  CrashLog.handleErrors();
  // `CrashLog.uploadsNow` is deliberately left null: nothing this app records
  // is uploaded, so every crash is worth describing to the next launch, which
  // is what makes it keep the report the user copies out by hand.
  Diag.install(LocalDiagnosticsSink());

  AppRouteObserver.addListener((settings, type) {
    Diag.crumb(
      DiagCategory.nav,
      type.name,
      data: {'route': settings?.name ?? '-'},
    );
  });

  AppLifecycleListener(
    onPause: () => unawaited(Diag.flush()),
    onDetach: () => unawaited(Diag.flush()),
  );
}

Future<void> _doPlatformRelated(ProviderContainer container) async {
  if (isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e, s) {
      Loggers.app.warning('Failed to set high refresh rate', e, s);
    }
  }

  await NativeExitReport.shared.collect();

  // The kept report is the whole delivery path: nothing is sent from here, so
  // this is only the file the user copies out of Settings → Privacy.
  unawaited(CrashReport.keep());

  if (isIOS || isAndroid) {
    unawaited(
      (() async {
        try {
          await WidgetSync.instance.init(container);
        } catch (e, s) {
          Loggers.app.warning('WidgetSync init failed', e, s);
        }
      })(),
    );
  }

  if (isAndroid) {
    unawaited(
      (() async {
        try {
          await AlertSync.instance.init(container);
        } catch (e, s) {
          Loggers.app.warning('AlertSync init failed', e, s);
        }
      })(),
    );
  }

  if (isIOS || isAndroid) {
    unawaited(
      (() async {
        try {
          await MethodChans.setPrivacyBlur(Stores.setting.privacyBlur.fetch());
        } catch (e, s) {
          Loggers.app.warning('setPrivacyBlur failed', e, s);
        }
      })(),
    );
  }

  await Computer.shared.turnOn(workersCount: 1);
}

Future<void> _initWindow() async {
  if (!isDesktop) return;
  await SystemUIs.initDesktopWindow(
    hideTitleBar: Stores.setting.hideTitleBar.fetch(),
  );
}
