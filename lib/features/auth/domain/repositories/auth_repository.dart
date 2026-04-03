import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class AuthRepository {
  Future<AppResult<ClientRegistrationSubmission>> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  });

  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  });

  Future<AppResult<UserProfile>> readCurrentUserProfile();

  Future<AppResult<UserProfile>> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? mobile,
    bool removeThumbnail = false,
  });

  Future<AppResult<UserProfile>> uploadThumbnail({
    required String filePath,
  });

  Future<AppResult<Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AppResult<String>> requestPasswordRecovery({
    required String email,
  });

  Future<AppResult<ClientPasswordRecoveryStatus>> readPasswordRecoveryStatus({
    required String token,
  });

  Future<AppResult<Unit>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<AppResult<AuthSession>> restoreSession();

  Future<AppResult<Unit>> logout();
}
