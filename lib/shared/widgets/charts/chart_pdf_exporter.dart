import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a PDF document for chart sharing (title, optional filters, table, image).
abstract final class ChartPdfExporter {
  static Future<Uint8List> build({
    required String title,
    String? subtitle,
    String? filterSummary,
    ChartShareTableData? tableData,
    Uint8List? chartImagePngBytes,
  }) async {
    final doc = pw.Document();
    final headerFont = await PdfGoogleFonts.interBold();
    final bodyFont = await PdfGoogleFonts.interRegular();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _buildHeader(
          title: title,
          subtitle: subtitle,
          filterSummary: filterSummary,
          headerFont: headerFont,
          bodyFont: bodyFont,
        ),
        footer: (ctx) => _buildFooter(ctx, bodyFont),
        build: (ctx) => <pw.Widget>[
          if (chartImagePngBytes != null && chartImagePngBytes.isNotEmpty) ...<pw.Widget>[
            pw.Center(
              child: pw.Image(pw.MemoryImage(chartImagePngBytes)),
            ),
            if (tableData != null && !tableData.isEmpty)
              pw.SizedBox(height: 16),
          ],
          if (tableData != null && !tableData.isEmpty)
            _buildTable(
              tableData: tableData,
              headerFont: headerFont,
              bodyFont: bodyFont,
            ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  static pw.Widget _buildHeader({
    required String title,
    required pw.Font headerFont,
    required pw.Font bodyFont,
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
        if (subtitle != null)
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        if (filterSummary != null && filterSummary.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 4),
          pw.Text(
            filterSummary,
            style: pw.TextStyle(
              font: bodyFont,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, pw.Font font) {
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
          'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable({
    required ChartShareTableData tableData,
    required pw.Font headerFont,
    required pw.Font bodyFont,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: tableData.headers,
      data: tableData.rows,
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 9),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}
