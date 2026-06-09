import 'package:colmeia/features/sales/presentation/share/sales_live_map_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _samplePoint = AppBrazilStoreSalesPoint(
  id: 'branch-1',
  name: 'Lucas Centro',
  uf: 'SP',
  latitude: -23.55,
  longitude: -46.63,
  salesAmount: 15000,
  salesCount: 42,
);

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  test(
    'share metadata is landscape table-only when export params are missing',
    () {
      final metadata = buildSalesLiveMapShareMetadata(
        l10n: l10n,
        title: 'Live sales map',
        subtitle: 'Today',
        chartPoints: const <AppBrazilStoreSalesPoint>[_samplePoint],
      );

      expect(metadata.title, 'Live sales map');
      expect(metadata.subtitle, 'Today');
      expect(metadata.subject, 'Live sales map');
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnStore,
          l10n.chartSharePdfColumnSalesCount,
          l10n.chartSharePdfColumnAmount,
        ],
      );
      expect(metadata.tableData?.rows.single.first, 'Lucas Centro');
      expect(metadata.tableData?.rows.single[1], '42');
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    },
  );

  test(
    'share metadata includes chart export when export params are provided',
    () {
      final metadata = buildSalesLiveMapShareMetadata(
        l10n: l10n,
        title: 'Live sales map',
        chartPoints: const <AppBrazilStoreSalesPoint>[_samplePoint],
        exportMetric: AppBrazilStoreSalesMapMetric.revenue,
        exportStyle: const AppBrazilStoreSalesMapStyle.standard(height: 400),
        filterBranchIds: <String>{'branch-1'},
      );

      expect(metadata.chartExportBuilder, isNotNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    },
  );

  test('share metadata omits chart export when chart points are empty', () {
    final metadata = buildSalesLiveMapShareMetadata(
      l10n: l10n,
      title: 'Live sales map',
      chartPoints: const <AppBrazilStoreSalesPoint>[],
      exportMetric: AppBrazilStoreSalesMapMetric.revenue,
      exportStyle: const AppBrazilStoreSalesMapStyle.standard(height: 400),
      filterBranchIds: <String>{'branch-1'},
    );

    expect(metadata.chartExportBuilder, isNull);
    expect(metadata.tableData?.rows, isEmpty);
  });

  test('share metadata truncates table rows over limit', () {
    final points = List<AppBrazilStoreSalesPoint>.generate(
      ChartSharePdfLimits.maxTableRows + 1,
      (index) => AppBrazilStoreSalesPoint(
        id: 'branch-$index',
        name: 'Store $index',
        uf: 'SP',
        latitude: -23.55,
        longitude: -46.63,
        salesAmount: (1000 + index).toDouble(),
        salesCount: index,
      ),
    );

    final metadata = buildSalesLiveMapShareMetadata(
      l10n: l10n,
      title: 'Live sales map',
      chartPoints: points,
    );

    const totalRows = ChartSharePdfLimits.maxTableRows + 1;
    expect(metadata.tableData?.rows.length, ChartSharePdfLimits.maxTableRows);
    expect(metadata.filterSummary, isNotNull);
    expect(
      metadata.filterSummary,
      contains('${ChartSharePdfLimits.maxTableRows}'),
    );
    expect(metadata.filterSummary, contains('$totalRows'));
  });
}
