class AgentPhaseTimings {
  AgentPhaseTimings(Map<String, double> phasesMs)
    : phasesMs = Map.unmodifiable(phasesMs);

  final Map<String, double> phasesMs;

  static AgentPhaseTimings? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final phases = <String, double>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (entry.key is String && value is num && value.isFinite && value >= 0) {
        phases[entry.key as String] = value.toDouble();
      }
    }
    return AgentPhaseTimings(phases);
  }

  static AgentPhaseTimings? fromRelayBody(Map<String, dynamic> body) {
    final meta = body['meta'];
    return meta is Map ? tryParse(meta['agent_phases']) : null;
  }
}
