import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_pdf_page_label.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Serializable payload for PDF generation in a background isolate.
class ChartPdfBuildPayload {
  const ChartPdfBuildPayload({
    required this.title,
    this.headerFontBytes,
    this.bodyFontBytes,
    this.subtitle,
    this.filterSummary,
    this.tableHeaders = const <String>[],
    this.tableRows = const <List<String>>[],
    this.chartImagePngBytes,
    this.pageNumberLabelTemplate,
    this.pdfOrientation = ChartSharePdfOrientation.portrait,
  });

  final String title;
  final String? subtitle;
  final String? filterSummary;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final Uint8List? chartImagePngBytes;
  final Uint8List? headerFontBytes;
  final Uint8List? bodyFontBytes;
  final String? pageNumberLabelTemplate;
  final ChartSharePdfOrientation pdfOrientation;
}

pw.Font _resolveHeaderFont(Uint8List? bytes) {
  if (bytes == null) {
    return pw.Font.helveticaBold();
  }
  return pw.Font.ttf(ByteData.sublistView(bytes));
}

pw.Font _resolveBodyFont(Uint8List? bytes) {
  if (bytes == null) {
    return pw.Font.helvetica();
  }
  return pw.Font.ttf(ByteData.sublistView(bytes));
}

Future<Uint8List> buildChartPdfInIsolate(ChartPdfBuildPayload payload) async {
  final headerFont = _resolveHeaderFont(payload.headerFontBytes);
  final bodyFont = _resolveBodyFont(payload.bodyFontBytes);
  final layout = ChartPdfLayoutMetrics.forOrientation(payload.pdfOrientation);
  final pageFormat = layout.pageFormat;
  final hasTable =
      payload.tableHeaders.isNotEmpty && payload.tableRows.isNotEmpty;
  final pageLabelTemplate =
      payload.pageNumberLabelTemplate ?? 'Page {page} of {pages}';

  final doc = pw.Document()
    ..addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        header: (ctx) => _buildHeader(
          title: payload.title,
          subtitle: payload.subtitle,
          filterSummary: payload.filterSummary,
          headerFont: headerFont,
          bodyFont: bodyFont,
          bottomGap: layout.headerBottomGap,
        ),
        footer: (ctx) => _buildFooter(
          ctx,
          bodyFont,
          pageLabelTemplate: pageLabelTemplate,
        ),
        build: (ctx) => <pw.Widget>[
          if (payload.chartImagePngBytes != null &&
              payload.chartImagePngBytes!.isNotEmpty) ...<pw.Widget>[
            _buildChartImage(
              bytes: payload.chartImagePngBytes!,
              pageFormat: pageFormat,
              maxHeightFraction: layout.imageMaxHeightFraction,
            ),
            if (hasTable) pw.SizedBox(height: layout.sectionGap),
          ],
          if (hasTable)
            _buildTable(
              headers: payload.tableHeaders,
              rows: payload.tableRows,
              headerFont: headerFont,
              bodyFont: bodyFont,
              pageFormat: pageFormat,
            ),
        ],
      ),
    );

  return Uint8List.fromList(await doc.save());
}

pw.Widget _buildChartImage({
  required Uint8List bytes,
  required PdfPageFormat pageFormat,
  required double maxHeightFraction,
}) {
  return pw.Center(
    child: pw.ConstrainedBox(
      constraints: pw.BoxConstraints(
        maxWidth: pageFormat.availableWidth,
        maxHeight: pageFormat.availableHeight * maxHeightFraction,
      ),
      child: pw.Image(pw.MemoryImage(bytes)),
    ),
  );
}

pw.Widget _buildHeader({
  required String title,
  required pw.Font headerFont,
  required pw.Font bodyFont,
  required double bottomGap,
  String? subtitle,
  String? filterSummary,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(
        title,
        style: pw.TextStyle(font: headerFont, fontSize: 16),
      ),
      if (subtitle != null) ...<pw.Widget>[
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 11,
            color: PdfColors.grey700,
          ),
        ),
      ],
      if (filterSummary != null && filterSummary.isNotEmpty) ...<pw.Widget>[
        pw.SizedBox(height: 6),
        pw.Text(
          filterSummary,
          style: pw.TextStyle(
            font: bodyFont,
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
      pw.SizedBox(height: bottomGap),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: bottomGap),
    ],
  );
}

pw.Widget _buildFooter(
  pw.Context ctx,
  pw.Font font, {
  required String pageLabelTemplate,
}) {
  final pageLabel = formatPdfPageLabel(
    pageLabelTemplate,
    ctx.pageNumber,
    ctx.pagesCount,
  );
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: <pw.Widget>[
      pw.Text(
        DateTime.now().toLocal().toString().substring(0, 16),
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: PdfColors.grey600,
        ),
      ),
      pw.Text(
        pageLabel,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: PdfColors.grey600,
        ),
      ),
    ],
  );
}

pw.Widget _buildTable({
  required List<String> headers,
  required List<List<String>> rows,
  required pw.Font headerFont,
  required pw.Font bodyFont,
  required PdfPageFormat pageFormat,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(font: headerFont, fontSize: 9),
    cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    rowDecoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
    ),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    columnWidths: chartPdfTableColumnWidths(
      headers: headers,
      rows: rows,
      availableWidth: pageFormat.availableWidth,
    ),
  );
}
