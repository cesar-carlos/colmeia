import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SalesMonthlyPnlBarChartCard shows Amounts / Percent controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final salesPrefs = SalesPreferences(prefs);

    final points = <SalesMonthlyPnlPoint>[
      const SalesMonthlyPnlPoint(
        year: 2025,
        month: 1,
        anoMes: '2025/01',
        venda: 100,
        lucro: 40,
        custoMercadoria: 50,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SalesMonthlyPnlBarChartCard(
          l10n: lookupAppLocalizations(const Locale('en')),
          points: points,
          loadFailed: false,
          isLoading: false,
          initialSession: salesPrefs.restoreMonthlyPnlBarChartPreferences(),
          persistSession: salesPrefs.persistMonthlyPnlBarChartPreferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amounts'), findsWidgets);
    expect(find.text('Percent metrics'), findsWidgets);
  });
}
