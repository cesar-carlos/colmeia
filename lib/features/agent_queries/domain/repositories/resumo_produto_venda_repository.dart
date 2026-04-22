import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_page_result.dart';

// Single entry point for now; batch/cancel may extend this interface later.
// ignore: one_member_abstracts
abstract interface class ResumoProdutoVendaRepository {
  Future<AppResult<ResumoProdutoVendaPageResult>> loadPage({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
