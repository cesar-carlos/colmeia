/// One purchase line from `Compra.ItemCompra` for an entrada note.
class NotaEntradaItemRow {
  const NotaEntradaItemRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.compraId,
    required this.compraCancelada,
    required this.codProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.subTotal,
    required this.valorDescontoItem,
    required this.valorTotalDesconto,
    required this.valorDescontoProporcional,
    required this.valorTotal,
    this.codUnidadeMedida,
    this.descricaoUnidadeMedida,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
  });

  final int codEmpresa;
  final int codFilial;
  final int compraId;

  /// `Compra.Compra.Cancelada`, either the flag (`S` / `N`) or the label
  /// (`Sim` / `Nao`).
  final String compraCancelada;
  final int codProduto;

  /// Empty when `Produto` has no row for [codProduto].
  final String nomeProduto;

  /// Unit code such as `UN` or `UNIDADE`. Null when the line has no unit.
  final String? codUnidadeMedida;
  final String? descricaoUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final double quantidade;
  final double valorUnitario;
  final double subTotal;
  final double valorDescontoItem;
  final double valorTotalDesconto;
  final double valorDescontoProporcional;
  final double valorTotal;

  bool get isCancelled {
    switch (compraCancelada.trim().toUpperCase()) {
      case 'S':
      case 'SIM':
        return true;
      default:
        return false;
    }
  }
}
