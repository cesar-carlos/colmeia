import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_summary_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

const _samplePnlPoint = SalesMonthlyPnlPoint(
  anoMes: '2026/05',
  year: 2026,
  month: 5,
  venda: 1000,
  lucro: 200,
  custoMercadoria: 700,
);

const _sampleTendenciaRow = ProdutoVendidoTendenciaDeVendaRow(
  codEmpresa: 1,
  codFilial: 1,
  codProduto: 7,
  nomeProduto: 'Coffee',
  codUnidadeMedida: 'UN',
  qtdAnterior: 8,
  qtdAtual: 10,
  diferenca: 2,
  percentualTendencia: 25,
  classificacao: 'CRESCENDO',
);

AppChartTheme _monthlyPnlChartTheme(AppThemeTokens tokens) {
  return AppChartTheme(
    height: tokens.chartStandardHeight,
    primaryColor: tokens.chartSeriesPrimary,
    gradient: LinearGradient(
      colors: <Color>[
        tokens.chartSeriesPrimary,
        tokens.chartSeriesPrimary.withValues(alpha: 0.05),
      ],
    ),
    enableSelectionZooming: false,
    palette: <Color>[
      tokens.chartSeriesPrimary,
      tokens.chartSeriesSecondary,
      tokens.chartSeriesTertiary,
    ],
  );
}

void main() {
  late AppLocalizations l10n;
  late AppThemeTokens tokens;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
    tokens = AppThemeTokens.light;
  });

  group('sales monthly pnl share metadata', () {
    test('bar values share metadata is table-only landscape export', () {
      final metadata = buildSalesMonthlyPnlBarChartShareMetadata(
        l10n: l10n,
        points: const <SalesMonthlyPnlPoint>[_samplePnlPoint],
        session: SalesMonthlyPnlBarChartPreferences.defaults,
        tokens: tokens,
        chartTheme: _monthlyPnlChartTheme(tokens),
        localeTag: 'en',
        primaryMoney: NumberFormat.currency(locale: 'en', symbol: r'$'),
        gridLineColor: const Color(0xFFE0E0E0),
        percentRatioFormat: NumberFormat.percentPattern('en'),
      );

      expect(metadata.title, l10n.salesMonthlyPnlBarChartTitle);
      expect(metadata.subtitle, l10n.salesMonthlyPnlBarChartSubtitle);
      expect(metadata.subject, l10n.salesMonthlyPnlBarChartTitle);
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnMonth,
          l10n.chartSharePdfColumnRevenue,
          l10n.chartSharePdfColumnCost,
          l10n.chartSharePdfColumnProfit,
        ],
      );
      expect(metadata.tableData?.rows.single.first, '2026/05');
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('bar percent share metadata includes chart export', () {
      final metadata = buildSalesMonthlyPnlBarChartShareMetadata(
        l10n: l10n,
        points: const <SalesMonthlyPnlPoint>[_samplePnlPoint],
        session: const SalesMonthlyPnlBarChartPreferences(
          displayMode: SalesMonthlyPnlBarDisplayMode.percent,
          percentMetric: LucratividadePercentMetric.grossMargin,
        ),
        tokens: tokens,
        chartTheme: _monthlyPnlChartTheme(tokens),
        localeTag: 'en',
        primaryMoney: NumberFormat.currency(locale: 'en', symbol: r'$'),
        gridLineColor: const Color(0xFFE0E0E0),
        percentRatioFormat: NumberFormat.percentPattern('en'),
      );

      expect(metadata.title, l10n.salesMonthlyPnlBarChartTitle);
      expect(metadata.tableData?.rows.single.first, '2026/05');
      expect(metadata.chartExportBuilder, isNotNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('bar share metadata omits chart export when points are empty', () {
      final metadata = buildSalesMonthlyPnlBarChartShareMetadata(
        l10n: l10n,
        points: const <SalesMonthlyPnlPoint>[],
        session: const SalesMonthlyPnlBarChartPreferences(
          displayMode: SalesMonthlyPnlBarDisplayMode.percent,
          percentMetric: LucratividadePercentMetric.grossMargin,
        ),
        tokens: tokens,
        chartTheme: _monthlyPnlChartTheme(tokens),
        localeTag: 'en',
        primaryMoney: NumberFormat.currency(locale: 'en', symbol: r'$'),
        gridLineColor: const Color(0xFFE0E0E0),
        percentRatioFormat: NumberFormat.percentPattern('en'),
      );

      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.tableData?.rows, isEmpty);
    });

    test('bar share metadata truncates table rows over limit', () {
      final points = List<SalesMonthlyPnlPoint>.generate(
        ChartSharePdfLimits.maxTableRows + 1,
        (index) => SalesMonthlyPnlPoint(
          anoMes: '2026/${((index % 12) + 1).toString().padLeft(2, '0')}',
          year: 2026,
          month: (index % 12) + 1,
          venda: 1000,
          lucro: 200,
          custoMercadoria: 700,
        ),
      );

      final metadata = buildSalesMonthlyPnlBarChartShareMetadata(
        l10n: l10n,
        points: points,
        session: SalesMonthlyPnlBarChartPreferences.defaults,
        tokens: tokens,
        chartTheme: _monthlyPnlChartTheme(tokens),
        localeTag: 'en',
        primaryMoney: NumberFormat.currency(locale: 'en', symbol: r'$'),
        gridLineColor: const Color(0xFFE0E0E0),
        percentRatioFormat: NumberFormat.percentPattern('en'),
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

    test('line share metadata includes month values and chart export', () {
      final metadata = buildSalesMonthlyPnlLineChartShareMetadata(
        l10n: l10n,
        points: const <SalesMonthlyPnlPoint>[_samplePnlPoint],
      );

      expect(metadata.title, l10n.salesMonthlyPnlChartTitle);
      expect(metadata.subtitle, l10n.salesMonthlyPnlChartSubtitle);
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnMonth,
          l10n.chartSharePdfColumnRevenue,
          l10n.chartSharePdfColumnProfit,
        ],
      );
      expect(metadata.tableData?.rows.single.first, '2026/05');
      expect(metadata.chartExportBuilder, isNotNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('line share metadata omits chart export when points are empty', () {
      final metadata = buildSalesMonthlyPnlLineChartShareMetadata(
        l10n: l10n,
        points: const <SalesMonthlyPnlPoint>[],
      );

      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.tableData?.rows, isEmpty);
    });
  });

  group('sales produto tendencia share metadata', () {
    test('classificacao share metadata is table-only landscape export', () {
      final metadata = buildSalesProdutoTendenciaClassificacaoShareMetadata(
        l10n: l10n,
        summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[
          ProdutoVendidoTendenciaDeVendaSummaryRow(
            classificacao: 'CRESCENDO',
            quantidadeProdutos: 3,
            impactoLiquido: 10,
          ),
        ],
        buckets: const <SalesProdutoTendenciaClassBucket>[
          SalesProdutoTendenciaClassBucket(
            classificacao: 'CRESCENDO',
            count: 3,
            impacto: 10,
          ),
        ],
      );

      expect(
        metadata.title,
        l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
      );
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnLabel,
          l10n.chartSharePdfColumnSalesCount,
          l10n.chartSharePdfColumnAmount,
        ],
      );
      expect(
        metadata.tableData?.rows.single.first,
        l10n.salesProdutoTendenciaClassificacaoGrowing,
      );
      expect(metadata.tableData?.rows.single[1], '3');
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('top gainers share metadata includes chart export', () {
      final metadata = buildSalesProdutoTendenciaTopGainersShareMetadata(
        l10n: l10n,
        tokens: tokens,
        rows: const <ProdutoVendidoTendenciaDeVendaRow>[_sampleTendenciaRow],
      );

      expect(metadata.title, l10n.salesProdutoTendenciaTopGainersTitle);
      expect(metadata.subtitle, l10n.salesProdutoTendenciaTopGainersSubtitle);
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnName,
          l10n.chartSharePdfColumnValue,
        ],
      );
      expect(metadata.tableData?.rows.single.first, 'Coffee');
      expect(metadata.chartExportBuilder, isNotNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('top losers share metadata includes chart export', () {
      final metadata = buildSalesProdutoTendenciaTopLosersShareMetadata(
        l10n: l10n,
        tokens: tokens,
        rows: const <ProdutoVendidoTendenciaDeVendaRow>[_sampleTendenciaRow],
      );

      expect(metadata.title, l10n.salesProdutoTendenciaTopLosersTitle);
      expect(metadata.subtitle, l10n.salesProdutoTendenciaTopLosersSubtitle);
      expect(metadata.tableData?.rows.single.first, 'Coffee');
      expect(metadata.chartExportBuilder, isNotNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test(
      'top movers share metadata omits chart export when rows are empty',
      () {
        final gainers = buildSalesProdutoTendenciaTopGainersShareMetadata(
          l10n: l10n,
          tokens: tokens,
          rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
        );
        final losers = buildSalesProdutoTendenciaTopLosersShareMetadata(
          l10n: l10n,
          tokens: tokens,
          rows: const <ProdutoVendidoTendenciaDeVendaRow>[],
        );

        expect(gainers.chartExportBuilder, isNull);
        expect(losers.chartExportBuilder, isNull);
      },
    );
  });

  group('sales produto tendencia media movel share metadata', () {
    const buckets = <SalesProdutoTendenciaMediaMovelClassBucket>[
      SalesProdutoTendenciaMediaMovelClassBucket(
        classificacao: 'CRESCENDO',
        count: 12,
        impacto: 40,
      ),
    ];

    test('count share metadata includes bucket rows', () {
      final metadata = buildSalesProdutoTendenciaMediaMovelCountShareMetadata(
        l10n: l10n,
        buckets: buckets,
      );

      expect(
        metadata.title,
        l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
      );
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnLabel,
          l10n.chartSharePdfColumnSalesCount,
        ],
      );
      expect(metadata.tableData?.rows.single.last, '12');
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('impact share metadata is table-only landscape export', () {
      final metadata = buildSalesProdutoTendenciaMediaMovelImpactShareMetadata(
        l10n: l10n,
        buckets: buckets,
      );

      expect(
        metadata.title,
        l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
      );
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.chartSharePdfColumnLabel,
          l10n.chartSharePdfColumnValue,
        ],
      );
      expect(metadata.tableData?.rows.single.last, '40');
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });

    test('details share metadata formats product rows', () {
      const rows = <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
        ProdutoVendidoTendenciaDeVendaMediaMovelRow(
          codEmpresa: 1,
          codFilial: 1,
          codProduto: 7,
          nomeProduto: 'Coffee',
          codUnidadeMedida: 'UN',
          mediaAtual: 10,
          mediaAnterior: 8,
          diferenca: 2,
          tendenciaPercentual: 25,
          classificacao: 'CRESCENDO',
          nomeGrupoProduto: 'Beverages',
        ),
      ];

      final metadata = buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata(
        l10n: l10n,
        rows: rows,
        filterSummary: '7 days',
      );

      expect(metadata.title, l10n.salesProdutoTendenciaMediaMovelDetailsTitle);
      expect(
        metadata.subtitle,
        l10n.salesProdutoTendenciaMediaMovelDetailsSubtitle,
      );
      expect(metadata.filterSummary, contains('7 days'));
      expect(
        metadata.tableData?.headers,
        <String>[
          l10n.salesProdutoTendenciaMediaMovelColProduct,
          l10n.salesProdutoTendenciaMediaMovelColClassificacao,
          l10n.salesProdutoTendenciaMediaMovelColGrupo,
          l10n.salesProdutoTendenciaMediaMovelColMediaAtual,
          l10n.salesProdutoTendenciaMediaMovelColMediaAnterior,
          l10n.salesProdutoTendenciaMediaMovelColDiferenca,
          l10n.salesProdutoTendenciaMediaMovelColPercentual,
        ],
      );
      expect(metadata.tableData?.rows.single.first, 'Coffee');
      expect(metadata.chartExportBuilder, isNull);
      expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
    });
  });
}
