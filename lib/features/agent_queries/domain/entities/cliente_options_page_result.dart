import 'package:colmeia/features/agent_queries/domain/entities/cliente_option.dart';

/// Paged cliente list with total row count for UI pagination.
class ClienteOptionsPageResult {
  const ClienteOptionsPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<ClienteOption> items;
  final int totalCount;
}
