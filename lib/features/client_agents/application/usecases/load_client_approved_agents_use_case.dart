import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/application/client_agents_paginated_loader.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadClientApprovedAgentsUseCase {
  LoadClientApprovedAgentsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<PaginatedResult<ClientAgent>>> call({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
    bool includeOnlineStatus = true,
    bool refresh = false,
  }) {
    return loadAllClientAgentsPages<ClientAgent>(
      query: query,
      search: search,
      status: status,
      loadPage: (pageQuery) => _repository.loadApprovedAgents(
        userId: userId,
        query: pageQuery,
        search: search,
        status: status,
        includeOnlineStatus: includeOnlineStatus,
        refresh: refresh && pageQuery.page == query.page,
      ),
    );
  }
}
