import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_branch_anchor_month_filters_sheet.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'custom range mode shows informational banner about reference month',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context);
                return SalesBranchAnchorMonthFiltersSheet(
                  l10n: l10n,
                  filtersContext: SalesAnchorMonthFiltersContext.monthlyPnl,
                  availableAgents: const <DashboardAgentOption>[
                    DashboardAgentOption(agentId: 'a', name: 'Branch A'),
                  ],
                  initialSelectedAgentId: 'a',
                  initialAnchorYearMonth: const DashboardYearMonth(
                    year: 2026,
                    month: 3,
                  ),
                  initialDailyTotalsUseCustomRange: true,
                  initialDailyTotalsDateRange:
                      DashboardDateRange.fromOrderedEndpoints(
                        DateTime(2026, 3),
                        DateTime(2026, 3, 12),
                      ),
                  onApply: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.descendant(
          of: find.byType(SalesBranchAnchorMonthFiltersSheet),
          matching: find.byType(ListView),
        ),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          l10n.salesDailyTotalsFilterCustomRangeAnchorIndependenceBanner,
        ),
        findsOneWidget,
      );
    },
  );
}
