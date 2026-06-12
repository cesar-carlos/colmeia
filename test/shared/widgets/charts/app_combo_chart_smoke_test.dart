import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppComboChart renders bar and line series', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppComboChart<_ComboPoint>(
          title: 'Smoke combo',
          items: const <_ComboPoint>[
            _ComboPoint(label: 'Jan', barValue: 10, lineValue: 4),
            _ComboPoint(label: 'Feb', barValue: 14, lineValue: 6),
          ],
          xLabelBuilder: (item) => item.label,
          barValueBuilder: (item) => item.barValue,
          barSeriesLabel: 'Pedidos',
          lineValueBuilder: (item) => item.lineValue,
          lineSeriesLabel: 'Ticket',
        ),
      ),
    );

    expect(find.byType(AppComboChart<_ComboPoint>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('AppComboChart renders bar-only variant without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppComboChart<_ComboPoint>(
          items: const <_ComboPoint>[
            _ComboPoint(label: 'A', barValue: 8, lineValue: 2),
            _ComboPoint(label: 'B', barValue: 12, lineValue: 3),
          ],
          xLabelBuilder: (item) => item.label,
          barValueBuilder: (item) => item.barValue,
          barSeriesLabel: 'Barras',
          lineValueBuilder: (item) => item.lineValue,
          lineSeriesLabel: 'Linha',
          style: const AppComboChartStyle(showLineSeries: false),
        ),
      ),
    );

    expect(find.byType(AppComboChart<_ComboPoint>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('AppComboChart loading state mounts without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppComboChart<_ComboPoint>(
          title: 'Loading',
          items: const <_ComboPoint>[],
          xLabelBuilder: (item) => item.label,
          barValueBuilder: (item) => item.barValue,
          barSeriesLabel: 'Barras',
          lineValueBuilder: (item) => item.lineValue,
          lineSeriesLabel: 'Linha',
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(AppComboChart<_ComboPoint>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'AppComboChart reduce-motion path renders without pending timers',
    (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: AppComboChart<_ComboPoint>(
              title: 'Reduce motion',
              items: <_ComboPoint>[
                _ComboPoint(label: 'A', barValue: 1, lineValue: 1),
                _ComboPoint(label: 'B', barValue: 2, lineValue: 2),
              ],
              xLabelBuilder: _comboLabel,
              barValueBuilder: _comboBarValue,
              barSeriesLabel: 'Barras',
              lineValueBuilder: _comboLineValue,
              lineSeriesLabel: 'Linha',
            ),
          ),
        ),
      );

      expect(find.byType(AppComboChart<_ComboPoint>), findsOneWidget);
    },
  );
}

String _comboLabel(_ComboPoint item) => item.label;

num _comboBarValue(_ComboPoint item) => item.barValue;

num _comboLineValue(_ComboPoint item) => item.lineValue;

class _ComboPoint {
  const _ComboPoint({
    required this.label,
    required this.barValue,
    required this.lineValue,
  });

  final String label;
  final num barValue;
  final num lineValue;
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
