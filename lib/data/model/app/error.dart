import 'package:server_box/core/extension/context/locale.dart';

/// Remote sync needs a backup password, and none is set.
///
/// Only an install that turned sync on before the password became required
/// gets here: every way of turning it on now asks for one first.
class RemoteBackupPasswordMissing implements Exception {
  const RemoteBackupPasswordMissing();

  @override
  String toString() => l10n.remoteBackupPasswordRequired;
}
