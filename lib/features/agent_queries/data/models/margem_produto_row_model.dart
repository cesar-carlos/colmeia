import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';

class MargemProdutoRowModel {
  const MargemProdutoRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.custoReposicao,
    required this.precoVendaProduto,
    required this.percentualMarkupCustoCompraProduto,
    required this.margemLucroProduto,
    this.nomeFantasiaFilial,
    this.codUnidadeMedida,
    this.descricaoUnidadeMedida,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  factory MargemProdutoRowModel.fromMap(Map<String, dynamic> map) {
    return MargemProdutoRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      nomeFilial: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFilial'),
      ),
      nomeFantasiaFilial:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'NomeFantasiaFilial',
            ),
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
      descricaoUnidadeMedida:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'DescricaoUnidadeMedida',
            ),
          ),
      codGrupoProduto: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodGrupoProduto'),
      ),
      nomeGrupoProduto:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeGrupoProduto'),
          ),
      codMarca: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMarca'),
      ),
      nomeMarca: AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeMarca'),
      ),
      custoReposicao: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CustoReposicao'),
      ),
      precoVendaProduto: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('PrecoVendaProduto'),
      ),
      percentualMarkupCustoCompraProduto:
          AgentQueriesSqlRowMapReader.readRequiredDouble(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'PercentualMarkupCustoCompraProduto',
            ),
          ),
      margemLucroProduto: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('MargemLucroProduto'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final int codProduto;
  final String nomeProduto;
  final String? codUnidadeMedida;
  final String? descricaoUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;
  final double custoReposicao;
  final double precoVendaProduto;
  final double percentualMarkupCustoCompraProduto;
  final double margemLucroProduto;

  MargemProdutoRow toEntity() {
    return MargemProdutoRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: nomeFilial,
      nomeFantasiaFilial: nomeFantasiaFilial,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      codUnidadeMedida: codUnidadeMedida,
      descricaoUnidadeMedida: descricaoUnidadeMedida,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      codMarca: codMarca,
      nomeMarca: nomeMarca,
      custoReposicao: custoReposicao,
      precoVendaProduto: precoVendaProduto,
      percentualMarkupCustoCompraProduto: percentualMarkupCustoCompraProduto,
      margemLucroProduto: margemLucroProduto,
    );
  }
}
