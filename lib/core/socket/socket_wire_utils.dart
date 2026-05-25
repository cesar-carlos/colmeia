// Shared wire-parsing helpers for the socket layer.
//
// Extracted from the three locations where identical or near-identical
// implementations existed:
//   - ConsumerSocketConnection._toStringKeyedMap
//   - SocketCommandDispatcherImpl._toStringKeyedMap
//   - RelayCommandDispatcherImpl._toMap
//
// Using a top-level function keeps the callers independent of each other
// while removing the duplication (see general_rules.mdc — DRY).

/// Coerces [raw] to a `Map<String, dynamic>` regardless of whether the
/// incoming map uses `dynamic`, `Object?`, or an untyped key type.
///
/// Returns `null` for any non-Map input so callers can null-guard without
/// casting.
Map<String, dynamic>? socketToStringKeyedMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry<String, dynamic>(key.toString(), value),
    );
  }
  return null;
}
