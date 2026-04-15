import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter/foundation.dart';

/// Represents a named agent option available for overview filtering.
@immutable
class OverviewAgentOption {
  const OverviewAgentOption({
    required this.agentId,
    required this.name,
    this.connectionStatus = AgentConnectionStatus.unknown,
  });

  final String agentId;
  final String name;
  final AgentConnectionStatus connectionStatus;

  @override
  bool operator ==(Object other) =>
      other is OverviewAgentOption &&
      other.agentId == agentId &&
      other.name == name &&
      other.connectionStatus == connectionStatus;

  @override
  int get hashCode => Object.hash(agentId, name, connectionStatus);
}

/// Year/month period selected by the user.
///
/// [month] is 1-based (January = 1, December = 12).
@immutable
class OverviewYearMonth {
  const OverviewYearMonth({required this.year, required this.month})
    : assert(month >= 1 && month <= 12, 'month must be between 1 and 12');

  factory OverviewYearMonth.fromDate(DateTime date) =>
      OverviewYearMonth(year: date.year, month: date.month);

  final int year;
  final int month;

  /// First instant of this month (local time).
  DateTime get start => DateTime(year, month);

  /// Last instant of this month — first instant of the next month minus one
  /// microsecond, so it covers the whole last day.
  DateTime get end => DateTime(year, month + 1).subtract(
    const Duration(microseconds: 1),
  );

  @override
  bool operator ==(Object other) =>
      other is OverviewYearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// Active filter state for the overview home screen.
///
/// [selectedAgentIds] — null means "all approved agents" (implicitly selected).
/// When non-null, only these agent ids are queried and shown.
/// [yearMonth] — null means "last 30 days" (default behaviour).
@immutable
class OverviewFilter {
  const OverviewFilter({this.selectedAgentIds, this.yearMonth});

  /// null = all agents. Non-null = restrict to this set (must be non-empty).
  final Set<String>? selectedAgentIds;

  /// null = default rolling 30-day window
  final OverviewYearMonth? yearMonth;

  bool get isDefault => selectedAgentIds == null && yearMonth == null;

  OverviewFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    Object? yearMonth = _sentinel,
  }) {
    return OverviewFilter(
      selectedAgentIds: selectedAgentIds == _sentinel
          ? this.selectedAgentIds
          : selectedAgentIds as Set<String>?,
      yearMonth: yearMonth == _sentinel
          ? this.yearMonth
          : yearMonth as OverviewYearMonth?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OverviewFilter &&
      _setEquals(other.selectedAgentIds, selectedAgentIds) &&
      other.yearMonth == yearMonth;

  @override
  int get hashCode {
    final ids = selectedAgentIds;
    if (ids == null) {
      return Object.hash(yearMonth, 0);
    }
    final sorted = List<String>.from(ids)..sort();
    return Object.hash(yearMonth, Object.hashAll(sorted));
  }
}

bool _setEquals(Set<String>? a, Set<String>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null) {
    return a == null && b == null;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final id in a) {
    if (!b.contains(id)) {
      return false;
    }
  }
  return true;
}

// Sentinel to distinguish "not provided" from explicit null in copyWith.
const Object _sentinel = Object();
