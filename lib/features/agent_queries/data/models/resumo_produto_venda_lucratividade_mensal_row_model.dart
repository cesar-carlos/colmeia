import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';

class ResumoProdutoVendaLucratividadeMensalRowModel {
  const ResumoProdutoVendaLucratividadeMensalRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.ano,
    required this.mes,
    required this.anoMes,
    required this.qtdVendas,
    required this.qtdItensVendido,
    required this.valorTotalCustoMedio,
    required this.custoReposicao,
    required this.pontoEquilibrio,
    required this.valorTotalItem,
    required this.percentualLucro,
  });

  factory ResumoProdutoVendaLucratividadeMensalRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoProdutoVendaLucratividadeMensalRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      ano: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Ano'),
      ),
      mes: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Mes'),
      ),
      anoMes: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('AnoMes'),
      ),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      qtdItensVendido: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdItensVendido'),
      ),
      valorTotalCustoMedio: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotalCustoMedio'),
      ),
      custoReposicao: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CustoReposicao'),
      ),
      pontoEquilibrio: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('PontoEquilibrio'),
      ),
      valorTotalItem: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotalItem'),
      ),
      percentualLucro: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('PercentualLucro'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int ano;
  final int mes;
  final String anoMes;
  final int qtdVendas;
  final double qtdItensVendido;
  final double valorTotalCustoMedio;
  final double custoReposicao;
  final double pontoEquilibrio;
  final double valorTotalItem;
  final double percentualLucro;

  ResumoProdutoVendaLucratividadeMensalRow toEntity() {
    return ResumoProdutoVendaLucratividadeMensalRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      ano: ano,
      mes: mes,
      anoMes: anoMes,
      qtdVendas: qtdVendas,
      qtdItensVendido: qtdItensVendido,
      valorTotalCustoMedio: valorTotalCustoMedio,
      custoReposicao: custoReposicao,
      pontoEquilibrio: pontoEquilibrio,
      valorTotalItem: valorTotalItem,
      percentualLucro: percentualLucro,
    );
  }
}
