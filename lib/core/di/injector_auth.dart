import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:get_it/get_it.dart';

void registerInjectorAuth(GetIt getIt) {
  getIt
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        localDataSource: getIt<AuthLocalDataSource>(),
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        appCacheStore: getIt<AppCacheStore>(),
      ),
    )
    ..registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<RestoreSessionUseCase>(
      () => RestoreSessionUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<RegisterUseCase>(
      () => RegisterUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<AuthController>(
      () => AuthController(
        loginUseCase: getIt<LoginUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        registerUseCase: getIt<RegisterUseCase>(),
        restoreSessionUseCase: getIt<RestoreSessionUseCase>(),
      ),
    );
}
