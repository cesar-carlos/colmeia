import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/repositories/user_context_repository_impl.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';
import 'package:get_it/get_it.dart';

void registerInjectorUserContext(GetIt getIt) {
  getIt
    ..registerLazySingleton<UserContextRepository>(
      () => UserContextRepositoryImpl(
        localDataSource: getIt<UserContextLocalDataSource>(),
        remoteDataSource: getIt<UserContextRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<LoadCurrentUserContextUseCase>(
      () => LoadCurrentUserContextUseCase(getIt<UserContextRepository>()),
    )
    ..registerLazySingleton<PersistActiveStoreUseCase>(
      () => PersistActiveStoreUseCase(getIt<UserContextRepository>()),
    )
    ..registerLazySingleton<ClearActiveStoreUseCase>(
      () => ClearActiveStoreUseCase(getIt<UserContextRepository>()),
    );
}
