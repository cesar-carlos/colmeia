import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';

/// Maps AppReportViewer sort/pagination onto the MargemProduto SQL
/// whitelist (`nomeProduto`, `custoReposicao`, `percentualMarkup`,
/// `margemLucroProduto`).
abstract final class SalesMargemProdutoSort {
  static const String cardId = 'margem_produto';

  static const String columnProduto = 'nomeProduto';
  static const String columnCustoReposicao = 'custoReposicao';
  static const String columnPrecoVenda = 'precoVendaProduto';
  static const String columnMarkup = 'percentualMarkup';
  static const String columnMargem = 'margemLucroProduto';

  static const List<int> allowedPageSizes = <int>[10, 20, 50];
  static const int defaultPageSize = 20;

  static const String persistSortByKey = 'sortBy';
  static const String persistSortDirectionKey = 'sortDirection';
  static const String persistPageSizeKey = 'pageSize';
  static const String persistCodEmpresaKey = 'codEmpresa';
  static const String persistCodFilialKey = 'codFilial';

  static const MargemProdutoSortBy defaultSortBy =
      MargemProdutoSortBy.nomeProduto;
  static const ResumoProdutoVendaSortDirection defaultSortDirection =
      ResumoProdutoVendaSortDirection.ascending;

  static MargemProdutoSortBy? tryParseColumnKey(String columnKey) {
    return switch (columnKey) {
      columnProduto => MargemProdutoSortBy.nomeProduto,
      columnCustoReposicao => MargemProdutoSortBy.custoReposicao,
      columnMarkup => MargemProdutoSortBy.percentualMarkup,
      columnMargem => MargemProdutoSortBy.margemLucroProduto,
      _ => null,
    };
  }

  static String columnKeyFor(MargemProdutoSortBy sortBy) {
    return switch (sortBy) {
      MargemProdutoSortBy.nomeProduto => columnProduto,
      MargemProdutoSortBy.custoReposicao => columnCustoReposicao,
      MargemProdutoSortBy.percentualMarkup => columnMarkup,
      MargemProdutoSortBy.margemLucroProduto => columnMargem,
    };
  }

  static MargemProdutoSortBy parseSortBy(String? raw) {
    return switch (raw) {
      'nomeProduto' => MargemProdutoSortBy.nomeProduto,
      'custoReposicao' => MargemProdutoSortBy.custoReposicao,
      'percentualMarkup' => MargemProdutoSortBy.percentualMarkup,
      'margemLucroProduto' => MargemProdutoSortBy.margemLucroProduto,
      _ => defaultSortBy,
    };
  }

  static ResumoProdutoVendaSortDirection parseSortDirection(String? raw) {
    return switch (raw) {
      'ascending' => ResumoProdutoVendaSortDirection.ascending,
      'descending' => ResumoProdutoVendaSortDirection.descending,
      _ => defaultSortDirection,
    };
  }

  static ResumoProdutoVendaSortDirection directionFromReport(
    AppReportSortDirection direction,
  ) {
    return switch (direction) {
      AppReportSortDirection.ascending =>
        ResumoProdutoVendaSortDirection.ascending,
      AppReportSortDirection.descending =>
        ResumoProdutoVendaSortDirection.descending,
    };
  }

  static AppReportSortDirection directionToReport(
    ResumoProdutoVendaSortDirection direction,
  ) {
    return switch (direction) {
      ResumoProdutoVendaSortDirection.ascending =>
        AppReportSortDirection.ascending,
      ResumoProdutoVendaSortDirection.descending =>
        AppReportSortDirection.descending,
    };
  }

  static int sanitizePageSize(Object? raw) {
    final parsed = restoreInt(raw);
    if (parsed != null && allowedPageSizes.contains(parsed)) {
      return parsed;
    }
    return defaultPageSize;
  }

  static int sanitizePage(Object? raw) {
    final parsed = restoreInt(raw);
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  static AppReportSortDescriptor descriptorFor({
    required MargemProdutoSortBy sortBy,
    required ResumoProdutoVendaSortDirection sortDirection,
  }) {
    return AppReportSortDescriptor(
      columnKey: columnKeyFor(sortBy),
      direction: directionToReport(sortDirection),
    );
  }

  static (MargemProdutoSortBy, ResumoProdutoVendaSortDirection) fromSorts(
    List<AppReportSortDescriptor> sorts,
  ) {
    for (final sort in sorts) {
      final sortBy = tryParseColumnKey(sort.columnKey);
      if (sortBy != null) {
        return (sortBy, directionFromReport(sort.direction));
      }
    }
    return (defaultSortBy, defaultSortDirection);
  }

  static AppReportQuery queryFor({
    required MargemProdutoSortBy sortBy,
    required ResumoProdutoVendaSortDirection sortDirection,
    required int page,
    required int pageSize,
    AppReportQuery? previous,
  }) {
    final sanitizedPageSize = sanitizePageSize(pageSize);
    final sanitizedPage = sanitizePage(page);
    final sorts = <AppReportSortDescriptor>[
      descriptorFor(sortBy: sortBy, sortDirection: sortDirection),
    ];
    if (previous == null) {
      return AppReportQuery(
        sorts: sorts,
        page: sanitizedPage,
        pageSize: sanitizedPageSize,
      );
    }
    return previous.copyWith(
      sorts: sorts,
      page: sanitizedPage,
      pageSize: sanitizedPageSize,
    );
  }

  static AppReportPageInfo pageInfo({
    required int page,
    required int pageSize,
    required int totalCount,
  }) {
    final sanitizedPageSize = sanitizePageSize(pageSize);
    final totalPages = totalCount <= 0
        ? 0
        : (totalCount / sanitizedPageSize).ceil();
    return AppReportPageInfo(
      currentPage: sanitizePage(page),
      pageSize: sanitizedPageSize,
      totalRows: totalCount < 0 ? 0 : totalCount,
      totalPages: totalPages,
    );
  }

  static SalesMargemProdutoPersistedFilters restore(
    Map<String, Object?> raw,
  ) {
    final empresa = restoreInt(raw[persistCodEmpresaKey]);
    final filial = restoreInt(raw[persistCodFilialKey]);
    return SalesMargemProdutoPersistedFilters(
      sortBy: parseSortBy(raw[persistSortByKey] as String?),
      sortDirection: parseSortDirection(
        raw[persistSortDirectionKey] as String?,
      ),
      pageSize: sanitizePageSize(raw[persistPageSizeKey]),
      codEmpresa: empresa != null && empresa >= 1 ? empresa : null,
      codFilial: filial != null && filial >= 0 ? filial : null,
    );
  }

  static Map<String, Object?> persistMap({
    required MargemProdutoSortBy sortBy,
    required ResumoProdutoVendaSortDirection sortDirection,
    required int pageSize,
    int? codEmpresa,
    int? codFilial,
  }) {
    return <String, Object?>{
      persistSortByKey: sortBy.name,
      persistSortDirectionKey: sortDirection.name,
      persistPageSizeKey: sanitizePageSize(pageSize),
      persistCodEmpresaKey: codEmpresa,
      persistCodFilialKey: codFilial,
    };
  }

  static int? restoreInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.round();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }
}

class SalesMargemProdutoPersistedFilters {
  const SalesMargemProdutoPersistedFilters({
    required this.sortBy,
    required this.sortDirection,
    required this.pageSize,
    this.codEmpresa,
    this.codFilial,
  });

  final MargemProdutoSortBy sortBy;
  final ResumoProdutoVendaSortDirection sortDirection;
  final int pageSize;
  final int? codEmpresa;
  final int? codFilial;
}
