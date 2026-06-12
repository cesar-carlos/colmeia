import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('AppCategoryDonutCard mounts with sample segments', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LocalizedTestApp(
        child: AppCategoryDonutCard(
          title: 'Mix por categoria',
          subtitle: 'Smoke test',
          segments: <AppCategoryDonutSegment>[
            AppCategoryDonutSegment(
              label: 'A',
              value: 60,
              valueLabel: '60%',
              percentLabel: '60%',
            ),
            AppCategoryDonutSegment(
              label: 'B',
              value: 40,
              valueLabel: '40%',
              percentLabel: '40%',
            ),
          ],
          centerPrimaryLabel: '100%',
        ),
      ),
    );

    expect(find.byType(AppCategoryDonutCard), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
