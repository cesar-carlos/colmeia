import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoProdutoVendaLucratividadeRow percent metrics', () {
    test('venda 200 custo 80 → custo%, margem bruta, markup', () {
      const row = ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 1,
        qtdVendas: 1,
        qtdItensVendido: 1,
        valorTotalCustoMedio: 80,
        custoReposicao: 80,
        pontoEquilibrio: 0,
        valorTotalItem: 200,
      );
      expect(row.percentualCustoSobreVenda, 40.0);
      expect(row.margemLucroBrutoPercent, 60.0);
      expect(row.markupSobreCustoPercent, 150.0);
    });

    test('venda zero → custo e margem percentuais zero; markup zero', () {
      const row = ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 1,
        qtdVendas: 0,
        qtdItensVendido: 0,
        valorTotalCustoMedio: 0,
        custoReposicao: 0,
        pontoEquilibrio: 0,
        valorTotalItem: 0,
      );
      expect(row.percentualCustoSobreVenda, 0.0);
      expect(row.margemLucroBrutoPercent, 0.0);
      expect(row.markupSobreCustoPercent, 0.0);
    });

    test('custo zero com venda positiva → markup getter 0', () {
      const row = ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 1,
        qtdVendas: 1,
        qtdItensVendido: 1,
        valorTotalCustoMedio: 0,
        custoReposicao: 0,
        pontoEquilibrio: 0,
        valorTotalItem: 100,
      );
      expect(row.markupSobreCustoPercent, 0.0);
      expect(row.margemLucroBrutoPercent, 100.0);
    });
  });
}
