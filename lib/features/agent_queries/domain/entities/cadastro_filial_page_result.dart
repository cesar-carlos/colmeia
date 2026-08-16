import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';

/// Paged branch registration result with total row count for UI pagination.
class CadastroFilialPageResult {
  const CadastroFilialPageResult({
    required this.items,
    required this.totalCount,
    this.fetchedPageSize,
  });

  final List<CadastroFilialRow> items;
  final int totalCount;

  /// Actual page size used for this fetch. Set when the repository shrinks
  /// a `SELECT TOP` fallback below the requested filter page size.
  final int? fetchedPageSize;
}
