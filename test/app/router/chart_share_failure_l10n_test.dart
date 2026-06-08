import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chartShareFailureMessage maps each reason to l10n', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(
      chartShareFailureMessage(
        l10n,
        ChartShareFailureReason.missingBoundary,
      ),
      'Chart is not ready to share yet. Try again.',
    );
    expect(
      chartShareFailureMessage(
        l10n,
        ChartShareFailureReason.shareInProgress,
      ),
      'A share is already in progress for this chart.',
    );
    expect(
      chartShareFailureMessage(
        l10n,
        ChartShareFailureReason.shareCancelled,
      ),
      isEmpty,
    );
  });
}
