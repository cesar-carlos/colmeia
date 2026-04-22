import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row_number_ordering.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Filters and pagination for the product sales summary `sql.execute` query.
///
/// **Período de venda:** o usuário informa [dataVendaInicio] e [dataVendaFim]
/// (obrigatórios). Apenas a parte de **data** importa: o repositório envia
/// `yyyy-MM-dd` ao agente e a SQL aplica
/// `CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim`
/// (intervalo **inclusivo**). Hora/minuto em [DateTime] é ignorada na validação
/// e no bind.
///
/// [sortBy] escolhe a coluna da métrica no `ORDER BY` do `ROW_NUMBER()`;
/// [sortDirection] define ASC ou **DESC** só para essa métrica (padrão: maior
/// primeiro). `CodEmpresa` e `CodFilial` vêm **sempre** antes em **crescente**;
/// em seguida desempates estáveis (`CodProduto` e demais chaves do agrupamento)
/// em crescente, exceto com `rowNumberOrdering` em modo ranking global
/// (`metricGlobal`: métrica antes de empresa/filial).
class ResumoProdutoVendaFilter {
  const ResumoProdutoVendaFilter({
    /// Limite inferior (inclusivo) do filtro em `ProdutoVendido.DataVenda`.
    required this.dataVendaInicio,
    /// Limite superior (inclusivo) do filtro em `ProdutoVendido.DataVenda`.
    required this.dataVendaFim,
    this.origem = 'FrenteLoja',
    this.sortBy = ResumoProdutoVendaSortBy.qtdVendas,
    this.sortDirection = ResumoProdutoVendaSortDirection.descending,
    this.rowNumberOrdering = ResumoProdutoVendaRowNumberOrdering.ledgerDefault,
    this.page = 1,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 100;

  /// Upper bound for page size (agent `max_rows` and payload safety).
  static const int maxPageSize = 500;

  /// Inclusive calendar-day cap on `(dataVendaFim - dataVendaInicio) + 1` to
  /// protect the agent from unbounded scans.
  static const int maxDateRangeDays = 366;

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;

  /// Bound to `pv.Origem LIKE :origem` (same default as parcel-line resumos).
  final String origem;

  /// Coluna da métrica no `ROW_NUMBER()` (após empresa/filial ASC).
  final ResumoProdutoVendaSortBy sortBy;

  /// ASC ou DESC só para [sortBy]; demais chaves do `ORDER BY` permanecem ASC.
  final ResumoProdutoVendaSortDirection sortDirection;

  /// Ledger (empresa/filial antes da métrica) vs ranking global (métrica antes).
  final ResumoProdutoVendaRowNumberOrdering rowNumberOrdering;

  final int page;
  final int pageSize;

  String get trimmedOrigem => origem.trim();

  int get offset => (page - 1) * pageSize;

  /// Inclusive 1-based row index for `ROW_NUMBER()` paging (`offset + 1`).
  int get startRow => offset + 1;

  /// Inclusive end row index for `ROW_NUMBER()` paging (`offset + pageSize`).
  int get endRow => offset + pageSize;

  /// `max_rows` safety margin above [pageSize] for the bridge execute options.
  int get sqlMaxRowsCap => pageSize + 24;

  String? validationError() {
    if (page < 1) {
      return 'page must be >= 1';
    }
    if (pageSize < 1) {
      return 'pageSize must be >= 1';
    }
    if (pageSize > maxPageSize) {
      return 'pageSize must be <= $maxPageSize';
    }
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
