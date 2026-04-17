import 'package:colmeia/shared/widgets/charts/chart_pan_footnote_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChartPanFootnoteColumn shows footnote text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            width: 300,
            child: ChartPanFootnoteColumn(
              plot: ColoredBox(color: Colors.orange),
              footnoteText: 'Pan hint line',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pan hint line'), findsOneWidget);
  });
}
