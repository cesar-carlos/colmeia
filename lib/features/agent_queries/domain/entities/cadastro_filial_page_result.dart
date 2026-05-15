import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';

/// Paged branch registration result with total row count for UI pagination.
class CadastroFilialPageResult {
  const CadastroFilialPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<CadastroFilialRow> items;
  final int totalCount;
}
