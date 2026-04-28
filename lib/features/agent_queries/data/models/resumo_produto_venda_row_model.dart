import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';

class ResumoProdutoVendaRowModel {
  const ResumoProdutoVendaRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.qtdVendas,
    required this.qtdItensVendido,
    required this.valorTotalCustoMedio,
    required this.custoReposicao,
    required this.pontoEquilibrio,
    required this.valorTotalItem,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
    this.codTipoGrupoProduto,
    this.descricaoTipoGrupoProduto,
  });

  factory ResumoProdutoVendaRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoProdutoVendaRowModel(
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
      codTipoGrupoProduto: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodTipoGrupoProduto'),
      ),
      descricaoTipoGrupoProduto:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'DescricaoTipoGrupoProduto',
            ),
          ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final int qtdVendas;
  final double qtdItensVendido;
  final double valorTotalCustoMedio;
  final double custoReposicao;
  final double pontoEquilibrio;
  final double valorTotalItem;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;
  final int? codTipoGrupoProduto;
  final String? descricaoTipoGrupoProduto;

  ResumoProdutoVendaRow toEntity() {
    return ResumoProdutoVendaRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      qtdVendas: qtdVendas,
      qtdItensVendido: qtdItensVendido,
      valorTotalCustoMedio: valorTotalCustoMedio,
      custoReposicao: custoReposicao,
      pontoEquilibrio: pontoEquilibrio,
      valorTotalItem: valorTotalItem,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      codMarca: codMarca,
      nomeMarca: nomeMarca,
      codTipoGrupoProduto: codTipoGrupoProduto,
      descricaoTipoGrupoProduto: descricaoTipoGrupoProduto,
    );
  }
}
