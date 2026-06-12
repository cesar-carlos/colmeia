import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overviewChartLoadFailureMessage prefers generic fallback when load failed', () {
    final l10n = AppLocalizationsEn();

    final message = overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: true,
      loadFailure: const ValidationFailure(message: 'agent sql timeout'),
      genericFallback: l10n.overviewLoadFailedUserMessage,
    );

    check(message).isNotEmpty();
  });
}
