import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:server_box/data/model/app/menu/server_func.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/view/page/home_tab.dart';
import 'package:server_box/view/page/setting/entries/home_tabs.dart';

void main() {
  group('the default order', () {
    test('is the bar, and the rest are behind "more"', () {
      // The list *is* the bar now, so it is a subset rather than everything.
      // The CF trim narrows a fresh bar to the server tab alone; the rest are
      // still reachable, behind "more" and through their own routes.
      expect(AppTab.defaultOrder, [AppTab.server]);
      expect(AppTab.overflowOf(AppTab.defaultOrder), [
        AppTab.ssh,
        AppTab.file,
      ]);
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
    /// stored record resolves against, so it is not free to follow the bar.
    test('is allowed to differ from the declaration order', () {
      expect(AppTab.defaultOrder, isNot(AppTab.values));
      expect(AppTab.server.index, 0);
      expect(AppTab.ssh.index, 1);
      expect(AppTab.file.index, 2);
    });
  });

  test('drops names the build no longer knows, keeping the stored order', () {
    // `snippet` named a tab the deleted domains took away; a record written by
    // a build that had it still parses, minus the names nobody can resolve.
    final tabs = AppTab.parseAppTabsFromObj([
      'server',
      'ssh',
      'file',
      'snippet',
    ]);

    expect(tabs, [AppTab.server, AppTab.ssh, AppTab.file]);
  });

  test('preserves an intentionally customized home tab list', () {
    final tabs = AppTab.parseAppTabsFromObj(['server', 'ssh']);

    expect(tabs, [AppTab.server, AppTab.ssh]);
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
    // puts the same page on screen twice and leaves "which position is
    // Terminal" without an answer — which is also what the reorder handler
    // asks when the set changes under it.
    final tabs = AppTab.parseAppTabsFromObj([
      'ssh',
      'server',
      'ssh',
      'file',
      'server',
    ]);

    expect(tabs, [AppTab.ssh, AppTab.server, AppTab.file]);
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
    final available = availableHomeTabs(const [AppTab.server]);

    expect(available, [AppTab.ssh, AppTab.file]);
  });

  /// A stored list may hold plain integers — `_parseAppTabFromElement`
  /// resolves one against `values` by position — so a retired case may never
  /// be replaced by a new one: [_retiredIndices] drops the integer instead of
  /// letting it resolve past the end of `values`.
  test('drops a retired tab index instead of resolving it', () {
    // 3 was `snippet`, then 4-7 named `agent`, `benchmark`, `remoteDesktop`
    // and `virt`. All gone; none may resolve.
    expect(AppTab.values, hasLength(3));
    expect(AppTab.parseAppTabsFromObj([0, 3, 4, 5, 6, 7, 1]), [
      AppTab.server,
      AppTab.ssh,
    ]);
    // Nothing left is nothing stored, which is what the default is for.
    expect(AppTab.parseAppTabsFromObj([7]), AppTab.defaultOrder);
    // The name is gone from `values` too, so a record that spelled it out is
    // dropped by the same path.
    expect(AppTab.parseAppTabsFromObj(['server', 'monitorSettings']), [
      AppTab.server,
    ]);
    expect(AppTab.parseAppTabsFromObj(['server', 'virt']), [AppTab.server]);
  });

  group('reorderHomeTabs', () {
    // [server, file] | separator at 2 | [ssh]
    const enabled = [AppTab.server, AppTab.file];
    const disabled = [AppTab.ssh];

    test('dragging past the separator enables a tab', () {
      final next = reorderHomeTabs(
        enabled: enabled,
        disabled: disabled,
        oldIndex: 3,
        newIndex: 1,
      );

      expect(next?.enabled, [AppTab.server, AppTab.ssh, AppTab.file]);
      expect(next?.disabled, isEmpty);
    });

    test('dragging under the separator disables a tab', () {
      final next = reorderHomeTabs(
        enabled: enabled,
        disabled: disabled,
        oldIndex: 1,
        newIndex: 3,
      );

      expect(next?.enabled, [AppTab.server]);
      expect(next?.disabled, [AppTab.ssh, AppTab.file]);
    });

    test('reorders within one half without changing what is enabled', () {
      final next = reorderHomeTabs(
        enabled: const [AppTab.server, AppTab.file, AppTab.ssh],
        disabled: const [],
        oldIndex: 2,
        newIndex: 0,
      );

      expect(next?.enabled, [AppTab.ssh, AppTab.server, AppTab.file]);
      expect(next?.disabled, isEmpty);
    });

    test('reports the server tab leaving, for the caller to refuse', () {
      final next = reorderHomeTabs(
        enabled: enabled,
        disabled: disabled,
        oldIndex: 0,
        newIndex: 3,
      );

      expect(next?.enabled, isNot(contains(AppTab.server)));
    });

    test('moves nothing for a drag that lands where it started', () {
      expect(
        reorderHomeTabs(
          enabled: enabled,
          disabled: disabled,
          oldIndex: 1,
          newIndex: 1,
        ),
        isNull,
      );
    });

    test('moves nothing when the separator itself is dragged', () {
      expect(
        reorderHomeTabs(
          enabled: enabled,
          disabled: disabled,
          oldIndex: 2,
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
