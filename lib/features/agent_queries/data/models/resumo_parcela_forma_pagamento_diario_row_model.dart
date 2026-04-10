import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';

class ResumoParcelaFormaPagamentoDiarioRowModel {
  const ResumoParcelaFormaPagamentoDiarioRowModel({
    required this.dataVenda,
    required this.descricaoFormaPagamento,
    required this.quantidade,
    required this.valorTotal,
  });

  factory ResumoParcelaFormaPagamentoDiarioRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoParcelaFormaPagamentoDiarioRowModel(
      dataVenda: AgentQueriesSqlRowMapReader.readDataVendaCalendarDate(map),
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

  final DateTime dataVenda;
  final String descricaoFormaPagamento;
  final int quantidade;
  final double valorTotal;

  ResumoParcelaFormaPagamentoDiarioRow toEntity() {
    return ResumoParcelaFormaPagamentoDiarioRow(
      dataVenda: dataVenda,
      descricaoFormaPagamento: descricaoFormaPagamento,
      quantidade: quantidade,
      valorTotal: valorTotal,
    );
  }
}
