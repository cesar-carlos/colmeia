abstract final class AppEnvironment {
  static const bool useFakeBackend = bool.fromEnvironment(
    'USE_FAKE_BACKEND',
    defaultValue: true,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
}
