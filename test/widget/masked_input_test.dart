/// What a field asks the platform for, and whether that raises a secure
/// keyboard.
///
/// `TextField(obscureText: true)` is the ordinary way to hide a password, and
/// it is what this app used — but the flag is not local to Flutter. The engine
/// turns it into `TYPE_TEXT_VARIATION_PASSWORD` (0x80) on the `EditorInfo` the
/// IME receives, and several Chinese ROMs read exactly that bit as "raise the
/// secure keyboard". On the Honor device this was found on, a second input
/// method window (`InputMethod SecureIme`) replaces the user's while the field
/// has focus.
///
/// There are **three** roads to that bit, and two of them are easy to miss:
///
/// 1. `obscureText: true` → `TYPE_TEXT_VARIATION_PASSWORD` (0x80).
/// 2. `enableSuggestions: false` on a text field → the engine emits
///    `TYPE_TEXT_VARIATION_VISIBLE_PASSWORD` (0x90), which *contains* 0x80.
///    This is why the site-URL field raised the secure keyboard without ever
///    being a password field: it passed `suggestion: false`.
/// 3. `inputType: TextInputType.visiblePassword` → 0x90 as well.
///
/// These tests assert on the `TextInput.setClient` configuration — the exact
/// JSON the framework hands the engine, and therefore the only place the bug is
/// visible from Dart. A widget test that merely found the field would pass
/// against the broken code, so the detector is tested too.
library;

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/core/utils/masked_text_controller.dart';
import 'package:nodepulse/view/widget/masked_input.dart';

/// Records every `TextInput.setClient` configuration sent from now on.
///
/// Installed before the field is focused: focusing sends the configuration,
/// and a recorder installed afterwards would miss it.
List<Map<String, Object?>> _recordConfigs(WidgetTester tester) {
  final configs = <Map<String, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.textInput,
    (call) async {
      if (call.method == 'TextInput.setClient') {
        // `setClient(clientId, configuration)`.
        final args = call.arguments as List<Object?>;
        configs.add(
          Map<String, Object?>.from(args[1] as Map<Object?, Object?>),
        );
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      null,
    ),
  );
  return configs;
}

/// Whether a configuration would raise a secure keyboard, by all three roads.
void expectNoSecureKeyboard(Map<String, Object?> config) {
  expect(
    config['obscureText'],
    isNot(true),
    reason: 'obscureText becomes TYPE_TEXT_VARIATION_PASSWORD (0x80)',
  );
  expect(
    config['enableSuggestions'],
    isNot(false),
    reason:
        'enableSuggestions false becomes TYPE_TEXT_VARIATION_VISIBLE_PASSWORD '
        '(0x90), which contains the password bit 0x80',
  );
  expect(
    config['inputType'],
    isNot('visiblePassword'),
    reason: 'visiblePassword is 0x90 as well',
  );
}

Map<String, Object?> _lastOf(List<Map<String, Object?>> configs) {
  expect(configs, isNotEmpty, reason: 'the field never asked for a keyboard');
  return configs.last;
}

void main() {
  testWidgets('a masked field draws dots but asks for a plain keyboard', (
    tester,
  ) async {
    final controller = MaskedTextEditingController(text: 'hunter2');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MaskedInput(controller: controller))),
    );
    final configs = _recordConfigs(tester);

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    expectNoSecureKeyboard(_lastOf(configs));

    // And it still hides: the dots are drawn here instead of by the platform.
    final context = tester.element(find.byType(EditableText));
    expect(
      controller.buildTextSpan(context: context, withComposing: false).text,
      '•' * 'hunter2'.length,
    );
  });

  testWidgets('revealing and re-hiding never changes the keyboard', (
    tester,
  ) async {
    final controller = MaskedTextEditingController(text: 'hunter2');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MaskedInput(controller: controller))),
    );
    final configs = _recordConfigs(tester);
    final context = tester.element(find.byType(EditableText));

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(controller.masked, isTrue);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();
    expect(controller.masked, isFalse);
    expect(
      controller.buildTextSpan(context: context, withComposing: false).text,
      'hunter2',
    );

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();
    expect(controller.masked, isTrue);

    // Every configuration the field ever sent is plain. Revealing is a paint
    // change: a field that re-asked for a password keyboard here would put the
    // secure keyboard back the moment somebody looked at what they had typed.
    for (final config in configs) {
      expectNoSecureKeyboard(config);
    }
  });

  testWidgets('the value it carries is never the masked string', (tester) async {
    final controller = MaskedTextEditingController(text: 'hunter2');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MaskedInput(controller: controller))),
    );

    // Masking is a paint decision. Anything that read the text back — the
    // submit path, autofill, a test — must see the password itself.
    expect(controller.text, 'hunter2');
  });

  // The detector is the whole test: if it cannot tell the broken
  // configurations apart from the good one, the tests above prove nothing.
  group('the detector fires on what this replaced', () {
    testWidgets('obscureText is the first road', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Input(controller: controller, obscureText: true),
          ),
        ),
      );
      final configs = _recordConfigs(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(_lastOf(configs)['obscureText'], isTrue);
    });

    testWidgets('suppressing suggestions is the second', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      // Exactly what the site-URL field did, with no password anywhere in
      // sight — and the secure keyboard came up anyway.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Input(controller: controller, suggestion: false),
          ),
        ),
      );
      final configs = _recordConfigs(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(_lastOf(configs)['enableSuggestions'], isFalse);
    });
  });
}
