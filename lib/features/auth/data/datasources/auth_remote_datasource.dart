import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/models/login_request_dto.dart';
import 'package:colmeia/features/auth/data/models/login_response_dto.dart';
import 'package:colmeia/features/auth/data/models/register_request_dto.dart';
import 'package:dio/dio.dart';

abstract interface class AuthRemoteDataSource {
  Future<void> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  });

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<AuthSessionModel> refreshSession({
    required String refreshToken,
  });

  Future<void> logout({
    required String accessToken,
  });
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  }) async {
    final request = RegisterRequestDto(
      fullName: fullName,
      email: email,
      storeName: storeName,
      password: password,
    );

    await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: request.toJson(),
    );
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestDto(email: email, password: password);
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );

    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Login response body is null');
    }

    final payload = _extractLoginPayload(responseBody);
    final loginResponse = LoginResponseDto.fromJson(payload);
    return loginResponse.toModel();
  }

  @override
  Future<AuthSessionModel> refreshSession({
    required String refreshToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, Object?>{
        'refreshToken': refreshToken,
      },
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Refresh response body is null');
    }

    final payload = _extractLoginPayload(responseBody);
    final loginResponse = LoginResponseDto.fromJson(payload);
    return loginResponse.toModel();
  }

  @override
  Future<void> logout({
    required String accessToken,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/logout',
      data: <String, Object?>{
        'accessToken': accessToken,
      },
    );
  }

  Map<String, dynamic> _extractLoginPayload(Map<String, dynamic> responseBody) {
    if (responseBody['data'] case final Map<String, dynamic> nestedData) {
      return nestedData;
    }
    if (responseBody['session'] case final Map<String, dynamic> sessionData) {
      return sessionData;
    }
    return responseBody;
  }
}
