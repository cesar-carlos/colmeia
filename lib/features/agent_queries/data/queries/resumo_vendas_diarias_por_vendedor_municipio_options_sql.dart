abstract final class ResumoVendasDiariasPorVendedorMunicipioOptionsSql {
  static const String query = '''
SELECT TOP (:limit)
  NomeMunicipio
FROM (
  SELECT DISTINCT
    LTRIM(RTRIM(m.Nome)) AS NomeMunicipio
  FROM ProdutoVendido pv
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  INNER JOIN Municipio m ON
    m.CodMunicipio = pv.CodMunicipio
  WHERE CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
    AND pv.Origem LIKE 'FrenteLoja'
    AND tos.GeraFinanceiro = 'S'
    AND pv.PreVenda = 'N'
    AND m.Nome IS NOT NULL
    AND LTRIM(RTRIM(m.Nome)) <> ''
    AND (
      :searchPattern IS NULL
      OR LTRIM(RTRIM(m.Nome)) LIKE :searchPattern
    )
) AS Opt
ORDER BY NomeMunicipio
''';
}
