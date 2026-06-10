import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_daily_totals_chart_copy.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_chart.dart';
import 'package:flutter/material.dart';

class SalesDailyTotalsChartCard extends StatelessWidget {
  const SalesDailyTotalsChartCard({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    this.loadFailure,
    this.loadFailureMessage,
    this.dailySaleDateRange,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DailySalesTrendPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;

  /// When non-null, daily totals were loaded for this inclusive span instead of the anchor month.
  final DashboardDateRange? dailySaleDateRange;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  Widget build(BuildContext context) {
    final range = dailySaleDateRange;
    return DailySalesTrendChart(
      l10n: l10n,
      points: points,
      loadFailed: loadFailed,
      loadFailure: loadFailure,
      loadFailureMessage: loadFailureMessage,
      isLoading: isLoading,
      useSalesDailyTotalsLabels: true,
      onRequestFullscreen: onRequestFullscreen,
      onRequestShare: onRequestShare,
      salesSubtitleOverride: range != null
          ? salesDailyTotalsEffectiveSubtitle(
              l10n,
              dailySaleDateRange: range,
            )
          : null,
      salesScopeHintOverride: range != null
          ? salesDailyTotalsEffectiveScopeHint(
              l10n,
              dailySaleDateRange: range,
            )
          : null,
    );
  }
}
