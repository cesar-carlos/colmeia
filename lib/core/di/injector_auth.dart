import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/features/auth/application/usecases/change_password_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/read_current_user_profile_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/read_password_recovery_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/request_password_recovery_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/reset_password_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/update_current_user_profile_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/upload_client_thumbnail_use_case.dart';
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
        sessionEvents: getIt<AuthSessionEvents>(),
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
    ..registerLazySingleton<ReadRegistrationStatusUseCase>(
      () => ReadRegistrationStatusUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<ReadCurrentUserProfileUseCase>(
      () => ReadCurrentUserProfileUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<UpdateCurrentUserProfileUseCase>(
      () => UpdateCurrentUserProfileUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<UploadClientThumbnailUseCase>(
      () => UploadClientThumbnailUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<ChangePasswordUseCase>(
      () => ChangePasswordUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<RequestPasswordRecoveryUseCase>(
      () => RequestPasswordRecoveryUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<ReadPasswordRecoveryStatusUseCase>(
      () => ReadPasswordRecoveryStatusUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<ResetPasswordUseCase>(
      () => ResetPasswordUseCase(getIt<AuthRepository>()),
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
        authSessionEvents: getIt<AuthSessionEvents>(),
      ),
    );
}
