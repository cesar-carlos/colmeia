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

  final Map<String, ({DateTime observedAt, int? revision})> _observations = {};

  /// Prefers monotonic [revision] when both events have one; otherwise uses
  /// [observedAt]. Unversioned events retain the last known revision.
  bool shouldAccept({
    required String key,
    required DateTime observedAt,
    int? revision,
  }) {
    final normalized = observedAt.toUtc();
    final last = _observations[key];
    if (last != null) {
      final hasComparableRevision = revision != null && last.revision != null;
      if (hasComparableRevision && revision < last.revision!) {
        return false;
      }
      final isNewerRevision =
          hasComparableRevision && revision > last.revision!;
      if (!isNewerRevision && !normalized.isAfter(last.observedAt)) {
        return false;
      }
    }
    if (last == null && _observations.length >= maxTrackedKeys) {
      // Evict the oldest entry (first in LinkedHashMap insertion order).
      _observations.remove(_observations.keys.first);
    }
    _observations[key] = (
      observedAt: normalized,
      revision: revision ?? last?.revision,
    );
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

  void clear() => _observations.clear();
}
