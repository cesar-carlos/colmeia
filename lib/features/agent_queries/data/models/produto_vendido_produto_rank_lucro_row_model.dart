import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';

class ProdutoVendidoProdutoRankLucroRowModel {
  const ProdutoVendidoProdutoRankLucroRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.qtdItensVendido,
    required this.valorTotal,
    required this.custoTotal,
    required this.lucroUnitario,
    required this.totalValorLucro,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  factory ProdutoVendidoProdutoRankLucroRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ProdutoVendidoProdutoRankLucroRowModel(
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
      qtdItensVendido: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdItensVendido'),
      ),
      valorTotal: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotal'),
      ),
      custoTotal: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CustoTotal'),
      ),
      lucroUnitario: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('LucroUnitario'),
      ),
      totalValorLucro: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalValorLucro'),
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
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final double qtdItensVendido;
  final double valorTotal;
  final double custoTotal;
  final double lucroUnitario;
  final double totalValorLucro;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;

  ProdutoVendidoProdutoRankLucroRow toEntity() {
    return ProdutoVendidoProdutoRankLucroRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      qtdItensVendido: qtdItensVendido,
      valorTotal: valorTotal,
      custoTotal: custoTotal,
      lucroUnitario: lucroUnitario,
      totalValorLucro: totalValorLucro,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      codMarca: codMarca,
      nomeMarca: nomeMarca,
    );
  }
}
