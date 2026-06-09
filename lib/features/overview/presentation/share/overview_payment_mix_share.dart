import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

const AppCategoryDonutCardStyle _overviewPaymentMixPdfDonutStyle =
    AppCategoryDonutCardStyle(
  innerRadius: '55%',
  outerRadius: '88%',
  doughnutAnimationDurationMs: 0,
  showLegend: false,
  chartSize: 320,
  chartMinHeight: 320,
);

ChartShareMetadata buildOverviewPaymentMixShareMetadata({
  required AppLocalizations l10n,
  required List<AppCategoryDonutSegment> segments,
  required String? centerPrimary,
}) {
  return ChartShareMetadata(
    title: l10n.overviewPaymentMixTitle,
    subtitle: l10n.overviewPaymentMixSubtitle,
    tableData: ChartShareTableData.fromDonutSegments(
      segments: segments,
      labelHeader: l10n.chartSharePdfColumnLabel,
      valueHeader: l10n.chartSharePdfColumnAmount,
      percentHeader: l10n.chartSharePdfColumnPercent,
    ),
    chartExportBuilder: segments.isEmpty
        ? null
        : (exportContext) {
            final segmentsSnapshot = List<AppCategoryDonutSegment>.of(
              segments,
              growable: false,
            );
            return ColoredBox(
              color: Theme.of(exportContext).colorScheme.surface,
              child: SizedBox(
                width: _overviewPaymentMixPdfDonutStyle.chartSize,
                height: _overviewPaymentMixPdfDonutStyle.chartSize,
                child: AppCategoryDonutCard(
                  title: l10n.overviewPaymentMixTitle,
                  showHeader: false,
                  wrapInSectionCard: false,
                  segments: segmentsSnapshot,
                  centerPrimaryLabel: centerPrimary,
                  centerSecondaryLabel: l10n.overviewPaymentMixDonutTotalLabel,
                  style: _overviewPaymentMixPdfDonutStyle,
                ),
              ),
            );
          },
  );
}
