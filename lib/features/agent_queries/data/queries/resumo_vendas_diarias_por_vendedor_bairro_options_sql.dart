abstract final class ResumoVendasDiariasPorVendedorBairroOptionsSql {
  static const String query = '''
SELECT TOP (:limit)
  Bairro
FROM (
  SELECT DISTINCT
    LTRIM(RTRIM(pv.Bairro)) AS Bairro
  FROM ProdutoVendido pv
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  WHERE CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
    AND pv.Origem LIKE 'FrenteLoja'
    AND tos.GeraFinanceiro = 'S'
    AND pv.PreVenda = 'N'
    AND pv.Bairro IS NOT NULL
    AND LTRIM(RTRIM(pv.Bairro)) <> ''
    AND (
      :searchPattern IS NULL
      OR LTRIM(RTRIM(pv.Bairro)) LIKE :searchPattern
    )
) AS Opt
ORDER BY Bairro
''';
}
