import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoProdutoVendaLucratividadeRowMerger', () {
    test('keeps first qtdVendas and pontoEquilibrio; sums additive money', () {
      final merged = ResumoProdutoVendaLucratividadeRowMerger.merge(
        <ResumoProdutoVendaLucratividadeRow>[
          const ResumoProdutoVendaLucratividadeRow(
            codEmpresa: 1,
            codFilial: 1,
            qtdVendas: 10,
            qtdItensVendido: 1,
            valorTotalCustoMedio: 2,
            custoReposicao: 3,
            pontoEquilibrio: 4,
            valorTotalItem: 5,
          ),
          const ResumoProdutoVendaLucratividadeRow(
            codEmpresa: 1,
            codFilial: 1,
            qtdVendas: 99,
            qtdItensVendido: 10,
            valorTotalCustoMedio: 20,
            custoReposicao: 30,
            pontoEquilibrio: 40,
            valorTotalItem: 50,
          ),
          const ResumoProdutoVendaLucratividadeRow(
            codEmpresa: 1,
            codFilial: 2,
            qtdVendas: 3,
            qtdItensVendido: 1,
            valorTotalCustoMedio: 1,
            custoReposicao: 1,
            pontoEquilibrio: 1,
            valorTotalItem: 1,
          ),
        ],
      );

      expect(merged.length, 2);
      expect(merged.first.qtdVendas, 10);
      expect(merged.first.pontoEquilibrio, 4);
      expect(merged.first.qtdItensVendido, 11);
      expect(merged.first.valorTotalCustoMedio, 22);
      expect(merged.first.custoReposicao, 33);
      expect(merged.first.valorTotalItem, 55);
      expect(merged.last.qtdVendas, 3);
    });
  });
}
