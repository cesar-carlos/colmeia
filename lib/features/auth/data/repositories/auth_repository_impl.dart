import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AppResult<Unit>> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  }) async {
    try {
      await _remoteDataSource.register(
        fullName: fullName,
        email: email,
        storeName: storeName,
        password: password,
      );

      AppLogger.info(
        'User registration request submitted',
        context: <String, Object?>{
          'operation': 'register',
          'email': email,
          'storeName': storeName,
        },
      );
      return const Success<Unit, AppFailure>(unit);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = statusCode == 409
          ? ValidationFailure(
              message: 'User already exists',
              userMessage: 'Este e-mail ja possui solicitacao de acesso.',
              cause: error,
              stackTrace: stackTrace,
              context: <String, Object?>{
                'operation': 'register',
                'email': email,
                'statusCode': statusCode,
              },
            )
          : mapToAppFailure(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Unable to submit register request',
              fallbackUserMessage:
                  'Nao foi possivel enviar sua solicitacao de acesso.',
              context: <String, Object?>{
                'operation': 'register',
                'email': email,
                'statusCode': statusCode,
              },
            );
      AppLogger.warning(
        'User registration request failed',
        context: <String, Object?>{
          'operation': 'register',
          'email': email,
          'statusCode': statusCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<Unit, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected user registration failure',
        context: <String, Object?>{
          'operation': 'register',
          'email': email,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to submit register request',
          fallbackUserMessage:
              'Nao foi possivel enviar sua solicitacao de acesso.',
          context: <String, Object?>{
            'operation': 'register',
            'email': email,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authSessionModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _localDataSource.saveSession(authSessionModel);
      AppLogger.info(
        'User authenticated successfully',
        context: <String, Object?>{
          'operation': 'login',
          'email': email,
          'userId': authSessionModel.userId,
        },
      );

      return Success<AuthSession, AppFailure>(authSessionModel.toEntity());
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'User authentication failed',
        context: <String, Object?>{
          'operation': 'login',
          'email': email,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AuthSession, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to sign in user',
          fallbackUserMessage:
              'Nao foi possivel entrar com as credenciais informadas.',
          context: <String, Object?>{
            'operation': 'login',
            'email': email,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> logout() async {
    try {
      final storedSession = await _localDataSource.readSession();
      if (storedSession != null) {
        await _remoteDataSource.logout(
          accessToken: storedSession.accessToken,
        );
      }
      await _localDataSource.clearSession();
      AppLogger.info(
        'User session cleared',
        context: const <String, Object?>{
          'operation': 'logout',
        },
      );

      return const Success<Unit, AppFailure>(unit);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unable to clear local session',
        context: const <String, Object?>{
          'operation': 'logout',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to clear local session',
          fallbackUserMessage: 'Nao foi possivel encerrar a sessao.',
          context: const <String, Object?>{
            'operation': 'logout',
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    try {
      final authSessionModel = await _localDataSource.readSession();

      if (authSessionModel == null) {
        AppLogger.debug(
          'No stored session found',
          context: const <String, Object?>{
            'operation': 'restoreSession',
          },
        );
        return const Failure<AuthSession, AppFailure>(
          SessionFailure(
            message: 'No active session found',
            userMessage: 'Sessao indisponivel.',
          ),
        );
      }

      final session = authSessionModel.toEntity();

      if (session.isExpired) {
        try {
          final refreshedSession = await _remoteDataSource.refreshSession(
            refreshToken: session.refreshToken,
          );
          await _localDataSource.saveSession(refreshedSession);
          AppLogger.info(
            'Stored session refreshed successfully',
            context: <String, Object?>{
              'operation': 'restoreSession',
              'userId': refreshedSession.userId,
            },
          );
          return Success<AuthSession, AppFailure>(refreshedSession.toEntity());
        } on Object catch (error, stackTrace) {
          await _localDataSource.clearSession();
          AppLogger.warning(
            'Stored session expired and refresh failed',
            context: <String, Object?>{
              'operation': 'restoreSession',
              'userId': session.userId,
            },
            error: error,
            stackTrace: stackTrace,
          );
          return const Failure<AuthSession, AppFailure>(
            SessionFailure(
              message: 'Stored session has expired',
              userMessage: 'Sua sessao expirou. Entre novamente.',
            ),
          );
        }
      }

      AppLogger.info(
        'Stored session restored successfully',
        context: <String, Object?>{
          'operation': 'restoreSession',
          'userId': session.userId,
        },
      );
      return Success<AuthSession, AppFailure>(session);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unable to restore local session',
        context: const <String, Object?>{
          'operation': 'restoreSession',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AuthSession, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to restore local session',
          fallbackUserMessage:
              'Nao foi possivel restaurar sua sessao neste dispositivo.',
          context: const <String, Object?>{
            'operation': 'restoreSession',
          },
        ),
      );
    }
  }
}
