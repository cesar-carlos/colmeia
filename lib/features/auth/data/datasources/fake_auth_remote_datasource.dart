import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:dio/dio.dart';

final class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._fakeBackendStore);

  final FakeIdentityBackendStore _fakeBackendStore;

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      await _fakeBackendStore.register(
        fullName: fullName,
        email: email,
        storeName: storeName,
        password: password,
      );
    } on FakeBackendConflictException catch (error) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
        ),
        message: error.message,
      );
    }
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    try {
      final user = await _fakeBackendStore.validateCredentials(
        email: email,
        password: password,
      );

      return AuthSessionModel(
        userId: user.id,
        email: user.email,
        accessToken: 'fake-access-token-${user.id}',
        refreshToken: 'fake-refresh-token-${user.id}',
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );
    } on FakeBackendUnauthorizedException catch (error) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
        message: error.message,
      );
    }
  }

  @override
  Future<AuthSessionModel> refreshSession({
    required String refreshToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final userId = refreshToken.replaceFirst('fake-refresh-token-', '');
    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 401,
        ),
        message: 'Invalid refresh token',
      );
    }

    final refreshedAccessToken =
        'fake-access-token-${user.id}'
        '-${DateTime.now().millisecondsSinceEpoch}';

    return AuthSessionModel(
      userId: user.id,
      email: user.email,
      accessToken: refreshedAccessToken,
      refreshToken: 'fake-refresh-token-${user.id}',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<void> logout({
    required String accessToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}
