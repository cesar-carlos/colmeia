import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:result_dart/result_dart.dart';

/// Loads every catalog row for PDF share, respecting the repository page cap.
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
  }) async {
    if (totalCount <= 0) {
      return const Success(<MargemProdutoRow>[]);
    }
    if (totalCount > maxExportRowCount) {
      return const Failure(
        ValidationFailure(message: 'share_export_row_limit_exceeded'),
      );
    }

    final collected = <MargemProdutoRow>[];
    var page = 1;
    while (collected.length < totalCount) {
      final remaining = totalCount - collected.length;
      final pageSize = remaining.clamp(1, MargemProdutoFilter.maxPageSize);
      final pageFilter = MargemProdutoFilter(
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
        sortBy: filter.sortBy,
        sortDirection: filter.sortDirection,
        page: page,
        pageSize: pageSize,
      );

      final result = await _repository.loadPage(
        userId: userId,
        agentId: agentId,
        filter: pageFilter,
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
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
      if (pageResult.items.isEmpty) {
        break;
      }
      collected.addAll(pageResult.items);
      if (collected.length >= totalCount) {
        break;
      }
      page++;
    }

    final cappedLength = collected.length > totalCount
        ? totalCount
        : collected.length;
    return Success(
      List<MargemProdutoRow>.unmodifiable(collected.sublist(0, cappedLength)),
    );
  }
}
