import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadOwnerAccessRequestsUseCase {
  LoadOwnerAccessRequestsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<List<OwnerClientAccessRequest>>> call({
    required String userId,
  }) {
    return _repository.loadOwnerAccessRequests(userId: userId);
  }
}
