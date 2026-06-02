import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';

class RankingProdutosFaturamentoRowModel {
  const RankingProdutosFaturamentoRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.valorVenda,
    required this.percentual,
    this.posicao,
    this.codUnidadeMedida,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
  });

  factory RankingProdutosFaturamentoRowModel.fromMap(Map<String, dynamic> map) {
    return RankingProdutosFaturamentoRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      codProduto: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
      ),
      nomeProduto: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeProduto'),
      ),
      codUnidadeMedida: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodUnidadeMedida'),
      ),
      codGrupoProduto: AgentQueriesSqlRowMapReader.readOptionalInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodGrupoProduto'),
      ),
      nomeGrupoProduto: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeGrupoProduto'),
      ),
      valorVenda: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorVenda'),
      ),
      percentual: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Percentual'),
      ),
      posicao: AgentQueriesSqlRowMapReader.readOptionalInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Posicao'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final String? codUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final double valorVenda;
  final double percentual;
  final int? posicao;

  RankingProdutosFaturamentoRow toEntity() {
    return RankingProdutosFaturamentoRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      codUnidadeMedida: codUnidadeMedida,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      valorVenda: valorVenda,
      percentual: percentual,
      posicao: posicao,
    );
  }
}
