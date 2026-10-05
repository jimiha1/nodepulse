/// What a [CfResourceAlertRule] watches.
///
/// The names are what the native evaluator matches on, so they are part of the
/// stored format and the JSON payload: renaming a case means an older build's
/// rules stop being understood. The percentages read the same history columns
/// the charts do; the two speed metrics convert B/s to Mbps on the native side,
/// which is the unit the threshold is typed in.
enum CfResourceMetric {
  cpu,
  ram,
  disk,
  netIn,
  netOut;

  /// The unit a threshold for this metric is in, for the settings UI.
  String get unit => switch (this) {
    CfResourceMetric.cpu || CfResourceMetric.ram || CfResourceMetric.disk => '%',
    CfResourceMetric.netIn || CfResourceMetric.netOut => 'Mbps',
  };

  bool get isPercent => unit == '%';

  static CfResourceMetric? parse(String? raw) {
    if (raw == null) return null;
    for (final m in values) {
      if (m.name == raw) return m;
    }
    return null;
  }
}

/// How a window of samples is judged against the threshold.
enum CfResourceTrigger {
  /// The mean of the window is over the threshold.
  avg,

  /// Every sample in the window is over the threshold.
  all;

  static CfResourceTrigger? parse(String? raw) {
    if (raw == null) return null;
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}

/// One user-authored rule: watch [metric] on [serverId] (or every node, when
/// null) over a [windowMinutes] window, and alert when [trigger] says the
/// window is over [threshold].
///
/// Stored as one JSON object per rule inside the `cfResourceAlertRules` list
/// property, and handed to the native side in the same shape — the evaluator
/// that runs the comparison is Kotlin, so this class is a carrier, not a
/// judge. [id] is minted once at creation and never changes: the native dedup
/// state is keyed on it, so a re-created rule with the same name would
/// otherwise inherit the old rule's "already notified" state.
class CfResourceAlertRule {
  final String id;
  final String name;
  final CfResourceMetric metric;
  final double threshold;

  /// The node this watches, or null for every node the site reports.
  final String? serverId;

  /// The node's display name at the time the rule was written, so the list can
  /// name a server the snapshot no longer carries.
  final String? serverName;

  final int windowMinutes;
  final CfResourceTrigger trigger;
  final bool enabled;

  const CfResourceAlertRule({
    required this.id,
    required this.name,
    required this.metric,
    required this.threshold,
    this.serverId,
    this.serverName,
    required this.windowMinutes,
    required this.trigger,
    this.enabled = true,
  });

  /// The windows the UI offers. The native evaluator maps each to the history
  /// request that covers it — see `ResourceAlertEvaluator.windowHours`.
  ///
  /// There is no 1-minute option: the site samples about every two minutes, so
  /// a window that short could never hold the two samples a judgement needs,
  /// and offering it would mean offering a rule that can never fire.
  static const windowOptions = [5, 10, 15, 30, 60];

  /// [serverId] and [serverName] take a function rather than a plain value so
  /// that *clearing* the server is expressible: `serverId: () => null` means
  /// "no server, watch them all", which a null default cannot say because it
  /// already means "leave it alone".
  ///
  /// Clearing the id clears the name with it — a rule that watches every node
  /// has no one node to name, and keeping the old name would label it with a
  /// server it no longer watches. Passing [serverName] explicitly in the same
  /// call still wins, for the case where both are being set together.
  CfResourceAlertRule copyWith({
    String? name,
    CfResourceMetric? metric,
    double? threshold,
    String? Function()? serverId,
    String? Function()? serverName,
    int? windowMinutes,
    CfResourceTrigger? trigger,
    bool? enabled,
  }) {
    final nextServerId = serverId == null ? this.serverId : serverId();
    return CfResourceAlertRule(
      id: id,
      name: name ?? this.name,
      metric: metric ?? this.metric,
      threshold: threshold ?? this.threshold,
      serverId: nextServerId,
      serverName: serverName != null
          ? serverName()
          : (nextServerId == null ? null : this.serverName),
      windowMinutes: windowMinutes ?? this.windowMinutes,
      trigger: trigger ?? this.trigger,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'metric': metric.name,
    'threshold': threshold,
    if (serverId != null) 'serverId': serverId,
    if (serverName != null) 'serverName': serverName,
    'windowMinutes': windowMinutes,
    'trigger': trigger.name,
    'enabled': enabled,
  };

  /// Null on anything the payload cannot supply: a rule the evaluator cannot
  /// name is one it cannot report on either, and a silently defaulted metric
  /// would alert about something nobody asked for.
  static CfResourceAlertRule? fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final metric = CfResourceMetric.parse(j['metric'] as String?);
    final trigger = CfResourceTrigger.parse(j['trigger'] as String?);
    final threshold = _dbl(j['threshold']);
    final window = _int(j['windowMinutes']);
    if (id is! String || id.isEmpty) return null;
    if (metric == null || trigger == null || threshold == null) return null;
    if (window == null || window <= 0) return null;
    final serverId = j['serverId'];
    final serverName = j['serverName'];
    return CfResourceAlertRule(
      id: id,
      name: (j['name'] as String?)?.trim().isNotEmpty == true
          ? (j['name'] as String).trim()
          : metric.name,
      metric: metric,
      threshold: threshold,
      serverId: serverId is String && serverId.isNotEmpty ? serverId : null,
      serverName: serverName is String && serverName.isNotEmpty
          ? serverName
          : null,
      windowMinutes: window,
      trigger: trigger,
      enabled: j['enabled'] != false,
    );
  }

  /// Reads the stored list, dropping entries that no longer parse rather than
  /// failing the whole read: one bad rule is not a reason to lose the rest.
  ///
  /// The store hands back whatever `jsonDecode` made of the row, so this takes
  /// the decoded list — see `Stores.setting.cfResourceAlertRules`.
  static List<CfResourceAlertRule> parseList(Object? raw) {
    if (raw is! List) return const [];
    final rules = <CfResourceAlertRule>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final rule = CfResourceAlertRule.fromJson(Map<String, dynamic>.from(e));
      if (rule != null) rules.add(rule);
    }
    return rules;
  }

  /// The stored form: one JSON object per rule, which is what the store's
  /// `toObj` writes into the row.
  static List<Object?> toObjList(
    List<CfResourceAlertRule>? rules,
  ) => [for (final r in rules ?? const <CfResourceAlertRule>[]) r.toJson()];
}

int? _int(Object? v) => switch (v) {
  final int n => n,
  final num n => n.round(),
  final String s => int.tryParse(s),
  _ => null,
};

double? _dbl(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};
