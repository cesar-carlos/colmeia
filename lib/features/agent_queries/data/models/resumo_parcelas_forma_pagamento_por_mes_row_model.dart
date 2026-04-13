import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';

class ResumoParcelasFormaPagamentoPorMesRowModel {
  const ResumoParcelasFormaPagamentoPorMesRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.anoMesDataVenda,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelasFormaPagamentoPorMesRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoParcelasFormaPagamentoPorMesRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      nomeUsuario: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeUsuario'),
      ),
      anoMesDataVenda: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('AnoMesDataVenda'),
      ),
      codFormaPagamento: _readCodFormaPagamento(map),
      descricaoFormaPagamento:
          AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'DescricaoFormaPagamento',
            ),
          ),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      valorParcela: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorParcela'),
      ),
    );
  }

  static String _readCodFormaPagamento(Map<String, dynamic> map) {
    final keys = AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
      'CodFormaPagamento',
    );
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(map, keys);
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    if (raw is num) {
      final n = raw.toDouble();
      if (n == n.roundToDouble()) {
        return n.toInt().toString();
      }
      return raw.toString();
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final String anoMesDataVenda;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelasFormaPagamentoPorMesRow toEntity() {
    return ResumoParcelasFormaPagamentoPorMesRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeUsuario: nomeUsuario,
      anoMesDataVenda: anoMesDataVenda,
      codFormaPagamento: codFormaPagamento,
      descricaoFormaPagamento: descricaoFormaPagamento,
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }
}
