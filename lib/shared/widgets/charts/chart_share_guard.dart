import 'package:flutter/foundation.dart';

/// Per-capture-key mutex for chart share operations.
///
/// Unrelated charts can share concurrently; only the same progress key is blocked
/// while capture and PDF generation are in flight.
abstract final class ChartShareGuard {
  static final Set<Object> _activeKeys = <Object>{};
  static final Map<Object, _ChartShareProgressNotifier> _keyNotifiers =
      <Object, _ChartShareProgressNotifier>{};

  /// Notifies only listeners for [key] when that key's busy state changes.
  static ValueListenable<int> listenableFor(Object key) {
    return _keyNotifiers.putIfAbsent(key, _ChartShareProgressNotifier.new);
  }

  /// Drops the notifier for [key] when it has no remaining listeners.
  static void releaseListenable(Object key) {
    final notifier = _keyNotifiers[key];
    if (notifier == null || notifier.isListenedTo) {
      return;
    }
    _keyNotifiers.remove(key);
    notifier.dispose();
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

final class _ChartShareProgressNotifier extends ValueNotifier<int> {
  _ChartShareProgressNotifier() : super(0);

  bool get isListenedTo => hasListeners;
}
