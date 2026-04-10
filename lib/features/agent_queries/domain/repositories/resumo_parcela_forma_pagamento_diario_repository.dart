import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';

// Query-specific repository entry point; more report methods may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoParcelaFormaPagamentoDiarioRepository {
  Future<AppResult<List<ResumoParcelaFormaPagamentoDiarioRow>>> load({
    required String agentId,
    required ResumoParcelaFormaPagamentoDiarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  });
}
