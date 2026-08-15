import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';

/// Maps AppReportViewer pagination onto the MargemProduto catalog query.
///
/// Column keys identify grid columns only. Ordering is fixed in SQL
/// (`NomeProduto ASC`, `CodProduto ASC`) and is not user-controlled.
abstract final class SalesMargemProdutoSort {
  static const String cardId = 'margem_produto';

  static const String columnProduto = 'nomeProduto';
  static const String columnCustoReposicao = 'custoReposicao';
  static const String columnPrecoVenda = 'precoVendaProduto';
  static const String columnMarkup = 'percentualMarkup';
  static const String columnMargem = 'margemLucroProduto';

  static const List<int> allowedPageSizes = <int>[10, 20, 50];
  static const int defaultPageSize = 20;
  // Agent SQL is too expensive to run per keystroke.
  static const Duration searchDebounce = Duration(milliseconds: 400);

  static const String persistPageSizeKey = 'pageSize';
  static const String persistSearchTermKey = 'searchTerm';

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

  static AppReportQuery queryFor({
    required int page,
    required int pageSize,
    String? searchTerm,
    bool clearSearchTerm = false,
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
      );
    }
    return previous.copyWith(
      sorts: const <AppReportSortDescriptor>[],
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

  static SalesMargemProdutoPersistedFilters restore(
    Map<String, Object?> raw,
  ) {
    return SalesMargemProdutoPersistedFilters(
      pageSize: sanitizePageSize(raw[persistPageSizeKey]),
      searchTerm: normalizeSearchTerm(raw[persistSearchTermKey]),
    );
  }

  static Map<String, Object?> persistMap({
    required int pageSize,
    String? searchTerm,
  }) {
    return <String, Object?>{
      persistPageSizeKey: sanitizePageSize(pageSize),
      persistSearchTermKey: normalizeSearchTerm(searchTerm),
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
  });

  final int pageSize;
  final String? searchTerm;
}
