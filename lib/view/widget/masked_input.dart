import 'package:fl_lib/fl_lib.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nodepulse/core/utils/masked_text_controller.dart';

/// A password field that hides its text without raising the secure keyboard.
///
/// [Input] with `obscureText: true` is the ordinary way to do this, and it is
/// what this app used. The flag is not local to Flutter: it becomes
/// `TYPE_TEXT_VARIATION_PASSWORD` (0x80) on the `EditorInfo` the IME receives,
/// and several Chinese ROMs read that bit as "raise the secure keyboard" — on
/// the Honor device this was found on, a second input method window
/// (`InputMethod SecureIme`) replaces the user's for as long as the field has
/// focus.
///
/// So the hiding moves to [MaskedTextEditingController], which draws the dots
/// while the platform sees an ordinary text field. The eye is the reveal
/// toggle, and it is drawn here rather than by [Input] because [Input] only
/// offers one on an `obscureText` field.
///
/// **What this gives up.** An ordinary text field is one the IME may learn
/// from, so a keyboard with personalised suggestions or cloud sync can see a
/// password typed through it. That is the thing the secure keyboard was there
/// to prevent, and there is no third option: on Android the only text
/// configuration carrying neither the password bit nor the "visible password"
/// variation that contains it is a plain field with suggestions enabled.
/// Avoiding the secure keyboard and keeping the password from the IME are
/// mutually exclusive, and this build chooses the former.
final class MaskedInput extends StatefulWidget {
  const MaskedInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.autoFocus = false,
    this.onSubmitted,
    this.onChanged,
  });

  /// Must be a [MaskedTextEditingController]: the masking is the controller's,
  /// and a plain one would show the password.
  final MaskedTextEditingController controller;

  final String? label;
  final String? hint;
  final IconData? icon;
  final bool autoFocus;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  @override
  State<MaskedInput> createState() => _MaskedInputState();
}

class _MaskedInputState extends State<MaskedInput> {
  void _toggleMask() {
    setState(() => widget.controller.masked = !widget.controller.masked);
  }

  @override
  Widget build(BuildContext context) {
    return Input(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      icon: widget.icon,
      autoFocus: widget.autoFocus,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      // Named rather than left to inference: `null` lets `EditableText` pick
      // from the autofill hints, and any answer other than a plain text type
      // is one the engine decorates — `url`, for instance, becomes
      // `TYPE_TEXT_VARIATION_URI`.
      type: TextInputType.text,
      // Not `false`. Suppressing suggestions on a text field is the *other*
      // road to the same bit: the engine then emits
      // `TYPE_TEXT_VARIATION_VISIBLE_PASSWORD` (0x90), which contains 0x80.
      // Suggestions on is what keeps the field plain.
      suggestion: true,
      suffix: IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(
          widget.controller.masked
              ? Icons.visibility
              : Icons.visibility_off,
        ),
        onPressed: _toggleMask,
      ),
    );
  }
}
