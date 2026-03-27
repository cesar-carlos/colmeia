import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:result_dart/result_dart.dart';

class RegisterUseCase {
  RegisterUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<Unit>> call({
    required String fullName,
    required String email,
    required String password,
    required String employeeId,
    required String accessProfileLabel,
    required List<String> requestedStoreIds,
  }) {
    return _authRepository.register(
      fullName: fullName,
      email: email,
      password: password,
      employeeId: employeeId,
      accessProfileLabel: accessProfileLabel,
      requestedStoreIds: requestedStoreIds,
    );
  }
}
