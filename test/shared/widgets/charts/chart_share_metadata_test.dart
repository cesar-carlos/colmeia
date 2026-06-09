import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveChartShareIncludeChartImage', () {
    test('auto skips image for table-only exports', () {
      expect(
        resolveChartShareIncludeChartImage(
          includeChartImage: null,
          hasTable: true,
          hasExportBuilder: false,
        ),
        isFalse,
      );
    });

    test('auto captures image when export builder exists', () {
      expect(
        resolveChartShareIncludeChartImage(
          includeChartImage: null,
          hasTable: true,
          hasExportBuilder: true,
        ),
        isTrue,
      );
    });

    test('explicit false skips capture even with export builder', () {
      expect(
        resolveChartShareIncludeChartImage(
          includeChartImage: false,
          hasTable: true,
          hasExportBuilder: true,
        ),
        isFalse,
      );
    });

    test('explicit true forces capture for table-only exports', () {
      expect(
        resolveChartShareIncludeChartImage(
          includeChartImage: true,
          hasTable: true,
          hasExportBuilder: false,
        ),
        isTrue,
      );
    });
  });
}
