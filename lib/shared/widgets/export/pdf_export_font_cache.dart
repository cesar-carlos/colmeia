import 'dart:async';

import 'package:colmeia/shared/design_system/app_font_families.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

const Duration _kPdfFontWarmTimeout = Duration(seconds: 15);

/// Shared Inter font cache for chart and report PDF exports.
abstract final class PdfExportFontCache {
  static late pw.Font _headerFont;
  static late pw.Font _bodyFont;
  static Uint8List? _headerFontBytes;
  static Uint8List? _bodyFontBytes;
  static bool _fontsLoaded = false;
  static Future<void>? _loading;

  /// Whether PDF export fonts are already available without awaiting network I/O.
  static bool get isWarmed => _fontsLoaded;

  /// Preloads bundled Inter fonts used by PDF exports.
  static Future<void> warmFonts() {
    if (_fontsLoaded) {
      return Future<void>.value();
    }
    return _loading ??= _ensureFontsLoaded();
  }

  static Future<void> _ensureFontsLoaded() async {
    if (_fontsLoaded) {
      return;
    }
    try {
      final headerData = await rootBundle
          .load(AppFontAssets.interBold)
          .timeout(_kPdfFontWarmTimeout);
      final bodyData = await rootBundle
          .load(AppFontAssets.interRegular)
          .timeout(_kPdfFontWarmTimeout);
      _headerFontBytes = headerData.buffer.asUint8List();
      _bodyFontBytes = bodyData.buffer.asUint8List();
      _headerFont = pw.Font.ttf(headerData);
      _bodyFont = pw.Font.ttf(bodyData);
    } on Object {
      _headerFont = pw.Font.helveticaBold();
      _bodyFont = pw.Font.helvetica();
      _headerFontBytes = null;
      _bodyFontBytes = null;
    }
    _fontsLoaded = true;
  }

  static Future<pw.Font> headerFont() async {
    await warmFonts();
    return _headerFont;
  }

  static Future<pw.Font> bodyFont() async {
    await warmFonts();
    return _bodyFont;
  }

  static Future<Uint8List?> headerFontBytes() async {
    await warmFonts();
    return _headerFontBytes;
  }

  static Future<Uint8List?> bodyFontBytes() async {
    await warmFonts();
    return _bodyFontBytes;
  }
}
