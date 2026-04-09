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
      other is DashboardYearMonth &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// Active filter state for the dashboard home screen.
///
/// [selectedAgentId] — null means "all approved agents".
/// [yearMonth] — null means "last 30 days" (default behaviour).
@immutable
class DashboardFilter {
  const DashboardFilter({this.selectedAgentId, this.yearMonth});

  /// null = all agents
  final String? selectedAgentId;

  /// null = default rolling 30-day window
  final DashboardYearMonth? yearMonth;

  bool get isDefault => selectedAgentId == null && yearMonth == null;

  DashboardFilter copyWith({
    Object? selectedAgentId = _sentinel,
    Object? yearMonth = _sentinel,
  }) {
    return DashboardFilter(
      selectedAgentId: selectedAgentId == _sentinel
          ? this.selectedAgentId
          : selectedAgentId as String?,
      yearMonth: yearMonth == _sentinel
          ? this.yearMonth
          : yearMonth as DashboardYearMonth?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardFilter &&
      other.selectedAgentId == selectedAgentId &&
      other.yearMonth == yearMonth;

  @override
  int get hashCode => Object.hash(selectedAgentId, yearMonth);
}

// Sentinel to distinguish "not provided" from explicit null in copyWith.
const Object _sentinel = Object();
