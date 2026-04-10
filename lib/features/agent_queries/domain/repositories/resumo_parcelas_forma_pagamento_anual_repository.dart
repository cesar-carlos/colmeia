import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';

// Query-specific repository entry point; more report methods may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoParcelasFormaPagamentoAnualRepository {
  Future<AppResult<List<ResumoParcelasFormaPagamentoAnualRow>>> load({
    required String agentId,
    required ResumoParcelasFormaPagamentoAnualFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  });
}
