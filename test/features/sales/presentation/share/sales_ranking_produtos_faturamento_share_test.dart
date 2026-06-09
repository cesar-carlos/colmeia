import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_ranking_produtos_faturamento_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RankingProdutosFaturamentoRow _row({
  required int codProduto,
  required String nome,
  required double valor,
  required double percentual,
}) {
  return RankingProdutosFaturamentoRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: nome,
    valorVenda: valor,
    percentual: percentual,
    posicao: 1,
  );
}

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  });

  test('share metadata includes table rows without offscreen chart export', () {
    final rows = <RankingProdutosFaturamentoRow>[
      _row(codProduto: 1, nome: 'Cafe', valor: 320, percentual: 32),
      _row(codProduto: 2, nome: 'Acucar', valor: 180, percentual: 18),
    ];

    final metadata = buildSalesRankingProdutosFaturamentoShareMetadata(
      l10n: l10n,
      branchTitle: 'Lucas Centro',
      metricSubtitle: 'Top 15 â€¢ Faturamento',
      displayRows: rows,
    );

    expect(metadata.title, 'Lucas Centro');
    expect(metadata.subject, 'Lucas Centro');
    expect(metadata.subtitle, 'Top 15 â€¢ Faturamento');
    expect(
      metadata.tableData?.headers,
      <String>[
        l10n.salesRankingProdutosFaturamentoGridColumnPosicao,
        l10n.salesRankingProdutosFaturamentoGridColumnProduto,
        l10n.salesRankingProdutosFaturamentoGridColumnVenda,
        l10n.salesRankingProdutosFaturamentoGridColumnPercent,
      ],
    );
    expect(metadata.tableData?.rows.length, 2);
    expect(metadata.tableData?.rows.first[1], 'Cafe');
    expect(metadata.chartExportBuilder, isNull);
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.portrait);
  });

  test('share metadata truncates table rows over limit', () {
    final rows = List<RankingProdutosFaturamentoRow>.generate(
      ChartSharePdfLimits.maxTableRows + 1,
      (index) => _row(
        codProduto: index,
        nome: 'Product $index',
        valor: (100 + index).toDouble(),
        percentual: 1,
      ),
    );

    final metadata = buildSalesRankingProdutosFaturamentoShareMetadata(
      l10n: l10n,
      branchTitle: 'Lucas Centro',
      metricSubtitle: 'Top 15 â€¢ Faturamento',
      displayRows: rows,
    );

    const totalRows = ChartSharePdfLimits.maxTableRows + 1;
    expect(metadata.tableData?.rows.length, ChartSharePdfLimits.maxTableRows);
    expect(
      metadata.filterSummary,
      contains('${ChartSharePdfLimits.maxTableRows}'),
    );
    expect(metadata.filterSummary, contains('$totalRows'));
  });

  test('share metadata omits chart export when display rows are empty', () {
    final metadata = buildSalesRankingProdutosFaturamentoShareMetadata(
      l10n: l10n,
      branchTitle: 'Lucas Centro',
      metricSubtitle: 'Top 15 â€¢ Faturamento',
      displayRows: const <RankingProdutosFaturamentoRow>[],
    );

    expect(metadata.chartExportBuilder, isNull);
  });
}
