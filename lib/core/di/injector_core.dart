import 'dart:async';

import 'package:colmeia/app/preferences/app_user_experience_preferences_controller.dart';
import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/hive_app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/core/network/auth_interceptor.dart';
import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/storage/app_hive.dart';
import 'package:colmeia/core/storage/app_secure_storage_factory.dart';
import 'package:colmeia/core/storage/session_storage.dart';
import 'package:colmeia/core/update/appcast_probe_client.dart';
import 'package:colmeia/core/update/auto_updater_client.dart';
import 'package:colmeia/core/update/windows_auto_update_controller.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/fake_auth_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_geocoding_plugin_geocoder.dart';
import 'package:colmeia/shared/maps/app_here_geocoding_geocoder.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_resolution_observer.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    ..registerLazySingleton<AppLocationGeocodeCache>(
      () => AppLocationGeocodeCache(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<AppLocationResolutionObserver>(
      () => const AppLoggerLocationResolutionObserver(),
    )
    ..registerLazySingleton<AppLocationResolver>(
      () => AppLocationResolver(
        cache: getIt<AppLocationGeocodeCache>(),
        observer: getIt<AppLocationResolutionObserver>(),
        geocoders: <AppLocationGeocoder>[
          const AppBrazilMunicipalityAssetGeocoder(),
          ...buildPlatformLocationGeocoders(
            isWeb: kIsWeb,
            targetPlatform: defaultTargetPlatform,
            dio: getIt<Dio>(),
            hereApiKey: AppEnvironment.hereGeocodingApiKey,
          ),
        ],
      ),
    )
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerSingleton<AppUserPreferencesStore>(
      AppUserPreferencesStore(sharedPreferences),
    )
    ..registerSingleton<AutoUpdaterClient>(const LeanAutoUpdaterClient())
    ..registerLazySingleton<AppcastProbeClient>(() {
      final client = DioAppcastProbeClient();
      return client.probe;
    })
    ..registerLazySingleton<WindowsAutoUpdateController>(
      () => WindowsAutoUpdateController(
        autoUpdaterClient: getIt<AutoUpdaterClient>(),
        appcastProbeClient: getIt<AppcastProbeClient>(),
        feedUrlResolver: () => AppEnvironment.autoUpdateFeedUrl,
        preferencesStore: getIt<AppUserPreferencesStore>(),
      ),
    )
    ..registerLazySingleton<AppThemeModeController>(
      () => AppThemeModeController(getIt<AppUserPreferencesStore>()),
    )
    ..registerLazySingleton<AppUserExperiencePreferencesController>(
      () => AppUserExperiencePreferencesController(
        getIt<AppUserPreferencesStore>(),
      ),
    )
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
    ..registerLazySingleton<AuthSessionAccessor>(
      () => AuthSessionAccessor(getIt<AuthLocalDataSource>()),
    )
    ..registerLazySingleton<AuthSessionEvents>(AuthSessionEvents.new)
    ..registerLazySingleton<Dio>(
      AppDioClient.create,
      instanceName: 'refresh_dio',
    )
    ..registerLazySingleton<AuthRefreshCoordinator>(
      () => AuthRefreshCoordinator(
        refreshDio: getIt<Dio>(instanceName: 'refresh_dio'),
        sessionAccessor: getIt<AuthSessionAccessor>(),
        sessionEvents: getIt<AuthSessionEvents>(),
      ),
    )
    ..registerLazySingleton<Dio>(
      () {
        final dio = AppDioClient.create();
        dio.interceptors.add(
          AuthInterceptor(
            dio: dio,
            sessionAccessor: getIt<AuthSessionAccessor>(),
            refreshCoordinator: getIt<AuthRefreshCoordinator>(),
          ),
        );
        return dio;
      },
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeAuthRemoteDataSource(
              getIt<FakeIdentityBackendStore>(),
              getIt<AuthSessionAccessor>(),
            )
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

  unawaited(_purgeLocationGeocodeCache(getIt));
}

Future<void> _purgeLocationGeocodeCache(GetIt getIt) async {
  final summary = await getIt<AppLocationGeocodeCache>().purgeExpiredEntries(
    maxEntries: 50,
  );
  getIt<AppLocationResolutionObserver>().onEvent(
    event: 'cache_purge_summary',
    context: summary.toJson(),
  );
}

List<AppLocationGeocoder> buildPlatformLocationGeocoders({
  required bool isWeb,
  required TargetPlatform targetPlatform,
  required Dio dio,
  required String hereApiKey,
}) {
  final geocoders = <AppLocationGeocoder>[];
  if (!isWeb &&
      (targetPlatform == TargetPlatform.android ||
          targetPlatform == TargetPlatform.iOS)) {
    geocoders.add(AppGeocodingPluginGeocoder());
  }
  if (!isWeb && hereApiKey.trim().isNotEmpty) {
    geocoders.add(
      AppHereGeocodingGeocoder(
        dio: dio,
        apiKey: hereApiKey,
      ),
    );
  }
  return geocoders;
}
