import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';

class LoadResumoVendasDiariasPorVendedorUseCase {
  LoadResumoVendasDiariasPorVendedorUseCase(this._repository);

  final ResumoVendasDiariasPorVendedorRepository _repository;

  Future<AppResult<List<ResumoVendasDiariasPorVendedorRow>>> call({
    required String agentId,
    required ResumoVendasDiariasPorVendedorFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) {
    return _repository.load(
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
    );
  }
}
