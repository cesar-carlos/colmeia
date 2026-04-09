import 'package:flutter/foundation.dart';

/// Represents a named agent option available for dashboard filtering.
@immutable
class DashboardAgentOption {
  const DashboardAgentOption({required this.agentId, required this.name});

  final String agentId;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is DashboardAgentOption && other.agentId == agentId;

  @override
  int get hashCode => agentId.hashCode;
}

/// Year/month period selected by the user.
///
/// [month] is 1-based (January = 1, December = 12).
@immutable
class DashboardYearMonth {
  const DashboardYearMonth({required this.year, required this.month})
    : assert(month >= 1 && month <= 12, 'month must be between 1 and 12');

  factory DashboardYearMonth.fromDate(DateTime date) =>
      DashboardYearMonth(year: date.year, month: date.month);

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
      other is DashboardYearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// Active filter state for the dashboard home screen.
///
/// [selectedAgentIds] — null means "all approved agents" (implicitly selected).
/// When non-null, only these agent ids are queried and shown.
/// [yearMonth] — null means "last 30 days" (default behaviour).
@immutable
class DashboardFilter {
  const DashboardFilter({this.selectedAgentIds, this.yearMonth});

  /// null = all agents. Non-null = restrict to this set (must be non-empty).
  final Set<String>? selectedAgentIds;

  /// null = default rolling 30-day window
  final DashboardYearMonth? yearMonth;

  bool get isDefault => selectedAgentIds == null && yearMonth == null;

  DashboardFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    Object? yearMonth = _sentinel,
  }) {
    return DashboardFilter(
      selectedAgentIds: selectedAgentIds == _sentinel
          ? this.selectedAgentIds
          : selectedAgentIds as Set<String>?,
      yearMonth: yearMonth == _sentinel
          ? this.yearMonth
          : yearMonth as DashboardYearMonth?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardFilter &&
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
