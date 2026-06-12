import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DailySalesTrendChart renders without agent_queries imports', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: DailySalesTrendChart(
                l10n: l10n,
                points: <DailySalesTrendPoint>[
                  DailySalesTrendPoint(
                    saleDate: DateTime(2026, 6),
                    salesCount: 3,
                    salesAmount: 150.5,
                  ),
                ],
                emptyMessage: l10n.overviewDailySalesEmpty,
              ),
            );
          },
        ),
      ),
    );

    expect(find.byType(DailySalesTrendChart), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('DailySalesTrendChart shows empty placeholder message', (
    tester,
  ) async {
    const emptyMessage = 'Sem vendas no período';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: DailySalesTrendChart(
                l10n: l10n,
                points: const <DailySalesTrendPoint>[],
                emptyMessage: emptyMessage,
              ),
            );
          },
        ),
      ),
    );

    expect(find.text(emptyMessage), findsOneWidget);
  });
}
