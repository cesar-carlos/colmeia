import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Calendar presets the produto tendência filters sheet offers as
/// one-tap selections for the "current period" range; the "previous
/// period" range is derived from the current one via
/// [salesTrendAutoPreviousRange].
enum SalesTrendDatePreset {
  currentMonth,
  previousMonth,
  last7Days,
  last30Days,
}

DateTime _salesTrendCalendarDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTimeRange salesTrendFullMonthInclusiveRange(DateTime anchor) {
  return DateTimeRange(
    start: DateTime(anchor.year, anchor.month),
    end: DateTime(anchor.year, anchor.month + 1, 0),
  );
}

DateTimeRange salesTrendPreviousMonthInclusiveRange(DateTime anchor) {
  final previous = DateTime(anchor.year, anchor.month - 1);
  return DateTimeRange(
    start: DateTime(previous.year, previous.month),
    end: DateTime(previous.year, previous.month + 1, 0),
  );
}

DateTimeRange salesTrendCurrentRangeForPreset(
  SalesTrendDatePreset preset, {
  DateTime? anchor,
}) {
  final today = _salesTrendCalendarDate(anchor ?? DateTime.now());
  return switch (preset) {
    SalesTrendDatePreset.currentMonth => salesTrendFullMonthInclusiveRange(
      today,
    ),
    SalesTrendDatePreset.previousMonth => salesTrendPreviousMonthInclusiveRange(
      today,
    ),
    SalesTrendDatePreset.last7Days => DateTimeRange(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    ),
    SalesTrendDatePreset.last30Days => DateTimeRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    ),
  };
}

bool salesTrendIsWholeCalendarMonthRange(DateTimeRange range) {
  final normalizedStart = _salesTrendCalendarDate(range.start);
  final normalizedEnd = _salesTrendCalendarDate(range.end);
  return normalizedStart.day == 1 &&
      normalizedEnd.day ==
          DateTime(
            normalizedEnd.year,
            normalizedEnd.month + 1,
            0,
          ).day;
}

int salesTrendInclusiveDayCount(DateTimeRange range) {
  final normalizedStart = _salesTrendCalendarDate(range.start);
  final normalizedEnd = _salesTrendCalendarDate(range.end);
  return normalizedEnd.difference(normalizedStart).inDays + 1;
}

int salesTrendCalendarMonthSpan(DateTimeRange range) {
  final normalizedStart = _salesTrendCalendarDate(range.start);
  final normalizedEnd = _salesTrendCalendarDate(range.end);
  return (normalizedEnd.year - normalizedStart.year) * 12 +
      normalizedEnd.month -
      normalizedStart.month +
      1;
}

DateTimeRange salesTrendAutoPreviousRange(DateTimeRange currentRange) {
  final normalizedStart = _salesTrendCalendarDate(currentRange.start);
  if (salesTrendIsWholeCalendarMonthRange(currentRange)) {
    final monthSpan = salesTrendCalendarMonthSpan(currentRange);
    return DateTimeRange(
      start: DateTime(
        normalizedStart.year,
        normalizedStart.month - monthSpan,
      ),
      end: DateTime(normalizedStart.year, normalizedStart.month, 0),
    );
  }

  final inclusiveDays = salesTrendInclusiveDayCount(currentRange);
  final previousEnd = normalizedStart.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(
    Duration(days: inclusiveDays - 1),
  );
  return DateTimeRange(start: previousStart, end: previousEnd);
}

bool salesTrendSameRange(DateTimeRange? a, DateTimeRange? b) {
  if (a == null || b == null) {
    return a == b;
  }
  return _salesTrendCalendarDate(a.start) == _salesTrendCalendarDate(b.start) &&
      _salesTrendCalendarDate(a.end) == _salesTrendCalendarDate(b.end);
}

String salesTrendRangeDescriptorLabel(
  AppLocalizations l10n,
  DateTimeRange range,
) {
  final durationLabel = l10n.salesProdutoTendenciaFilterDurationDays(
    salesTrendInclusiveDayCount(range),
  );
  final rangeKind = salesTrendIsWholeCalendarMonthRange(range)
      ? l10n.salesProdutoTendenciaFilterRangeKindFullMonth
      : l10n.salesProdutoTendenciaFilterRangeKindCustom;
  return '$durationLabel • $rangeKind';
}
