import 'package:colmeia/l10n/app_localizations.dart';

/// Which Sales flow uses the branch + reference-month filter sheet (copy context).
enum SalesAnchorMonthFiltersContext {
  monthlyPnl,
  dailyTotals,
}

extension SalesAnchorMonthFiltersContextX on SalesAnchorMonthFiltersContext {
  String filtersSheetTitle(AppLocalizations l10n) => switch (this) {
    SalesAnchorMonthFiltersContext.monthlyPnl => l10n.salesCardMonthlyPnlTitle,
    SalesAnchorMonthFiltersContext.dailyTotals =>
      l10n.salesCardResumoTotalDiarioVendasTitle,
  };
}
