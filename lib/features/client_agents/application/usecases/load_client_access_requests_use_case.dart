import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/application/client_agents_paginated_loader.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadClientAccessRequestsUseCase {
  LoadClientAccessRequestsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>> call({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) {
    return loadAllClientAgentsPages<ClientAgentAccessRequest>(
      query: query,
      search: search,
      status: status,
      loadPage: (pageQuery) => _repository.loadAccessRequests(
        userId: userId,
        query: pageQuery,
        search: search,
        status: status,
      ),
    );
  }
}
