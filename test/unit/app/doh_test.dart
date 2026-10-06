import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/core/utils/doh.dart';

/// A DoH response shaped like the ones the providers actually send: AliDNS
/// echoes the question as an object, DNSPod as an array, and both put the
/// records in `Answer`.
String _answer(List<Map<String, Object>> records) => '{"Status":0,"TC":false,'
    '"Question":{"name":"monitor.example.com.","type":1},'
    '"Answer":[${records.map((r) => '{"name":"monitor.example.com.","type":${r['type']},'
        '"TTL":300,"data":"${r['data']}"}').join(',')}]}';

void main() {
  group('parseDohAnswers', () {
    test('reads the A records out of an answer', () {
      final body = _answer([
        {'type': 1, 'data': '104.21.18.181'},
        {'type': 1, 'data': '172.67.183.26'},
      ]);
      expect(parseDohAnswers(body), ['104.21.18.181', '172.67.183.26']);
    });

    test('ignores records that are not IPv4 addresses', () {
      // An AAAA record and a CNAME chain are both normal in a real answer,
      // and neither is something a socket can be pointed at.
      final body = _answer([
        {'type': 28, 'data': '2606:4700:3033::ac43:b71a'},
        {'type': 5, 'data': 'somewhere.else.example.'},
        {'type': 1, 'data': '104.21.18.181'},
        {'type': 1, 'data': 'not-an-address'},
        {'type': 1, 'data': '999.1.1.1'},
      ]);
      expect(parseDohAnswers(body), ['104.21.18.181']);
    });

    test('answers with nothing when the response carries no answers', () {
      expect(parseDohAnswers('{"Status":3}'), isEmpty);
      expect(parseDohAnswers('{"Status":0,"Answer":[]}'), isEmpty);
    });
  });

  group('DohResolver', () {
    const alidns = DohProvider(
      address: '223.5.5.5',
      name: 'dns.alidns.com',
      path: '/resolve',
    );
    const dnspod = DohProvider(
      address: '1.12.12.12',
      name: 'doh.pub',
      path: '/dns-query',
    );

    test('asks the first provider and keeps its addresses', () async {
      final asked = <String>[];
      final resolver = DohResolver(
        providers: const [alidns, dnspod],
        fetch: (provider, host, timeout) async {
          asked.add(provider.name);
          return _answer([
            {'type': 1, 'data': '104.21.18.181'},
          ]);
        },
      );
      expect(await resolver.resolve('monitor.example.com'), ['104.21.18.181']);
      expect(asked, ['dns.alidns.com']);
    });

    test('moves on to the next provider when one fails', () async {
      final asked = <String>[];
      final resolver = DohResolver(
        providers: const [alidns, dnspod],
        fetch: (provider, host, timeout) async {
          asked.add(provider.name);
          if (provider.name == alidns.name) throw const SocketException('down');
          return _answer([
            {'type': 1, 'data': '172.67.183.26'},
          ]);
        },
      );
      expect(await resolver.resolve('monitor.example.com'), ['172.67.183.26']);
      expect(asked, ['dns.alidns.com', 'doh.pub']);
    });

    test('moves on when a provider answers with no usable address', () async {
      final asked = <String>[];
      final resolver = DohResolver(
        providers: const [alidns, dnspod],
        fetch: (provider, host, timeout) async {
          asked.add(provider.name);
          if (provider.name == alidns.name) return '{"Status":3}';
          return _answer([
            {'type': 1, 'data': '172.67.183.26'},
          ]);
        },
      );
      expect(await resolver.resolve('monitor.example.com'), ['172.67.183.26']);
      expect(asked, ['dns.alidns.com', 'doh.pub']);
    });

    test('keeps an answer for its ttl and asks again after', () async {
      var now = DateTime(2026, 10, 4, 12);
      var fetches = 0;
      final resolver = DohResolver(
        providers: const [alidns],
        clock: () => now,
        ttl: const Duration(minutes: 5),
        fetch: (provider, host, timeout) async {
          fetches++;
          return _answer([
            {'type': 1, 'data': '104.21.18.181'},
          ]);
        },
      );
      await resolver.resolve('monitor.example.com');
      now = now.add(const Duration(minutes: 4));
      await resolver.resolve('monitor.example.com');
      expect(fetches, 1, reason: 'a second lookup inside the ttl is served '
          'from the cache');

      now = now.add(const Duration(minutes: 2));
      await resolver.resolve('monitor.example.com');
      expect(fetches, 2, reason: 'past the ttl the address is looked up '
          'again, because an address that moves must not be pinned forever');
    });

    test('does not remember a failure', () async {
      var fetches = 0;
      final resolver = DohResolver(
        providers: const [alidns],
        fetch: (provider, host, timeout) async {
          fetches++;
          if (fetches == 1) throw const SocketException('down');
          return _answer([
            {'type': 1, 'data': '104.21.18.181'},
          ]);
        },
      );
      expect(await resolver.resolve('monitor.example.com'), isEmpty);
      expect(await resolver.resolve('monitor.example.com'), ['104.21.18.181']);
      expect(fetches, 2, reason: 'a resolver that was briefly unreachable is '
          'worth asking again');
    });

    test('stops asking once a provider has answered', () async {
      final asked = <String>[];
      final resolver = DohResolver(
        providers: const [alidns, dnspod],
        fetch: (provider, host, timeout) async {
          asked.add(provider.name);
          return _answer([
            {'type': 1, 'data': '104.21.18.181'},
          ]);
        },
      );
      await resolver.resolve('monitor.example.com');
      expect(asked, hasLength(1));
    });

    test('falls back to the platform resolver when no provider answers',
        () async {
      final resolver = DohResolver(
        providers: const [alidns, dnspod],
        fetch: (provider, host, timeout) async => throw const SocketException('down'),
        lookup: (host) async => ['10.0.0.9'],
      );
      expect(await resolver.resolveOrSystem('monitor.example.com'), ['10.0.0.9']);
    });

    test('prefers the DoH answer over the platform resolver', () async {
      var lookedUp = false;
      final resolver = DohResolver(
        providers: const [alidns],
        fetch: (provider, host, timeout) async => _answer([
          {'type': 1, 'data': '104.21.18.181'},
        ]),
        lookup: (host) async {
          lookedUp = true;
          return ['182.16.61.117'];
        },
      );
      expect(
        await resolver.resolveOrSystem('monitor.example.com'),
        ['104.21.18.181'],
      );
      expect(lookedUp, isFalse,
          reason: 'the platform resolver is the path being worked around');
    });
  });
}
