import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository_v2.dart';

class LoadResumoParcelaFormaPagamentoUseCaseV2 {
  LoadResumoParcelaFormaPagamentoUseCaseV2(this._repository);

  final ResumoParcelaFormaPagamentoRepositoryV2 _repository;

  Future<AppResult<List<ResumoParcelaFormaPagamentoRowV2>>> call({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoFilterV2 filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.load(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }
}
