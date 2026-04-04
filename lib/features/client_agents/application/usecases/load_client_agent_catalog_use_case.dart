import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadClientAgentCatalogUseCase {
  LoadClientAgentCatalogUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<PaginatedResult<ClientAgentCatalogItem>>> call({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) {
    return _repository.loadCatalog(
      userId: userId,
      query: query,
      search: search,
    );
  }
}
