abstract final class ResumoVendasDiariasPorVendedorVendedorOptionsSql {
  static const String query = '''
      SELECT TOP (:limit)
        CodVendedor,
        NomeVendedor
      FROM (
        SELECT DISTINCT
          pv.CodVendedor,
          COALESCE(
            NULLIF(LTRIM(RTRIM(v.Nome)), ''),
            'Vendedor nao informado'
          ) AS NomeVendedor
        FROM ProdutoVendido pv
        INNER JOIN TipoOperacaoSaida tos ON
          tos.CodEmpresa = pv.CodEmpresa
          AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
        LEFT JOIN Vendedor v ON
          v.CodVendedor = pv.CodVendedor
        WHERE CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
          AND pv.Origem LIKE 'FrenteLoja'
          AND tos.GeraFinanceiro = 'S'
          AND pv.PreVenda = 'N'
          AND COALESCE(
            NULLIF(LTRIM(RTRIM(v.Nome)), ''),
            'Vendedor nao informado'
          ) LIKE COALESCE(:searchPattern, '%')
      ) AS Opt
      WHERE CodVendedor IS NOT NULL
        AND NomeVendedor IS NOT NULL
        AND LTRIM(RTRIM(NomeVendedor)) <> ''
      ORDER BY NomeVendedor, CodVendedor
    ''';
}
