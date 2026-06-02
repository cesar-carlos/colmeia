import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  testWidgets('renders explicit edit filters action', (tester) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        child: SalesCardFilterTrigger(
          summaryItems: const <SalesCardFilterSummaryItem>[
            SalesCardFilterSummaryItem(
              label: 'FILIAL',
              value: 'Rondonopolis Lions',
            ),
          ],
          buttonSemanticsLabel: 'Filtros',
          editActionLabel: 'Editar filtros',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Editar filtros'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });

  testWidgets('renders footer below summary content', (tester) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        child: SalesCardFilterTrigger(
          summaryItems: const <SalesCardFilterSummaryItem>[
            SalesCardFilterSummaryItem(
              label: 'PERIODO',
              value: '01/06 - 30/06',
            ),
          ],
          buttonSemanticsLabel: 'Filtros',
          onTap: () {},
          footer: const Text('Atualizado 16:51'),
        ),
      ),
    );

    final periodFinder = find.text('01/06 - 30/06');
    final footerFinder = find.text('Atualizado 16:51');

    expect(periodFinder, findsOneWidget);
    expect(footerFinder, findsOneWidget);

    final periodBottomLeft = tester.getBottomLeft(periodFinder);
    final footerTopLeft = tester.getTopLeft(footerFinder);
    expect(footerTopLeft.dy, greaterThan(periodBottomLeft.dy));
  });
}
