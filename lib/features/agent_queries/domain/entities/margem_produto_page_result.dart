import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';

/// Paged MargemProduto grid with total catalog row count for UI.
class MargemProdutoPageResult {
  const MargemProdutoPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<MargemProdutoRow> items;
  final int totalCount;
}
