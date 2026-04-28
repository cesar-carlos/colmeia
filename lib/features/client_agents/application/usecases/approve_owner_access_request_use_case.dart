import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class ApproveOwnerAccessRequestUseCase {
  ApproveOwnerAccessRequestUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<Unit>> call({
    required String userId,
    required String requestId,
  }) {
    return _repository.approveOwnerAccessRequest(
      userId: userId,
      requestId: requestId,
    );
  }
}
