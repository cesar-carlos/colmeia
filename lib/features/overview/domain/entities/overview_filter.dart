import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter/foundation.dart';

/// Represents a named agent option available for overview filtering.
@immutable
class OverviewAgentOption {
  const OverviewAgentOption({
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
      other is OverviewAgentOption &&
      other.agentId == agentId &&
      other.name == name &&
      other.connectionStatus == connectionStatus &&
      other.missingLocalClientToken == missingLocalClientToken;

  @override
  int get hashCode =>
      Object.hash(agentId, name, connectionStatus, missingLocalClientToken);
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

/// Inclusive local calendar dates for an overview “custom period” filter.
@immutable
class OverviewDateRange {
  const OverviewDateRange({
    required this.startInclusive,
    required this.endInclusive,
  });

  /// Normalizes to date-only local instants and orders [a]/[b] correctly.
  factory OverviewDateRange.fromOrderedEndpoints(DateTime a, DateTime b) {
    final sa = DateTime(a.year, a.month, a.day);
    final sb = DateTime(b.year, b.month, b.day);
    if (sb.isBefore(sa)) {
      return OverviewDateRange(startInclusive: sb, endInclusive: sa);
    }
    return OverviewDateRange(startInclusive: sa, endInclusive: sb);
  }

  final DateTime startInclusive;
  final DateTime endInclusive;

  @override
  bool operator ==(Object other) =>
      other is OverviewDateRange &&
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

/// Inclusive calendar-day cap for [OverviewFilter.referenceRange] on home.
const int kOverviewCustomReferenceRangeMaxInclusiveDays = 366;

extension OverviewDateRangeHomePolicy on OverviewDateRange {
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
      inclusiveCalendarDayCount <= kOverviewCustomReferenceRangeMaxInclusiveDays;

  /// Clamps both endpoints to local calendar days inside
  /// [[firstInclusive], [lastInclusive]] (inclusive).
  OverviewDateRange clampedToPickerCalendarBounds({
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
    return OverviewDateRange.fromOrderedEndpoints(s, e);
  }

  /// Shrinks [startInclusive] forward so the span has at most [maxInclusiveDays]
  /// calendar days, keeping [endInclusive] fixed.
  OverviewDateRange clampedToMaxInclusiveCalendarDays(int maxInclusiveDays) {
    if (maxInclusiveDays < 1) {
      return OverviewDateRange.fromOrderedEndpoints(
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
    return OverviewDateRange(startInclusive: newStart, endInclusive: e);
  }
}

/// Active filter state for the overview home screen.
///
/// [selectedAgentIds] — null means "all approved agents" (implicitly selected).
/// When non-null, only these agent ids are queried and shown.
/// [yearMonth] — null means a rolling **last 30 days** window (see repository).
/// The overview home uses [OverviewFilter.initial] so the default period is
/// the current calendar month instead.
/// Custom sale-date span when non-null: KPIs, rankings, and the weekday chart
/// use this inclusive local date range (it may span multiple calendar months).
/// The monthly trend chart uses 12 months ending in the calendar month of the
/// range end. When null, the whole [yearMonth] window applies.
@immutable
class OverviewFilter {
  const OverviewFilter({
    this.selectedAgentIds,
    this.yearMonth,
    this.referenceRange,
  });

  /// All agents and the current local calendar month (app open / after clear).
  factory OverviewFilter.initial({DateTime? now}) {
    final n = now ?? DateTime.now();
    return OverviewFilter(
      yearMonth: OverviewYearMonth.fromDate(n),
    );
  }

  /// null = all agents. Non-null = restrict to this set (must be non-empty).
  final Set<String>? selectedAgentIds;

  /// null = rolling 30-day window; non-null = that calendar month (local).
  final OverviewYearMonth? yearMonth;

  /// null = use full [yearMonth] (or rolling window when it is null).
  final OverviewDateRange? referenceRange;

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

  OverviewFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    Object? yearMonth = _sentinel,
    Object? referenceRange = _sentinel,
  }) {
    return OverviewFilter(
      selectedAgentIds: selectedAgentIds == _sentinel
          ? this.selectedAgentIds
          : selectedAgentIds as Set<String>?,
      yearMonth: yearMonth == _sentinel
          ? this.yearMonth
          : yearMonth as OverviewYearMonth?,
      referenceRange: referenceRange == _sentinel
          ? this.referenceRange
          : referenceRange as OverviewDateRange?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OverviewFilter &&
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
  /// through today, local) and within [kOverviewCustomReferenceRangeMaxInclusiveDays].
  ///
  /// When adjustment is needed, [yearMonth] is aligned to the clamped range end.
  OverviewFilter normalizedForHomeDashboardReferenceRange({DateTime? now}) {
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
      kOverviewCustomReferenceRangeMaxInclusiveDays,
    );
    if (next == r) {
      return this;
    }
    return copyWith(
      referenceRange: next,
      yearMonth: OverviewYearMonth.fromDate(next.endInclusive),
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
