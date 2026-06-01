import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';

// Query-specific repository entry point; more report methods may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoParcelaFormaPagamentoRepositoryV2 {
  Future<AppResult<List<ResumoParcelaFormaPagamentoRowV2>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoFilterV2 filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
