import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

ChartShareMetadata buildOverviewPaymentMixShareMetadata({
  required AppLocalizations l10n,
  required List<AppCategoryDonutSegment> segments,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromDonutSegments(
      segments: segments,
      labelHeader: l10n.chartSharePdfColumnLabel,
      valueHeader: l10n.chartSharePdfColumnAmount,
      percentHeader: l10n.chartSharePdfColumnPercent,
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.overviewPaymentMixTitle,
    subtitle: l10n.overviewPaymentMixSubtitle,
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
  );
}
