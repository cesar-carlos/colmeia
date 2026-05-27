/// Order-independent equality for nullable `Set<T>` values.
///
/// Two sets are equal when both are null, or when both contain the same
/// elements regardless of iteration order. Use together with
/// [appOrderedSetHash] to keep `==` and `hashCode` consistent.
bool appSetEquals<T>(Set<T>? a, Set<T>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null) {
    return a == null && b == null;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final value in a) {
    if (!b.contains(value)) {
      return false;
    }
  }
  return true;
}

/// Order-independent hash for nullable `Set<T>` values.
///
/// Maps each element through [keyOf] to a string, sorts the resulting list
/// lexicographically and hashes it. Returns `null` when [value] is `null` so
/// callers can fold it into `Object.hash` and keep `==` consistent.
int? appOrderedSetHash<T>(Set<T>? value, String Function(T element) keyOf) {
  if (value == null) {
    return null;
  }
  final sorted = value.map(keyOf).toList(growable: false)..sort();
  return Object.hashAll(sorted);
}
