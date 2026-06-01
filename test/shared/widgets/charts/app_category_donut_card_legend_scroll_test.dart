import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scrollable legend reserves right gutter for scrollbar', (
    tester,
  ) async {
    final segments = List<AppCategoryDonutSegment>.generate(
      6,
      (i) => AppCategoryDonutSegment(
        label: 'METHOD $i',
        value: 1000 + i,
        valueLabel: r'R$ 10.000,00',
        percentLabel: '12.1%',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 360,
            child: AppCategoryDonutCard(
              title: 'Mix',
              segments: segments,
              centerPrimaryLabel: r'R$ 114 mil',
              centerSecondaryLabel: 'TOTAL',
              style: const AppCategoryDonutCardStyle(
                legendMaxHeight: 160,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding;
    expect(padding, isA<EdgeInsets>());
    expect((padding! as EdgeInsets).right, 14);
  });
}
