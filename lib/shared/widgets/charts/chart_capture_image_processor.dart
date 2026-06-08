import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Target pixel width for chart images embedded in A4 landscape PDFs
/// (~150–200 DPI of the usable page width).
const int kChartPdfEmbedMaxWidth = 1550;

/// Target pixel height for chart images embedded in A4 landscape PDFs.
const int kChartPdfEmbedMaxHeight = 520;

/// Downscales [pngBytes] to fit within [kChartPdfEmbedMaxWidth] ×
/// [kChartPdfEmbedMaxHeight] while preserving aspect ratio.
///
/// Returns the original bytes when already within bounds or when decoding fails.
Future<Uint8List> downscalePngForPdfEmbed(Uint8List pngBytes) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      if (image.width <= kChartPdfEmbedMaxWidth &&
          image.height <= kChartPdfEmbedMaxHeight) {
        return pngBytes;
      }

      final scale = math.min(
        kChartPdfEmbedMaxWidth / image.width,
        kChartPdfEmbedMaxHeight / image.height,
      );
      if (scale >= 1) {
        return pngBytes;
      }

      final targetWidth = math.max(1, (image.width * scale).round());
      final targetHeight = math.max(1, (image.height * scale).round());

      final picture = _recordScaledImage(
        image: image,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final resized = await picture.toImage(targetWidth, targetHeight);
      picture.dispose();
      try {
        final byteData =
            await resized.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          return pngBytes;
        }
        return byteData.buffer.asUint8List();
      } finally {
        resized.dispose();
      }
    } finally {
      image.dispose();
    }
  } on Object {
    return pngBytes;
  } finally {
    codec.dispose();
  }
}

ui.Picture _recordScaledImage({
  required ui.Image image,
  required int targetWidth,
  required int targetHeight,
}) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    ),
    Paint(),
  );
  return recorder.endRecording();
}

/// Decodes PNG dimensions for tests and diagnostics.
Future<({int width, int height})?> decodePngDimensions(
  Uint8List pngBytes,
) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      return (width: image.width, height: image.height);
    } finally {
      image.dispose();
    }
  } on Object {
    return null;
  } finally {
    codec.dispose();
  }
}
