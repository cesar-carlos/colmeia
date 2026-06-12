import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppComparisonBarChart renders sample bars', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppComparisonBarChart<_SampleBar>(
          title: 'Smoke',
          items: const <_SampleBar>[
            _SampleBar(label: 'A', value: 12),
            _SampleBar(label: 'B', value: 24),
          ],
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.value,
        ),
      ),
    );

    expect(find.byType(AppComparisonBarChart<_SampleBar>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('AppComparisonBarChart loading state mounts without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppComparisonBarChart<_SampleBar>(
          title: 'Loading',
          items: const <_SampleBar>[],
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.value,
          isLoading: true,
        ),
      ),
    );

    expect(find.byType(AppComparisonBarChart<_SampleBar>), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'AppComparisonBarChart with plot-floor data mounts without throwing',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: AppComparisonBarChart<_SampleBar>(
            items: const <_SampleBar>[
              _SampleBar(label: 'High', value: 50000),
              _SampleBar(label: 'Low', value: 40),
            ],
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.value,
            plotFloorAccessibilityNotice: 'Barras pequenas foram ampliadas.',
          ),
        ),
      );

      expect(find.byType(AppComparisonBarChart<_SampleBar>), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets(
    'AppComparisonBarChart reduce-motion path renders without pending timers',
    (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: AppComparisonBarChart<_SampleBar>(
              items: <_SampleBar>[
                _SampleBar(label: 'A', value: 5),
                _SampleBar(label: 'B', value: 9),
              ],
              labelBuilder: _sampleBarLabel,
              valueBuilder: _sampleBarValue,
            ),
          ),
        ),
      );

      expect(find.byType(AppComparisonBarChart<_SampleBar>), findsOneWidget);
    },
  );
}

String _sampleBarLabel(_SampleBar item) => item.label;

num _sampleBarValue(_SampleBar item) => item.value;

class _SampleBar {
  const _SampleBar({required this.label, required this.value});

  final String label;
  final num value;
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
