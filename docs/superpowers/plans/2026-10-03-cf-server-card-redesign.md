# 2026-10-03 CF Server Card Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign `CfServerCard` in the Flutter client (`lib/view/page/server/cf_card.dart`) into a modern layered dashboard featuring colored resource progress bars, tri-network latency and packet loss metrics, and clean typography.

**Architecture:** Split the presentation logic into modular widget helpers: Header with OS/uptime badges, linear progress indicators for CPU/Memory/Disk with load-based color ramps, and an enclosed sub-panel for real-time network, latency, loss, and diagnostics.

**Tech Stack:** Flutter 3.47+, Dart 3.11+, flutter_riverpod, fl_lib (CardX, UIs).

## Global Constraints
- Do not run code formatters (`dart format`). Match existing indentation and style.
- All telemetry and latency labels must use Chinese names (`电信`, `联通`, `移动`).
- Ensure dark/light theme compatibility using theme tokens.
- All existing tests in `test/unit/server/cf/` must pass.

---

### Task 1: Update Tests for New CfServerCard Layout & Metrics

**Files:**
- Modify: `test/unit/server/cf/cf_card_test.dart`

**Interfaces:**
- Consumes: `CfServer` model from `lib/data/model/cf/cf_server.dart`.
- Produces: Test assertions for LinearProgressIndicator widgets, packet loss metrics (`丢包: 电信`), and Chinese telecom latency text.

- [ ] **Step 1: Write test assertions for progress indicators and loss metrics in cf_card_test.dart**

```dart
testWidgets('renders progress indicators and loss metrics for cf server', (tester) async {
  final server = CfServer(
    id: 's1',
    name: 'Tokyo Node',
    region: 'JP',
    group: 'Edge',
    os: 'Ubuntu 22.04',
    online: true,
    cpu: 45.0,
    cpuCores: 4,
    ramUsed: 4096,
    ramTotal: 8192,
    swapUsed: 0,
    swapTotal: 2048,
    diskUsed: 51200,
    diskTotal: 102400,
    load1: 0.15,
    load5: 0.20,
    load15: 0.18,
    netInSpeed: 1024000,
    netOutSpeed: 512000,
    netRxMonthly: 1000000000,
    netTxMonthly: 2000000000,
    netRx: 1000000000,
    netTx: 2000000000,
    tcpConn: 85,
    udpConn: 12,
    processes: 120,
    pingCt: 45.0,
    pingCu: 38.0,
    pingCm: 60.0,
    lossCt: 0.0,
    lossCu: 1.0,
    lossCm: 0.0,
    bootTime: (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 86400 * 2,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CfServerCard(node: server),
      ),
    ),
  );

  expect(find.text('Tokyo Node'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  expect(find.textContaining('电信 45ms'), findsOneWidget);
  expect(find.textContaining('联通 38ms'), findsOneWidget);
  expect(find.textContaining('移动 60ms'), findsOneWidget);
  expect(find.textContaining('电信 0%'), findsOneWidget);
  expect(find.textContaining('联通 1%'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/unit/server/cf/cf_card_test.dart`
Expected: FAIL (LinearProgressIndicator not found or loss text missing).

---

### Task 2: Implement Modern Layered Dashboard in CfServerCard

**Files:**
- Modify: `lib/view/page/server/cf_card.dart`

**Interfaces:**
- Consumes: `CfServer` (`pingCt`, `pingCu`, `pingCm`, `lossCt`, `lossCu`, `lossCm`, `cpu`, `ramUsed`, `ramTotal`, etc.).
- Produces: `CfServerCard` stateless widget with Header, Resource Progress Gauges, and Sub-panel Grid.

- [ ] **Step 1: Implement `_resourceBar` helper with LinearProgressIndicator and color ramps**

```dart
Widget _resourceBar({
  required BuildContext context,
  required String label,
  required double percent,
  required String detail,
  Color? color,
}) {
  final effectiveColor = color ?? switch (percent) {
    > 85 => Colors.redAccent,
    > 60 => Colors.orangeAccent,
    _ => const Color(0xFF34C759),
  };
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(label, style: UIs.text12Grey),
        ),
        SizedBox(
          width: 52,
          child: Text('${percent.toStringAsFixed(1)}%', style: UIs.text13Bold),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(effectiveColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(detail, style: UIs.text12Grey),
      ],
    ),
  );
}
```

- [ ] **Step 2: Implement tri-network packet loss row `_losses()`**

```dart
List<Widget> _losses() {
  Text? at(String label, double? loss) => switch (loss) {
    null => null,
    final v => Text(
      '$label ${v.toStringAsFixed(0)}%',
      style: TextStyle(
        fontSize: 13,
        color: v > 0 ? Colors.redAccent : null,
        fontWeight: v > 0 ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  };
  final items = [?at('电信', node.lossCt), ?at('联通', node.lossCu), ?at('移动', node.lossCm)];
  if (items.isEmpty) return const [];
  return [
    Text('丢包: ', style: UIs.text12Grey),
    ...items,
  ];
}
```

- [ ] **Step 3: Reassemble `CfServerCard.build` with Header, Progress Gauges, and Sub-panel**

Assemble the 3 distinct visual sections inside `CardX`:
1. Header: Status dot, Server name, Region code, Group tag, OS distro icon + Uptime.
2. Resource Progress: CPU bar, RAM bar (`#0A84FF`), Disk bar (`#FF9F0A`).
3. Sub-panel container with slight background tint containing Realtime Speed, Monthly Quota, Tri-network Latency, Tri-network Loss, and System/Expiry details.

- [ ] **Step 4: Run Flutter unit tests**

Run: `flutter test test/unit/server/cf/`
Expected: 41/41 tests pass cleanly.

- [ ] **Step 5: Run Flutter analyzer**

Run: `flutter analyze lib test/unit/server/cf`
Expected: 0 issues found.

---

### Task 3: Build Debug APK and Install to Real Android Device

**Files:**
- Output: `build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 1: Build the updated APK**

Run: `flutter build apk --debug`
Expected: Build successfully created without error.

- [ ] **Step 2: Install onto real device with -d flag**

Run: `adb install -r -d build/app/outputs/flutter-apk/app-debug.apk`
Expected: `Success`

- [ ] **Step 3: Launch app and take updated screencap**

Run: `adb shell monkey -p tech.lolli.toolbox -c android.intent.category.LAUNCHER 1`
Run: `adb exec-out screencap -p > D:/flutter_server_box/screenshot_server_updated.png`
Expected: App launches and displays new modern dashboard layout.
