import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/logging/log_redaction.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._localDataSource,
    required this._remoteDataSource,
    required this._appCacheStore,
    this._sessionEvents,
  });

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final AppCacheStore _appCacheStore;

  /// Optional sink used to broadcast invalidation when a stored session
  /// fails to refresh on boot. Same channel the dio refresh
  /// coordinator uses on 401/403, kept optional so existing tests
  /// that wire the repository directly do not need to materialise
  /// the events stream.
  final AuthSessionEvents? _sessionEvents;

  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final redactedEmail = LogRedaction.redactEmail(email);
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
          'email': redactedEmail,
          'userId': authSessionModel.userId,
        },
      );

      return Success<AuthSession, AppFailure>(authSessionModel.toEntity());
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to sign in client',
        fallbackUserMessage: switch (statusCode) {
          401 => 'Nao foi possivel entrar com as credenciais informadas.',
          403 =>
            'Sua conta ainda nao foi aprovada ou nao pode acessar no momento.',
          423 =>
            'Sua conta esta bloqueada. Fale com o responsavel pela aprovacao.',
          429 =>
            'Voce excedeu o limite de tentativas. Aguarde para tentar '
                'novamente.',
          _ => 'Nao foi possivel autenticar sua conta agora.',
        },
        context: <String, Object?>{
          'operation': 'login',
          'email': redactedEmail,
          'statusCode': statusCode,
        },
      );
      AppLogger.warning(
        'Client authentication failed',
        context: <String, Object?>{
          'operation': 'login',
          'email': redactedEmail,
          'statusCode': statusCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AuthSession, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected client authentication failure',
        context: <String, Object?>{
          'operation': 'login',
          'email': redactedEmail,
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
            'email': redactedEmail,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<UserProfile>> readCurrentUserProfile() async {
    try {
      await _readRequiredStoredSession();
      final profile = await _remoteDataSource.readCurrentUserProfile();
      return Success<UserProfile, AppFailure>(profile);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure reading current user profile',
        context: const <String, Object?>{
          'operation': 'readCurrentUserProfile',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<UserProfile, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load current client profile',
          fallbackUserMessage: 'Nao foi possivel carregar os dados da conta.',
          context: const <String, Object?>{
            'operation': 'readCurrentUserProfile',
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<UserProfile>> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? mobile,
    bool removeThumbnail = false,
  }) async {
    try {
      await _readRequiredStoredSession();
      final profile = await _remoteDataSource.updateCurrentUserProfile(
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        removeThumbnail: removeThumbnail,
      );
      return Success<UserProfile, AppFailure>(profile);
    } on DioException catch (error, stackTrace) {
      return Failure<UserProfile, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to update current client profile',
          fallbackUserMessage:
              'Nao foi possivel atualizar os dados da sua conta.',
          context: const <String, Object?>{
            'operation': 'updateCurrentUserProfile',
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure updating current user profile',
        context: const <String, Object?>{
          'operation': 'updateCurrentUserProfile',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<UserProfile, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to update current client profile',
          fallbackUserMessage:
              'Nao foi possivel atualizar os dados da sua conta.',
          context: const <String, Object?>{
            'operation': 'updateCurrentUserProfile',
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<UserProfile>> uploadThumbnail({
    required String filePath,
  }) async {
    try {
      await _readRequiredStoredSession();
      final profile = await _remoteDataSource.uploadThumbnail(
        filePath: filePath,
      );
      return Success<UserProfile, AppFailure>(profile);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to upload thumbnail',
        fallbackUserMessage: statusCode == 429
            ? 'Voce excedeu o limite de envios de imagem por agora.'
            : 'Nao foi possivel enviar a foto da conta.',
        context: <String, Object?>{
          'operation': 'uploadThumbnail',
          'statusCode': statusCode,
        },
      );
      return Failure<UserProfile, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure uploading thumbnail',
        context: const <String, Object?>{
          'operation': 'uploadThumbnail',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<UserProfile, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to upload thumbnail',
          fallbackUserMessage: 'Nao foi possivel enviar a foto da conta.',
          context: const <String, Object?>{
            'operation': 'uploadThumbnail',
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _readRequiredStoredSession();
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Success<Unit, AppFailure>(unit);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to change client password',
        fallbackUserMessage: statusCode == 401
            ? 'A senha atual informada nao confere.'
            : 'Nao foi possivel alterar sua senha agora.',
        context: <String, Object?>{
          'operation': 'changePassword',
          'statusCode': statusCode,
        },
      );
      return Failure<Unit, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure changing password',
        context: const <String, Object?>{
          'operation': 'changePassword',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to change client password',
          fallbackUserMessage: 'Nao foi possivel alterar sua senha agora.',
          context: const <String, Object?>{
            'operation': 'changePassword',
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<String>> requestPasswordRecovery({
    required String email,
  }) async {
    final redactedEmail = LogRedaction.redactEmail(email);
    try {
      final message = await _remoteDataSource.requestPasswordRecovery(
        email: email,
      );
      return Success<String, AppFailure>(message);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to request password recovery',
        fallbackUserMessage: statusCode == 429
            ? 'Voce excedeu o limite de tentativas. Aguarde para tentar '
                  'novamente.'
            : 'Nao foi possivel iniciar a recuperacao de acesso.',
        context: <String, Object?>{
          'operation': 'requestPasswordRecovery',
          'email': redactedEmail,
          'statusCode': statusCode,
        },
      );
      return Failure<String, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure requesting password recovery',
        context: <String, Object?>{
          'operation': 'requestPasswordRecovery',
          'email': redactedEmail,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<String, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to request password recovery',
          fallbackUserMessage:
              'Nao foi possivel iniciar a recuperacao de acesso.',
          context: <String, Object?>{
            'operation': 'requestPasswordRecovery',
            'email': redactedEmail,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<ClientPasswordRecoveryStatus>> readPasswordRecoveryStatus({
    required String token,
  }) async {
    try {
      final status = await _remoteDataSource.readPasswordRecoveryStatus(
        token: token,
      );
      return Success<ClientPasswordRecoveryStatus, AppFailure>(status);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return const Success<ClientPasswordRecoveryStatus, AppFailure>(
          ClientPasswordRecoveryStatus.invalid,
        );
      }
      if (statusCode == 410) {
        return const Success<ClientPasswordRecoveryStatus, AppFailure>(
          ClientPasswordRecoveryStatus.expired,
        );
      }
      return Failure<ClientPasswordRecoveryStatus, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read password recovery status',
          fallbackUserMessage:
              'Nao foi possivel consultar o status da recuperacao.',
          context: <String, Object?>{
            'operation': 'readPasswordRecoveryStatus',
            'statusCode': statusCode,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure reading password recovery status',
        context: const <String, Object?>{
          'operation': 'readPasswordRecoveryStatus',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<ClientPasswordRecoveryStatus, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read password recovery status',
          fallbackUserMessage:
              'Nao foi possivel consultar o status da recuperacao.',
          context: const <String, Object?>{
            'operation': 'readPasswordRecoveryStatus',
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return const Success<Unit, AppFailure>(unit);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = statusCode == 404
          ? ValidationFailure(
              message: 'Password recovery token not found',
              userMessage: 'O token de recuperacao informado e invalido.',
              cause: error,
              stackTrace: stackTrace,
              context: const <String, Object?>{
                'operation': 'resetPassword',
              },
            )
          : statusCode == 410
          ? ValidationFailure(
              message: 'Password recovery token expired',
              userMessage: 'O token de recuperacao expirou. Solicite outro.',
              cause: error,
              stackTrace: stackTrace,
              context: const <String, Object?>{
                'operation': 'resetPassword',
              },
            )
          : mapToAppFailure(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Unable to reset client password',
              fallbackUserMessage:
                  'Nao foi possivel redefinir a senha com este token.',
              context: <String, Object?>{
                'operation': 'resetPassword',
                'statusCode': statusCode,
              },
            );
      return Failure<Unit, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected failure resetting password',
        context: const <String, Object?>{
          'operation': 'resetPassword',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to reset client password',
          fallbackUserMessage:
              'Nao foi possivel redefinir a senha com este token.',
          context: const <String, Object?>{
            'operation': 'resetPassword',
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
          refreshToken: storedSession.refreshToken,
        );
      }
      await _localDataSource.clearSession();
      await _appCacheStore.clearAll();
      _sessionEvents?.notifyInvalidated();
      AppLogger.info(
        'User session cleared',
        context: const <String, Object?>{
          'operation': 'logout',
        },
      );

      return const Success<Unit, AppFailure>(unit);
    } on DioException catch (error, stackTrace) {
      AppLogger.warning(
        'Remote client logout failed; local session will still be cleared',
        context: const <String, Object?>{
          'operation': 'logout',
        },
        error: error,
        stackTrace: stackTrace,
      );
      await _localDataSource.clearSession();
      await _appCacheStore.clearAll();
      _sessionEvents?.notifyInvalidated();
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
            currentSession: authSessionModel,
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
          // Broadcast the invalidation so other consumers wired to
          // `AuthSessionEvents` (typically the consumer socket
          // connection) drop their state too. Without this, a failed
          // boot-time refresh leaves the socket holding a stale
          // assumption of "session present" until the next manual
          // disconnect.
          _sessionEvents?.notifyInvalidated();
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

  Future<AuthSessionModel> _readRequiredStoredSession() async {
    final storedSession = await _localDataSource.readSession();
    if (storedSession != null) {
      return storedSession;
    }

    throw const SessionFailure(
      message: 'No active client session found',
      userMessage: 'Sua sessao nao esta disponivel. Entre novamente.',
    );
  }
}
