import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_pdf_build_isolate.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_isolate_runner_stub.dart'
    if (dart.library.io) 'package:colmeia/shared/widgets/charts/chart_pdf_isolate_runner_io.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_page_label.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a PDF document for chart sharing (title, optional filters, table, image).
abstract final class ChartPdfExporter {
  static Uint8List? _headerFontBytes;
  static Uint8List? _bodyFontBytes;
  static bool _fontsLoaded = false;

  /// Preloads Google Fonts used by chart PDF exports.
  static Future<void> warmFonts() => _ensureFontsLoaded();

  static Future<void> _ensureFontsLoaded() async {
    if (_fontsLoaded) {
      return;
    }
    final headerFont = await PdfGoogleFonts.interBold();
    final bodyFont = await PdfGoogleFonts.interRegular();
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

  static Future<Uint8List> build({
    required String title,
    String? subtitle,
    String? filterSummary,
    ChartShareTableData? tableData,
    Uint8List? chartImagePngBytes,
    String Function(int page, int pages)? pageNumberLabelBuilder,
  }) async {
    await _ensureFontsLoaded();

    final hasTable = tableData != null && !tableData.isEmpty;
    final payload = ChartPdfBuildPayload(
      title: title,
      subtitle: subtitle,
      filterSummary: filterSummary,
      tableHeaders: hasTable ? tableData.headers : const <String>[],
      tableRows: hasTable ? tableData.rows : const <List<String>>[],
      chartImagePngBytes: chartImagePngBytes,
      headerFontBytes: _headerFontBytes,
      bodyFontBytes: _bodyFontBytes,
      pageNumberLabelTemplate:
          pageLabelTemplateFromBuilder(pageNumberLabelBuilder),
    );

    return runChartPdfBuild(payload);
  }
}
