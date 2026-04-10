import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_anual_repository.dart';

class LoadResumoParcelasFormaPagamentoAnualUseCase {
  LoadResumoParcelasFormaPagamentoAnualUseCase(this._repository);

  final ResumoParcelasFormaPagamentoAnualRepository _repository;

  Future<AppResult<List<ResumoParcelasFormaPagamentoAnualRow>>> call({
    required String agentId,
    required ResumoParcelasFormaPagamentoAnualFilter filter,
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
