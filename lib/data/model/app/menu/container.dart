import 'package:fl_lib/fl_lib.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/data/model/container/status.dart';

/// `logs` and `terminal` used to sit here and opened an interactive terminal;
/// both went with the SSH terminal itself.
enum ContainerMenu {
  start,
  stop,
  restart,
  rm;

  static List<ContainerMenu> items(ContainerStatus status) {
    if (status.isRunning) {
      return [stop, restart, rm];
    }
    if (status.isStopped || status == ContainerStatus.unknown) {
      return [start, rm];
    }
    return [rm];
  }

  IconData get icon => switch (this) {
    ContainerMenu.start => Icons.play_arrow,
    ContainerMenu.stop => Icons.stop,
    ContainerMenu.restart => Icons.restart_alt,
    ContainerMenu.rm => Icons.delete,
  };

  String get toStr => switch (this) {
    ContainerMenu.start => libL10n.start,
    ContainerMenu.stop => libL10n.stop,
    ContainerMenu.restart => libL10n.restart,
    ContainerMenu.rm => libL10n.delete,
  };
}
