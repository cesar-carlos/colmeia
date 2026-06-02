/// Filters for the product billing rank `sql.execute` query.
///
/// [quantidadeProdutos] is the TOP N bound per branch (`Posicao <= N`). Each
/// branch may also return one `DIVERSOS` row for products outside the top N.
class RankingProdutosFaturamentoFilter {
  const RankingProdutosFaturamentoFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    required this.quantidadeProdutos,
    this.origem = 'FrenteLoja',
    this.preVenda = 'N',
    this.codEmpresa,
    this.codFilial,
  });

  static const int maxQuantidadeProdutos = 100;
  static const int maxDateRangeDays = 366;

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;
  final int quantidadeProdutos;

  /// Bound to `pv.Origem = :origem` (exact match; wildcards rejected).
  final String origem;

  /// Bound to `pv.PreVenda = :preVenda` (`'S'` or `'N'`).
  final String preVenda;

  /// When set with [codFilial], restricts ranking to a single branch.
  final int? codEmpresa;

  final int? codFilial;

  String get trimmedOrigem => origem.trim();

  String get trimmedPreVenda => preVenda.trim();

  String? validationError() {
    if (quantidadeProdutos < 1) {
      return 'quantidadeProdutos must be at least 1';
    }
    if (quantidadeProdutos > maxQuantidadeProdutos) {
      return 'quantidadeProdutos must be at most $maxQuantidadeProdutos';
    }

    final origemTrim = trimmedOrigem;
    if (origemTrim.isEmpty) {
      return 'origem must not be empty';
    }
    if (origemTrim.contains('%') || origemTrim.contains('_')) {
      return 'origem must not contain SQL LIKE wildcards (% or _) '
          'for ProdutoVendido resumo queries (exact match only)';
    }

    final preVendaTrim = trimmedPreVenda;
    if (preVendaTrim != 'S' && preVendaTrim != 'N') {
      return "preVenda must be 'S' or 'N'";
    }

    if (codEmpresa != null && codEmpresa! < 1) {
      return 'codEmpresa must be positive when set';
    }
    if (codFilial != null && codFilial! < 0) {
      return 'codFilial must be non-negative when set';
    }
    if (codFilial != null && codEmpresa == null) {
      return 'codEmpresa is required when codFilial is set';
    }

    final start = DateTime(
      dataVendaInicio.year,
      dataVendaInicio.month,
      dataVendaInicio.day,
    );
    final end = DateTime(
      dataVendaFim.year,
      dataVendaFim.month,
      dataVendaFim.day,
    );
    if (end.isBefore(start)) {
      return 'dataVendaFim must be on or after dataVendaInicio';
    }
    final inclusiveDays = end.difference(start).inDays + 1;
    if (inclusiveDays > maxDateRangeDays) {
      return 'date range must be at most $maxDateRangeDays inclusive days';
    }
    return null;
  }
}
