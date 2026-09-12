import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_resumo_fornecedor_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_resumo_fornecedor_repository.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:result_dart/result_dart.dart';

/// Loads every supplier-total row for PDF share, respecting the page cap.
class LoadNotasEntradaResumoFornecedorRowsForShareUseCase {
  LoadNotasEntradaResumoFornecedorRowsForShareUseCase(this._repository);

  final NotasEntradaResumoFornecedorRepository _repository;

  static const int maxExportRowCount = ChartSharePdfLimits.maxTableRows;

  Future<AppResult<List<NotaEntradaResumoFornecedorRow>>> call({
    required String userId,
    required String agentId,
    required NotasEntradaFilter filter,
    required int totalCount,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (totalCount <= 0) {
      return const Success(<NotaEntradaResumoFornecedorRow>[]);
    }
    if (totalCount > maxExportRowCount) {
      return const Failure(
        ValidationFailure(message: 'share_export_row_limit_exceeded'),
      );
    }

    final pageSize = totalCount.clamp(1, NotasEntradaFilter.maxPageSize);
    final collected = <NotaEntradaResumoFornecedorRow>[];
    var page = 1;
    while (collected.length < totalCount) {
      final pageFilter = filter.copyWith(page: page, pageSize: pageSize);
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
      var pageResult = const NotasEntradaResumoFornecedorPageResult(
        items: <NotaEntradaResumoFornecedorRow>[],
        totalCount: 0,
        totalValorCompra: 0,
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
    return Success(
      List<NotaEntradaResumoFornecedorRow>.unmodifiable(collected),
    );
  }
}
