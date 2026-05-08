import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SalesAnchorMonthFiltersContext titles', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      SalesAnchorMonthFiltersContext.monthlyPnl.filtersSheetTitle(l10n),
      l10n.salesCardMonthlyPnlTitle,
    );
    expect(
      SalesAnchorMonthFiltersContext.dailyTotals.filtersSheetTitle(l10n),
      l10n.salesCardResumoTotalDiarioVendasTitle,
    );
  });
}
