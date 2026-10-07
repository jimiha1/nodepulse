import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:nodepulse/core/service/native_exit.dart';
import 'package:nodepulse/data/res/build_data.dart';

/// The text a user pastes into an issue after a crash.
///
/// Markdown, because that is where it is going. The log is fenced so that a
/// stack trace keeps its line breaks, and the environment is a list because it
/// is the part that gets read first and the part reporters most often leave
/// out — every one of the three open crash reports named a version and none
/// named the same thing twice.
///
/// **Not claimed to be anonymous.** Crumbs go through [Redact], but the log
/// also holds records this app has been writing for years, and some of those
/// format a server name into the message. Saying "redacted" about the whole
/// file would be false, and a user who believed it would post something they
/// would not have. The dialog shows the text and says to read it; this is why.
abstract final class CrashReport {
  /// How much of the log goes in.
  ///
  /// From the *end*: the lines nearest the crash are the ones worth having,
  /// and a report starting at launch and stopping halfway is the wrong half.
  /// Also keeps the text small enough to render in a dialog — the file itself
  /// is allowed to be twenty times this.
  static const maxLogChars = 24 * 1024;

  /// The kept report's filename, beside the logs it is made from.
  static const savedName = 'crash_report.md';

  /// Where the previous run's report waits for somebody to go and read it.
  ///
  /// **It has to be kept, because nothing prompts for it any more.** The toast
  /// this replaced was raised on the one launch that read the marker, and that
  /// was the only moment the report existed: `app.log.1` is the *previous*
  /// run's log, so the launch after next overwrites the crashed run's with an
  /// ordinary one. A row in Settings the user reaches whenever they get round
  /// to it needs the report to still be there when they do.
  ///
  /// Null before [CrashLog.attach] has run, which is the same window in which
  /// there is no log to build one from.
  static String? get savedPath => CrashLog.dirPath?.joinPath(savedName);

  /// Whether an unhandled error is something *this app* got wrong.
  ///
  /// It gates the marker, and the marker raises a dialog on the next launch
  /// asking the user to file a report — so what goes in it has to be something
  /// a report could act on. A machine that is off, a link that dropped, a
  /// server that answers the sftp subsystem with the output of a login script:
  /// those are conditions of the world. The user watched them fail, the
  /// failure is in the log either way, and being asked at the next launch to
  /// report the network is the kind of noise that teaches people to dismiss
  /// the dialog without reading it — including the time it is real.
  ///
  /// Narrow on purpose, and not an excuse. An error that reaches the zone
  /// handler at all is a routing bug: something failed to hand it to the page
  /// that asked, which is what the file browser's error view is for. This only
  /// decides whether to interrupt the user about it.
  static bool isAppFault(Object error) {
    // A wrapper with the original inside, and it is the original that says
    // where the failure came from.
    if (error is AsyncError) return isAppFault(error.error);

    // The whole `dart:io` family: a socket that would not open, a TLS
    // handshake that failed, a process that would not start, a file the OS
    // refused. `FileSystemException` is in there too, and included
    // deliberately — a disk that is full or a directory that is not ours reads
    // exactly like a path this app got wrong, and of the two only one is worth
    // waking someone about.
    if (error is IOException) return false;
    if (error is TimeoutException) return false;
    if (error is DioException) return false;

    return true;
  }

  /// Builds the report from the previous run's log.
  static Future<String> build() async => compose(
    log: await CrashLog.readPrevious(),
    build: BuildData.build,
    os: '${Pfs.type.name} ${Platform.operatingSystemVersion}',
    locale: Platform.localeName,
    identifiers: const {},
    previousExit: NativeExitReport.shared.lastExit,
    previousExitTrace: NativeExitReport.shared.lastExitTrace,
  );

  /// Keeps the previous run's report, for the user to read and hand over.
  ///
  /// Called once at launch, after `NativeExitReport.shared.collect` has had its
  /// say about how the process died. The file is the whole product: nothing is
  /// sent from here, at any time, and the log it quotes is the one thing this
  /// app writes that nobody has audited for what it might name — see the note
  /// on this class. A crash reaches the developer only when somebody opens
  /// Settings → Privacy, copies the report and sends it.
  static Future<void> collect() async => keep();

  /// Writes the report, and waits for nothing to do it.
  ///
  /// Nothing is uploaded from here, so this is only file work. It is kept
  /// separate from [collect] because a caller may want the report on disk
  /// without the rest of what a launch does.
  static Future<void> keep() async {
    if (!CrashLog.lastRunEndedBadly) return;
    final path = savedPath;
    if (path == null) return;
    try {
      // Replaces rather than accumulates. The newest crash is the one worth
      // reporting, and a directory of them is a disclosure risk that grows
      // on its own.
      await File(path).writeAsString(await build());
    } catch (e, s) {
      Loggers.app.warning('Could not keep the crash report', e, s);
    }
  }

  /// The kept report, or null when nothing has crashed since it was last read.
  static Future<String?> saved() async {
    final path = savedPath;
    if (path == null) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e, s) {
      Loggers.app.warning('Could not read the kept crash report', e, s);
      return null;
    }
  }

  /// Takes the kept report off the device.
  ///
  /// Offered because it is the user's log and they should be able to be rid of
  /// it without waiting for the next crash to overwrite it — which is the only
  /// other thing that ever does.
  static Future<void> dropSaved() async {
    final path = savedPath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e, s) {
      Loggers.app.warning('Could not drop the kept crash report', e, s);
    }
  }

  @visibleForTesting
  static String compose({
    required String? log,
    required int build,
    required String os,
    required String locale,
    Map<String, String> identifiers = const {},
    Map<String, String>? previousExit,
    String? previousExitTrace,
    int maxLogChars = maxLogChars,
  }) {
    final buf = StringBuffer()
      ..writeln('### Environment')
      ..writeln()
      ..writeln('- App: $build')
      ..writeln('- OS: $os')
      ..writeln('- Locale: $locale');

    // The platform's account of how the previous run ended, which is the one
    // fact a report assembled only from the previous run's log cannot contain:
    // a native crash leaves nothing behind in the run it kills, and the record
    // of it arrives on the next launch — into a different file.
    if (previousExit != null && previousExit.isNotEmpty) {
      final fields = previousExit.entries
          .map((e) => '${e.key} ${e.value}')
          .join(', ');
      buf.writeln('- Previous exit: $fields');
    }
    buf.writeln();

    // Before the log, because it describes the failure while the log only
    // leads up to it — and because it is the part a reader wants first. It is
    // not in the log at all: the platform hands it over on the launch after
    // the crash, into a file this report does not read.
    if (previousExitTrace != null && previousExitTrace.trim().isNotEmpty) {
      buf.writeln('### Previous exit trace');
      buf.writeln();
      buf.writeln('```');
      buf.writeln(previousExitTrace.trimRight());
      buf.writeln('```');
      buf.writeln();
    }

    if (log == null || log.trim().isEmpty) {
      // Says so rather than showing an empty fence. An empty log is itself
      // information — it means the run died before anything was written, which
      // points at startup.
      buf.writeln('### Log');
      buf.writeln();
      buf.writeln('_No log was kept for the previous run._');
      return buf.toString();
    }

    var body = log;
    var truncated = false;
    if (body.length > maxLogChars) {
      body = body.substring(body.length - maxLogChars);
      truncated = true;
      // Whole lines only: cutting by character count lands mid-line, and a
      // half stack frame at the top reads as corruption.
      final firstBreak = body.indexOf('\n');
      if (firstBreak != -1) body = body.substring(firstBreak + 1);
    }

    buf.writeln('### Log');
    buf.writeln();
    if (truncated) buf.writeln('_Earlier lines omitted._');
    buf.writeln('```');
    buf.writeln(body.trimRight());
    buf.writeln('```');
    return buf.toString();
  }
}
