/// Grain shown on the entrada-notes report: documents or supplier totals.
enum SalesNotasEntradaView {
  notes,
  bySupplier;

  static const String persistKey = 'view';

  static SalesNotasEntradaView fromPersisted(Object? raw) {
    return switch (raw) {
      'bySupplier' => SalesNotasEntradaView.bySupplier,
      _ => SalesNotasEntradaView.notes,
    };
  }
}
