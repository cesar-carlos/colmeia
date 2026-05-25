/// Idempotency helper for push events that may replay after reconnect (§5.10).
///
/// [maxTrackedKeys] bounds the map size so long-running sessions with many
/// distinct agent IDs do not accumulate entries indefinitely. When the limit
/// is reached, the oldest entry (by insertion order — Dart `Map` is a
/// `LinkedHashMap`) is evicted before inserting the new one.
class PushEventDeduper {
  PushEventDeduper({this.maxTrackedKeys = 512});

  /// Maximum number of (key → DateTime) entries retained. Oldest entries
  /// are evicted first when this limit is reached.
  final int maxTrackedKeys;

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
    if (last == null && _lastObservedAtByKey.length >= maxTrackedKeys) {
      // Evict the oldest entry (first in LinkedHashMap insertion order).
      _lastObservedAtByKey.remove(_lastObservedAtByKey.keys.first);
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
