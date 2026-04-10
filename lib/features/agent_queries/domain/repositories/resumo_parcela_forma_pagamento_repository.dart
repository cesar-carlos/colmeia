import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';

// Query-specific repository entry point; more report methods may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoParcelaFormaPagamentoRepository {
  Future<AppResult<List<ResumoParcelaFormaPagamentoRow>>> load({
    required String agentId,
    required ResumoParcelaFormaPagamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  });
}
