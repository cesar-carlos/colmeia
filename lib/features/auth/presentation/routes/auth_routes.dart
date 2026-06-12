import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/auth/application/auth_login_preferences_service.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/read_password_recovery_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/request_password_recovery_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/reset_password_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/retry_client_registration_use_case.dart';
import 'package:colmeia/features/auth/presentation/controllers/login_page_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/register_page_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/registration_status_page_controller.dart';
import 'package:colmeia/features/auth/presentation/pages/login_page.dart';
import 'package:colmeia/features/auth/presentation/pages/password_recovery_request_page.dart';
import 'package:colmeia/features/auth/presentation/pages/password_recovery_reset_page.dart';
import 'package:colmeia/features/auth/presentation/pages/register_page.dart';
import 'package:colmeia/features/auth/presentation/pages/registration_status_page.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> buildAuthRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.login.name,
      path: AppRoute.login.path,
      builder: (context, state) {
        return LoginPage(
          controller: LoginPageController(
            getIt<AuthLoginPreferencesService>(),
          ),
        );
      },
    ),
    GoRoute(
      name: AppRoute.register.name,
      path: AppRoute.register.path,
      builder: (context, state) {
        return RegisterPage(
          controller: RegisterPageController(
            registerUseCase: getIt<RegisterUseCase>(),
            preferencesService: getIt<AuthRegistrationPreferencesService>(),
          ),
        );
      },
    ),
    GoRoute(
      name: AppRoute.registrationStatus.name,
      path: AppRoute.registrationStatus.path,
      builder: (context, state) {
        final preferencesService = getIt<AuthRegistrationPreferencesService>();
        final extraToken = state.extra is String
            ? state.extra! as String
            : null;
        return RegistrationStatusPage(
          controller: RegistrationStatusPageController(
            readRegistrationStatusUseCase:
                getIt<ReadRegistrationStatusUseCase>(),
            retryClientRegistrationUseCase:
                getIt<RetryClientRegistrationUseCase>(),
            preferencesService: preferencesService,
            initialToken: extraToken ?? preferencesService.readPollToken(),
          ),
        );
      },
    ),
    GoRoute(
      name: AppRoute.passwordRecovery.name,
      path: AppRoute.passwordRecovery.path,
      builder: (context, state) {
        return PasswordRecoveryRequestPage(
          requestPasswordRecoveryUseCase:
              getIt<RequestPasswordRecoveryUseCase>(),
        );
      },
    ),
    GoRoute(
      name: AppRoute.passwordRecoveryReset.name,
      path: AppRoute.passwordRecoveryReset.path,
      builder: (context, state) {
        return PasswordRecoveryResetPage(
          readPasswordRecoveryStatusUseCase:
              getIt<ReadPasswordRecoveryStatusUseCase>(),
          resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
          initialToken: state.uri.queryParameters['token'],
        );
      },
    ),
  ];
}
