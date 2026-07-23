import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('add keeps first qtdVendas and sums totalVenda', () {
    final aggregate = SalesLiveMapBranchAggregate(
      agentId: 'a1',
      agentName: 'Agent',
      codEmpresa: 1,
      codFilial: 1,
      nomeFilial: 'Filial',
      nomeMunicipioFilial: 'Cidade',
      ufMunicipioFilial: 'MT',
    )
      ..add(
        const ResumoTotalVendasMunicipioFilialPeriodoRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Filial',
          qtdVendas: 10,
          totalVenda: 100,
        ),
      )
      ..add(
        const ResumoTotalVendasMunicipioFilialPeriodoRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Filial',
          qtdVendas: 99,
          totalVenda: 50,
        ),
      );

    expect(aggregate.qtdVendas, 10);
    expect(aggregate.totalVenda, 150);
  });
}
