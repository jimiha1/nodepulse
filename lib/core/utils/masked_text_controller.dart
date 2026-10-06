import 'package:flutter/widgets.dart';

/// A password field's controller that hides its text without asking the
/// platform to.
///
/// `TextField(obscureText: true)` is the obvious way to hide a password, and it
/// is what this app used. What it also does is send
/// `TYPE_TEXT_VARIATION_PASSWORD` to the IME — and that flag is how several
/// Chinese ROMs decide to raise their own *secure keyboard*, a separate input
/// method that replaces the user's for the duration of the field. On an Honor
/// device it is a distinct window (`InputMethod SecureIme`), and a user who
/// does not want it has no way to say so: the switch that used to offer the
/// choice was never read by anything.
///
/// So the hiding moves here. The field is an ordinary text field to the
/// platform — plain `TYPE_CLASS_TEXT`, the same input type the username field
/// gets, which no ROM treats specially — and the dots are drawn by
/// [buildTextSpan]. [masked] is the eye toggle.
///
/// The trade is explicit and is the reason this is a choice rather than a fix:
/// an ordinary field's text is visible to the IME, so a keyboard with
/// personalised learning or cloud suggestions can see a password typed through
/// it. That is what the secure keyboard was protecting against.
class MaskedTextEditingController extends TextEditingController {
  MaskedTextEditingController({super.text, this.masked = true});

  /// Whether [text] is drawn as [obscuringCharacter] rather than itself.
  ///
  /// The value the field submits is [text] either way — this changes only what
  /// is painted.
  bool masked;

  /// What each hidden character is drawn as.
  static const obscuringCharacter = '•';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!masked) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    // The length, not the characters: what is drawn is what a masked field
    // draws, and nothing here reads the value to decide it.
    return TextSpan(
      style: style,
      text: obscuringCharacter * text.length,
    );
  }
}
