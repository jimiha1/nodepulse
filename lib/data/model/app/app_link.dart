import 'package:nodepulse/data/model/app/tab.dart';

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
      ServerLink._host when segs.length == 1 => ServerLink(segs.single),
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

/// One server, by its id on the CF site.
///
/// The name is deliberately not carried: it changes with the site (a rename,
/// a different site), so the id is the only part that stays true, and the
/// caller already has a snapshot to look the name up in.
final class ServerLink extends AppLink {
  const ServerLink(this.id);

  static const _host = 'server';

  final String id;

  @override
  Uri toUri() =>
      Uri(scheme: AppLink.scheme, host: _host, pathSegments: [id]);
}
