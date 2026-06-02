import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_donut_segments.dart';
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
    posicao: codProduto > 0 ? 1 : null,
  );
}

void main() {
  const palette = <Color>[Colors.red, Colors.blue];

  test('uses percentual as slice weight so total closes at 100', () {
    final segments = rankingProdutosFaturamentoDonutSegments(
      rows: <RankingProdutosFaturamentoRow>[
        _row(codProduto: 1, nome: 'A', valor: 600, percentual: 60),
        _row(
          codProduto: 0,
          nome: RankingProdutosFaturamentoRow.diversosNomeProduto,
          valor: 400,
          percentual: 40,
        ),
      ],
      diversosLabel: 'Demais produtos',
      palette: palette,
    );

    expect(segments, hasLength(2));
    expect(segments[0].value, 60);
    expect(segments[1].value, 40);
    expect(segments.fold<num>(0, (sum, s) => sum + s.value), 100);
    expect(segments[1].label, 'Demais produtos');
    expect(segments[1].percentLabel, '40,0%');
  });

  test('returns empty list for empty rows', () {
    expect(
      rankingProdutosFaturamentoDonutSegments(
        rows: const <RankingProdutosFaturamentoRow>[],
        diversosLabel: 'Demais',
        palette: palette,
      ),
      isEmpty,
    );
  });

  test('collapses rows after top five into diversos visual segment', () {
    final segments = rankingProdutosFaturamentoDonutSegments(
      rows: <RankingProdutosFaturamentoRow>[
        _row(codProduto: 1, nome: 'A', valor: 100, percentual: 30),
        _row(codProduto: 2, nome: 'B', valor: 90, percentual: 20),
        _row(codProduto: 3, nome: 'C', valor: 80, percentual: 15),
        _row(codProduto: 4, nome: 'D', valor: 70, percentual: 10),
        _row(codProduto: 5, nome: 'E', valor: 60, percentual: 8),
        _row(codProduto: 6, nome: 'F', valor: 50, percentual: 7),
        _row(codProduto: 7, nome: 'G', valor: 40, percentual: 10),
      ],
      diversosLabel: 'Demais produtos',
      palette: palette,
      maxHighlightedSegments: 5,
    );

    expect(segments, hasLength(6));
    expect(segments.last.label, 'Demais produtos');
    expect(segments.last.value, 17);
  });
}
