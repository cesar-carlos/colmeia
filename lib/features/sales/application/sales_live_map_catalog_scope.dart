import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:flutter/foundation.dart';

enum SalesLiveMapCatalogScopeKind { fullAgent, branchSubset }

@immutable
class SalesLiveMapCatalogScope {
  SalesLiveMapCatalogScope.fullAgent({
    Iterable<String>? agentIds,
  }) : kind = SalesLiveMapCatalogScopeKind.fullAgent,
       agentIds = _normalizeAgentIds(agentIds),
       selectedBranches = const <CadastroFilialBranchRef>[];

  SalesLiveMapCatalogScope.branchSubset({
    required Iterable<CadastroFilialBranchRef> selectedBranches,
  }) : kind = SalesLiveMapCatalogScopeKind.branchSubset,
       selectedBranches = _normalizeBranches(selectedBranches),
       agentIds = _normalizeAgentIds(
         selectedBranches.map((branch) => branch.normalizedAgentId),
       );

  /// Canonical signature for a set of agent ids — `'*'` when empty/null,
  /// otherwise a comma-separated sorted list. Used as a cache key fragment so
  /// equivalent selections share storage regardless of insertion order.
  static String agentSignatureOf(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null || selectedAgentIds.isEmpty) {
      return '*';
    }
    final sorted = selectedAgentIds.toList(growable: false)..sort();
    return sorted.join(',');
  }

  /// Canonical signature for a set of branch refs — `'*'` when empty,
  /// otherwise delegates to [CadastroFilialBranchRef.signature]. Used as a
  /// cache key fragment.
  static String branchSignatureOf(
    Iterable<CadastroFilialBranchRef> selectedBranches,
  ) {
    return CadastroFilialBranchRef.signature(selectedBranches);
  }

  final SalesLiveMapCatalogScopeKind kind;
  final List<String> agentIds;
  final List<CadastroFilialBranchRef> selectedBranches;

  bool get isFullAgent => kind == SalesLiveMapCatalogScopeKind.fullAgent;

  bool get isBranchSubset => kind == SalesLiveMapCatalogScopeKind.branchSubset;

  Set<String>? get selectedAgentIds {
    if (agentIds.isEmpty) {
      return null;
    }
    return Set<String>.unmodifiable(agentIds);
  }

  String get agentSignature {
    if (agentIds.isEmpty) {
      return '*';
    }
    return agentIds.join(',');
  }

  String get branchSignature {
    if (selectedBranches.isEmpty) {
      return '*';
    }
    return CadastroFilialBranchRef.signature(selectedBranches);
  }

  String get storageKey =>
      'kind=${kind.name}|agents=$agentSignature|branches=$branchSignature';

  SalesLiveMapCatalogScope get compatibleFullAgentScope {
    return SalesLiveMapCatalogScope.fullAgent(agentIds: agentIds);
  }

  /// Builds the catalog filter for cadastro filial SQL.
  ///
  /// Always scopes SQL to the live-map primary branch (company 1 / branch 1),
  /// matching the sales aggregate filter for the same codes.
  CadastroFilialFilter toCatalogFilter() {
    final primaryBranches = isBranchSubset
        ? _primaryBranchesOnly(selectedBranches)
        : const <CadastroFilialBranchRef>[];
    return CadastroFilialFilter(
      codEmpresa: SalesLiveMapPolicies.primaryCompanyCode,
      codFilial: SalesLiveMapPolicies.primaryBranchCode,
      selectedBranches: primaryBranches,
      pageSize: CadastroFilialFilter.maxPageSize,
      mapCatalogProjection: true,
    );
  }

  static List<CadastroFilialBranchRef> _primaryBranchesOnly(
    Iterable<CadastroFilialBranchRef> branches,
  ) {
    return branches
        .where(
          (branch) =>
              branch.codEmpresa == SalesLiveMapPolicies.primaryCompanyCode &&
              branch.codFilial == SalesLiveMapPolicies.primaryBranchCode,
        )
        .toList(growable: false);
  }

  static List<String> _normalizeAgentIds(Iterable<String>? agentIds) {
    if (agentIds == null) {
      return const <String>[];
    }
    final normalized =
        agentIds
            .map((agentId) => agentId.trim())
            .where((agentId) => agentId.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return List<String>.unmodifiable(normalized);
  }

  static List<CadastroFilialBranchRef> _normalizeBranches(
    Iterable<CadastroFilialBranchRef> branches,
  ) {
    final unique = <String, CadastroFilialBranchRef>{};
    for (final branch in branches) {
      unique['${branch.normalizedAgentId}:${branch.codEmpresa}:${branch.codFilial}'] =
          CadastroFilialBranchRef(
            agentId: branch.normalizedAgentId,
            codEmpresa: branch.codEmpresa,
            codFilial: branch.codFilial,
          );
    }
    final normalized = unique.values.toList(growable: false)
      ..sort((left, right) {
        final agent = left.normalizedAgentId.compareTo(right.normalizedAgentId);
        if (agent != 0) {
          return agent;
        }
        final company = left.codEmpresa.compareTo(right.codEmpresa);
        if (company != 0) {
          return company;
        }
        return left.codFilial.compareTo(right.codFilial);
      });
    return List<CadastroFilialBranchRef>.unmodifiable(normalized);
  }
}
