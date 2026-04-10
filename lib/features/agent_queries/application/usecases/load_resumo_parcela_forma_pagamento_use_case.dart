import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository.dart';

class LoadResumoParcelaFormaPagamentoUseCase {
  LoadResumoParcelaFormaPagamentoUseCase(this._repository);

  final ResumoParcelaFormaPagamentoRepository _repository;

  Future<AppResult<List<ResumoParcelaFormaPagamentoRow>>> call({
    required String agentId,
    required ResumoParcelaFormaPagamentoFilter filter,
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
