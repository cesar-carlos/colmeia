import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/l10n/app_localizations.dart';

String mapAuthRegistrationFailure(
  AppFailure failure,
  AppLocalizations l10n,
) {
  final statusCode = failure.context['statusCode'];
  if (statusCode == 429) {
    return l10n.authRegistrationRateLimited;
  }

  final operation = failure.context['operation'];
  if (failure is ValidationFailure) {
    return switch (operation) {
      'register' when failure.message.contains('not eligible') =>
        l10n.authRegisterOwnerEmailNotEligible,
      'readRegistrationStatus' when failure.message.contains('expired') =>
        l10n.authRegistrationStatusTokenExpired,
      'readRegistrationStatus' when failure.message.contains('not found') =>
        l10n.authRegistrationStatusTokenInvalid,
      _ => failure.displayMessage,
    };
  }

  return switch (operation) {
    'register' => l10n.authRegisterSubmitFailure,
    'readRegistrationStatus' => l10n.authRegistrationStatusLoadFailure,
    'retryClientRegistration' => l10n.authRegistrationRetryFailure,
    _ => failure.displayMessage,
  };
}
