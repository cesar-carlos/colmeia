import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';

class LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase {
  LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase(this._repository);

  final ResumoVendasDiariasPorVendedorFilterOptionsRepository _repository;

  Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>> call({
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) {
    return _repository.loadVendedorOptions(
      agentId: agentId,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      searchTerm: searchTerm,
      limit: limit,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
    );
  }
}
