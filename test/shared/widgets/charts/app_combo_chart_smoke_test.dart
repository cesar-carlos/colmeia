import 'package:colmeia/app/theme/app_theme.dart';
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
}

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
      home: Scaffold(body: child),
    );
  }
}
