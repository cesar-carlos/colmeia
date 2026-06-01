import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesLiveMapCatalogScope.toCatalogFilter', () {
    test('fullAgent scopes catalog SQL to primary company and branch', () {
      final filter = SalesLiveMapCatalogScope.fullAgent(
        agentIds: const <String>{'agent-a'},
      ).toCatalogFilter();

      expect(filter.codEmpresa, SalesLiveMapPolicies.primaryCompanyCode);
      expect(filter.codFilial, SalesLiveMapPolicies.primaryBranchCode);
      expect(filter.selectedBranches, isEmpty);
      expect(filter.filterScopeSignature, 'empresa=1|filial=1');
    });

    test('branchSubset keeps only primary branches in catalog SQL', () {
      final filter = SalesLiveMapCatalogScope.branchSubset(
        selectedBranches: const <CadastroFilialBranchRef>[
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 1,
          ),
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 2,
          ),
        ],
      ).toCatalogFilter();

      expect(filter.codEmpresa, SalesLiveMapPolicies.primaryCompanyCode);
      expect(filter.codFilial, SalesLiveMapPolicies.primaryBranchCode);
      expect(filter.selectedBranches, hasLength(1));
      expect(filter.selectedBranches.single.codFilial, 1);
    });
  });
}
