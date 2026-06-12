import 'package:colmeia/core/errors/app_failure.dart';

/// Resolves the user-facing chart load failure line without depending on
/// widget-layer localization. Callers supply localized text via
/// [localizedFailureMessage].
String resolveAgentQueryChartLoadFailureMessage({
  required String genericFallback,
  required String? Function(AppFailure failure) localizedFailureMessage,
  AppFailure? loadFailure,
  String? legacyMessage,
}) {
  if (loadFailure != null) {
    final localized = localizedFailureMessage(loadFailure)?.trim();
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }
  }
  final legacy = legacyMessage?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    return legacy;
  }
  return genericFallback;
}
