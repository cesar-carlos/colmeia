import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';

class ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel {
  const ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel({
    required this.classificacao,
    required this.quantidadeProdutos,
    required this.impactoLiquido,
  });

  factory ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel(
      classificacao: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Classificacao'),
      ),
      quantidadeProdutos: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QuantidadeProdutos'),
      ),
      impactoLiquido: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ImpactoLiquido'),
      ),
    );
  }

  final String classificacao;
  final int quantidadeProdutos;
  final double impactoLiquido;

  ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow toEntity() {
    return ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
      classificacao: classificacao,
      quantidadeProdutos: quantidadeProdutos,
      impactoLiquido: impactoLiquido,
    );
  }
}
