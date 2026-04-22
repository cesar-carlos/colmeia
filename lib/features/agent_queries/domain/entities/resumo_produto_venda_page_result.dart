import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';

/// Paged ResumoProdutoVenda grid with total grouped row count for UI.
class ResumoProdutoVendaPageResult {
  const ResumoProdutoVendaPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<ResumoProdutoVendaRow> items;
  final int totalCount;
}
