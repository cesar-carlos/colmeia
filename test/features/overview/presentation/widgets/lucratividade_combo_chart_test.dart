import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_row_percent_metric_comparator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row_percent_metric.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

ResumoProdutoVendaLucratividadeRow _row({
  required String label,
  required double lucro,
  required double valorTotalItem,
  required double custoReposicao,
}) {
  return ResumoProdutoVendaLucratividadeRow(
    codEmpresa: 1,
    codFilial: 1,
    qtdVendas: 10,
    qtdItensVendido: 20,
    valorTotalCustoMedio: custoReposicao,
    custoReposicao: custoReposicao,
    pontoEquilibrio: 0,
    valorTotalItem: valorTotalItem,
    chartAxisLabel: label,
  );
}

final _rowAccessors =
    LucratividadeComboRowAccessors<ResumoProdutoVendaLucratividadeRow>(
      lucro: (r) => r.lucro,
      valorTotalItem: (r) => r.valorTotalItem,
      custoReposicao: (r) => r.custoReposicao,
      metricBarValue: (r, m) => r.metricBarValue(m),
      sortPoints: (sorted, display, percentMetric) {
        if (display == LucratividadeComboDisplay.profitRevenue) {
          sorted.sort((a, b) => b.lucro.compareTo(a.lucro));
        } else if (display == LucratividadeComboDisplay.costRevenue) {
          sorted.sort((a, b) => b.custoReposicao.compareTo(a.custoReposicao));
        } else if (display == LucratividadeComboDisplay.percentMetrics) {
          sorted.sort(
            (a, b) =>
                compareLucratividadeRowsByPercentMetric(a, b, percentMetric),
          );
        } else {
          sorted.sort((a, b) => b.valorTotalItem.compareTo(a.valorTotalItem));
        }
      },
    );

ChartShareMetadata _shareMetadata({
  required List<ResumoProdutoVendaLucratividadeRow> sortedPoints,
  required AppComboChartStyle exportBaseStyle,
  required num Function(ResumoProdutoVendaLucratividadeRow) barFn,
  required num Function(ResumoProdutoVendaLucratividadeRow) lineFn,
  required String Function(ResumoProdutoVendaLucratividadeRow, num) labelFn,
  required String barSeriesLabel,
  required String lineSeriesLabel,
}) {
  return const ChartShareMetadata(title: 'Lucratividade');
}

Widget _chart({
  required AppLocalizations l10n,
  required List<ResumoProdutoVendaLucratividadeRow> points,
  bool loadFailed = false,
}) {
  return LucratividadeComboChart<ResumoProdutoVendaLucratividadeRow>(
    l10n: l10n,
    copy: LucratividadeComboChartCopy(
      title: l10n.overviewLucratividadeTitle,
      subtitle: l10n.overviewLucratividadeSubtitle,
      switchProfit: l10n.overviewLucratividadeSwitchProfit,
      switchRevenue: l10n.overviewLucratividadeSwitchRevenue,
      switchCost: l10n.overviewLucratividadeSwitchCost,
      switchMargin: l10n.overviewLucratividadeSwitchMargin,
      profitSeriesLabel: l10n.overviewLucratividadeProfitSeriesLabel,
      revenueSeriesLabel: l10n.overviewLucratividadeRevenueSeriesLabel,
      costSeriesLabel: l10n.overviewLucratividadeCostSeriesLabel,
      emptyMessage: l10n.overviewLucratividadeEmpty,
      multiAgentHintMessage: l10n.overviewLucratividadeMultiAgentHint,
      loadFailedFallback: l10n.overviewMonthlyParcelsLoadFailed,
      showChronologicalPercentHint: false,
      useSmartCompactCurrencyLabels: true,
    ),
    points: points,
    loadFailed: loadFailed,
    rowAccessors: _rowAccessors,
    xLabelBuilder: (row) => row.filialLabel,
    shareMetadataBuilder: _shareMetadata,
    hasMultiAgentEmptyHint: true,
  );
}

void main() {
  testWidgets('shows empty placeholder when points are empty', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: Builder(
          builder: (context) => _chart(
            l10n: AppLocalizations.of(context),
            points: const <ResumoProdutoVendaLucratividadeRow>[],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.overviewLucratividadeEmpty), findsOneWidget);
    expect(
      find.byType(AppComboChart<ResumoProdutoVendaLucratividadeRow>),
      findsOneWidget,
    );
  });

  testWidgets('renders chart with a single point', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return _chart(
              l10n: l10n,
              points: <ResumoProdutoVendaLucratividadeRow>[
                _row(
                  label: 'Loja A',
                  lucro: 120,
                  valorTotalItem: 500,
                  custoReposicao: 380,
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byType(AppComboChart<ResumoProdutoVendaLucratividadeRow>),
      findsOneWidget,
    );
    expect(find.text(l10n.overviewLucratividadeSwitchProfit), findsWidgets);
  });

  testWidgets('switches display mode via segmented control', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: Builder(
          builder: (context) => _chart(
            l10n: AppLocalizations.of(context),
            points: <ResumoProdutoVendaLucratividadeRow>[
              _row(
                label: 'Loja A',
                lucro: 120,
                valorTotalItem: 500,
                custoReposicao: 380,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text(l10n.overviewLucratividadeSwitchRevenue).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(AppSegmentedControl<LucratividadeComboDisplay>),
      findsOneWidget,
    );
    expect(
      find.byType(AppComboChart<ResumoProdutoVendaLucratividadeRow>),
      findsOneWidget,
    );
  });
}
