import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';

class ProdutoVendidoTendenciaDeVendaMediaMovelRowModel {
  const ProdutoVendidoTendenciaDeVendaMediaMovelRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.codUnidadeMedida,
    required this.mediaAtual,
    required this.mediaAnterior,
    required this.diferenca,
    required this.tendenciaPercentual,
    required this.classificacao,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  factory ProdutoVendidoTendenciaDeVendaMediaMovelRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ProdutoVendidoTendenciaDeVendaMediaMovelRowModel(
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
      codUnidadeMedida: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
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
      codMarca: AgentQueriesSqlRowMapReader.readOptionalInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMarca'),
      ),
      nomeMarca: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeMarca'),
      ),
      mediaAtual: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('MediaAtual'),
      ),
      mediaAnterior: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('MediaAnterior'),
      ),
      diferenca: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Diferenca'),
      ),
      tendenciaPercentual: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
          'TendenciaPercentual',
        ),
      ),
      classificacao: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Classificacao'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final String codUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;
  final double mediaAtual;
  final double mediaAnterior;
  final double diferenca;
  final double tendenciaPercentual;
  final String classificacao;

  ProdutoVendidoTendenciaDeVendaMediaMovelRow toEntity() {
    return ProdutoVendidoTendenciaDeVendaMediaMovelRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      codUnidadeMedida: codUnidadeMedida,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      codMarca: codMarca,
      nomeMarca: nomeMarca,
      mediaAtual: mediaAtual,
      mediaAnterior: mediaAnterior,
      diferenca: diferenca,
      tendenciaPercentual: tendenciaPercentual,
      classificacao: classificacao,
    );
  }
}
