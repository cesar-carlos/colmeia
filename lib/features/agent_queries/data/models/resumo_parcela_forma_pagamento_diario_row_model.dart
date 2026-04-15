import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';

class ResumoVendaProdutoDiarioRowModel {
  const ResumoVendaProdutoDiarioRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProdutoVendido,
    required this.origem,
    required this.codOrigem,
    required this.dataVenda,
    required this.anoMesDataVenda,
    required this.nomeUsuario,
    required this.qtdVendas,
    required this.valorTotalVenda,
    this.codVendedor,
    this.nomeVendedor,
  });

  factory ResumoVendaProdutoDiarioRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoVendaProdutoDiarioRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      codProdutoVendido: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProdutoVendido'),
      ),
      origem: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Origem'),
      ),
      codOrigem: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodOrigem'),
      ),
      dataVenda: AgentQueriesSqlRowMapReader.readDataVendaCalendarDate(map),
      anoMesDataVenda:
          AgentQueriesSqlRowMapReader.readRequiredAnoMesDataVenda(map),
      nomeUsuario: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeUsuario'),
      ),
      codVendedor: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodVendedor'),
      ),
      nomeVendedor: AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeVendedor'),
      ),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      valorTotalVenda: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotalVenda'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int codProdutoVendido;
  final String origem;
  final int codOrigem;
  final DateTime dataVenda;
  final String anoMesDataVenda;
  final String nomeUsuario;
  final int? codVendedor;
  final String? nomeVendedor;
  final int qtdVendas;
  final double valorTotalVenda;

  ResumoVendaProdutoDiarioRow toEntity() {
    return ResumoVendaProdutoDiarioRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codProdutoVendido: codProdutoVendido,
      origem: origem,
      codOrigem: codOrigem,
      dataVenda: dataVenda,
      anoMesDataVenda: anoMesDataVenda,
      nomeUsuario: nomeUsuario,
      codVendedor: codVendedor,
      nomeVendedor: nomeVendedor,
      qtdVendas: qtdVendas,
      valorTotalVenda: valorTotalVenda,
    );
  }
}
