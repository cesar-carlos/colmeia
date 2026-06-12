import 'package:colmeia/app/theme/app_theme.dart';
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
}

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
      home: Scaffold(body: child),
    );
  }
}
