import 'package:server_box/data/model/app/tab.dart';

/// A `serverbox://` link, parsed.
sealed class AppLink {
  const AppLink();

  static const scheme = 'serverbox';

  static AppLink? parse(String raw) {
    try {
      return _parse(Uri.parse(raw.trim()));
    } on FormatException {
      return null;
    }
  }

  static AppLink? _parse(Uri uri) {
    if (uri.scheme.toLowerCase() != scheme) return null;
    var segs = uri.pathSegments;
    if (segs.isNotEmpty && segs.last.isEmpty) {
      segs = segs.sublist(0, segs.length - 1);
    }
    if (segs.any((seg) => seg.isEmpty)) return null;
    return switch (uri.host.toLowerCase()) {
      TabLink._host when segs.length == 1 => TabLink._parse(segs.single),
      _ => null,
    };
  }

  Uri toUri();

  @override
  String toString() => toUri().toString();
}

/// One of the home tabs, by its [AppTab] name.
final class TabLink extends AppLink {
  const TabLink(this.tab);

  static const _host = 'tab';

  final AppTab tab;

  static TabLink? _parse(String name) {
    final tab = AppTab.values.asNameMap()[name];
    return tab == null ? null : TabLink(tab);
  }

  @override
  Uri toUri() =>
      Uri(scheme: AppLink.scheme, host: _host, pathSegments: [tab.name]);
}
