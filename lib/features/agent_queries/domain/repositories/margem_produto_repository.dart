import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';

// Single entry point for now; batch/cancel may extend this interface later.
// ignore: one_member_abstracts
abstract interface class MargemProdutoRepository {
  Future<AppResult<MargemProdutoPageResult>> loadPage({
    required String userId,
    required String agentId,
    required MargemProdutoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
