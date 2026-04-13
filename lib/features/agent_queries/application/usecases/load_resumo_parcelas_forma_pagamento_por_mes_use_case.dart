import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_repository.dart';

class LoadResumoParcelasFormaPagamentoPorMesUseCase {
  LoadResumoParcelasFormaPagamentoPorMesUseCase(this._repository);

  final ResumoParcelasFormaPagamentoPorMesRepository _repository;

  Future<AppResult<List<ResumoParcelasFormaPagamentoPorMesRow>>> call({
    required String agentId,
    required ResumoParcelasFormaPagamentoPorMesFilter filter,
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
