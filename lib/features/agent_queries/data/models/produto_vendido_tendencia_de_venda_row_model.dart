import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';

class ProdutoVendidoTendenciaDeVendaRowModel {
  const ProdutoVendidoTendenciaDeVendaRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.codUnidadeMedida,
    required this.qtdAnterior,
    required this.qtdAtual,
    required this.diferenca,
    required this.percentualTendencia,
    required this.classificacao,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  factory ProdutoVendidoTendenciaDeVendaRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ProdutoVendidoTendenciaDeVendaRowModel(
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
      qtdAnterior: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdAnterior'),
      ),
      qtdAtual: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdAtual'),
      ),
      diferenca: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Diferenca'),
      ),
      percentualTendencia: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('PercentualTendencia'),
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
  final double qtdAnterior;
  final double qtdAtual;
  final double diferenca;
  final double percentualTendencia;
  final String classificacao;

  ProdutoVendidoTendenciaDeVendaRow toEntity() {
    return ProdutoVendidoTendenciaDeVendaRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      codUnidadeMedida: codUnidadeMedida,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      codMarca: codMarca,
      nomeMarca: nomeMarca,
      qtdAnterior: qtdAnterior,
      qtdAtual: qtdAtual,
      diferenca: diferenca,
      percentualTendencia: percentualTendencia,
      classificacao: classificacao,
    );
  }
}
