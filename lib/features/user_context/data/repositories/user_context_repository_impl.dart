import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_context.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class UserContextRepositoryImpl implements UserContextRepository {
  UserContextRepositoryImpl({
    required UserContextLocalDataSource localDataSource,
    required UserContextRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final UserContextLocalDataSource _localDataSource;
  final UserContextRemoteDataSource _remoteDataSource;

  @override
  Future<AppResult<CurrentUserContext>> loadUserContext({
    required String userId,
  }) async {
    try {
      final persistedActiveStoreId = await _localDataSource.readActiveStoreId(
        userId,
      );
      final model = await _remoteDataSource.loadUserContext(
        userId: userId,
      );
      return Success<CurrentUserContext, AppFailure>(
        model.toEntity(
          persistedActiveStoreId: persistedActiveStoreId,
        ),
      );
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      return Failure<CurrentUserContext, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load user context',
          fallbackUserMessage: switch (statusCode) {
            401 =>
              'Sua sessao expirou. Entre novamente para carregar seu contexto.',
            403 =>
              'Sua conta nao possui acesso ao contexto solicitado no momento.',
            404 => 'Nao foi possivel encontrar os dados da sua conta.',
            _ => 'Nao foi possivel carregar permissoes e lojas do usuario.',
          },
          context: <String, Object?>{
            'operation': 'loadUserContext',
            'userId': userId,
            'statusCode': statusCode,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unable to load user context',
        context: <String, Object?>{
          'operation': 'loadUserContext',
          'userId': userId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<CurrentUserContext, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load user context',
          fallbackUserMessage:
              'Nao foi possivel carregar permissoes e lojas do usuario.',
          context: <String, Object?>{
            'operation': 'loadUserContext',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<void> persistActiveStoreId({
    required String userId,
    required String storeId,
  }) {
    return _localDataSource.saveActiveStoreId(userId: userId, storeId: storeId);
  }

  @override
  Future<void> clearPersistedActiveStoreId({
    required String userId,
  }) {
    return _localDataSource.clearActiveStoreId(userId);
  }
}
