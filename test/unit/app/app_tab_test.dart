import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/data/model/app/menu/server_func.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/view/page/home_tab.dart';
import 'package:server_box/view/page/setting/entries/home_tabs.dart';

void main() {
  group('the default order', () {
    test('is the bar, and nothing is behind "more"', () {
      // The trim to a CF-Server-Monitor front end leaves the server tab as
      // the only one, so the bar is the whole enum.
      expect(AppTab.defaultOrder, [AppTab.server]);
      expect(AppTab.overflowOf(AppTab.defaultOrder), isEmpty);
    });

    test('every tab is reachable, in the bar or behind more', () {
      // Anything in neither is a tab a fresh install could not reach at all.
      expect(
        {...AppTab.defaultOrder, ...AppTab.overflowOf(AppTab.defaultOrder)},
        AppTab.values.toSet(),
      );
    });

    test('turning every tab on leaves nothing behind "more"', () {
      // Which is what removes the "more" destination — and why the settings
      // one beside it is pinned rather than being an `AppTab`: it is the only
      // way into the settings on a phone, and "more" used to carry it.
      expect(AppTab.overflowOf(AppTab.values), isEmpty);
      expect(availableHomeTabs(AppTab.values), isEmpty);
    });

    /// The declaration order is the `@HiveField` index and what an `int` in a
    /// stored record resolves against.
    test('declares server as the single primary tab', () {
      expect(AppTab.defaultOrder, equals(AppTab.values));
      expect(AppTab.server.index, 0);
    });
  });

  test('drops names the build no longer knows, keeping the stored order', () {
    // `ssh` and `file` named tabs the terminal-and-files trim took away; a
    // record written by a build that had them still parses, minus the names
    // nobody can resolve.
    final tabs = AppTab.parseAppTabsFromObj([
      'server',
      'ssh',
      'file',
      'snippet',
    ]);

    expect(tabs, [AppTab.server]);
  });

  test('uses defaults for null and empty tab values', () {
    expect(AppTab.parseAppTabsFromObj(null), AppTab.defaultOrder);
    expect(AppTab.parseAppTabsFromObj(const []), AppTab.defaultOrder);
  });

  test('uses non-null defaults when every stored tab name is unknown', () {
    expect(AppTab.parseAppTabsFromObj(['unknown']), AppTab.defaultOrder);
  });

  test('names one tab twice and gets it once, in the order it first appeared', () {
    // The home page indexes its pages and its nav bar by position, so a repeat
    // puts the same page on screen twice and leaves "which position is which"
    // without an answer — which is also what the reorder handler asks when the
    // set changes under it.
    final tabs = AppTab.parseAppTabsFromObj(['server', 'ssh', 'server']);

    expect(tabs, [AppTab.server]);
  });

  test('and mixes the ways a tab can be named without repeating it', () {
    // A record written by a build that stored indices, merged with one that
    // stored names: the same tab, said two ways.
    expect(
      AppTab.parseAppTabsFromObj(['server', AppTab.server.index, AppTab.server]),
      [AppTab.server],
    );
  });

  test('offers every arrangeable tab the stored list does not name', () {
    // A bar the user arranged once only names part of the enum; the rest has
    // to come back here, or the install could never turn one on.
    final available = availableHomeTabs(const []);

    expect(available, [AppTab.server]);
  });

  /// A stored list may hold plain integers — `_parseAppTabFromElement`
  /// resolves one against `values` by position — so a retired case may never
  /// be replaced by a new one: [_retiredIndices] drops the integer instead of
  /// letting it resolve past the end of `values`.
  test('drops a retired tab index instead of resolving it', () {
    // 1 was the terminal tab, 2 the file tab, and 3-7 named `snippet`,
    // `agent`, `benchmark`, `remoteDesktop` and `virt` before those. All
    // gone; none may resolve — and none may hand its index to the one tab
    // that is left.
    expect(AppTab.values, hasLength(1));
    expect(AppTab.parseAppTabsFromObj([0, 1, 2, 3, 4, 5, 6, 7]), [
      AppTab.server,
    ]);
    // Nothing left is nothing stored, which is what the default is for.
    expect(AppTab.parseAppTabsFromObj([7]), AppTab.defaultOrder);
    // The name is gone from `values` too, so a record that spelled it out is
    // dropped by the same path.
    expect(AppTab.parseAppTabsFromObj(['server', 'ssh']), [AppTab.server]);
    expect(AppTab.parseAppTabsFromObj(['server', 'file']), [AppTab.server]);
    expect(AppTab.parseAppTabsFromObj(['server', 'virt']), [AppTab.server]);
  });

  group('reorderHomeTabs', () {
    test('moves nothing when there is nothing to move', () {
      // One tab, and the separator beside it: any drag is either the
      // separator's own or lands where it started.
      expect(
        reorderHomeTabs(
          enabled: const [AppTab.server],
          disabled: const [],
          oldIndex: 0,
          newIndex: 0,
        ),
        isNull,
      );
      expect(
        reorderHomeTabs(
          enabled: const [AppTab.server],
          disabled: const [],
          oldIndex: 1,
          newIndex: 0,
        ),
        isNull,
      );
    });
  });

  group('the mark a feature carries', () {
    // Read off the enums rather than drawn: what the mark *looks* like is
    // fl_lib's to test, and what matters here is which entries have one. A tab
    // that gained a mark without the row that lists it being told would draw
    // the mark nowhere at all.
    test('nothing carries one now the beta features are gone', () {
      final marked = {
        for (final tab in AppTab.values)
          if (tab.mark != null) tab,
      };
      expect(marked, isEmpty);

      final markedBtns = {
        for (final btn in ServerFuncBtn.values)
          if (btn.mark != null) btn,
      };
      expect(markedBtns, isEmpty);
    });

    test('a tab with no mark is listed as plain text', () {
      expect(AppTab.server.mark, isNull);
      expect(AppTab.server.listTitle, isA<Text>());
    });
  });
}
