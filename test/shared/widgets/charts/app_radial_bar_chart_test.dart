import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_radial_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  testWidgets('loading state uses AppSkeleton instead of spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppRadialBarChart<String>(
            title: 'Loading demo',
            items: <String>[],
            labelBuilder: _identity,
            valueBuilder: _zero,
            isLoading: true,
            loadingSemanticsLabel: 'Carregando ranking radial',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Carregando ranking radial'), findsOneWidget);
  });

  testWidgets(
    'exposes default semantics label and hint for interactive chart',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: AppRadialBarChart<_MutableMetric>(
              title: 'SLA por canal',
              items: <_MutableMetric>[
                _MutableMetric(label: 'Delivery', value: 94),
                _MutableMetric(label: 'Retirada', value: 88),
              ],
              labelBuilder: (item) => item.label,
              valueBuilder: (item) => item.value,
              onSegmentTap: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      const semanticsLabel = 'SLA por canal, grafico radial com 2 series.';
      const semanticsHint = 'Toque em um anel para destacar ou ver detalhes.';

      expect(
        find.bySemanticsLabel(semanticsLabel),
        findsOneWidget,
      );
      final semanticsNode = tester.getSemantics(
        find.bySemanticsLabel(semanticsLabel),
      );
      expect(semanticsNode.hint, semanticsHint);
    },
  );

  testWidgets('exposes custom empty semantics label', (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppRadialBarChart<String>(
            title: 'Horas por frente',
            items: <String>[],
            labelBuilder: _identity,
            valueBuilder: _zero,
            emptySemanticsLabel: 'Horas por frente sem dados disponiveis',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('Horas por frente sem dados disponiveis'),
      findsOneWidget,
    );
  });

  testWidgets('recomputes maximum value when same list instance changes', (
    tester,
  ) async {
    final items = <_MutableMetric>[
      _MutableMetric(label: 'Loja Norte', value: 24),
      _MutableMetric(label: 'Loja Sul', value: 36),
    ];

    Future<void> pumpChart() async {
      await tester.pumpWidget(
        _TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: AppRadialBarChart<_MutableMetric>(
              items: items,
              labelBuilder: (item) => item.label,
              valueBuilder: (item) => item.value,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    RadialBarSeries<_MutableMetric, String> currentSeries() {
      final chart = tester.widget<SfCircularChart>(
        find.byType(SfCircularChart),
      );
      return chart.series.single as RadialBarSeries<_MutableMetric, String>;
    }

    await pumpChart();
    expect(currentSeries().maximumValue, 36);

    items[1].value = 72;
    await pumpChart();
    expect(currentSeries().maximumValue, 72);
  });
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

String _identity(String item) => item;

num _zero(String _) => 0;

class _MutableMetric {
  _MutableMetric({
    required this.label,
    required this.value,
  });

  final String label;
  double value;
}
