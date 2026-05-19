import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:flutter/foundation.dart';

@immutable
class AutoRefreshSnapshot {
  const AutoRefreshSnapshot({
    this.option,
    this.lastSuccessfulRefreshAt,
    this.nextDueAt,
    this.remainingDelay,
    this.failureStreak = 0,
  });

  static const AutoRefreshSnapshot disabled = AutoRefreshSnapshot();

  final AutoRefreshOption? option;
  final DateTime? lastSuccessfulRefreshAt;
  final DateTime? nextDueAt;
  final Duration? remainingDelay;
  final int failureStreak;

  bool get enabled => option != null;
  bool get isBackingOff => failureStreak > 0;

  AutoRefreshSnapshot copyWith({
    Object? option = _sentinel,
    Object? lastSuccessfulRefreshAt = _sentinel,
    Object? nextDueAt = _sentinel,
    Object? remainingDelay = _sentinel,
    Object? failureStreak = _sentinel,
  }) {
    return AutoRefreshSnapshot(
      option: identical(option, _sentinel)
          ? this.option
          : option as AutoRefreshOption?,
      lastSuccessfulRefreshAt: identical(lastSuccessfulRefreshAt, _sentinel)
          ? this.lastSuccessfulRefreshAt
          : lastSuccessfulRefreshAt as DateTime?,
      nextDueAt: identical(nextDueAt, _sentinel)
          ? this.nextDueAt
          : nextDueAt as DateTime?,
      remainingDelay: identical(remainingDelay, _sentinel)
          ? this.remainingDelay
          : remainingDelay as Duration?,
      failureStreak: identical(failureStreak, _sentinel)
          ? this.failureStreak
          : (failureStreak as int?) ?? 0,
    );
  }
}

const Object _sentinel = Object();
