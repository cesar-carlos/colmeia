import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_line_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';

Future<void> pushSalesMonthlyPnlLineChartFullscreen({
  required BuildContext context,
  required List<SalesMonthlyPnlPoint> points,
  required bool isLoading,
  required bool loadFailed,
  String? loadFailureMessage,
  String? filterSummary,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final pageL10n = AppLocalizations.of(context);
  final fullscreenShareKey = GlobalKey();
  final shareTitle = pageL10n.salesMonthlyPnlChartTitle;
  return context.pushChartFullscreen<void>(
    extra: AppChartFullscreenRouteExtra(
      title: shareTitle,
      subtitle: pageL10n.salesMonthlyPnlChartSubtitle,
      filterSummary: filterSummary,
      chartSemanticsLabel: pageL10n.salesMonthlyPnlChartSemantics,
      headerTrailing: buildChartFullscreenShareTrailing(
        context: context,
        shareKey: fullscreenShareKey,
        metadata: buildSalesMonthlyPnlLineChartShareMetadata(
          l10n: pageL10n,
          points: points,
          exportHeaderContext: exportHeaderContext,
        ),
      ),
      chartBuilder: (fullscreenContext) {
        final l10n = AppLocalizations.of(fullscreenContext);
        return RepaintBoundary(
          key: fullscreenShareKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SalesMonthlyPnlLineChart(
                l10n: l10n,
                points: points,
                loadFailed: loadFailed,
                loadFailureMessage: loadFailureMessage,
                isLoading: isLoading,
                exportHeaderContext: exportHeaderContext,
                useChartShell: false,
                chartHeightOverride: constraints.maxHeight,
              );
            },
          ),
        );
      },
    ),
  );
}
