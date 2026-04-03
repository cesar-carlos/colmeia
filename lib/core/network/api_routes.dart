abstract final class ApiRoutes {
  static const String dashboardsOverview = '/dashboards/overview';
}

abstract final class ClientAuthApiRoutes {
  static const String register = '/client-auth/register';
  static const String registrationStatus = '/client-auth/registration/status';
  static const String login = '/client-auth/login';
  static const String refresh = '/client-auth/refresh';
  static const String logout = '/client-auth/logout';
  static const String me = '/client-auth/me';
  static const String password = '/client-auth/password';
  static const String thumbnail = '/client-auth/thumbnail';
  static const String passwordRecoveryRequest =
      '/client-auth/password-recovery/request';
  static const String passwordRecoveryStatus =
      '/client-auth/password-recovery/status';
  static const String passwordRecoveryReset =
      '/client-auth/password-recovery/reset';

  static const Set<String> unauthenticated = <String>{
    register,
    registrationStatus,
    login,
    refresh,
    logout,
    passwordRecoveryRequest,
    passwordRecoveryStatus,
    passwordRecoveryReset,
  };
}
