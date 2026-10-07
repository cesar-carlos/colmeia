import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/progressive_report_loading.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/paged_progressive_report_repository.dart';

/// Loads one page of the product-margin catalog. [MargemProdutoFilter]
/// carries optional contains search, [MargemProdutoFilter.sortBy] /
/// [MargemProdutoFilter.sortDirection] for `ROW_NUMBER`, and pagination;
/// company and branch are fixed at `1`/`1`. Default order is `NomeProduto
/// ASC`, then `CodProduto ASC`.
class LoadMargemProdutoPageUseCase {
  LoadMargemProdutoPageUseCase(this._repository);

  final MargemProdutoRepository _repository;

  bool get usesProgressiveCatalog =>
      ProgressiveReportLoading.isEnabled('margem_produto') &&
      _repository
          is PagedProgressiveReportRepository<
            MargemProdutoFilter,
            MargemProdutoRow
          >;

  Future<AppResult<MargemProdutoPageResult>> call({
    required String userId,
    required String agentId,
    required MargemProdutoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _repository.loadPage(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );
  }

  Stream<AppResult<AgentQueryProgress<MargemProdutoRow>>> watchCatalog({
    required String userId,
    required String agentId,
    required MargemProdutoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) => ProgressiveReportLoading.watchPages(
    reportId: 'margem_produto',
    repository: _repository,
    userId: userId,
    agentId: agentId,
    filter: filter,
    clientToken: clientToken,
    bridgeTimeoutMs: bridgeTimeoutMs,
    hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    cancelScope: cancelScope,
  );
}
