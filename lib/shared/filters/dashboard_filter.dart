import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter/foundation.dart';

/// Represents a named agent option available for overview filtering.
@immutable
class DashboardAgentOption {
  const DashboardAgentOption({
    required this.agentId,
    required this.name,
    this.connectionStatus = AgentConnectionStatus.unknown,
    this.missingLocalClientToken = false,
  });

  final String agentId;
  final String name;
  final AgentConnectionStatus connectionStatus;

  /// True when the hub lists the agent but this device has no stored
  /// `client_token`, so Agent SQL queries are skipped for that agent.
  final bool missingLocalClientToken;

  @override
  bool operator ==(Object other) =>
      other is DashboardAgentOption &&
      other.agentId == agentId &&
      other.name == name &&
      other.connectionStatus == connectionStatus &&
      other.missingLocalClientToken == missingLocalClientToken;

  @override
  int get hashCode =>
      Object.hash(agentId, name, connectionStatus, missingLocalClientToken);
}

/// Convenience selectors over a collection of [DashboardAgentOption].
extension DashboardAgentOptionListX on Iterable<DashboardAgentOption> {
  /// Returns the ids of agents that have a local client token on this device
  /// (i.e. those eligible to receive Agent SQL queries from the current user).
  Set<String> tokenBackedAgentIds() {
    return where((agent) => !agent.missingLocalClientToken)
        .map((agent) => agent.agentId)
        .toSet();
  }
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

/// Inclusive local calendar dates for an overview “custom period” filter.
@immutable
class DashboardDateRange {
  const DashboardDateRange({
    required this.startInclusive,
    required this.endInclusive,
  });

  /// Normalizes to date-only local instants and orders [a]/[b] correctly.
  factory DashboardDateRange.fromOrderedEndpoints(DateTime a, DateTime b) {
    final sa = DateTime(a.year, a.month, a.day);
    final sb = DateTime(b.year, b.month, b.day);
    if (sb.isBefore(sa)) {
      return DashboardDateRange(startInclusive: sb, endInclusive: sa);
    }
    return DashboardDateRange(startInclusive: sa, endInclusive: sb);
  }

  final DateTime startInclusive;
  final DateTime endInclusive;

  @override
  bool operator ==(Object other) =>
      other is DashboardDateRange &&
      _sameCalendarDay(other.startInclusive, startInclusive) &&
      _sameCalendarDay(other.endInclusive, endInclusive);

  @override
  int get hashCode => Object.hash(
    startInclusive.year,
    startInclusive.month,
    startInclusive.day,
    endInclusive.year,
    endInclusive.month,
    endInclusive.day,
  );
}

/// Inclusive calendar-day cap for [DashboardFilter.referenceRange] on home.
const int kDashboardCustomReferenceRangeMaxInclusiveDays = 366;

extension DashboardDateRangeHomePolicy on DashboardDateRange {
  /// Inclusive count of local calendar days from [startInclusive] through
  /// [endInclusive].
  int get inclusiveCalendarDayCount {
    final s = DateTime(
      startInclusive.year,
      startInclusive.month,
      startInclusive.day,
    );
    final e = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    );
    return e.difference(s).inDays + 1;
  }

  bool get withinHomeDashboardMaxInclusiveDays =>
      inclusiveCalendarDayCount <=
      kDashboardCustomReferenceRangeMaxInclusiveDays;

  /// Clamps both endpoints to local calendar days inside
  /// [[firstInclusive], [lastInclusive]] (inclusive).
  DashboardDateRange clampedToPickerCalendarBounds({
    required DateTime firstInclusive,
    required DateTime lastInclusive,
  }) {
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final fa = day(firstInclusive);
    final la = day(lastInclusive);
    var s = day(startInclusive);
    var e = day(endInclusive);
    if (s.isBefore(fa)) {
      s = fa;
    }
    if (s.isAfter(la)) {
      s = la;
    }
    if (e.isAfter(la)) {
      e = la;
    }
    if (e.isBefore(fa)) {
      e = fa;
    }
    return DashboardDateRange.fromOrderedEndpoints(s, e);
  }

  /// Shrinks [startInclusive] forward so the span has at most [maxInclusiveDays]
  /// calendar days, keeping [endInclusive] fixed.
  DashboardDateRange clampedToMaxInclusiveCalendarDays(int maxInclusiveDays) {
    if (maxInclusiveDays < 1) {
      return DashboardDateRange.fromOrderedEndpoints(
        endInclusive,
        endInclusive,
      );
    }
    if (inclusiveCalendarDayCount <= maxInclusiveDays) {
      return this;
    }
    final e = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    );
    final newStart = e.subtract(Duration(days: maxInclusiveDays - 1));
    return DashboardDateRange(startInclusive: newStart, endInclusive: e);
  }
}

/// Active filter state for the overview home screen.
///
/// [selectedAgentIds] — null means "all approved agents" (implicitly selected).
/// When non-null, only these agent ids are queried and shown.
/// [yearMonth] — null means a rolling **last 30 days** window (see repository).
/// The overview home uses [DashboardFilter.initial] so the default period is
/// the current calendar month instead.
/// Custom sale-date span when non-null: KPIs, rankings, and the weekday chart
/// use this inclusive local date range (it may span multiple calendar months).
/// The monthly trend chart uses 12 months ending in the calendar month of the
/// range end. When null, the whole [yearMonth] window applies.
@immutable
class DashboardFilter {
  const DashboardFilter({
    this.selectedAgentIds,
    this.yearMonth,
    this.referenceRange,
  });

  /// All agents and the current local calendar month (app open / after clear).
  factory DashboardFilter.initial({DateTime? now}) {
    final n = now ?? DateTime.now();
    return DashboardFilter(
      yearMonth: DashboardYearMonth.fromDate(n),
    );
  }

  /// null = all agents. Non-null = restrict to this set (must be non-empty).
  final Set<String>? selectedAgentIds;

  /// null = rolling 30-day window; non-null = that calendar month (local).
  final DashboardYearMonth? yearMonth;

  /// null = use full [yearMonth] (or rolling window when it is null).
  final DashboardDateRange? referenceRange;

  /// True when showing all agents and the period is the current local month.
  /// [yearMonth] null ("last 30 days") is not the default baseline.
  bool get isDefault {
    if (selectedAgentIds != null) {
      return false;
    }
    if (referenceRange != null) {
      return false;
    }
    final ym = yearMonth;
    if (ym == null) {
      return false;
    }
    final n = DateTime.now();
    return ym.year == n.year && ym.month == n.month;
  }

  DashboardFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    Object? yearMonth = _sentinel,
    Object? referenceRange = _sentinel,
  }) {
    return DashboardFilter(
      selectedAgentIds: selectedAgentIds == _sentinel
          ? this.selectedAgentIds
          : selectedAgentIds as Set<String>?,
      yearMonth: yearMonth == _sentinel
          ? this.yearMonth
          : yearMonth as DashboardYearMonth?,
      referenceRange: referenceRange == _sentinel
          ? this.referenceRange
          : referenceRange as DashboardDateRange?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardFilter &&
      _setEquals(other.selectedAgentIds, selectedAgentIds) &&
      other.yearMonth == yearMonth &&
      other.referenceRange == referenceRange;

  @override
  int get hashCode {
    final refPart = referenceRange?.hashCode ?? 0;
    final ids = selectedAgentIds;
    if (ids == null) {
      return Object.hash(yearMonth, refPart);
    }
    final sorted = List<String>.from(ids)..sort();
    return Object.hash(yearMonth, refPart, Object.hashAll(sorted));
  }

  /// Ensures [referenceRange] stays within the home date-picker window (10 years
  /// through today, local) and within [kDashboardCustomReferenceRangeMaxInclusiveDays].
  ///
  /// When adjustment is needed, [yearMonth] is aligned to the clamped range end.
  DashboardFilter normalizedForHomeDashboardReferenceRange({DateTime? now}) {
    final r = referenceRange;
    if (r == null) {
      return this;
    }
    final n = now ?? DateTime.now();
    final last = DateTime(n.year, n.month, n.day);
    final first = DateTime(n.year - 10);
    var next = r.clampedToPickerCalendarBounds(
      firstInclusive: first,
      lastInclusive: last,
    );
    next = next.clampedToMaxInclusiveCalendarDays(
      kDashboardCustomReferenceRangeMaxInclusiveDays,
    );
    if (next == r) {
      return this;
    }
    return copyWith(
      referenceRange: next,
      yearMonth: DashboardYearMonth.fromDate(next.endInclusive),
    );
  }
}

bool _sameCalendarDay(DateTime? a, DateTime? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
