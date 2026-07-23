import 'package:colmeia/features/sales/presentation/share/sales_live_map_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _samplePoint = AppBrazilStoreSalesPoint(
  id: 'branch-1',
  name: 'Casa do Mel Produtos Naturais',
  branchName: 'ALCINEZIO ROSA DE MELO LTDA',
  fantasyName: 'Casa do Mel Produtos Naturais',
  city: 'Jataí',
  uf: 'GO',
  latitude: -17.88,
  longitude: -51.72,
  salesAmount: 578.62,
  salesCount: 8,
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
          l10n.chartSharePdfColumnMunicipality,
          l10n.chartSharePdfColumnState,
          l10n.chartSharePdfColumnSalesCount,
          l10n.chartSharePdfColumnAmount,
        ],
      );
      expect(
        metadata.tableData?.rows.single,
        <String>[
          'ALCINEZIO ROSA DE MELO LTDA',
          'Jataí',
          'GO',
          '8',
          r'R$ 578,62',
        ],
      );
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    },
  );

  test(
    'share store column prefers registration name like sidebar cards',
    () {
      final metadata = buildSalesLiveMapShareMetadata(
        l10n: l10n,
        title: 'Live sales map',
        chartPoints: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'branch-2',
            name: 'Casa do Mel',
            branchName: 'KARINE ENZWEILER LTDA',
            fantasyName: 'Casa do Mel',
            city: 'Sorriso',
            uf: 'mt',
            latitude: -12.54,
            longitude: -55.71,
            salesAmount: 100,
            salesCount: 2,
          ),
        ],
      );

      expect(metadata.tableData?.rows.single[0], 'KARINE ENZWEILER LTDA');
      expect(metadata.tableData?.rows.single[1], 'Sorriso');
      expect(metadata.tableData?.rows.single[2], 'MT');
    },
  );

  test('share table rows follow sidebar ranking by revenue then name', () {
    final metadata = buildSalesLiveMapShareMetadata(
      l10n: l10n,
      title: 'Live sales map',
      chartPoints: const <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'low',
          name: 'Low',
          branchName: 'LOW BRANCH LTDA',
          city: 'Cuiaba',
          uf: 'MT',
          latitude: -15.6,
          longitude: -56.1,
          salesAmount: 10,
          salesCount: 1,
        ),
        AppBrazilStoreSalesPoint(
          id: 'high',
          name: 'High',
          branchName: 'HIGH BRANCH LTDA',
          city: 'Jatai',
          uf: 'GO',
          latitude: -17.8,
          longitude: -51.7,
          salesAmount: 500,
          salesCount: 9,
        ),
      ],
    );

    expect(metadata.tableData?.rows.map((row) => row[0]).toList(), <String>[
      'HIGH BRANCH LTDA',
      'LOW BRANCH LTDA',
    ]);
  });

  test(
    'share store column falls back to point name when registration is empty',
    () {
      final metadata = buildSalesLiveMapShareMetadata(
        l10n: l10n,
        title: 'Live sales map',
        chartPoints: const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'branch-fallback',
            name: 'Fallback Store',
            city: 'Goiania',
            uf: 'GO',
            latitude: -16.6,
            longitude: -49.2,
            salesAmount: 20,
            salesCount: 1,
          ),
        ],
      );

      expect(metadata.tableData?.rows.single[0], 'Fallback Store');
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
