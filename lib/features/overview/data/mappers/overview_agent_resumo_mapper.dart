import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';

OverviewPaymentResumoRow overviewPaymentResumoRowFromAgentRow(
  ResumoParcelaFormaPagamentoRow row,
) {
  return OverviewPaymentResumoRow(
    nomeUsuario: row.nomeUsuario,
    codFormaPagamento: row.codFormaPagamento,
    descricaoFormaPagamento: row.descricaoFormaPagamento,
    qtdVendas: row.qtdVendas,
    valorParcela: row.valorParcela,
  );
}
