import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/network/auth_request_options.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/models/client_change_password_request_dto.dart';
import 'package:colmeia/features/auth/data/models/client_login_response_dto.dart';
import 'package:colmeia/features/auth/data/models/client_me_response_dto.dart';
import 'package:colmeia/features/auth/data/models/client_password_recovery_request_accepted_dto.dart';
import 'package:colmeia/features/auth/data/models/client_password_recovery_request_dto.dart';
import 'package:colmeia/features/auth/data/models/client_password_recovery_reset_request_dto.dart';
import 'package:colmeia/features/auth/data/models/client_password_recovery_status_response_dto.dart';
import 'package:colmeia/features/auth/data/models/client_patch_me_request_dto.dart';
import 'package:colmeia/features/auth/data/models/client_refresh_response_dto.dart';
import 'package:colmeia/features/auth/data/models/client_register_request_dto.dart';
import 'package:colmeia/features/auth/data/models/client_register_response_dto.dart';
import 'package:colmeia/features/auth/data/models/client_registration_status_response_dto.dart';
import 'package:colmeia/features/auth/data/models/login_request_dto.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:dio/dio.dart';

abstract interface class AuthRemoteDataSource {
  Future<ClientRegistrationSubmission> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  });

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<ClientRegistrationStatus> readRegistrationStatus({
    required String token,
  });

  Future<AuthSessionModel> refreshSession({
    required AuthSessionModel currentSession,
  });

  Future<void> logout({
    required String refreshToken,
  });

  Future<UserProfile> readCurrentUserProfile();

  Future<UserProfile> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? mobile,
    bool removeThumbnail = false,
  });

  Future<UserProfile> uploadThumbnail({
    required String filePath,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<String> requestPasswordRecovery({
    required String email,
  });

  Future<ClientPasswordRecoveryStatus> readPasswordRecoveryStatus({
    required String token,
  });

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Never attach `Authorization` on the shared authenticated [Dio] for these
  /// routes (defense in depth beside `ClientAuthApiRoutes.unauthenticated`).
  /// Stale JWT on `/client-auth/refresh` would otherwise confuse debugging
  /// (401 loops vs `credentialAuthRateLimit` on `/client-auth/login`).
  static final Options _publicClientAuthOptions = Options(
    extra: <String, Object?>{
      AuthRequestOptions.skipAuth: true,
    },
  );

  @override
  Future<ClientRegistrationSubmission> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) async {
    final request = ClientRegisterRequestDto(
      ownerEmail: ownerEmail,
      email: email,
      password: password,
      name: firstName,
      lastName: lastName,
      mobile: mobile,
    );

    final response = await _dio.post<Map<String, dynamic>>(
      ClientAuthApiRoutes.register,
      data: request.toJson(),
      options: _publicClientAuthOptions,
    );

    return ClientRegisterResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestDto(email: email, password: password);
    final response = await _dio.post<Map<String, dynamic>>(
      ClientAuthApiRoutes.login,
      data: request.toJson(),
      options: _publicClientAuthOptions,
    );

    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Login response body is null');
    }

    return ClientLoginResponseDto.fromJson(responseBody).toSessionModel();
  }

  @override
  Future<ClientRegistrationStatus> readRegistrationStatus({
    required String token,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAuthApiRoutes.registrationStatus,
      queryParameters: <String, Object?>{
        'token': token,
      },
      options: _publicClientAuthOptions,
    );

    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Registration status response body is null');
    }

    return ClientRegistrationStatusResponseDto.fromJson(responseBody).status;
  }

  @override
  Future<AuthSessionModel> refreshSession({
    required AuthSessionModel currentSession,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ClientAuthApiRoutes.refresh,
      data: <String, Object?>{
        'refreshToken': currentSession.refreshToken,
      },
      options: _publicClientAuthOptions,
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Refresh response body is null');
    }

    final refreshed = ClientRefreshResponseDto.fromJson(responseBody);
    return refreshed.tokens.toSessionModel(
      userId: currentSession.userId,
      email: currentSession.email,
      role: currentSession.role,
      accountStatus: currentSession.accountStatus,
    );
  }

  @override
  Future<void> logout({
    required String refreshToken,
  }) async {
    await _dio.post<void>(
      ClientAuthApiRoutes.logout,
      data: <String, Object?>{
        'refreshToken': refreshToken,
      },
      options: _publicClientAuthOptions,
    );
  }

  @override
  Future<UserProfile> readCurrentUserProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAuthApiRoutes.me,
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Current client profile response is null');
    }

    return ClientMeResponseDto.fromJson(responseBody).user.toUserProfile();
  }

  @override
  Future<UserProfile> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? mobile,
    bool removeThumbnail = false,
  }) async {
    final request = ClientPatchMeRequestDto(
      firstName: firstName,
      lastName: lastName,
      mobile: mobile,
      removeThumbnail: removeThumbnail,
    );
    final response = await _dio.patch<Map<String, dynamic>>(
      ClientAuthApiRoutes.me,
      data: request.toJson(),
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Updated client profile response is null');
    }

    return ClientMeResponseDto.fromJson(responseBody).user.toUserProfile();
  }

  @override
  Future<UserProfile> uploadThumbnail({
    required String filePath,
  }) async {
    final formData = FormData.fromMap(<String, Object?>{
      'thumbnail': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ClientAuthApiRoutes.thumbnail,
      data: formData,
      options: Options(
        extra: <String, Object?>{
          AuthRequestOptions.disableAuthRetry: true,
        },
      ),
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Upload thumbnail response is null');
    }

    return ClientMeResponseDto.fromJson(responseBody).user.toUserProfile();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _dio.patch<void>(
      ClientAuthApiRoutes.password,
      data: ClientChangePasswordRequestDto(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ).toJson(),
    );
  }

  @override
  Future<String> requestPasswordRecovery({
    required String email,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ClientAuthApiRoutes.passwordRecoveryRequest,
      data: ClientPasswordRecoveryRequestDto(email: email).toJson(),
      options: _publicClientAuthOptions,
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Password recovery request response is null');
    }

    return ClientPasswordRecoveryRequestAcceptedDto.fromJson(
      responseBody,
    ).message;
  }

  @override
  Future<ClientPasswordRecoveryStatus> readPasswordRecoveryStatus({
    required String token,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAuthApiRoutes.passwordRecoveryStatus,
      queryParameters: <String, Object?>{
        'token': token,
      },
      options: _publicClientAuthOptions,
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Password recovery status response is null');
    }

    return ClientPasswordRecoveryStatusResponseDto.fromJson(
      responseBody,
    ).status;
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _dio.post<void>(
      ClientAuthApiRoutes.passwordRecoveryReset,
      data: ClientPasswordRecoveryResetRequestDto(
        token: token,
        newPassword: newPassword,
      ).toJson(),
      options: _publicClientAuthOptions,
    );
  }
}
