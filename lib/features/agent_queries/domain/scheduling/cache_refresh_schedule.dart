import 'dart:convert';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_filter_normalization.dart';

enum CacheRefreshStatus {
  waiting,
  running,
  waitingAgent,
  waitingConnection,
  deferred,
  paused,
  accessUnavailable,
}

enum CacheRefreshPeriod { fixed, last30Days }

class CacheRefreshSchedule {
  CacheRefreshSchedule({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.reportId,
    this.reportVersion = 1,
    this.period = CacheRefreshPeriod.last30Days,
    this.start,
    this.end,
    this.interval = defaultInterval,
    this.enabled = true,
    Map<String, Object?> filters = const {},
  }) : filters = normalizeCacheRefreshFilters(reportId, filters);
  factory CacheRefreshSchedule.fromJson(Map<String, dynamic> json) =>
      CacheRefreshSchedule(
        id: json['id'] as String,
        userId: json['userId'] as String,
        agentId: json['agentId'] as String,
        reportId: json['reportId'] as String,
        reportVersion: json['reportVersion'] as int,
        period: CacheRefreshPeriod.values.byName(json['period'] as String),
        start: DateTime.tryParse(json['start'] as String? ?? ''),
        end: DateTime.tryParse(json['end'] as String? ?? ''),
        interval: Duration(minutes: json['intervalMinutes'] as int),
        enabled: json['enabled'] as bool,
        filters: Map<String, Object?>.from(json['filters'] as Map),
      );
  final String id;
  final String userId;
  final String agentId;
  final String reportId;
  final int reportVersion;
  final CacheRefreshPeriod period;
  final DateTime? start;
  final DateTime? end;
  final Duration interval;
  final bool enabled;
  final Map<String, Object?> filters;
  static const defaultInterval = Duration(hours: 2);
  static const List<Duration> intervals = [
    Duration(minutes: 15),
    Duration(hours: 1),
    defaultInterval,
    Duration(hours: 24),
  ];

  ({DateTime start, DateTime end}) resolvePeriod(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (period == CacheRefreshPeriod.last30Days) {
      return (
        start: DateTime(today.year, today.month, today.day - 29),
        end: today,
      );
    }
    if (start == null || end == null || end!.isBefore(start!)) {
      throw const ValidationFailure(message: 'invalid_schedule_period');
    }
    return (start: start!, end: end!);
  }

  void validate(DateTime now) {
    if ([id, userId, agentId, reportId].any((s) => s.trim().isEmpty) ||
        reportVersion != 1 ||
        !intervals.contains(interval)) {
      throw const ValidationFailure(message: 'invalid_schedule');
    }
    final range = resolvePeriod(now);
    for (final date in [range.start, range.end]) {
      if (date.isUtc || date != DateTime(date.year, date.month, date.day)) {
        throw const ValidationFailure(
          message: 'schedule_requires_calendar_dates',
        );
      }
    }
    if (range.end.isAfter(DateTime(now.year, now.month, now.day))) {
      throw const ValidationFailure(message: 'future_schedule_period');
    }
  }

  String get identity => jsonEncode([
    userId,
    agentId,
    reportId,
    reportVersion,
    period.name,
    if (period == CacheRefreshPeriod.fixed) start?.toIso8601String() else null,
    if (period == CacheRefreshPeriod.fixed) end?.toIso8601String() else null,
    {for (final key in filters.keys.toList()..sort()) key: filters[key]},
  ]);

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'agentId': agentId,
    'reportId': reportId,
    'reportVersion': reportVersion,
    'period': period.name,
    'start': start?.toIso8601String(),
    'end': end?.toIso8601String(),
    'intervalMinutes': interval.inMinutes,
    'enabled': enabled,
    'filters': filters,
  };
}

class CacheRefreshState {
  const CacheRefreshState({
    this.status = CacheRefreshStatus.waiting,
    this.lastSuccess,
    this.nextAttempt,
    this.failures = 0,
    this.reason,
    this.durationMs,
  });
  factory CacheRefreshState.fromJson(Map<String, dynamic> json) =>
      CacheRefreshState(
        status: CacheRefreshStatus.values.byName(json['status'] as String),
        lastSuccess: DateTime.tryParse(json['lastSuccess'] as String? ?? ''),
        nextAttempt: DateTime.tryParse(json['nextAttempt'] as String? ?? ''),
        failures: json['failures'] as int,
        reason: json['reason'] as String?,
        durationMs: json['durationMs'] as int?,
      );
  final CacheRefreshStatus status;
  final DateTime? lastSuccess;
  final DateTime? nextAttempt;
  final int failures;
  final String? reason;
  final int? durationMs;
  Map<String, Object?> toJson() => {
    'status': status.name,
    'lastSuccess': lastSuccess?.toIso8601String(),
    'nextAttempt': nextAttempt?.toIso8601String(),
    'failures': failures,
    'reason': reason,
    'durationMs': durationMs,
  };
}

class CacheRefreshRecord {
  const CacheRefreshRecord({
    required this.schedule,
    required this.revision,
    this.state = const CacheRefreshState(),
    this.snapshot,
    this.snapshotId,
    this.snapshotBytes = 0,
    this.currentDayPartial = false,
    this.queryKeys = const [],
  });
  factory CacheRefreshRecord.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 && json['version'] != 2) {
      throw const FormatException('Unsupported schedule version');
    }
    return CacheRefreshRecord(
      schedule: CacheRefreshSchedule.fromJson(
        Map<String, dynamic>.from(json['schedule'] as Map),
      ),
      revision: json['revision'] as String,
      snapshotId: json['snapshotId'] as String?,
      snapshotBytes: json['snapshotBytes'] as int? ?? 0,
      currentDayPartial: json['currentDayPartial'] as bool? ?? false,
      queryKeys: (json['queryKeys'] as List? ?? const []).cast<String>(),
      state: CacheRefreshState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map),
      ),
      snapshot: json['snapshot'] == null
          ? null
          : Map<String, dynamic>.from(json['snapshot'] as Map),
    );
  }
  final CacheRefreshSchedule schedule;
  final String revision;
  final CacheRefreshState state;
  final Map<String, dynamic>? snapshot;
  final String? snapshotId;
  final int snapshotBytes;
  final bool currentDayPartial;
  final List<String> queryKeys;
  bool get isQuarantined => state.reason == 'invalid_storage';
  Map<String, Object?> toJson({bool includeSnapshot = true}) => {
    'version': 2,
    'schedule': schedule.toJson(),
    'revision': revision,
    'state': state.toJson(),
    'snapshot': includeSnapshot ? snapshot : null,
    'snapshotId': snapshotId,
    'snapshotBytes': snapshotBytes,
    'currentDayPartial': currentDayPartial,
    'queryKeys': queryKeys,
  };
}
