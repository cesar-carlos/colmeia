import 'package:colmeia/features/agent_queries/domain/entities/fornecedor_option.dart';

/// Paged fornecedor list with total row count for UI pagination.
class FornecedorOptionsPageResult {
  const FornecedorOptionsPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<FornecedorOption> items;
  final int totalCount;
}
