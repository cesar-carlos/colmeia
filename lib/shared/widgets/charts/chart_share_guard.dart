import 'package:flutter/foundation.dart';

/// Per-capture-key mutex for chart share operations.
///
/// Unrelated charts can share concurrently; only the same progress key is blocked
/// while capture and PDF generation are in flight.
abstract final class ChartShareGuard {
  static final Set<Object> _activeKeys = <Object>{};
  static final Map<Object, ValueNotifier<int>> _keyNotifiers =
      <Object, ValueNotifier<int>>{};

  /// Notifies only listeners for [key] when that key's busy state changes.
  static ValueListenable<int> listenableFor(Object key) {
    return _keyNotifiers.putIfAbsent(key, () => ValueNotifier<int>(0));
  }

  static bool isInProgress(Object key) => _activeKeys.contains(key);

  static bool tryAcquire(Object key) {
    if (_activeKeys.contains(key)) {
      return false;
    }
    _activeKeys.add(key);
    _notifyKey(key);
    return true;
  }

  static void release(Object key) {
    if (_activeKeys.remove(key)) {
      _notifyKey(key);
    }
  }

  static void _notifyKey(Object key) {
    final notifier = _keyNotifiers[key];
    if (notifier != null) {
      notifier.value++;
    }
  }
}
