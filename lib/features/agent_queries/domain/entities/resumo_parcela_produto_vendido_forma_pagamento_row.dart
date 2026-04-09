class ResumoParcelaProdutoVendidoFormaPagamentoRow {
  const ResumoParcelaProdutoVendidoFormaPagamentoRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.anoDataVenda,
    required this.mesDataVenda,
    required this.anoMesDataVenda,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;

  /// Calendar year of the sale date in the underlying row (SQL `YEAR`).
  final int anoDataVenda;

  /// Calendar month of the sale date in the underlying row (SQL `MONTH`).
  final int mesDataVenda;

  /// Server-built label for the sale month (e.g. `YYYY/MM` or `YYYY/M`).
  /// Prefer two-digit months from the bundled SQL; bridges may return either.
  final String anoMesDataVenda;

  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;

  /// True when [anoMesDataVenda] parses as `year/month` and matches
  /// [anoDataVenda] / [mesDataVenda].
  bool get isAnoMesConsistentWithParts {
    return ResumoParcelaProdutoVendidoFormaPagamentoRow.isAnoMesConsistent(
      anoMesDataVenda: anoMesDataVenda,
      anoDataVenda: anoDataVenda,
      mesDataVenda: mesDataVenda,
    );
  }

  /// Shared check for tests and callers (bridge vs SQL drift).
  static bool isAnoMesConsistent({
    required String anoMesDataVenda,
    required int anoDataVenda,
    required int mesDataVenda,
  }) {
    final parts = anoMesDataVenda.split('/');
    if (parts.length != 2) {
      return false;
    }
    final y = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    return y == anoDataVenda && m == mesDataVenda;
  }
}
