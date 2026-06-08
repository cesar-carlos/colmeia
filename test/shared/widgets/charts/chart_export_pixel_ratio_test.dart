import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_pixel_ratio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveChartExportPixelRatio honors explicit pixelRatio', () {
    expect(
      resolveChartExportPixelRatio(
        logicalWidth: 8000,
        pixelRatio: 2.5,
      ),
      2.5,
    );
  });

  test('resolveChartExportPixelRatio caps wide charts', () {
    final ratio = resolveChartExportPixelRatio(
      logicalWidth: 8000,
      devicePixelRatio: 3,
    );

    expect(ratio, lessThanOrEqualTo(kWideChartCaptureMaxPixelRatio));
    expect(ratio, greaterThanOrEqualTo(1));
  });

  test('resolveChartExportPixelRatio scales to target pixel width', () {
    final ratio = resolveChartExportPixelRatio(
      logicalWidth: 500,
      devicePixelRatio: 3,
    );

    expect(
      ratio,
      closeTo(
        math.min(
          kDefaultChartCaptureMaxPixelRatio,
          kChartPdfEmbedMaxWidth / 500,
        ),
        0.01,
      ),
    );
    expect(ratio, lessThanOrEqualTo(kDefaultChartCaptureMaxPixelRatio));
  });

  test('resolveChartExportPixelRatio caps square charts by embed height', () {
    const chartSize = 320.0;
    final ratio = resolveChartExportPixelRatio(
      logicalWidth: chartSize,
      logicalHeight: chartSize,
      devicePixelRatio: 3,
    );

    expect(
      ratio,
      closeTo(kChartPdfEmbedMaxHeight / chartSize, 0.01),
    );
    expect(
      chartCaptureFitsPdfEmbedBounds(
        logicalWidth: chartSize,
        logicalHeight: chartSize,
        pixelRatio: ratio,
      ),
      isTrue,
    );
  });
}
