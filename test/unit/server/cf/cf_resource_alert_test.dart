import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/data/model/cf/cf_resource_alert.dart';

/// The rule model is a carrier between the settings UI and the native
/// evaluator, so what matters here is the wire format: the field names the
/// Kotlin side parses, and that a rule survives a round trip through the store
/// (which is `jsonDecode`d on the way back) unchanged.
void main() {
  CfResourceAlertRule rule({
    String id = 'rabc',
    String name = 'CPU 高',
    CfResourceMetric metric = CfResourceMetric.cpu,
    double threshold = 80,
    String? serverId,
    String? serverName,
    int windowMinutes = 5,
    CfResourceTrigger trigger = CfResourceTrigger.avg,
    bool enabled = true,
  }) => CfResourceAlertRule(
    id: id,
    name: name,
    metric: metric,
    threshold: threshold,
    serverId: serverId,
    serverName: serverName,
    windowMinutes: windowMinutes,
    trigger: trigger,
    enabled: enabled,
  );

  group('wire format', () {
    test('writes the field names the native evaluator parses', () {
      final j = rule(serverId: 'srv-1', serverName: 'Osaka').toJson();
      expect(j['id'], 'rabc');
      expect(j['name'], 'CPU 高');
      expect(j['metric'], 'cpu');
      expect(j['threshold'], 80);
      expect(j['serverId'], 'srv-1');
      expect(j['serverName'], 'Osaka');
      expect(j['windowMinutes'], 5);
      expect(j['trigger'], 'avg');
      expect(j['enabled'], true);
    });

    test('metric names are the ones Kotlin matches on', () {
      for (final m in CfResourceMetric.values) {
        expect(rule(metric: m).toJson()['metric'], m.name);
      }
      expect(CfResourceMetric.netIn.name, 'netIn');
      expect(CfResourceMetric.netOut.name, 'netOut');
      expect(CfResourceTrigger.avg.name, 'avg');
      expect(CfResourceTrigger.all.name, 'all');
    });

    test('omits an unset server rather than writing null', () {
      final j = rule().toJson();
      expect(j.containsKey('serverId'), isFalse);
      expect(j.containsKey('serverName'), isFalse);
    });

    test('round trips through json like the store does', () {
      final original = rule(
        metric: CfResourceMetric.netOut,
        threshold: 12.5,
        serverId: 'srv-1',
        serverName: 'Osaka',
        windowMinutes: 30,
        trigger: CfResourceTrigger.all,
        enabled: false,
      );
      final back = CfResourceAlertRule.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      )!;
      expect(back.id, original.id);
      expect(back.name, original.name);
      expect(back.metric, original.metric);
      expect(back.threshold, original.threshold);
      expect(back.serverId, original.serverId);
      expect(back.serverName, original.serverName);
      expect(back.windowMinutes, original.windowMinutes);
      expect(back.trigger, original.trigger);
      expect(back.enabled, original.enabled);
    });

    test('a threshold survives the store as a number, not a string', () {
      // `listProperty` JSON-encodes what `toObj` returns, and `fromJson` reads
      // it back with `_dbl`; a string would work there but would not match the
      // JSON the native side expects.
      final decoded = jsonDecode(jsonEncode(rule(threshold: 95).toJson()));
      expect((decoded as Map)['threshold'], isA<num>());
    });
  });

  group('parseList', () {
    test('reads the stored list', () {
      final raw = jsonDecode(
        jsonEncode(CfResourceAlertRule.toObjList([
          rule(id: 'r1'),
          rule(id: 'r2', metric: CfResourceMetric.ram),
        ])),
      );
      final rules = CfResourceAlertRule.parseList(raw);
      expect(rules.map((r) => r.id), ['r1', 'r2']);
      expect(rules.last.metric, CfResourceMetric.ram);
    });

    test('an empty or absent list is no rules', () {
      expect(CfResourceAlertRule.parseList(null), isEmpty);
      expect(CfResourceAlertRule.parseList(const []), isEmpty);
      expect(CfResourceAlertRule.parseList('not a list'), isEmpty);
      expect(CfResourceAlertRule.toObjList(null), isEmpty);
    });

    test('drops entries that no longer parse rather than failing the read', () {
      final raw = jsonDecode(
        jsonEncode([
          rule(id: 'good').toJson(),
          {'name': 'no id', 'metric': 'cpu', 'threshold': 80},
          'not an object',
          {'id': 'bad-metric', 'metric': 'wat', 'threshold': 80, 'windowMinutes': 5, 'trigger': 'avg'},
        ]),
      );
      final rules = CfResourceAlertRule.parseList(raw);
      expect(rules.map((r) => r.id), ['good']);
    });
  });

  group('fromJson', () {
    test('rejects a rule the evaluator could not run', () {
      Map<String, dynamic> base() => {
        'id': 'r1',
        'metric': 'cpu',
        'threshold': 80,
        'windowMinutes': 5,
        'trigger': 'avg',
      };
      expect(CfResourceAlertRule.fromJson(base()), isNotNull);

      expect(CfResourceAlertRule.fromJson(base()..remove('id')), isNull);
      expect(CfResourceAlertRule.fromJson(base()..['id'] = ''), isNull);
      expect(CfResourceAlertRule.fromJson(base()..['metric'] = 'wat'), isNull);
      expect(CfResourceAlertRule.fromJson(base()..remove('metric')), isNull);
      expect(CfResourceAlertRule.fromJson(base()..['trigger'] = 'wat'), isNull);
      expect(CfResourceAlertRule.fromJson(base()..remove('threshold')), isNull);
      expect(CfResourceAlertRule.fromJson(base()..['windowMinutes'] = 0), isNull);
      expect(CfResourceAlertRule.fromJson(base()..['windowMinutes'] = -5), isNull);
      expect(CfResourceAlertRule.fromJson(base()..remove('windowMinutes')), isNull);
    });

    test('an unnamed rule falls back to its metric name', () {
      final r = CfResourceAlertRule.fromJson({
        'id': 'r1',
        'metric': 'netIn',
        'threshold': 50,
        'windowMinutes': 5,
        'trigger': 'avg',
      })!;
      expect(r.name, 'netIn');
    });

    test('an absent enabled flag means enabled', () {
      final r = CfResourceAlertRule.fromJson({
        'id': 'r1',
        'metric': 'cpu',
        'threshold': 80,
        'windowMinutes': 5,
        'trigger': 'avg',
      })!;
      expect(r.enabled, isTrue);
    });

    test('an empty server id is no server, not an empty one', () {
      final r = CfResourceAlertRule.fromJson({
        'id': 'r1',
        'metric': 'cpu',
        'threshold': 80,
        'serverId': '',
        'serverName': '',
        'windowMinutes': 5,
        'trigger': 'avg',
      })!;
      expect(r.serverId, isNull);
      expect(r.serverName, isNull);
    });
  });

  group('windowOptions', () {
    test('offers only windows the site samples fast enough to judge', () {
      // The site samples about every two minutes and the evaluator needs two
      // samples, so a one-minute window could never fire.
      expect(CfResourceAlertRule.windowOptions, everyElement(greaterThanOrEqualTo(5)));
      expect(CfResourceAlertRule.windowOptions, isNotEmpty);
      expect(CfResourceAlertRule.windowOptions, orderedEquals([...CfResourceAlertRule.windowOptions]..sort()));
    });
  });

  group('metric units', () {
    test('percentages and speeds carry the unit the threshold is typed in', () {
      expect(CfResourceMetric.cpu.unit, '%');
      expect(CfResourceMetric.ram.unit, '%');
      expect(CfResourceMetric.disk.unit, '%');
      expect(CfResourceMetric.netIn.unit, 'Mbps');
      expect(CfResourceMetric.netOut.unit, 'Mbps');
      expect(CfResourceMetric.cpu.isPercent, isTrue);
      expect(CfResourceMetric.netIn.isPercent, isFalse);
    });
  });

  group('copyWith', () {
    test('clears a server explicitly but keeps it when not mentioned', () {
      final r = rule(serverId: 'srv-1', serverName: 'Osaka');
      expect(r.copyWith(name: 'x').serverId, 'srv-1');
      expect(r.copyWith(serverId: () => null).serverId, isNull);
      expect(r.copyWith(serverId: () => null).serverName, isNull);
    });

    test('never changes the id', () {
      final r = rule(id: 'fixed');
      expect(r.copyWith(name: 'other').id, 'fixed');
    });
  });
}
