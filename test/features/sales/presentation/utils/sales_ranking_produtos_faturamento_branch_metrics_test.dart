import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_branch_metrics.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter_test/flutter_test.dart';

RankingProdutosFaturamentoRow _row({
  required int codProduto,
  required String nome,
  required double valor,
  required double percentual,
  int? posicao,
}) {
  return RankingProdutosFaturamentoRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: nome,
    valorVenda: valor,
    percentual: percentual,
    posicao: posicao,
  );
}

void main() {
  group('branchRevenueTotal', () {
    test('sums valorVenda', () {
      final rows = <RankingProdutosFaturamentoRow>[
        _row(codProduto: 1, nome: 'A', valor: 100, percentual: 10, posicao: 1),
        _row(codProduto: 2, nome: 'B', valor: 50, percentual: 5, posicao: 2),
      ];
      expect(branchRevenueTotal(rows), 150);
    });
  });

  group('branchPercentSum', () {
    test('sums percentual', () {
      final rows = <RankingProdutosFaturamentoRow>[
        _row(codProduto: 1, nome: 'A', valor: 100, percentual: 60, posicao: 1),
        _row(codProduto: 0, nome: 'DIVERSOS', valor: 40, percentual: 40),
      ];
      expect(branchPercentSum(rows), 100);
    });
  });

  group('branchPercentSumDiverges', () {
    test('returns false when sum is ~100', () {
      final rows = <RankingProdutosFaturamentoRow>[
        _row(
          codProduto: 1,
          nome: 'A',
          valor: 100,
          percentual: 99.8,
          posicao: 1,
        ),
        _row(codProduto: 0, nome: 'DIVERSOS', valor: 1, percentual: 0.2),
      ];
      expect(branchPercentSumDiverges(rows), isFalse);
    });

    test('returns true when sum diverges beyond tolerance', () {
      final rows = <RankingProdutosFaturamentoRow>[
        _row(codProduto: 1, nome: 'A', valor: 100, percentual: 80, posicao: 1),
        _row(codProduto: 0, nome: 'DIVERSOS', valor: 10, percentual: 10),
      ];
      expect(branchPercentSumDiverges(rows), isTrue);
    });
  });

  group('sortRankingProdutosFaturamentoRows', () {
    final rows = <RankingProdutosFaturamentoRow>[
      _row(codProduto: 1, nome: 'A', valor: 100, percentual: 10, posicao: 1),
      _row(codProduto: 2, nome: 'B', valor: 200, percentual: 20, posicao: 2),
      _row(
        codProduto: 0,
        nome: RankingProdutosFaturamentoRow.diversosNomeProduto,
        valor: 50,
        percentual: 70,
      ),
    ];

    test('keeps DIVERSOS last when sorting by venda desc', () {
      final sorted = sortRankingProdutosFaturamentoRows(
        rows,
        const <AppReportSortDescriptor>[
          AppReportSortDescriptor(
            columnKey: 'venda',
            direction: AppReportSortDirection.descending,
          ),
        ],
      );
      expect(sorted.last.isDiversos, isTrue);
      expect(sorted.first.valorVenda, 200);
      expect(sorted[1].valorVenda, 100);
    });

    test('returns SQL order when sorts empty', () {
      final sorted = sortRankingProdutosFaturamentoRows(rows, const []);
      expect(sorted.map((r) => r.codProduto).toList(), <int>[1, 2, 0]);
    });
  });

  group('branchLeadProductInsight', () {
    test('returns lead product insight with highest revenue row', () {
      final rows = <RankingProdutosFaturamentoRow>[
        _row(
          codProduto: 1,
          nome: 'Cafe',
          valor: 320,
          percentual: 32,
          posicao: 1,
        ),
        _row(
          codProduto: 2,
          nome: 'Acucar',
          valor: 180,
          percentual: 18,
          posicao: 2,
        ),
      ];

      final insight = branchLeadProductInsight(rows);

      expect(insight, isNotNull);
      expect(insight!.productName, 'Cafe');
      expect(insight.percentual, 32);
    });
  });
}
