import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/progressive_report_loading.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_repository.dart';

class LoadResumoParcelaFormaPagamentoDiarioUseCase {
  LoadResumoParcelaFormaPagamentoDiarioUseCase(this._repository);

  final ResumoParcelaFormaPagamentoDiarioRepository _repository;

  Future<AppResult<List<ResumoVendaProdutoDiarioRow>>> call({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoDiarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.load(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      cancelScope: cancelScope,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }

  Stream<AppResult<AgentQueryProgress<ResumoVendaProdutoDiarioRow>>> watch({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoDiarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) => ProgressiveReportLoading.watch(
    reportId: 'resumo_parcela_forma_pagamento_diario',
    repository: _repository,
    userId: userId,
    agentId: agentId,
    filter: filter,
    clientToken: clientToken,
    bridgeTimeoutMs: bridgeTimeoutMs,
    hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    cancelScope: cancelScope,
    loadComplete: (scope) => call(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      cancelScope: scope,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    ),
  );
}
