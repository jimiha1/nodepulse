import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/view/page/ssh/float.dart';

/// The windows that float over every tab.
class FloatingPanels extends ConsumerWidget {
  const FloatingPanels({super.key, required this.area});

  final Size area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        TerminalFloatingShell(area: area),
      ],
    );
  }
}
