import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';

class ResumoProdutoVendaLucratividadeRowModel {
  const ResumoProdutoVendaLucratividadeRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.qtdVendas,
    required this.qtdItensVendido,
    required this.valorTotalCustoMedio,
    required this.custoReposicao,
    required this.pontoEquilibrio,
    required this.valorTotalItem,
  });

  factory ResumoProdutoVendaLucratividadeRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoProdutoVendaLucratividadeRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
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
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int qtdVendas;
  final double qtdItensVendido;
  final double valorTotalCustoMedio;
  final double custoReposicao;
  final double pontoEquilibrio;
  final double valorTotalItem;

  ResumoProdutoVendaLucratividadeRow toEntity() {
    return ResumoProdutoVendaLucratividadeRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      qtdVendas: qtdVendas,
      qtdItensVendido: qtdItensVendido,
      valorTotalCustoMedio: valorTotalCustoMedio,
      custoReposicao: custoReposicao,
      pontoEquilibrio: pontoEquilibrio,
      valorTotalItem: valorTotalItem,
    );
  }
}
