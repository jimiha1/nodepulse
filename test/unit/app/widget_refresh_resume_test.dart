import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/core/chan.dart';

/// When coming forward pushes a home-widget refresh.
///
/// Worth its own tests because the wrong answer is invisible: the widget keeps
/// showing numbers, just stale ones, and the only evidence is a reading whose
/// age keeps growing.
void main() {
  group('pushesWidgetRefreshOnResume', () {
    test('a desktop never pushes', () {
      // The widgets are mobile-only; there is no channel on the other
      // platforms to push to.
      expect(
        MethodChans.pushesWidgetRefreshOnResume(
          isIOS: false,
          isAndroid: false,
          autoUpdateHomeWidget: true,
        ),
        isFalse,
      );
    });

    test('iOS follows its own switch', () {
      // The setting exists for iOS and its label describes exactly this
      // moment, so there it decides.
      expect(
        MethodChans.pushesWidgetRefreshOnResume(
          isIOS: true,
          isAndroid: false,
          autoUpdateHomeWidget: true,
        ),
        isTrue,
      );
      expect(
        MethodChans.pushesWidgetRefreshOnResume(
          isIOS: true,
          isAndroid: false,
          autoUpdateHomeWidget: false,
        ),
        isFalse,
      );
    });

    test('Android pushes regardless of the iOS switch', () {
      // The regression: the setting's default is `isIOS` — always false on
      // Android — and its control lived on the iOS settings page alone. Read
      // here, it made this call a no-op on every Android device, so opening
      // the app never refreshed the widget and no setting could change that.
      expect(
        MethodChans.pushesWidgetRefreshOnResume(
          isIOS: false,
          isAndroid: true,
          autoUpdateHomeWidget: false,
        ),
        isTrue,
        reason: 'the iOS-only switch must not gate the Android path',
      );
      expect(
        MethodChans.pushesWidgetRefreshOnResume(
          isIOS: false,
          isAndroid: true,
          autoUpdateHomeWidget: true,
        ),
        isTrue,
      );
    });
  });
}
