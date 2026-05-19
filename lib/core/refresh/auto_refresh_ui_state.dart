import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:flutter/foundation.dart';

@immutable
class AutoRefreshUiState {
  const AutoRefreshUiState({
    this.option,
    this.lastUpdatedAt,
    this.nextDueAt,
    this.remainingDelay,
    this.isBackingOff = false,
    this.failureStreak = 0,
  });

  final AutoRefreshOption? option;
  final DateTime? lastUpdatedAt;
  final DateTime? nextDueAt;
  final Duration? remainingDelay;
  final bool isBackingOff;
  final int failureStreak;

  AutoRefreshSnapshot toSnapshot() {
    return AutoRefreshSnapshot(
      option: option,
      lastSuccessfulRefreshAt: lastUpdatedAt,
      nextDueAt: nextDueAt,
      remainingDelay: remainingDelay,
      failureStreak: failureStreak,
    );
  }

  AutoRefreshUiState copyWith({
    Object? option = _sentinel,
    Object? lastUpdatedAt = _sentinel,
    Object? nextDueAt = _sentinel,
    Object? remainingDelay = _sentinel,
    Object? isBackingOff = _sentinel,
    Object? failureStreak = _sentinel,
  }) {
    return AutoRefreshUiState(
      option: identical(option, _sentinel)
          ? this.option
          : option as AutoRefreshOption?,
      lastUpdatedAt: identical(lastUpdatedAt, _sentinel)
          ? this.lastUpdatedAt
          : lastUpdatedAt as DateTime?,
      nextDueAt: identical(nextDueAt, _sentinel)
          ? this.nextDueAt
          : nextDueAt as DateTime?,
      remainingDelay: identical(remainingDelay, _sentinel)
          ? this.remainingDelay
          : remainingDelay as Duration?,
      isBackingOff: identical(isBackingOff, _sentinel)
          ? this.isBackingOff
          : (isBackingOff as bool?) ?? false,
      failureStreak: identical(failureStreak, _sentinel)
          ? this.failureStreak
          : (failureStreak as int?) ?? 0,
    );
  }
}

const Object _sentinel = Object();
