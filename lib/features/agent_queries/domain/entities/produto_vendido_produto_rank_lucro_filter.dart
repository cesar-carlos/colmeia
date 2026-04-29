import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Filters for the product profitability rank `sql.execute` query.
///
/// Only [dataVendaInicio] and [dataVendaFim] are required. The repository sends
/// `yyyy-MM-dd` strings; the SQL uses
/// `CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim`.
class ProdutoVendidoProdutoRankLucroFilter {
  const ProdutoVendidoProdutoRankLucroFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.origem = 'FrenteLoja',
    this.sortBy = ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
    this.sortDirection = ResumoProdutoVendaSortDirection.descending,
  });

  /// Allows up to 366 days so any full-year or custom range fits in a
  /// single request.
  static const int maxDateRangeDays = 366;

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;

  /// Bound to `pv.Origem LIKE :origem`.
  final String origem;

  final ProdutoVendidoProdutoRankLucroSortBy sortBy;
  final ResumoProdutoVendaSortDirection sortDirection;

  String get trimmedOrigem => origem.trim();

  String? validationError() {
    if (trimmedOrigem.isEmpty) {
      return 'origem must not be empty';
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
