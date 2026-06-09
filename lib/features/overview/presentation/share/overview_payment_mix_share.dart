import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

ChartShareMetadata buildOverviewPaymentMixShareMetadata({
  required AppLocalizations l10n,
  required List<AppCategoryDonutSegment> segments,
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
  );
}
