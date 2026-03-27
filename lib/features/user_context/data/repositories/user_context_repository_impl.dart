import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/domain/entities/user_context_snapshot.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';
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
  Future<AppResult<UserContextSnapshot>> loadUserContext({
    required String userId,
  }) async {
    try {
      final persistedActiveStoreId = await _localDataSource.readActiveStoreId(
        userId,
      );
      final model = await _remoteDataSource.loadUserContext(userId: userId);
      return Success<UserContextSnapshot, AppFailure>(
        model.toSnapshot(persistedActiveStoreId: persistedActiveStoreId),
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
      return Failure<UserContextSnapshot, AppFailure>(
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
