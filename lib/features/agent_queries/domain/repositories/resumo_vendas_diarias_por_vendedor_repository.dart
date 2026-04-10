import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';

// Query-specific repository entry point; more report methods may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoVendasDiariasPorVendedorRepository {
  Future<AppResult<List<ResumoVendasDiariasPorVendedorRow>>> load({
    required String agentId,
    required ResumoVendasDiariasPorVendedorFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  });
}
