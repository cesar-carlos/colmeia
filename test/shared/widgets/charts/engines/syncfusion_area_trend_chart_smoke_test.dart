import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_area_trend_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for [AppAreaTrendChart] focused on the Phase 1 changes:
/// - the engine renders without throwing,
/// - the new tooltip helper / animation defaults do not regress on common
///   input (single + multi-series),
/// - reduce-motion path drains its timers cleanly.
void main() {
  testWidgets('renders single-series area chart without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppAreaTrendChart(
          points: const <AppChartPoint>[
            AppChartPoint(label: 'Sem 1', value: 10),
            AppChartPoint(label: 'Sem 2', value: 18),
            AppChartPoint(label: 'Sem 3', value: 14),
            AppChartPoint(label: 'Sem 4', value: 22),
          ],
          title: 'Smoke',
        ),
      ),
    );
    expect(find.byType(AppAreaTrendChart), findsOneWidget);
    // Drain the 350 ms entrance animation timer Syncfusion spins up.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('renders multi-series area chart without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppAreaTrendChart(
          entries: const <AppAreaTrendEntry>[
            AppAreaTrendEntry(
              label: 'Plano A',
              points: <AppChartPoint>[
                AppChartPoint(label: 'Jan', value: 5),
                AppChartPoint(label: 'Fev', value: 8),
              ],
            ),
            AppAreaTrendEntry(
              label: 'Plano B',
              points: <AppChartPoint>[
                AppChartPoint(label: 'Jan', value: 7),
                AppChartPoint(label: 'Fev', value: 9),
              ],
            ),
          ],
          title: 'Smoke multi',
        ),
      ),
    );
    expect(find.byType(AppAreaTrendChart), findsOneWidget);
    expect(find.text('Plano A'), findsOneWidget);
    expect(find.text('Plano B'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets(
    'reduce-motion path renders without scheduling tween timers',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: AppAreaTrendChart(
              points: <AppChartPoint>[
                AppChartPoint(label: 'A', value: 1),
                AppChartPoint(label: 'B', value: 2),
              ],
              title: 'Reduce motion',
            ),
          ),
        ),
      );
      // Tester guarantees no timers were left pending if no extra pump is
      // needed before tearDown — the resolver should have collapsed the
      // animation duration to 0, so the chart paints synchronously.
      expect(find.byType(AppAreaTrendChart), findsOneWidget);
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }
}
