import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_direction.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter/foundation.dart';

/// Maps AppReportViewer pagination and sort onto the MargemProduto catalog.
///
/// Column keys identify grid columns. Ordering is applied in SQL
/// (`ROW_NUMBER`) from a whitelist — never from raw user identifiers.
abstract final class SalesMargemProdutoSort {
  static const String cardId = 'margem_produto';

  static const String columnCodigo = 'codProduto';
  static const String columnProduto = 'nomeProduto';
  static const String columnGrupo = 'nomeGrupoProduto';
  static const String columnMarca = 'nomeMarca';
  static const String columnCustoReposicao = 'custoReposicao';
  static const String columnPrecoVenda = 'precoVendaProduto';
  static const String columnMarkup = 'percentualMarkup';
  static const String columnMargem = 'margemLucro';

  static const List<int> allowedPageSizes = <int>[10, 20, 50];
  static const int defaultPageSize = 20;
  // Agent SQL is too expensive to run per keystroke.
  static const Duration searchDebounce = Duration(milliseconds: 400);

  static const String persistPageSizeKey = 'pageSize';
  static const String persistSearchTermKey = 'searchTerm';
  static const String persistSortByKey = 'sortBy';
  static const String persistSortDirectionKey = 'sortDirection';

  static const List<AppReportSortDescriptor> defaultSorts =
      <AppReportSortDescriptor>[
        AppReportSortDescriptor(
          columnKey: columnProduto,
          direction: AppReportSortDirection.ascending,
        ),
      ];

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

  static String? normalizeSearchTerm(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String columnKeyFor(MargemProdutoSortBy sortBy) {
    return switch (sortBy) {
      MargemProdutoSortBy.codProduto => columnCodigo,
      MargemProdutoSortBy.nomeProduto => columnProduto,
      MargemProdutoSortBy.nomeGrupoProduto => columnGrupo,
      MargemProdutoSortBy.nomeMarca => columnMarca,
      MargemProdutoSortBy.custoReposicao => columnCustoReposicao,
      MargemProdutoSortBy.precoVendaProduto => columnPrecoVenda,
      MargemProdutoSortBy.percentualMarkup => columnMarkup,
      MargemProdutoSortBy.margemLucro => columnMargem,
    };
  }

  static MargemProdutoSortBy sortByFromColumnKey(String key) {
    return switch (key) {
      columnCodigo => MargemProdutoSortBy.codProduto,
      columnProduto => MargemProdutoSortBy.nomeProduto,
      columnGrupo => MargemProdutoSortBy.nomeGrupoProduto,
      columnMarca => MargemProdutoSortBy.nomeMarca,
      columnCustoReposicao => MargemProdutoSortBy.custoReposicao,
      columnPrecoVenda => MargemProdutoSortBy.precoVendaProduto,
      columnMarkup => MargemProdutoSortBy.percentualMarkup,
      columnMargem => MargemProdutoSortBy.margemLucro,
      _ => MargemProdutoSortBy.nomeProduto,
    };
  }

  static MargemProdutoSortDirection domainDirectionFrom(
    AppReportSortDirection direction,
  ) {
    return switch (direction) {
      AppReportSortDirection.ascending => MargemProdutoSortDirection.ascending,
      AppReportSortDirection.descending =>
        MargemProdutoSortDirection.descending,
    };
  }

  static AppReportSortDirection reportDirectionFrom(
    MargemProdutoSortDirection direction,
  ) {
    return switch (direction) {
      MargemProdutoSortDirection.ascending => AppReportSortDirection.ascending,
      MargemProdutoSortDirection.descending =>
        AppReportSortDirection.descending,
    };
  }

  static List<AppReportSortDescriptor> descriptorsFor({
    required MargemProdutoSortBy sortBy,
    required MargemProdutoSortDirection sortDirection,
  }) {
    return <AppReportSortDescriptor>[
      AppReportSortDescriptor(
        columnKey: columnKeyFor(sortBy),
        direction: reportDirectionFrom(sortDirection),
      ),
    ];
  }

  static List<AppReportSortDescriptor> sanitizeSorts(
    List<AppReportSortDescriptor> sorts,
  ) {
    if (sorts.isEmpty) {
      return defaultSorts;
    }
    final first = sorts.first;
    return descriptorsFor(
      sortBy: sortByFromColumnKey(first.columnKey),
      sortDirection: domainDirectionFrom(first.direction),
    );
  }

  static MargemProdutoSortBy sortByFromQuery(AppReportQuery query) {
    final sorts = sanitizeSorts(query.sorts);
    return sortByFromColumnKey(sorts.first.columnKey);
  }

  static MargemProdutoSortDirection sortDirectionFromQuery(
    AppReportQuery query,
  ) {
    final sorts = sanitizeSorts(query.sorts);
    return domainDirectionFrom(sorts.first.direction);
  }

  static bool sortsEqual(
    List<AppReportSortDescriptor> left,
    List<AppReportSortDescriptor> right,
  ) {
    return listEquals(sanitizeSorts(left), sanitizeSorts(right));
  }

  static AppReportQuery queryFor({
    required int page,
    required int pageSize,
    String? searchTerm,
    bool clearSearchTerm = false,
    List<AppReportSortDescriptor>? sorts,
    AppReportQuery? previous,
  }) {
    final sanitizedPageSize = sanitizePageSize(pageSize);
    final sanitizedPage = sanitizePage(page);
    final normalizedSearch = clearSearchTerm
        ? null
        : normalizeSearchTerm(searchTerm);
    if (previous == null) {
      return AppReportQuery(
        page: sanitizedPage,
        pageSize: sanitizedPageSize,
        searchTerm: normalizedSearch,
        sorts: sanitizeSorts(sorts ?? defaultSorts),
      );
    }
    return previous.copyWith(
      sorts: sorts == null ? null : sanitizeSorts(sorts),
      page: sanitizedPage,
      pageSize: sanitizedPageSize,
      searchTerm: normalizedSearch,
      clearSearchTerm: clearSearchTerm,
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

  static MargemProdutoSortBy restoreSortBy(Object? raw) {
    if (raw is MargemProdutoSortBy) {
      return raw;
    }
    if (raw is String) {
      for (final value in MargemProdutoSortBy.values) {
        if (value.name == raw.trim()) {
          return value;
        }
      }
    }
    return MargemProdutoSortBy.nomeProduto;
  }

  static MargemProdutoSortDirection restoreSortDirection(Object? raw) {
    if (raw is MargemProdutoSortDirection) {
      return raw;
    }
    if (raw is String) {
      for (final value in MargemProdutoSortDirection.values) {
        if (value.name == raw.trim()) {
          return value;
        }
      }
    }
    return MargemProdutoSortDirection.ascending;
  }

  static SalesMargemProdutoPersistedFilters restore(
    Map<String, Object?> raw,
  ) {
    return SalesMargemProdutoPersistedFilters(
      pageSize: sanitizePageSize(raw[persistPageSizeKey]),
      searchTerm: normalizeSearchTerm(raw[persistSearchTermKey]),
      sortBy: restoreSortBy(raw[persistSortByKey]),
      sortDirection: restoreSortDirection(raw[persistSortDirectionKey]),
    );
  }

  static Map<String, Object?> persistMap({
    required int pageSize,
    required MargemProdutoSortBy sortBy,
    required MargemProdutoSortDirection sortDirection,
    String? searchTerm,
  }) {
    return <String, Object?>{
      persistPageSizeKey: sanitizePageSize(pageSize),
      persistSearchTermKey: normalizeSearchTerm(searchTerm),
      persistSortByKey: sortBy.name,
      persistSortDirectionKey: sortDirection.name,
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
    required this.pageSize,
    this.searchTerm,
    this.sortBy = MargemProdutoSortBy.nomeProduto,
    this.sortDirection = MargemProdutoSortDirection.ascending,
  });

  final int pageSize;
  final String? searchTerm;
  final MargemProdutoSortBy sortBy;
  final MargemProdutoSortDirection sortDirection;
}
