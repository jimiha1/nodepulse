part of '../entry.dart';

/// The resource alert rules: one list, one editor.
///
/// The rules themselves are evaluated by the native alert worker, not here —
/// this page only authors them. Everything it writes goes into
/// `Stores.setting.cfResourceAlertRules`, which `AlertSync` publishes to the
/// platform as part of the alert settings payload, so saving a rule is enough
/// to put it in front of the worker on its next run.
final class CfResourceAlertsPage extends ConsumerStatefulWidget {
  const CfResourceAlertsPage({super.key});

  static const route = AppRouteNoArg(
    page: CfResourceAlertsPage.new,
    path: '/settings/cf/resource-alerts',
  );

  @override
  ConsumerState<CfResourceAlertsPage> createState() =>
      _CfResourceAlertsPageState();
}

final class _CfResourceAlertsPageState
    extends ConsumerState<CfResourceAlertsPage> {
  List<CfResourceAlertRule> get _rules =>
      Stores.setting.cfResourceAlertRules.fetch();

  void _save(List<CfResourceAlertRule> rules) {
    Stores.setting.cfResourceAlertRules.put(rules);
    setState(() {});
  }

  Future<void> _edit([CfResourceAlertRule? rule]) async {
    final snapshot = ref.read(cfServersProvider).value;
    final result = await showDialog<CfResourceAlertRule>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _RuleEditorDialog(
        initial: rule,
        servers: [
          for (final s in snapshot?.servers ?? const <CfServer>[])
            (id: s.id, name: s.name),
        ],
      ),
    );
    if (result == null) return;

    final rules = [..._rules];
    final index = rules.indexWhere((r) => r.id == result.id);
    if (index >= 0) {
      rules[index] = result;
    } else {
      rules.add(result);
    }
    _save(rules);
  }

  Future<void> _delete(CfResourceAlertRule rule) async {
    final confirmed = await context.showRoundDialog<bool>(
      title: l10n.cfResourceRuleDelete,
      child: Text(l10n.cfResourceRuleDeleteConfirm(rule.name)),
      actions: Btn.ok().toList,
    );
    if (confirmed != true) return;
    _save([..._rules]..removeWhere((r) => r.id == rule.id));
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    final known = {
      for (final s in ref.watch(cfServersProvider).value?.servers ?? const <CfServer>[])
        s.id: s.name,
    };

    return Scaffold(
      appBar: CustomAppBar(title: Text(l10n.cfResourceAlerts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_edit()),
        icon: const Icon(Icons.add),
        label: Text(l10n.cfResourceRuleNew),
      ),
      body: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n.cfResourceAlertsEmpty,
                  textAlign: TextAlign.center,
                  style: UIs.text13Grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 88),
              itemCount: rules.length,
              itemBuilder: (_, i) {
                final rule = rules[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ruleCard(rule, known),
                );
              },
            ),
    );
  }

  Widget _ruleCard(CfResourceAlertRule rule, Map<String, String> known) {
    // A rule pointing at a node the site no longer reports is kept, not
    // deleted: the node may come back, and the rule is the user's text. It is
    // marked instead, and the worker skips it — see the evaluator's own
    // handling of an unknown id.
    final gone = rule.serverId != null && !known.containsKey(rule.serverId);
    final serverLabel = switch (rule.serverId) {
      null => l10n.cfResourceRuleServerAll,
      final id => known[id] ?? rule.serverName ?? id,
    };
    final threshold = _thresholdText(rule);

    return CardX(
      child: InkWell(
        borderRadius: CardX.borderRadius,
        onTap: () => unawaited(_edit(rule)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rule.name,
                            style: UIs.text15,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (gone) ...[
                          const SizedBox(width: 6),
                          Text(
                            l10n.cfResourceRuleServerGone,
                            style: UIs.text11Grey.copyWith(
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rule.trigger == CfResourceTrigger.avg
                          ? l10n.cfResourceRuleSummaryAvg(
                              _metricLabel(rule.metric),
                              rule.windowMinutes,
                              threshold,
                            )
                          : l10n.cfResourceRuleSummaryAll(
                              _metricLabel(rule.metric),
                              rule.windowMinutes,
                              threshold,
                            ),
                      style: UIs.text12Grey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serverLabel,
                      style: UIs.text11Grey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.enabled,
                onChanged: (on) => _save([
                  for (final r in _rules)
                    if (r.id == rule.id) r.copyWith(enabled: on) else r,
                ]),
              ),
              IconButton(
                tooltip: l10n.cfResourceRuleDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => unawaited(_delete(rule)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The create/edit form.
///
/// A dialog rather than a page: six fields, and the list behind it is where
/// the result goes. It owns its controllers and returns the finished rule —
/// null when dismissed, which is what tells the caller nothing changed.
class _RuleEditorDialog extends StatefulWidget {
  const _RuleEditorDialog({this.initial, required this.servers});

  final CfResourceAlertRule? initial;

  /// The nodes the site currently reports, as id and display name.
  final List<({String id, String name})> servers;

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _thresholdCtrl;

  late CfResourceMetric _metric;
  late int _windowMinutes;
  late CfResourceTrigger _trigger;
  late String? _serverId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _thresholdCtrl = TextEditingController(
      text: initial == null ? '' : _trimNumber(initial.threshold),
    );
    _metric = initial?.metric ?? CfResourceMetric.cpu;
    _windowMinutes = initial?.windowMinutes ?? 5;
    _trigger = initial?.trigger ?? CfResourceTrigger.avg;
    // A server the site no longer reports would otherwise be silently dropped
    // by the picker below and rewritten to "all servers" on save.
    _serverId = initial?.serverId;
    if (_serverId != null &&
        !widget.servers.any((s) => s.id == _serverId)) {
      _serverId = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _thresholdCtrl.text.trim();
    final threshold = double.tryParse(raw);
    if (threshold == null) {
      Toast.show(l10n.cfResourceRuleThresholdRequired);
      return;
    }
    if (threshold <= 0) {
      Toast.show(l10n.cfResourceRuleThresholdPositive);
      return;
    }
    // A percentage over 100 is not wrong to *store* — the metric might be
    // reinterpreted later, and the number is the user's — but it can never
    // fire, so it is worth one question rather than a silent dead rule.
    if (_metric.isPercent && threshold > 100) {
      final go = await context.showRoundDialog<bool>(
        title: l10n.cfResourceRuleThreshold,
        child: Text(l10n.cfResourceRuleThresholdOver100),
        actions: Btn.ok().toList,
      );
      if (go != true) return;
    }
    if (!mounted) return;

    final name = _nameCtrl.text.trim();
    final serverName = _serverId == null
        ? null
        : _serverNameOf(widget.servers, _serverId!);
    final base =
        widget.initial ??
        CfResourceAlertRule(
          id: _mintId(),
          name: '',
          metric: _metric,
          threshold: threshold,
          windowMinutes: _windowMinutes,
          trigger: _trigger,
        );

    Navigator.of(context).pop(
      base.copyWith(
        // An unnamed rule falls back to the metric's own name: a rule the
        // notification cannot name is one nobody can act on.
        name: name.isEmpty ? _metricLabel(_metric) : name,
        metric: _metric,
        threshold: threshold,
        serverId: () => _serverId,
        serverName: () => serverName,
        windowMinutes: _windowMinutes,
        trigger: _trigger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? l10n.cfResourceRuleNew
            : l10n.cfResourceRuleEdit,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(l10n.cfResourceRuleName),
            Input(
              controller: _nameCtrl,
              hint: l10n.cfResourceRuleNameHint,
              suggestion: false,
            ),
            const SizedBox(height: 12),
            _fieldLabel(l10n.cfResourceRuleMetric),
            _dropdown<CfResourceMetric>(
              value: _metric,
              items: CfResourceMetric.values,
              label: _metricLabel,
              onChanged: (v) => setState(() => _metric = v),
            ),
            const SizedBox(height: 12),
            _fieldLabel(l10n.cfResourceRuleThreshold),
            Input(
              controller: _thresholdCtrl,
              type: const TextInputType.numberWithOptions(decimal: true),
              icon: Icons.speed,
              suffix: Text(_metric.unit),
              suggestion: false,
            ),
            const SizedBox(height: 12),
            _fieldLabel(l10n.cfResourceRuleServer),
            _dropdown<String?>(
              value: _serverId,
              items: [null, for (final s in widget.servers) s.id],
              label: (id) => id == null
                  ? l10n.cfResourceRuleServerAll
                  : _serverNameOf(widget.servers, id) ?? id,
              onChanged: (v) => setState(() => _serverId = v),
            ),
            const SizedBox(height: 12),
            _fieldLabel(l10n.cfResourceRuleWindow),
            _dropdown<int>(
              value: _windowMinutes,
              items: CfResourceAlertRule.windowOptions,
              label: (m) => l10n.cfResourceWindowFmt(m),
              onChanged: (v) => setState(() => _windowMinutes = v),
            ),
            const SizedBox(height: 12),
            _fieldLabel(l10n.cfResourceRuleTrigger),
            _dropdown<CfResourceTrigger>(
              value: _trigger,
              items: CfResourceTrigger.values,
              label: _triggerLabel,
              onChanged: (v) => setState(() => _trigger = v),
            ),
          ],
        ),
      ),
      actions: [
        Btn.cancel(),
        Btn.ok(onTap: () => unawaited(_submit())),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: UIs.text13Grey),
  );

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required void Function(T) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(value: item, child: Text(label(item))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

String _metricLabel(CfResourceMetric metric) => switch (metric) {
  CfResourceMetric.cpu => l10n.cfResourceMetricCpu,
  CfResourceMetric.ram => l10n.cfResourceMetricRam,
  CfResourceMetric.disk => l10n.cfResourceMetricDisk,
  CfResourceMetric.netIn => l10n.cfResourceMetricNetIn,
  CfResourceMetric.netOut => l10n.cfResourceMetricNetOut,
};

/// The display name of one node, or null when the list does not carry it.
///
/// Written as a loop rather than `firstWhereOrNull`: `fl_lib` and
/// `package:collection` both define that extension, and with both in scope the
/// call does not compile.
String? _serverNameOf(List<({String id, String name})> servers, String id) {
  for (final s in servers) {
    if (s.id == id) return s.name;
  }
  return null;
}

String _triggerLabel(CfResourceTrigger trigger) => switch (trigger) {
  CfResourceTrigger.avg => l10n.cfResourceTriggerAvg,
  CfResourceTrigger.all => l10n.cfResourceTriggerAll,
};

/// The threshold as the editor should show it: no trailing `.0`, which is what
/// `double.toString` would otherwise produce for a round number.
String _thresholdText(CfResourceAlertRule rule) {
  final unit = rule.metric.unit;
  return '${_trimNumber(rule.threshold)}$unit';
}

String _trimNumber(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// A rule id that is unique per creation and stable afterwards.
///
/// The native dedup state is keyed on it, so it must not be derived from the
/// rule's own text: editing a name would otherwise look like a new rule and
/// re-notify, and reusing a deleted rule's name would inherit its state.
String _mintId() =>
    'r${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
