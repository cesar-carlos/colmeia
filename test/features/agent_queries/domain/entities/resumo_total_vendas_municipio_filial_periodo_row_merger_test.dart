import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoTotalVendasMunicipioFilialPeriodoRowMerger', () {
    test('dedupes by empresa|filial without summing distinct qtdVendas', () {
      const a = ResumoTotalVendasMunicipioFilialPeriodoRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeFilial: 'Filial 1',
        qtdVendas: 10,
        totalVenda: 100,
      );
      const b = ResumoTotalVendasMunicipioFilialPeriodoRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeFilial: 'Filial 1',
        qtdVendas: 7,
        totalVenda: 50,
      );
      const other = ResumoTotalVendasMunicipioFilialPeriodoRow(
        codEmpresa: 1,
        codFilial: 2,
        nomeFilial: 'Filial 2',
        qtdVendas: 3,
        totalVenda: 20,
      );

      final merged = ResumoTotalVendasMunicipioFilialPeriodoRowMerger.merge([
        a,
        b,
        other,
      ]);

      expect(merged, hasLength(2));
      expect(merged.first.codFilial, 1);
      expect(merged.first.qtdVendas, 10);
      expect(merged.first.totalVenda, 150);
      expect(merged.last.codFilial, 2);
      expect(merged.last.qtdVendas, 3);
    });
  });
}
