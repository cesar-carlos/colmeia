import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, XFile;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Stateless utility that produces PDF or Excel output from a typed report.
///
/// Usage:
/// ```dart
/// await AppReportExportHandler.export(
///   request: AppReportExportRequest(format: AppReportExportFormat.pdf),
///   columns: visibleColumns,
///   rows: allRows,
///   title: 'Vendas por loja',
/// );
/// ```
abstract final class AppReportExportHandler {
  static Future<void> export<T>({
    required AppReportExportRequest request,
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
    String? subtitle,
    List<AppReportSummaryItem>? summaryItems,
    BuildContext? context,
  }) async {
    try {
      switch (request.format) {
        case AppReportExportFormat.pdf:
          await _exportPdf<T>(
            request: request,
            columns: columns,
            rows: rows,
            title: title,
            subtitle: subtitle,
            summaryItems: summaryItems,
            context: context,
          );
        case AppReportExportFormat.excel:
          await _exportExcel<T>(
            request: request,
            columns: columns,
            rows: rows,
            title: title,
            summaryItems: summaryItems,
          );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Export failed: ${request.format.name}',
        name: 'colmeia.report_export',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // PDF
  // -------------------------------------------------------------------------

  static Future<void> _exportPdf<T>({
    required AppReportExportRequest request,
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
    String? subtitle,
    List<AppReportSummaryItem>? summaryItems,
    BuildContext? context,
  }) async {
    final doc = pw.Document();
    final pageFormat =
        request.landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    final headerFont = await PdfGoogleFonts.interBold();
    final bodyFont = await PdfGoogleFonts.interRegular();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        header: request.includeHeaders
            ? (ctx) => _buildPdfHeader(ctx, title, subtitle, headerFont)
            : null,
        footer: (ctx) => _buildPdfFooter(ctx, bodyFont),
        build: (ctx) => <pw.Widget>[
          if (request.includeSummary && (summaryItems?.isNotEmpty ?? false))
            _buildPdfSummary(summaryItems!, bodyFont, headerFont),
          pw.SizedBox(height: 8),
          _buildPdfTable<T>(
            columns: columns,
            rows: rows,
            headerFont: headerFont,
            bodyFont: bodyFont,
          ),
        ],
      ),
    );

    if (context != null && context.mounted) {
      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: title ?? 'relatorio',
      );
    } else {
      final bytes = await doc.save();
      final fileName = '${_sanitizeFileName(title ?? 'relatorio')}.pdf';
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: fileName,
              mimeType: 'application/pdf',
            ),
          ],
          subject: title ?? 'Relatório',
        ),
      );
    }
  }

  static pw.Widget _buildPdfHeader(
    pw.Context ctx,
    String? title,
    String? subtitle,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        if (title != null)
          pw.Text(
            title,
            style: pw.TextStyle(font: font, fontSize: 16),
          ),
        if (subtitle != null)
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context ctx, pw.Font font) {
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

  static pw.Widget _buildPdfSummary(
    List<AppReportSummaryItem> items,
    pw.Font bodyFont,
    pw.Font headerFont,
  ) {
    return pw.Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              item.label,
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              item.value,
              style: pw.TextStyle(font: headerFont, fontSize: 13),
            ),
          ],
        );
      }).toList(growable: false),
    );
  }

  static pw.Widget _buildPdfTable<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    required pw.Font headerFont,
    required pw.Font bodyFont,
  }) {
    final headers = columns.map((c) => c.label).toList(growable: false);
    final data = rows.map<List<String>>((row) {
      return columns.map((c) => c.formatValue(c.valueGetter(row))).toList();
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 9),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: _pdfColumnWidths(columns),
    );
  }

  static Map<int, pw.TableColumnWidth> _pdfColumnWidths<T>(
    List<AppReportColumn<T>> columns,
  ) {
    final result = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      if (col.width != null) {
        result[i] = pw.FixedColumnWidth(col.width! * 0.75);
      } else if (col.flex != null) {
        result[i] = pw.FlexColumnWidth(col.flex!.toDouble());
      } else {
        result[i] = const pw.FlexColumnWidth();
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Excel
  // -------------------------------------------------------------------------

  static Future<void> _exportExcel<T>({
    required AppReportExportRequest request,
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
    List<AppReportSummaryItem>? summaryItems,
  }) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0]
      ..name = _sanitizeSheetName(title ?? 'Relatório');

    var rowIndex = 1;

    if (title != null) {
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, columns.length)
        ..merge()
        ..setText(title)
        ..cellStyle.fontSize = 14
        ..cellStyle.bold = true;
      rowIndex++;
    }

    if (request.includeSummary && (summaryItems?.isNotEmpty ?? false)) {
      for (final item in summaryItems!) {
        sheet.getRangeByIndex(rowIndex, 1).setText(item.label);
        sheet.getRangeByIndex(rowIndex, 2).setText(item.value);
        rowIndex++;
      }
      rowIndex++;
    }

    final headerRowIndex = rowIndex;
    for (var colIndex = 0; colIndex < columns.length; colIndex++) {
      sheet.getRangeByIndex(rowIndex, colIndex + 1)
        ..setText(columns[colIndex].label)
        ..cellStyle.bold = true
        ..cellStyle.backColorRgb = const Color(0xFFEEEEEE);
    }
    rowIndex++;

    for (final row in rows) {
      for (var colIndex = 0; colIndex < columns.length; colIndex++) {
        final col = columns[colIndex];
        final value = col.valueGetter(row);
        final cell = sheet.getRangeByIndex(rowIndex, colIndex + 1);
        if (value is num) {
          cell.setNumber(value.toDouble());
        } else if (value is DateTime) {
          cell.setDateTime(value);
        } else {
          cell.setText(col.formatValue(value));
        }
      }
      rowIndex++;
    }

    for (var colIndex = 0; colIndex < columns.length; colIndex++) {
      final col = columns[colIndex];
      sheet.getRangeByIndex(1, colIndex + 1).columnWidth =
          col.width != null ? col.width! / 7 : 15;
    }

    sheet.autoFilters.filterRange = sheet.getRangeByIndex(
      headerRowIndex,
      1,
      headerRowIndex,
      columns.length,
    );

    final bytes = Uint8List.fromList(workbook.saveAsStream());
    workbook.dispose();

    final fileName = '${_sanitizeFileName(title ?? 'relatorio')}.xlsx';
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument'
                '.spreadsheetml.sheet',
          ),
        ],
        subject: title ?? 'Relatório',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
  }

  static String _sanitizeSheetName(String name) {
    final clean = name.replaceAll(RegExp(r'[/\\?*\[\]:]'), '');
    return clean.length > 31 ? clean.substring(0, 31) : clean;
  }
}
