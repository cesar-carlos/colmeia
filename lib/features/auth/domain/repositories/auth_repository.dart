import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class AuthRepository {
  Future<AppResult<Unit>> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  });

  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<AppResult<AuthSession>> restoreSession();

  Future<AppResult<Unit>> logout();
}
