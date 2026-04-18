import 'package:checks/checks.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppCategoryDonutCardStyle defaults', () {
    const s = AppCategoryDonutCardStyle();
    check(s.doughnutAnimationDurationMs).isNull();
    check(s.legendMaxHeight).isNull();
    check(AppCategoryDonutCardStyle.defaultDoughnutAnimationDurationMs).equals(500);
  });

  test('AppCategoryDonutCardStyle can disable animation and cap legend', () {
    const s = AppCategoryDonutCardStyle(
      doughnutAnimationDurationMs: 0,
      legendMaxHeight: 240,
    );
    check(s.doughnutAnimationDurationMs).equals(0);
    check(s.legendMaxHeight).equals(240);
  });
}
