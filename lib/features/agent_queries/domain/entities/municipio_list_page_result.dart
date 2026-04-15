import 'package:colmeia/features/agent_queries/domain/entities/municipio_row.dart';

/// Paged municipio list with total row count for UI pagination.
class MunicipioListPageResult {
  const MunicipioListPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<MunicipioRow> items;
  final int totalCount;
}
