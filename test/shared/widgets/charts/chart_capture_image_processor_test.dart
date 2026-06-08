import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List encodeSolidPng({required int width, required int height}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(10, 20, 30));
    return Uint8List.fromList(img.encodePng(image));
  }

  test('downscalePngForPdfEmbed keeps small images unchanged', () async {
    final original = encodeSolidPng(width: 400, height: 200);
    final result = await downscalePngForPdfEmbed(original);

    expect(result, same(original));
    final dimensions = await decodePngDimensions(result);
    expect(dimensions?.width, 400);
    expect(dimensions?.height, 200);
  });

  test('downscalePngForPdfEmbed fits within PDF embed bounds', () async {
    final original = encodeSolidPng(width: 4000, height: 2000);
    final result = await downscalePngForPdfEmbed(original);
    final dimensions = await decodePngDimensions(result);

    expect(dimensions, isNotNull);
    expect(dimensions!.width, lessThanOrEqualTo(kChartPdfEmbedMaxWidth));
    expect(dimensions.height, lessThanOrEqualTo(kChartPdfEmbedMaxHeight));
  });

  test('downscalePngForPdfEmbed preserves aspect ratio', () async {
    final original = encodeSolidPng(width: 3100, height: 1040);
    final result = await downscalePngForPdfEmbed(original);
    final dimensions = await decodePngDimensions(result);

    expect(dimensions, isNotNull);
    final widthRatio = dimensions!.width / 3100;
    final heightRatio = dimensions.height / 1040;
    expect((widthRatio - heightRatio).abs(), lessThan(0.02));
  });
}
