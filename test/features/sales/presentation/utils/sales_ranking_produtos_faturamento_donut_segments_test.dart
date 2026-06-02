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
}
