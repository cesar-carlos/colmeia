import 'package:checks/checks.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCategoryDonutSegmentListX.donutWeightTotal', () {
    test('should sum values with a positive floor', () {
      final list = <AppCategoryDonutSegment>[
        const AppCategoryDonutSegment(label: 'A', value: 40),
        const AppCategoryDonutSegment(label: 'B', value: 60),
      ];
      check(list.donutWeightTotal).equals(100);
    });

    test('should resolve percent from value weights', () {
      const seg = AppCategoryDonutSegment(
        label: 'A',
        value: 40,
      );
      check(seg.resolvePercentLabel(100)).equals('40%');
    });
  });
}
