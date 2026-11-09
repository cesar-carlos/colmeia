import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/models/current_user_context_model.dart';
import 'package:colmeia/features/user_context/data/repositories/user_context_repository_impl.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';
import 'package:get_it/get_it.dart';

void registerInjectorUserContext(GetIt getIt) {
  getIt
    ..registerLazySingleton<UserContextRepository>(
      () => UserContextRepositoryImpl(
        localDataSource: getIt<UserContextLocalDataSource>(),
        remoteDataSource: getIt<UserContextRemoteDataSource>(),
        offlineContextLoader: (user) async {
          final packages = getIt<PwaPackageService>();
          if (packages.platform.online) return null;
          for (final agent in await packages.selectedAgents(user)) {
            final package = await packages.read(user, agent);
            if (package != null) {
              return CurrentUserContextModel.fromJson(
                Map<String, dynamic>.from(package.datasets['context'] as Map),
              ).toEntity();
            }
          }
          return null;
        },
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
