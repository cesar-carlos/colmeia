import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/l10n/app_localizations.dart';

abstract final class SalesAutoRefreshL10n {
  static String intervalLabel(
    AppLocalizations l10n,
    AutoRefreshOption option,
  ) {
    return switch (option.id) {
      'fiveMinutes' => l10n.salesAutoRefreshIntervalFiveMinutes,
      'tenMinutes' => l10n.salesAutoRefreshIntervalTenMinutes,
      'fifteenMinutes' => l10n.salesAutoRefreshIntervalFifteenMinutes,
      'thirtyMinutes' => l10n.salesAutoRefreshIntervalThirtyMinutes,
      _ => option.id,
    };
  }
}
