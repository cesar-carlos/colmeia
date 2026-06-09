import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared Inter font cache for chart and report PDF exports.
abstract final class PdfExportFontCache {
  static late pw.Font _headerFont;
  static late pw.Font _bodyFont;
  static Uint8List? _headerFontBytes;
  static Uint8List? _bodyFontBytes;
  static bool _fontsLoaded = false;
  static Future<void>? _loading;

  /// Preloads Google Fonts used by PDF exports.
  static Future<void> warmFonts() {
    return _loading ??= _ensureFontsLoaded();
  }

  static Future<void> _ensureFontsLoaded() async {
    if (_fontsLoaded) {
      return;
    }
    final headerFont = await PdfGoogleFonts.interBold();
    final bodyFont = await PdfGoogleFonts.interRegular();
    _headerFont = headerFont;
    _bodyFont = bodyFont;
    _headerFontBytes = _optionalFontBytes(headerFont);
    _bodyFontBytes = _optionalFontBytes(bodyFont);
    _fontsLoaded = true;
  }

  static Uint8List? _optionalFontBytes(pw.Font font) {
    if (font is pw.TtfFont) {
      return font.data.buffer.asUint8List();
    }
    return null;
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
