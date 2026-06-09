import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_scope_resolver.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = SalesLiveMapCatalogScopeResolver();

  test('returns branchSubset scope when query filter has selected branches', () {
    final scope = resolver.resolve(
      queryFilter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        selectedBranches: const <ResumoTotalVendasMunicipioFilialPeriodoBranchRef>[
          ResumoTotalVendasMunicipioFilialPeriodoBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 2,
          ),
        ],
      ),
      fallbackSelectedAgentIds: const <String>{'agent-b'},
    );

    expect(scope.kind, SalesLiveMapCatalogScopeKind.branchSubset);
    expect(scope.selectedBranches, hasLength(1));
    expect(scope.selectedBranches.single.agentId, 'agent-a');
    expect(scope.selectedBranches.single.codEmpresa, 1);
    expect(scope.selectedBranches.single.codFilial, 2);
  });

  test('returns fullAgent scope with fallback ids when no branches selected', () {
    final scope = resolver.resolve(
      queryFilter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
      fallbackSelectedAgentIds: const <String>{'agent-a', 'agent-b'},
    );

    expect(scope.kind, SalesLiveMapCatalogScopeKind.fullAgent);
    expect(scope.agentIds, const <String>{'agent-a', 'agent-b'});
  });
}
