import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';

/// Catalog browsing and profile patch — global agent directory surface.
abstract interface class ClientAgentsCatalogRemoteDataSource {
  Future<PaginatedAgentCatalogResponseDto> fetchCatalog({
    required PaginatedQuery query,
    String? search,
  });

  Future<AgentCatalogRecordDto> fetchCatalogAgentById(String agentId);

  Future<AgentCatalogRecordDto> patchAgentProfile({
    required String agentId,
    required Map<String, Object?> body,
    String? idempotencyKey,
  });
}
