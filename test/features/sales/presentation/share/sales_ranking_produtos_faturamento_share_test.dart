import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_ranking_produtos_faturamento_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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

  test('share metadata includes table rows and dedicated pie export', () {
    final rows = <RankingProdutosFaturamentoRow>[
      _row(codProduto: 1, nome: 'Cafe', valor: 320, percentual: 32),
      _row(codProduto: 2, nome: 'Acucar', valor: 180, percentual: 18),
    ];

    final metadata = buildSalesRankingProdutosFaturamentoShareMetadata(
      l10n: l10n,
      branchTitle: 'Lucas Centro',
      metricSubtitle: 'Top 15 • Faturamento',
      displayRows: rows,
      chartRows: rows,
    );

    expect(metadata.title, 'Lucas Centro');
    expect(metadata.subtitle, 'Top 15 • Faturamento');
    expect(metadata.tableData?.rows.length, 2);
    expect(metadata.chartExportBuilder, isNotNull);
  });

  test('share metadata omits chart export when chart rows are empty', () {
    final metadata = buildSalesRankingProdutosFaturamentoShareMetadata(
      l10n: l10n,
      branchTitle: 'Lucas Centro',
      metricSubtitle: 'Top 15 • Faturamento',
      displayRows: const <RankingProdutosFaturamentoRow>[],
      chartRows: const <RankingProdutosFaturamentoRow>[],
    );

    expect(metadata.chartExportBuilder, isNull);
  });
}
