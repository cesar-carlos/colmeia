import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:result_dart/result_dart.dart';

/// Loads every catalog row for PDF share, respecting the repository page cap.
///
/// The page size stays constant across requests so `ROW_NUMBER` windows stay
/// contiguous (`page 2` of 500 starts at row 501). Shrinking the last page
/// would re-window earlier rows and export duplicates.
///
/// Returns a validation failure when paging cannot reconstruct the advertised
/// totalCount (short page, changing total, or extra rows). A partial catalog
/// is never exported as success.
class LoadMargemProdutoRowsForShareUseCase {
  LoadMargemProdutoRowsForShareUseCase(this._repository);

  final MargemProdutoRepository _repository;

  static const int maxExportRowCount = ChartSharePdfLimits.maxTableRows;

  Future<AppResult<List<MargemProdutoRow>>> call({
    required String userId,
    required String agentId,
    required MargemProdutoFilter filter,
    required int totalCount,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (totalCount <= 0) {
      return const Success(<MargemProdutoRow>[]);
    }
    if (totalCount > maxExportRowCount) {
      return const Failure(
        ValidationFailure(message: 'share_export_row_limit_exceeded'),
      );
    }

    final pageSize = totalCount.clamp(1, MargemProdutoFilter.maxPageSize);
    final collected = <MargemProdutoRow>[];
    var page = 1;
    while (collected.length < totalCount) {
      final pageFilter = MargemProdutoFilter(
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
        searchTerm: filter.searchTerm,
        page: page,
        pageSize: pageSize,
      );
      final expectedCount = (totalCount - collected.length).clamp(1, pageSize);

      final result = await _repository.loadPage(
        userId: userId,
        agentId: agentId,
        filter: pageFilter,
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
      );

      AppFailure? failure;
      var pageResult = const MargemProdutoPageResult(
        items: <MargemProdutoRow>[],
        totalCount: 0,
      );
      result.fold(
        (value) => pageResult = value,
        (err) => failure = err,
      );
      if (failure != null) {
        return Failure(failure!);
      }
      if (pageResult.totalCount != totalCount ||
          pageResult.items.length != expectedCount) {
        return const Failure(
          ValidationFailure(message: 'share_export_incomplete_catalog'),
        );
      }
      collected.addAll(pageResult.items);
      page++;
    }

    if (collected.length != totalCount) {
      return const Failure(
        ValidationFailure(message: 'share_export_incomplete_catalog'),
      );
    }
    return Success(List<MargemProdutoRow>.unmodifiable(collected));
  }
}
