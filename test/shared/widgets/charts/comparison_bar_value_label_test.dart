import 'package:colmeia/shared/widgets/charts/comparison_bar_value_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('buildComparisonBarOuterValueLabel stacks newline lines', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: buildComparisonBarOuterValueLabel(
                text: 'R\$ 48,2 mil\nTicket médio: R\$ 61,77',
                baseStyle: const TextStyle(fontSize: 11),
                colorScheme: Theme.of(context).colorScheme,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            );
          },
        ),
      ),
    );

    expect(find.text(r'R$ 48,2 mil'), findsOneWidget);
    expect(find.text(r'Ticket médio: R$ 61,77'), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
  });
}
