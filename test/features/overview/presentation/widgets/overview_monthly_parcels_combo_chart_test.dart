// Manual QA (plan): narrow layout + 12 months with category pan enabled, large
// text scale, dark mode, EN/PT — confirm pan footnote, tooltips for both
// series, and no clipped bar labels.

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<OverviewMonthlyParcelPoint> points;

  setUp(() {
    points = List<OverviewMonthlyParcelPoint>.generate(
      12,
      (i) => OverviewMonthlyParcelPoint(
        anoMes: '2025-${(i + 1).toString().padLeft(2, '0')}',
        qtdVendas: 10 + i,
        valorParcela: 1000.0 + i * 50,
      ),
      growable: false,
    );
  });

  testWidgets('toggle updates subtitle and chart semantics label', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Scaffold(
              body: OverviewMonthlyParcelsComboChart(
                l10n: l10n,
                points: points,
                loadFailed: false,
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text(l10n.overviewMonthlyParcelsSubtitle), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.overviewMonthlyParcelsChartSemantics),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.overviewMonthlyParcelsSwitchValueLabel));
    await tester.pump();

    expect(find.text(l10n.overviewMonthlyParcelsSubtitleValueView), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.overviewMonthlyParcelsChartSemanticsValueView),
      findsOneWidget,
    );
  });

  testWidgets('builds at elevated text scale without throwing', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.25)),
          child: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return Scaffold(
                body: SingleChildScrollView(
                  child: OverviewMonthlyParcelsComboChart(
                    l10n: l10n,
                    points: points,
                    loadFailed: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(OverviewMonthlyParcelsComboChart), findsOneWidget);
  });
}
