import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:result_dart/result_dart.dart';

/// Loads every detail row for PDF share, respecting the repository page cap.
class LoadMediaMovelRowsForShareUseCase {
  LoadMediaMovelRowsForShareUseCase(this._repository);

  final ProdutoVendidoTendenciaDeVendaMediaMovelRepository _repository;

  static const int maxExportRowCount = ChartSharePdfLimits.maxTableRows;

  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaMediaMovelRow>>> call({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaMediaMovelFilter filter,
    required int totalCount,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (totalCount <= 0) {
      return const Success(<ProdutoVendidoTendenciaDeVendaMediaMovelRow>[]);
    }
    if (totalCount > maxExportRowCount) {
      return const Failure(
        ValidationFailure(message: 'share_export_row_limit_exceeded'),
      );
    }

    final collected = <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[];
    var page = 1;
    while (collected.length < totalCount) {
      final remaining = totalCount - collected.length;
      final pageSize = remaining.clamp(
        1,
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.maxPageSize,
      );
      final pageFilter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: filter.quantidadeDias,
        origem: filter.origem,
        searchTerm: filter.searchTerm,
        classificacao: filter.classificacao,
        codGrupoProduto: filter.codGrupoProduto,
        codMarca: filter.codMarca,
        sortBy: filter.sortBy,
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
        cancelScope: cancelScope,
      );

      AppFailure? failure;
      var pageResult = const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
        items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
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

    return Success(
      List<ProdutoVendidoTendenciaDeVendaMediaMovelRow>.unmodifiable(collected),
    );
  }
}
