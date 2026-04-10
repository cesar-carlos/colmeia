import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';

abstract interface class ResumoVendasDiariasPorVendedorFilterOptionsRepository {
  Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>>
  loadVendedorOptions({
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
  });

  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadBairroOptions({
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
  });

  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadMunicipioOptions({
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
  });
}
