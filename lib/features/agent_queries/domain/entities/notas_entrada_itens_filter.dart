/// Purchase identity for entrada-note line items.
class NotasEntradaItensFilter {
  const NotasEntradaItensFilter({required this.compraId});

  final int compraId;

  String? validationError() {
    if (compraId <= 0) {
      return 'compraId must be greater than zero';
    }
    return null;
  }
}
