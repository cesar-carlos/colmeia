abstract final class ResumoParcelaFormaPagamentoSql {
  /// Named-parameter version of the report query.
  ///
  /// Inner slice joins cliente and municipio; nome lookups on grupo/regiao/
  /// vendedor are omitted so stricter agent policies (e.g. no `GrupoCliente`
  /// read) still authorize this query. Outer aggregate groups by month label
  /// and payment method, counting distinct sales via the composite `Id`
  /// expression in the inner select.
  static const String query = '''
SELECT
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  MAX(AnoDataVenda) AS AnoDataVenda,
  MAX(MesDataVenda) AS MesDataVenda,
  AnoMesDataVenda,
  CodFormaPagamento,
  DescricaoFormaPagamento,
  COUNT(DISTINCT Id) AS QtdVendas,
  SUM(ValorParcela) AS ValorParcela
FROM (
  SELECT
    pv.CodEmpresa,
    pv.CodFilial,
    pv.CodProdutoVendido,
    CAST(pv.CodEmpresa AS VARCHAR) +
      CAST(pv.CodFilial AS VARCHAR) +
      CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
    pv.Origem,
    pv.CodOrigem,
    COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1), tos.GeraFinanceiro)
      AS GeraFinanceiro,
    pv.PreVenda,
    pv.CodVendedor,
    pv.CodCliente,
    pv.NomeCliente,
    c.CodGrupoCliente,
    pv.CodMunicipio,
    m.Nome AS NomeMunicipio,
    m.UF AS UFMunicipio,
    c.CodRegiao,
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    ppv.DataEmissao,
    ppv.DataVencimento,
    ppv.NumeroDocumento,
    COALESCE(
      NULLIF(LTRIM(RTRIM(pv.NomeUsuario)), ''),
      'Usuario nao informado'
    ) AS NomeUsuario,
    ppv.NumeroParcela,
    YEAR(pv.DataVenda) AS AnoDataVenda,
    MONTH(pv.DataVenda) AS MesDataVenda,
    CAST(YEAR(pv.DataVenda) AS VARCHAR(4)) + '/' +
      RIGHT(
        '0' + CAST(MONTH(pv.DataVenda) AS VARCHAR(2)),
        2
      ) AS AnoMesDataVenda,
    ppv.CodFormaPagamento,
    fp.Descricao AS DescricaoFormaPagamento,
    ppv.ValorParcela
  FROM ParcelaProdutoVendido ppv
  INNER JOIN ProdutoVendido pv ON
    pv.CodEmpresa = ppv.CodEmpresa
    AND pv.CodProdutoVendido = ppv.CodProdutoVendido
  INNER JOIN FormaPagamento fp ON
    fp.CodFormaPagamento = ppv.CodFormaPagamento
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  INNER JOIN Cliente c ON
    c.CodCliente = pv.CodCliente
  INNER JOIN Municipio m ON
    m.CodMunicipio = pv.CodMunicipio
) ResumoParcelaFormaPagamento
WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
  AND Origem LIKE :origem
  AND GeraFinanceiro = :geraFinanceiro
  AND PreVenda = :preVenda
GROUP BY
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  AnoMesDataVenda,
  CodFormaPagamento,
  DescricaoFormaPagamento
ORDER BY
  AnoDataVenda,
  MesDataVenda
''';
}
