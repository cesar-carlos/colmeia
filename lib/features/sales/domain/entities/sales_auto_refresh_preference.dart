import 'package:flutter/foundation.dart';

enum SalesAutoRefreshInterval {
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
}

extension SalesAutoRefreshIntervalDuration on SalesAutoRefreshInterval {
  Duration get duration => switch (this) {
    SalesAutoRefreshInterval.fiveMinutes => const Duration(minutes: 5),
    SalesAutoRefreshInterval.tenMinutes => const Duration(minutes: 10),
    SalesAutoRefreshInterval.fifteenMinutes => const Duration(minutes: 15),
    SalesAutoRefreshInterval.thirtyMinutes => const Duration(minutes: 30),
  };
}

@immutable
class SalesAutoRefreshPreference {
  const SalesAutoRefreshPreference({
    this.interval,
    this.lastSuccessfulRefreshAt,
    this.nextDueAt,
    this.remainingDelay,
    this.failureStreak = 0,
  });

  static const SalesAutoRefreshPreference disabled =
      SalesAutoRefreshPreference();

  final SalesAutoRefreshInterval? interval;
  final DateTime? lastSuccessfulRefreshAt;
  final DateTime? nextDueAt;
  final Duration? remainingDelay;
  final int failureStreak;

  bool get enabled => interval != null;
  bool get isBackingOff => failureStreak > 0;

  SalesAutoRefreshPreference copyWith({
    Object? interval = _sentinel,
    Object? lastSuccessfulRefreshAt = _sentinel,
    Object? nextDueAt = _sentinel,
    Object? remainingDelay = _sentinel,
    Object? failureStreak = _sentinel,
  }) {
    return SalesAutoRefreshPreference(
      interval: identical(interval, _sentinel)
          ? this.interval
          : interval as SalesAutoRefreshInterval?,
      lastSuccessfulRefreshAt: identical(lastSuccessfulRefreshAt, _sentinel)
          ? this.lastSuccessfulRefreshAt
          : lastSuccessfulRefreshAt as DateTime?,
      nextDueAt: identical(nextDueAt, _sentinel)
          ? this.nextDueAt
          : nextDueAt as DateTime?,
      remainingDelay: identical(remainingDelay, _sentinel)
          ? this.remainingDelay
          : remainingDelay as Duration?,
      failureStreak:
          identical(failureStreak, _sentinel)
              ? this.failureStreak
              : (failureStreak as int?) ?? 0,
    );
  }
}

const Object _sentinel = Object();
