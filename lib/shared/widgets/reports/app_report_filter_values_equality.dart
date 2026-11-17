import 'package:flutter/foundation.dart';

bool reportFilterValuesEqual(
  Map<String, Object?> first,
  Map<String, Object?> second,
) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (!second.containsKey(entry.key)) return false;
    final left = entry.value;
    final right = second[entry.key];
    if (left is List && right is List) {
      if (!listEquals(left, right)) return false;
    } else if (left != right) {
      return false;
    }
  }
  return true;
}
