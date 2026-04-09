import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository.dart';

class LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase {
  LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase(this._repository);

  final ResumoParcelaProdutoVendidoFormaPagamentoRepository _repository;

  Future<AppResult<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>>> call({
    required String agentId,
    required ResumoParcelaProdutoVendidoFormaPagamentoFilter filter,
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
