import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_repository.dart';

class LoadResumoParcelaFormaPagamentoDiarioUseCase {
  LoadResumoParcelaFormaPagamentoDiarioUseCase(this._repository);

  final ResumoParcelaFormaPagamentoDiarioRepository _repository;

  Future<AppResult<List<ResumoParcelaFormaPagamentoDiarioRow>>> call({
    required String agentId,
    required ResumoParcelaFormaPagamentoDiarioFilter filter,
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
