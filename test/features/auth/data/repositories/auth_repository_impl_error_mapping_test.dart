import 'package:checks/checks.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockAppCacheStore extends Mock implements AppCacheStore {}

void main() {
  late _MockAuthLocalDataSource local;
  late _MockAuthRemoteDataSource remote;
  late _MockAppCacheStore cache;
  late AuthRepositoryImpl repository;

  setUp(() {
    local = _MockAuthLocalDataSource();
    remote = _MockAuthRemoteDataSource();
    cache = _MockAppCacheStore();
    repository = AuthRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      appCacheStore: cache,
    );
  });

  group('AuthRepositoryImpl error mapping', () {
    test(
      'should expose clearer pending approval message on login 403',
      () async {
        when(
          () => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/client-auth/login'),
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/client-auth/login'),
              statusCode: 403,
              data: <String, dynamic>{
                'message': 'Sua conta ainda esta pendente de aprovacao.',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.login(
          email: 'client@corp.com',
          password: '12345678',
        );

        check(result.isError()).isTrue();
        check(result.exceptionOrNull()).isA<AuthorizationFailure>();
        check(result.exceptionOrNull()?.displayMessage).equals(
          'Sua conta ainda esta pendente de aprovacao.',
        );
      },
    );

    test(
      'should map missing registration token to validation failure',
      () async {
        when(
          () => remote.readRegistrationStatus(token: any(named: 'token')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/client-auth/registration/status',
            ),
            response: Response<void>(
              requestOptions: RequestOptions(
                path: '/client-auth/registration/status',
              ),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.readRegistrationStatus(
          token: 'bad-token',
        );

        check(result.isError()).isTrue();
        check(result.exceptionOrNull()).isA<ValidationFailure>();
        check(result.exceptionOrNull()?.displayMessage).equals(
          'O token de cadastro informado e invalido.',
        );
      },
    );

    test(
      'should map expired password recovery token to expired status',
      () async {
        when(
          () => remote.readPasswordRecoveryStatus(token: any(named: 'token')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/client-auth/password-recovery/status',
            ),
            response: Response<void>(
              requestOptions: RequestOptions(
                path: '/client-auth/password-recovery/status',
              ),
              statusCode: 410,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.readPasswordRecoveryStatus(
          token: 'expired-token',
        );

        check(result.isSuccess()).isTrue();
        check(result.getOrNull()).equals(ClientPasswordRecoveryStatus.expired);
      },
    );

    test(
      'should keep invalid password recovery token as invalid status',
      () async {
        when(
          () => remote.readPasswordRecoveryStatus(token: any(named: 'token')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/client-auth/password-recovery/status',
            ),
            response: Response<void>(
              requestOptions: RequestOptions(
                path: '/client-auth/password-recovery/status',
              ),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.readPasswordRecoveryStatus(
          token: 'invalid-token',
        );

        check(result.isSuccess()).isTrue();
        check(result.getOrNull()).equals(ClientPasswordRecoveryStatus.invalid);
      },
    );

    test(
      'should map expired registration token to validation failure',
      () async {
        when(
          () => remote.readRegistrationStatus(token: any(named: 'token')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/client-auth/registration/status',
            ),
            response: Response<void>(
              requestOptions: RequestOptions(
                path: '/client-auth/registration/status',
              ),
              statusCode: 410,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.readRegistrationStatus(
          token: 'expired-token',
        );

        check(result.isError()).isTrue();
        check(result.exceptionOrNull()).isA<ValidationFailure>();
        check(result.exceptionOrNull()?.displayMessage).equals(
          'O token de cadastro expirou. Solicite um novo cadastro.',
        );
      },
    );
  });
}
