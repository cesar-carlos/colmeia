/// Line items of one entrada note from `Compra.ItemCompra`.
///
/// ## Tables read
///
/// | Alias | Table | Role |
/// | --- | --- | --- |
/// | `cic` | `Compra.ItemCompra` | purchase line: product, qty, amounts |
/// | `p` | `Produto` | product name and group; missing product keeps the line |
/// | `um` | `UnidadeMedida` | unit description for the line unit |
/// | `gp` | `GrupoProduto` | product-group name |
/// | `cc` | `Compra.Compra` | company, branch, and cancelled flag |
///
/// ## Parameters
///
/// `:compraId` is `Compra.Compra.Id` from the notes list. It is compared on
/// `cc.Id` once, without an integer cast, so a wider purchase key still matches.
///
/// Lines are ordered by product name, then product code when names match.
abstract final class NotasEntradaItensSql {
  static const String query = '''
SELECT
  cc.CodEmpresa,
  cc.CodFilial,
  cic.CompraID AS CompraId,
  cc.Cancelada AS CompraCancelada,
  cic.CodProduto,
  p.Nome AS NomeProduto,
  cic.CodUnidadeMedida,
  um.Descricao AS DescricaoUnidadeMedida,
  p.CodGrupoProduto,
  gp.Nome AS NomeGrupoProduto,
  cic.Quantidade,
  cic.ValorUnitario,
  cic.SubTotal,
  cic.ValorDescontoItem,
  cic.ValorTotalDesconto,
  cic.ValorDescontoProporcional,
  cic.ValorTotal
FROM Compra.ItemCompra cic
INNER JOIN Compra.Compra cc ON cc.Id = cic.CompraID
LEFT JOIN Produto p ON p.CodProduto = cic.CodProduto
LEFT JOIN UnidadeMedida um ON um.CodUnidadeMedida = cic.CodUnidadeMedida
LEFT JOIN GrupoProduto gp ON gp.CodGrupoProduto = p.CodGrupoProduto
WHERE cc.Id = :compraId
ORDER BY p.Nome, cic.CodProduto
''';
}
