/// Snapshot returned by `agent.getProfile` on the agent.
///
/// The hub forwards this exact payload back to the consumer; we keep it as a
/// thin entity so screens can refresh the catalog view without a new HTTP
/// round-trip via `GET /client/me/agents/{id}`.
class AgentProfileSnapshot {
  const AgentProfileSnapshot({
    required this.agentId,
    required this.name,
    required this.profileVersion,
    this.tradeName,
    this.document,
    this.documentType,
    this.phone,
    this.mobile,
    this.email,
    this.notes,
    this.observation,
    this.profileUpdatedAt,
    this.raw = const <String, Object?>{},
  });

  final String agentId;
  final String name;

  /// Server-side monotonic counter — `null` when the agent did not return
  /// the field (older agents). Callers should treat `null` as "unknown" and
  /// avoid relying on CAS in that case.
  final int? profileVersion;

  final String? tradeName;
  final String? document;
  final String? documentType;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? notes;
  final String? observation;
  final DateTime? profileUpdatedAt;

  /// Original wire payload, preserved verbatim for diagnostics. Callers
  /// should NOT depend on the keys here for business logic.
  final Map<String, Object?> raw;
}
