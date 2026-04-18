/// Pure resolution rules for `AppEnvironment` (dart-define and dotenv
/// precedence).
///
/// Used by tests without Flutter bindings or loaded assets.
abstract final class AppEnvironmentResolution {
  static String resolveString({
    required String fromDefine,
    required String? fromDotenv,
    required String fallback,
  }) {
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return fromDotenv;
    }
    return fallback;
  }

  static bool resolveBool({
    required String fromDefine,
    required String? fromDotenv,
    required bool fallback,
  }) {
    if (fromDefine.isNotEmpty) {
      return parseBoolString(fromDefine, fallback: fallback);
    }
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return parseBoolString(fromDotenv, fallback: fallback);
    }
    return fallback;
  }

  static bool parseBoolString(String raw, {required bool fallback}) {
    final v = raw.trim().toLowerCase();
    if (v == 'true' || v == '1') {
      return true;
    }
    if (v == 'false' || v == '0') {
      return false;
    }
    return fallback;
  }

  static int resolveInt({
    required String fromDefine,
    required String? fromDotenv,
    required int fallback,
  }) {
    if (fromDefine.isNotEmpty) {
      return int.tryParse(fromDefine.trim()) ?? fallback;
    }
    if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
      return int.tryParse(fromDotenv.trim()) ?? fallback;
    }
    return fallback;
  }
}
