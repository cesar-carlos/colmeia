import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void showSalesLiveMapRetryCooldownSnackbar(
  BuildContext context,
  RetryAfterGate retryAfterGate,
) {
  final remainingSeconds = retryAfterGate.remaining?.inSeconds;
  if (remainingSeconds == null || remainingSeconds <= 0) {
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(l10n.appInlineErrorRetryCountdown(remainingSeconds)),
    ),
  );
}
