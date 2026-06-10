import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_pdf_build_isolate.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_isolate_runner_stub.dart'
    if (dart.library.io) 'package:colmeia/shared/widgets/charts/chart_pdf_isolate_runner_io.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_page_label.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/export/pdf_export_font_cache.dart';

/// Builds a PDF document for chart sharing (title, optional filters, table, image).
abstract final class ChartPdfExporter {
  /// Preloads Google Fonts used by chart PDF exports.
  static Future<void> warmFonts() => PdfExportFontCache.warmFonts();

  static Future<Uint8List> build({
    required String title,
    String? subtitle,
    String? filterSummary,
    ChartShareTableData? tableData,
    Uint8List? chartImagePngBytes,
    ChartSharePdfOrientation pdfOrientation = ChartSharePdfOrientation.portrait,
    String Function(int page, int pages)? pageNumberLabelBuilder,
  }) async {
    final headerFontBytes = await PdfExportFontCache.headerFontBytes();
    final bodyFontBytes = await PdfExportFontCache.bodyFontBytes();

    final hasTable = tableData != null && !tableData.isEmpty;
    final payload = ChartPdfBuildPayload(
      title: title,
      subtitle: subtitle,
      filterSummary: filterSummary,
      tableHeaders: hasTable ? tableData.headers : const <String>[],
      tableRows: hasTable ? tableData.rows : const <List<String>>[],
      chartImagePngBytes: chartImagePngBytes,
      headerFontBytes: headerFontBytes,
      bodyFontBytes: bodyFontBytes,
      pageNumberLabelTemplate: pageLabelTemplateFromBuilder(
        pageNumberLabelBuilder,
      ),
      pdfOrientation: pdfOrientation,
    );

    return runChartPdfBuild(payload);
  }
}
