import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart'
    show CadastroFilialBranchRef;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';

/// Derives the branch catalog cache scope from the sales query filter.
class SalesLiveMapCatalogScopeResolver {
  const SalesLiveMapCatalogScopeResolver();

  SalesLiveMapCatalogScope resolve({
    required ResumoTotalVendasMunicipioFilialPeriodoFilter queryFilter,
    required Set<String>? fallbackSelectedAgentIds,
  }) {
    final selectedBranches = queryFilter.selectedBranches
        .map(
          (branch) => CadastroFilialBranchRef(
            agentId: branch.normalizedAgentId,
            codEmpresa: branch.codEmpresa,
            codFilial: branch.codFilial,
          ),
        )
        .toList(growable: false);
    if (selectedBranches.isNotEmpty) {
      return SalesLiveMapCatalogScope.branchSubset(
        selectedBranches: selectedBranches,
      );
    }
    return SalesLiveMapCatalogScope.fullAgent(
      agentIds: fallbackSelectedAgentIds,
    );
  }
}
