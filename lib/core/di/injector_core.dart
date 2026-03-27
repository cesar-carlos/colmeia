import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/hive_app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/storage/app_hive.dart';
import 'package:colmeia/core/storage/app_secure_storage_factory.dart';
import 'package:colmeia/core/storage/session_storage.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/fake_auth_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> registerInjectorCore(GetIt getIt) async {
  await AppHive.ensureInitialized();
  final kvCacheBox = await Hive.openBox<String>(AppHive.kvCacheBoxName);
  final sharedPreferences = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<AppCacheStore>(HiveAppCacheStore(kvCacheBox))
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerSingleton<AppUserPreferencesStore>(
      AppUserPreferencesStore(sharedPreferences),
    )
    ..registerLazySingleton<AppThemeModeController>(
      () => AppThemeModeController(getIt<AppUserPreferencesStore>()),
    )
    ..registerLazySingleton<Dio>(AppDioClient.create)
    ..registerLazySingleton<FlutterSecureStorage>(createAppSecureStorage)
    ..registerLazySingleton<SessionStorage>(
      () => SessionStorage(getIt<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<FakeIdentityBackendStore>(
      () => FakeIdentityBackendStore(getIt<SessionStorage>()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSource(
        sessionStorage: getIt<SessionStorage>(),
      ),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeAuthRemoteDataSource(getIt<FakeIdentityBackendStore>())
          : ApiAuthRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<UserContextLocalDataSource>(
      () => UserContextLocalDataSource(getIt<SessionStorage>()),
    )
    ..registerLazySingleton<UserContextRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeUserContextRemoteDataSource(getIt<FakeIdentityBackendStore>())
          : ApiUserContextRemoteDataSource(getIt<Dio>()),
    );
}
