import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';

class ResumoParcelasFormaPagamentoAnualRowModel {
  const ResumoParcelasFormaPagamentoAnualRowModel({
    required this.ano,
    required this.descricaoFormaPagamento,
    required this.quantidade,
    required this.valorTotal,
  });

  factory ResumoParcelasFormaPagamentoAnualRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoParcelasFormaPagamentoAnualRowModel(
      ano: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Ano'),
      ),
      descricaoFormaPagamento:
          AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'DescricaoFormaPagamento',
            ),
          ),
      quantidade: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Quantidade'),
      ),
      valorTotal: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotal'),
      ),
    );
  }

  final int ano;
  final String descricaoFormaPagamento;
  final int quantidade;
  final double valorTotal;

  ResumoParcelasFormaPagamentoAnualRow toEntity() {
    return ResumoParcelasFormaPagamentoAnualRow(
      ano: ano,
      descricaoFormaPagamento: descricaoFormaPagamento,
      quantidade: quantidade,
      valorTotal: valorTotal,
    );
  }
}
