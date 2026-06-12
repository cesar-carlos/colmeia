import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/share/overview_lucratividade_chart_share.dart';
import 'package:colmeia/features/overview/presentation/share/overview_lucratividade_mensal_chart_share.dart';
import 'package:colmeia/features/overview/presentation/share/overview_monthly_parcels_combo_chart_share.dart';
import 'package:colmeia/features/overview/presentation/share/overview_payment_mix_share.dart';
import 'package:colmeia/features/overview/presentation/share/overview_rankings_share.dart';
import 'package:colmeia/features/overview/presentation/share/overview_weekday_sales_trend_share.dart';
import 'package:colmeia/features/overview/presentation/share/overview_weekday_user_sales_trend_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  late AppLocalizations l10n;
  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  test('weekday sales trend share metadata is table-only landscape export', () {
    const points = <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 2,
        salesCount: 12,
        salesAmount: 1500,
      ),
    ];
    final salesCountFormat = NumberFormat.decimalPattern(l10n.localeName);

    final metadata = buildOverviewWeekdaySalesTrendShareMetadata(
      l10n: l10n,
      tablePoints: points,
      isSalesCountMetric: true,
      salesCountFormat: salesCountFormat,
    );

    expect(metadata.title, l10n.overviewWeekdaySalesTitle);
    expect(metadata.tableData?.rows.single.first, isNotEmpty);
    expect(metadata.chartExportBuilder, isNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });

  test('weekday user sales trend share metadata includes grouped export', () {
    const points = <OverviewWeekdayUserSalesTrendPoint>[
      OverviewWeekdayUserSalesTrendPoint(
        weekdayNumber: 2,
        userName: 'Alice',
        salesCount: 8,
        salesAmount: 900,
      ),
    ];
    final salesCountFormat = NumberFormat.decimalPattern(l10n.localeName);

    final metadata = buildOverviewWeekdayUserSalesTrendShareMetadata(
      l10n: l10n,
      points: points,
      isSalesCount: true,
      title: l10n.overviewWeekdayUserSalesTitle,
      salesCountFormat: salesCountFormat,
      chartExportBuilder: (_) => const SizedBox.shrink(),
    );

    expect(metadata.title, l10n.overviewWeekdayUserSalesTitle);
    expect(metadata.tableData?.rows.single[1], 'Alice');
    expect(metadata.chartExportBuilder, isNotNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });

  test('agent ranking share metadata is table-only landscape export', () {
    const rankings = <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a1',
        displayName: 'Store A',
        totalSalesCount: 20,
        totalAmount: 5000,
      ),
    ];

    final metadata = buildOverviewAgentRankingShareMetadata(
      l10n: l10n,
      agentRankings: rankings,
    );

    expect(metadata.title, l10n.dashboardAgentRankingTitle);
    expect(metadata.tableData?.rows.single[1], 'Store A');
    expect(metadata.chartExportBuilder, isNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });

  test('user ranking share metadata is table-only landscape export', () {
    const rankings = <OverviewUserRanking>[
      OverviewUserRanking(
        userName: 'Bob',
        totalSalesCount: 5,
        totalAmount: 1200,
        averageTicket: 240,
      ),
    ];

    final metadata = buildOverviewUserRankingShareMetadata(
      l10n: l10n,
      userRankings: rankings,
    );

    expect(metadata.title, l10n.dashboardUserRankingTitle);
    expect(metadata.tableData?.rows.single[1], 'Bob');
    expect(metadata.chartExportBuilder, isNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });

  test('payment mix share metadata is table-only export', () {
    const segments = <AppCategoryDonutSegment>[
      AppCategoryDonutSegment(
        label: 'PIX',
        value: 800,
        valueLabel: r'R$ 800,00',
        percentLabel: '80.0%',
      ),
    ];

    final metadata = buildOverviewPaymentMixShareMetadata(
      l10n: l10n,
      segments: segments,
    );

    expect(metadata.title, l10n.overviewPaymentMixTitle);
    expect(metadata.tableData?.rows.single.first, 'PIX');
    expect(metadata.chartExportBuilder, isNull);
  });

  test('lucratividade chart share metadata includes agent rows', () {
    const points = <ResumoProdutoVendaLucratividadeRow>[
      ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 1,
        qtdVendas: 10,
        qtdItensVendido: 20,
        valorTotalCustoMedio: 400,
        custoReposicao: 500,
        pontoEquilibrio: 0,
        valorTotalItem: 1000,
        chartAxisLabel: 'Agent A',
      ),
    ];
    const exportStyle = AppComboChartStyle(height: 280);
    const series = OverviewLucratividadeComboShareSeries(
      barValueBuilder: _barByProfit,
      lineValueBuilder: _lineByProfit,
      barDataLabelBuilder: _barDataLabel,
      barSeriesLabel: 'Profit',
      lineSeriesLabel: 'Revenue',
    );

    final metadata = buildOverviewLucratividadeChartShareMetadata(
      l10n: l10n,
      sortedPoints: points,
      exportBaseStyle: exportStyle,
      series: series,
    );

    expect(metadata.title, l10n.overviewLucratividadeTitle);
    expect(metadata.tableData?.rows.single.first, 'Agent A');
    expect(metadata.chartExportBuilder, isNotNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });

  test('lucratividade mensal share metadata includes month values', () {
    const points = <ResumoProdutoVendaLucratividadeMensalRow>[
      ResumoProdutoVendaLucratividadeMensalRow(
        codEmpresa: 1,
        codFilial: 1,
        ano: 2026,
        mes: 5,
        anoMes: '2026/05',
        qtdVendas: 10,
        qtdItensVendido: 20,
        valorTotalCustoMedio: 400,
        custoReposicao: 500,
        pontoEquilibrio: 0,
        valorTotalItem: 1000,
      ),
    ];
    const exportStyle = AppComboChartStyle(height: 280);
    const series = OverviewLucratividadeMensalComboShareSeries(
      barValueBuilder: _mensalBarByProfit,
      lineValueBuilder: _mensalLineByProfit,
      barDataLabelBuilder: _mensalBarDataLabel,
      barSeriesLabel: 'Profit',
      lineSeriesLabel: 'Revenue',
    );

    final metadata = buildOverviewLucratividadeMensalChartShareMetadata(
      l10n: l10n,
      sortedPoints: points,
      exportBaseStyle: exportStyle,
      series: series,
    );

    expect(metadata.title, l10n.overviewLucratividadeMensalTitle);
    expect(metadata.tableData?.rows.single.first, '2026/05');
    expect(metadata.chartExportBuilder, isNotNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });

  test('monthly parcels combo share metadata uses landscape export', () {
    const points = <OverviewMonthlyParcelPoint>[
      OverviewMonthlyParcelPoint(
        anoMes: '2026/05',
        qtdVendas: 40,
        valorParcela: 3200,
      ),
    ];
    const exportStyle = AppComboChartStyle(height: 280);
    final decimalFormat = NumberFormat.decimalPattern(l10n.localeName);
    final compactCurrencyFormat = NumberFormat.compactCurrency(
      locale: l10n.localeName,
      symbol: r'R$',
    );

    final metadata = buildOverviewMonthlyParcelsComboShareMetadata(
      l10n: l10n,
      points: points,
      exportBaseStyle: exportStyle,
      valuePrimary: false,
      copy: null,
      title: l10n.overviewMonthlyParcelsTitle,
      subtitle: l10n.overviewMonthlyParcelsSubtitle,
      decimalFormat: decimalFormat,
      compactCurrencyFormat: compactCurrencyFormat,
    );

    expect(metadata.title, l10n.overviewMonthlyParcelsTitle);
    expect(metadata.tableData?.rows.single.first, '2026/05');
    expect(metadata.chartExportBuilder, isNotNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.landscape);
  });
}

num _barByProfit(ResumoProdutoVendaLucratividadeRow row) => row.lucro;
num _lineByProfit(ResumoProdutoVendaLucratividadeRow row) => row.valorTotalItem;
String _barDataLabel(ResumoProdutoVendaLucratividadeRow _, num value) =>
    value.toStringAsFixed(0);

num _mensalBarByProfit(ResumoProdutoVendaLucratividadeMensalRow row) =>
    row.lucro;
num _mensalLineByProfit(ResumoProdutoVendaLucratividadeMensalRow row) =>
    row.valorTotalItem;
String _mensalBarDataLabel(
  ResumoProdutoVendaLucratividadeMensalRow _,
  num value,
) => value.toStringAsFixed(0);
