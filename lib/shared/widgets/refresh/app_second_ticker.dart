import 'dart:async';

import 'package:flutter/foundation.dart';

class AppSecondTicker implements ValueListenable<DateTime> {
  AppSecondTicker._({
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  @visibleForTesting
  factory AppSecondTicker.create({
    DateTime Function()? now,
  }) {
    return AppSecondTicker._(now: now);
  }

  static final AppSecondTicker instance = AppSecondTicker._();

  final DateTime Function() _now;
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();
  Timer? _timer;
  DateTime _value = DateTime.now();

  @override
  DateTime get value => _timer?.isActive ?? false ? _value : _now();

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    if (_listeners.length == 1) {
      _start();
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _stop();
    }
  }

  @visibleForTesting
  int get listenerCount => _listeners.length;

  @visibleForTesting
  bool get isTicking => _timer?.isActive ?? false;

  void _start() {
    _value = _now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _value = _now();
      final listeners = List<VoidCallback>.from(_listeners);
      for (final listener in listeners) {
        if (_listeners.contains(listener)) {
          listener();
        }
      }
      if (_listeners.isEmpty) {
        _stop();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}
