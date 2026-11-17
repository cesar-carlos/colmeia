import 'package:colmeia/shared/widgets/metrics/resolve_metric_grid_columns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int columns(double width, {double scale = 1}) => resolveMetricGridColumns(
    width: width,
    gap: 12,
    textScale: scale,
    narrowColumns: 2,
    wideColumns: 3,
    extraWideColumns: 5,
  );

  test('should keep at least one column in a constrained viewport', () {
    expect(columns(0), 1);
    expect(columns(288), 1);
    expect(columns(328), 1);
    expect(columns(358), 2);
  });

  test(
    'should preserve configured tablet and desktop tiers when tiles fit',
    () {
      expect(columns(600), 2);
      expect(columns(720), 3);
      expect(columns(960), 5);
      expect(columns(1440), 5);
    },
  );

  test('should reduce columns for enlarged text without shrinking text', () {
    expect(columns(358, scale: 2), 1);
    expect(columns(720, scale: 2), 2);
    expect(columns(960, scale: 2), 2);
    expect(columns(1440, scale: 2), 4);
  });

  test('should not add columns when accessibility text is smaller', () {
    expect(columns(328, scale: 0.8), columns(328));
  });
}
