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

  static const String persistPageSizeKey = 'pageSize';
  static const String persistCodEmpresaKey = 'codEmpresa';
  static const String persistCodFilialKey = 'codFilial';

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

  static AppReportQuery queryFor({
    required int page,
    required int pageSize,
    AppReportQuery? previous,
  }) {
    final sanitizedPageSize = sanitizePageSize(pageSize);
    final sanitizedPage = sanitizePage(page);
    if (previous == null) {
      return AppReportQuery(
        page: sanitizedPage,
        pageSize: sanitizedPageSize,
      );
    }
    return previous.copyWith(
      sorts: const <AppReportSortDescriptor>[],
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
      pageSize: sanitizePageSize(raw[persistPageSizeKey]),
      codEmpresa: empresa != null && empresa >= 1 ? empresa : null,
      codFilial: filial != null && filial >= 0 ? filial : null,
    );
  }

  static Map<String, Object?> persistMap({
    required int pageSize,
    int? codEmpresa,
    int? codFilial,
  }) {
    return <String, Object?>{
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
    required this.pageSize,
    this.codEmpresa,
    this.codFilial,
  });

  final int pageSize;
  final int? codEmpresa;
  final int? codFilial;
}
