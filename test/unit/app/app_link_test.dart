import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/app/app_link.dart';

void main() {
  group('ServerLink', () {
    test('parses a server id', () {
      final link = AppLink.parse('serverbox://server/abc123');
      expect(link, isA<ServerLink>());
      expect((link! as ServerLink).id, 'abc123');
    });

    test('round-trips through toUri', () {
      const link = ServerLink('abc123');
      expect(link.toUri().toString(), 'serverbox://server/abc123');
      final again = AppLink.parse(link.toUri().toString());
      expect(again, isA<ServerLink>());
      expect((again! as ServerLink).id, 'abc123');
    });

    test('tolerates a trailing slash and surrounding whitespace', () {
      final link = AppLink.parse('  serverbox://server/abc123/  ');
      expect((link! as ServerLink).id, 'abc123');
    });

    test('refuses extra path segments', () {
      expect(AppLink.parse('serverbox://server/abc/def'), isNull);
    });

    test('refuses an empty id', () {
      expect(AppLink.parse('serverbox://server/'), isNull);
      expect(AppLink.parse('serverbox://server'), isNull);
    });

    test('refuses an unknown host', () {
      expect(AppLink.parse('serverbox://node/abc'), isNull);
    });

    test('refuses a foreign scheme', () {
      expect(AppLink.parse('https://server/abc'), isNull);
    });
  });

  group('TabLink', () {
    test('still parses, unaffected by the new shape', () {
      final link = AppLink.parse('serverbox://tab/server');
      expect(link, isA<TabLink>());
    });
  });
}
