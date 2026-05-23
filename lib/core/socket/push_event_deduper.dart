/// Idempotency helper for push events that may replay after reconnect (§5.10).
class PushEventDeduper {
  final Map<String, DateTime> _lastObservedAtByKey = <String, DateTime>{};

  /// Returns `true` when [observedAt] is strictly newer than the last event
  /// for [key]. Updates internal state on accept.
  bool shouldAccept({
    required String key,
    required DateTime observedAt,
  }) {
    final normalized = observedAt.toUtc();
    final last = _lastObservedAtByKey[key];
    if (last != null && !normalized.isAfter(last)) {
      return false;
    }
    _lastObservedAtByKey[key] = normalized;
    return true;
  }

  /// Compare-only helper for flows that carry extra ordering (profile version).
  static bool isObservationAfter({
    required DateTime candidate,
    required DateTime? lastObservedAt,
  }) {
    if (lastObservedAt == null) {
      return true;
    }
    return candidate.toUtc().isAfter(lastObservedAt.toUtc());
  }

  void clear() => _lastObservedAtByKey.clear();
}
