import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadClientAccessStatusUseCase {
  LoadClientAccessStatusUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<ClientAccessStatusSnapshot>> call({required String token}) {
    return _repository.loadClientAccessStatus(token: token);
  }
}
