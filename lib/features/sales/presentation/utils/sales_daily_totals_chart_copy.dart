import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';

/// Subtitle and semantics copy for the Sales daily totals chart.
String salesDailyTotalsEffectiveSubtitle(
  AppLocalizations l10n, {
  required OverviewDateRange? dailySaleDateRange,
}) {
  if (dailySaleDateRange == null) {
    return l10n.salesDailyTotalsChartSubtitle;
  }
  return l10n.salesDailyTotalsChartSubtitleCustomRange(
    AppBrFormatters.shortDate(dailySaleDateRange.startInclusive),
    AppBrFormatters.shortDate(dailySaleDateRange.endInclusive),
  );
}

/// Scope hint for Semantics when a custom daily range is active.
String salesDailyTotalsEffectiveScopeHint(
  AppLocalizations l10n, {
  required OverviewDateRange? dailySaleDateRange,
}) {
  if (dailySaleDateRange == null) {
    return l10n.salesDailyTotalsChartScopeHint;
  }
  return l10n.salesDailyTotalsChartScopeHintCustomRange;
}
