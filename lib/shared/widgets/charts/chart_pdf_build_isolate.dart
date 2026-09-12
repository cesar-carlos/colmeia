import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_pdf_page_label.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_table_alignment.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
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
    this.tableFooterRows = const <List<String>>[],
    this.chartImagePngBytes,
    this.pageNumberLabelTemplate,
    this.pdfOrientation = ChartSharePdfOrientation.portrait,
  });

  final String title;
  final String? subtitle;
  final String? filterSummary;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final List<List<String>> tableFooterRows;
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
        maxPages: ChartSharePdfLimits.maxPdfPages,
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
            ..._buildPaginatedTables(
              headers: payload.tableHeaders,
              rows: payload.tableRows,
              footerRows: payload.tableFooterRows,
              headerFont: headerFont,
              bodyFont: bodyFont,
              pageFormat: pageFormat,
              sectionGap: layout.sectionGap,
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

List<pw.Widget> _buildPaginatedTables({
  required List<String> headers,
  required List<List<String>> rows,
  required List<List<String>> footerRows,
  required pw.Font headerFont,
  required pw.Font bodyFont,
  required PdfPageFormat pageFormat,
  required double sectionGap,
}) {
  final rowChunks = paginateChartShareTableRows(rows);
  if (rowChunks.isEmpty) {
    return const <pw.Widget>[];
  }

  final normalizedFooterRows = _normalizedTableFooterRows(
    footerRows: footerRows,
    columnCount: headers.length,
  );
  final columnWidths = chartPdfTableColumnWidths(
    headers: headers,
    rows: <List<String>>[...rows, ...normalizedFooterRows],
    availableWidth: pageFormat.availableWidth,
  );
  final alignments = resolveChartPdfTableAlignments(
    headers: headers,
    rows: rows,
  );

  return <pw.Widget>[
    for (var index = 0; index < rowChunks.length; index++) ...<pw.Widget>[
      if (index > 0) pw.SizedBox(height: sectionGap),
      _buildTable(
        headers: headers,
        rows: rowChunks[index],
        headerFont: headerFont,
        bodyFont: bodyFont,
        cellAlignments: alignments.cellAlignments,
        headerAlignments: alignments.headerAlignments,
        columnWidths: columnWidths,
      ),
      if (index == rowChunks.length - 1 && normalizedFooterRows.isNotEmpty)
        _buildTableFooter(
          footerRows: normalizedFooterRows,
          headerFont: headerFont,
          bodyFont: bodyFont,
          columnWidths: columnWidths,
        ),
    ],
  ];
}

pw.Widget _buildTable({
  required List<String> headers,
  required List<List<String>> rows,
  required pw.Font headerFont,
  required pw.Font bodyFont,
  required Map<int, pw.Alignment> cellAlignments,
  required Map<int, pw.Alignment> headerAlignments,
  required Map<int, pw.TableColumnWidth> columnWidths,
}) {
  final zebra = chartPdfTableZebraRowDecorations();

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(font: headerFont, fontSize: 9),
    cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    rowDecoration: zebra.rowDecoration,
    oddRowDecoration: zebra.oddRowDecoration,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    cellAlignments: cellAlignments,
    headerAlignments: headerAlignments,
    columnWidths: columnWidths,
  );
}

pw.Widget _buildTableFooter({
  required List<List<String>> footerRows,
  required pw.Font headerFont,
  required pw.Font bodyFont,
  required Map<int, pw.TableColumnWidth> columnWidths,
}) {
  return pw.Table(
    columnWidths: columnWidths,
    children: <pw.TableRow>[
      for (final row in footerRows)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
            ),
          ),
          children: <pw.Widget>[
            for (var index = 0; index < row.length; index++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                child: pw.Align(
                  alignment: index == row.length - 1
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
                  child: pw.Text(
                    row[index],
                    style: pw.TextStyle(
                      font: index == row.length - 1 ? headerFont : bodyFont,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

List<List<String>> _normalizedTableFooterRows({
  required List<List<String>> footerRows,
  required int columnCount,
}) {
  if (columnCount <= 0 || footerRows.isEmpty) {
    return const <List<String>>[];
  }

  return <List<String>>[
    for (final row in footerRows)
      <String>[
        for (var index = 0; index < columnCount; index++)
          if (index < row.length) row[index] else '',
      ],
  ];
}
