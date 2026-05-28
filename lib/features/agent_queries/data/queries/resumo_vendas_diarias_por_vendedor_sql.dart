import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_nome_expression.dart';

abstract final class ResumoVendasDiariasPorVendedorSql {
  /// Daily sales by seller from parcel lines with troco allocation, distinct
  /// sale count, and net value. Aligns with the ERP ResumoVendasDiarioVendedor
  /// report name on the wrapped subquery.
  ///
  /// Inner slice uses LEFT JOIN for GrupoCliente, Regiao, and Vendedor; those
  /// columns may be SQL NULL. Stricter agent policies may be required than the
  /// older ProdutoVendido-only version.
  ///
  /// `BairroNomeNorm` / `NomeMunicipioNomeNorm` are computed once per row so
  /// filters compare a column to a normalized expression.
  ///
  /// [codVendedor], [bairro], and [municipio] are inlined into the SQL text so
  /// the bridge payload stays within its named-parameter limit (five: dates +
  /// origem flags).
  static String query({
    int? codVendedor,
    String? bairro,
    String? municipio,
  }) {
    final bNorm =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.nomeBairroSql(
          "COALESCE(det_inner.Bairro, '')",
        );
    final mNorm =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.nomeMunicipioSql(
          "COALESCE(det_inner.NomeMunicipio, '')",
        );
    final codVendedorLine = codVendedor == null
        ? '        AND (1 = 1)'
        : '        AND CodVendedor = $codVendedor';
    final bairroLine =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.outerWhereNormalizedBairro(
          bairro,
        );
    final municipioLine =
        ResumoVendasDiariasPorVendedorBairroNomeExpression.outerWhereNormalizedMunicipio(
          municipio,
        );
    return '''
      SELECT
        CodEmpresa,
        CodFilial,
        DataVenda,
        AnoMesDataVenda,
        CodVendedor,
        NomeVendedor,
        COUNT(DISTINCT Id) AS QtdVendas,
        SUM(ValorParcela - ValorTrocoParcela) AS ValorTotalVenda
      FROM (
        SELECT
          CodEmpresa,
          CodFilial,
          CodProdutoVendido,
          Id,
          Origem,
          CodOrigem,
          GeraFinanceiro,
          PreVenda,
          CodVendedor,
          NomeVendedor,
          CodCliente,
          NomeCliente,
          CodGrupoCliente,
          NomeGrupoCliente,
          CodMunicipio,
          Bairro,
          NomeMunicipio,
          UFMunicipio,
          CodRegiao,
          NomeRegiao,
          DataVenda,
          DataEmissao,
          DataVencimento,
          NumeroDocumento,
          NomeUsuario,
          NumeroParcela,
          AnoDataVenda,
          MesDataVenda,
          AnoMesDataVenda,
          CodFormaPagamento,
          DescricaoFormaPagamento,
          ValorTrocoParcela,
          ValorParcela,
          BairroNomeNorm,
          NomeMunicipioNomeNorm
        FROM (
          SELECT
            det_inner.*,
            $bNorm AS BairroNomeNorm,
            $mNorm AS NomeMunicipioNomeNorm
          FROM (
      ${ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins}
          ) det_inner
        ) Detalhe
      ) ResumoVendasDiarioVendedor
      WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
        AND Origem = :origem
        AND GeraFinanceiro = :geraFinanceiro
        AND PreVenda = :preVenda
$codVendedorLine
$bairroLine
$municipioLine
      GROUP BY
        CodEmpresa,
        CodFilial,
        DataVenda,
        AnoMesDataVenda,
        CodVendedor,
        NomeVendedor
      ORDER BY
        CodEmpresa,
        CodFilial,
        DataVenda,
        AnoMesDataVenda,
        CodVendedor,
        NomeVendedor
    ''';
  }
}
