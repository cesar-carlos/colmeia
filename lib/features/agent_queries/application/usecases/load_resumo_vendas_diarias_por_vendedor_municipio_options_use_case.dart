import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';

class LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase {
  LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase(this._repository);

  final ResumoVendasDiariasPorVendedorFilterOptionsRepository _repository;

  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>> call({
    required String userId,
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadMunicipioOptions(
      userId: userId,
      agentId: agentId,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      searchTerm: searchTerm,
      limit: limit,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }
}
