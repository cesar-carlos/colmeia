import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';

/// Direction of [MargemProdutoSortBy] in `ROW_NUMBER() OVER`.
/// Tie-breakers stay ascending.
enum MargemProdutoSortDirection {
  ascending,
  descending,
}
