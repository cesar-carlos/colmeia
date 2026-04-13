import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, XFile;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Stateless utility that produces PDF, Excel, JSON, or CSV output from a
/// typed report.
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
  // Automatically switch to landscape when visible column count exceeds this.
  static const int _autoLandscapeColumnThreshold = 6;

  // When scaling fixed-width columns to fit the page, reserve this fraction
  // of the available width for flex columns so they are never squeezed to zero.
  static const double _minFlexFraction = 0.20;

  static Future<void> export<T>({
    required AppReportExportRequest request,
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
    String? subtitle,
    List<AppReportSummaryItem>? summaryItems,
    List<AppReportFilterDescriptor>? filters,
    Map<String, Object?>? filterValues,
    BuildContext? context,
  }) async {
    final effectiveTitle = request.title ?? title;
    final effectiveSubtitle = request.subtitle ?? subtitle;
    final resolvedFilters = _buildResolvedFilters(filters, filterValues);

    try {
      switch (request.format) {
        case AppReportExportFormat.pdf:
          await _exportPdf<T>(
            request: request,
            columns: columns,
            rows: rows,
            title: effectiveTitle,
            subtitle: effectiveSubtitle,
            summaryItems: summaryItems,
            resolvedFilters: resolvedFilters,
            context: context,
          );
        case AppReportExportFormat.excel:
          await _exportExcel<T>(
            request: request,
            columns: columns,
            rows: rows,
            title: effectiveTitle,
            subtitle: effectiveSubtitle,
            summaryItems: summaryItems,
            resolvedFilters: resolvedFilters,
            context: context,
          );
        case AppReportExportFormat.json:
          await _exportJson<T>(
            columns: columns,
            rows: rows,
            title: effectiveTitle,
          );
        case AppReportExportFormat.csv:
          await _exportCsv<T>(
            columns: columns,
            rows: rows,
            title: effectiveTitle,
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
    List<({String label, String value})>? resolvedFilters,
    BuildContext? context,
  }) async {
    final doc = pw.Document();
    final l10n = context != null ? AppLocalizations.of(context) : null;
    final filtersTitle =
        l10n?.reportFiltersAppliedSectionTitle ?? 'Applied filters';
    final useLandscape =
        request.landscape ||
        (request.autoLandscape &&
            columns.length > _autoLandscapeColumnThreshold);
    final pageFormat = useLandscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

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
          if (request.includeFilters && (resolvedFilters?.isNotEmpty ?? false))
            _buildPdfFilters(
              resolvedFilters!,
              bodyFont,
              headerFont,
              filtersTitle,
            ),
          if (request.includeFilters && (resolvedFilters?.isNotEmpty ?? false))
            pw.SizedBox(height: 8),
          if (request.includeSummary && (summaryItems?.isNotEmpty ?? false))
            _buildPdfSummary(summaryItems!, bodyFont, headerFont),
          pw.SizedBox(height: 8),
          _buildPdfTable<T>(
            columns: columns,
            rows: rows,
            headerFont: headerFont,
            bodyFont: bodyFont,
            pageFormat: pageFormat,
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
      await _shareExportBytes(
        format: AppReportExportFormat.pdf,
        bytes: Uint8List.fromList(await doc.save()),
        title: title,
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
      children: items
          .map((item) {
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
          })
          .toList(growable: false),
    );
  }

  static pw.Widget _buildPdfFilters(
    List<({String label, String value})> filters,
    pw.Font bodyFont,
    pw.Font headerFont,
    String sectionTitle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          sectionTitle,
          style: pw.TextStyle(font: headerFont, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        ...filters.map((filter) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: bodyFont, fontSize: 9),
                children: <pw.InlineSpan>[
                  pw.TextSpan(
                    text: '${filter.label}: ',
                    style: pw.TextStyle(font: headerFont, fontSize: 9),
                  ),
                  pw.TextSpan(text: filter.value),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildPdfTable<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    required pw.Font headerFont,
    required pw.Font bodyFont,
    required PdfPageFormat pageFormat,
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
      columnWidths: _pdfColumnWidths(columns, pageFormat),
    );
  }

  static Map<int, pw.TableColumnWidth> _pdfColumnWidths<T>(
    List<AppReportColumn<T>> columns,
    PdfPageFormat pageFormat,
  ) {
    final available = pageFormat.availableWidth;

    // Sum of all explicitly fixed widths (Syncfusion px → PDF pt via 0.75).
    var totalFixed = 0.0;
    var flexCount = 0;
    for (final col in columns) {
      if (col.width != null) {
        totalFixed += col.width! * 0.75;
      } else {
        flexCount++;
      }
    }

    // Reserve a share of the page for flex columns so they are never zero.
    final fixedBudget = flexCount > 0
        ? available * (1 - _minFlexFraction)
        : available;
    final scale = totalFixed > fixedBudget && totalFixed > 0
        ? fixedBudget / totalFixed
        : 1.0;

    final result = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      if (col.width != null) {
        result[i] = pw.FixedColumnWidth(col.width! * 0.75 * scale);
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
    String? subtitle,
    List<AppReportSummaryItem>? summaryItems,
    List<({String label, String value})>? resolvedFilters,
    BuildContext? context,
  }) async {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    final filtersTitle =
        l10n?.reportFiltersAppliedSectionTitle ?? 'Applied filters';
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0]
      ..name = _sanitizeSheetName(title ?? 'Relatório');

    var rowIndex = 1;

    if (request.includeHeaders && title != null) {
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, columns.length)
        ..merge()
        ..setText(title)
        ..cellStyle.fontSize = 14
        ..cellStyle.bold = true;
      rowIndex++;
    }

    if (request.includeHeaders && subtitle != null) {
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, columns.length)
        ..merge()
        ..setText(subtitle)
        ..cellStyle.fontSize = 10
        ..cellStyle.fontColorRgb = const Color(0xFF666666);
      rowIndex++;
    }

    if (request.includeHeaders && (title != null || subtitle != null)) {
      rowIndex++;
    }

    if (request.includeFilters && (resolvedFilters?.isNotEmpty ?? false)) {
      sheet.getRangeByIndex(rowIndex, 1).setText(filtersTitle);
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = true;
      rowIndex++;

      for (final filter in resolvedFilters!) {
        sheet.getRangeByIndex(rowIndex, 1).setText(filter.label);
        sheet.getRangeByIndex(rowIndex, 2).setText(filter.value);
        rowIndex++;
      }
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
      sheet.getRangeByIndex(1, colIndex + 1).columnWidth = col.width != null
          ? col.width! / 7
          : 15;
    }

    sheet.autoFilters.filterRange = sheet.getRangeByIndex(
      headerRowIndex,
      1,
      headerRowIndex,
      columns.length,
    );

    final bytes = Uint8List.fromList(workbook.saveAsStream());
    workbook.dispose();

    await _shareExportBytes(
      format: AppReportExportFormat.excel,
      bytes: bytes,
      title: title,
    );
  }

  // -------------------------------------------------------------------------
  // JSON / CSV
  // -------------------------------------------------------------------------

  static Future<void> _exportJson<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
  }) async {
    final objects = <Map<String, Object?>>[];
    for (final row in rows) {
      final map = <String, Object?>{};
      for (final col in columns) {
        map[col.key] = _exportCellValue(col, row);
      }
      objects.add(map);
    }
    final str = const JsonEncoder.withIndent('  ').convert(objects);
    final bytes = Uint8List.fromList(utf8.encode(str));
    await _shareExportBytes(
      format: AppReportExportFormat.json,
      bytes: bytes,
      title: title,
    );
  }

  static Future<void> _exportCsv<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
    String? title,
  }) async {
    final buffer = StringBuffer()
      ..writeln(columns.map((c) => _escapeCsvField(c.label)).join(','));
    for (final row in rows) {
      final line = columns
          .map((col) => _escapeCsvField(col.formatValue(col.valueGetter(row))))
          .join(',');
      buffer.writeln(line);
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await _shareExportBytes(
      format: AppReportExportFormat.csv,
      bytes: bytes,
      title: title,
    );
  }

  static Object? _exportCellValue<T>(AppReportColumn<T> col, T row) {
    final v = col.valueGetter(row);
    if (v == null) {
      return null;
    }
    if (v is num || v is bool) {
      return v;
    }
    if (v is String) {
      return v;
    }
    return col.formatValue(v);
  }

  static String _escapeCsvField(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static Future<void> _shareExportBytes({
    required AppReportExportFormat format,
    required Uint8List bytes,
    String? title,
  }) async {
    final fileName =
        '${_sanitizeFileName(title ?? 'relatorio')}.${format.fileExtension}';
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: format.mimeType,
          ),
        ],
        subject: title ?? 'Relatório',
      ),
    );
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  static String _sanitizeSheetName(String name) {
    final clean = name.replaceAll(RegExp(r'[/\\?*\[\]:]'), '');
    return clean.length > 31 ? clean.substring(0, 31) : clean;
  }

  static List<({String label, String value})> _buildResolvedFilters(
    List<AppReportFilterDescriptor>? filters,
    Map<String, Object?>? filterValues,
  ) {
    if (filters == null || filters.isEmpty || filterValues == null) {
      return const <({String label, String value})>[];
    }

    final result = <({String label, String value})>[];
    for (final filter in filters) {
      final rawValue = filterValues[filter.name];
      final formattedValue = _formatFilterValue(filter, rawValue);
      if (formattedValue == null || formattedValue.isEmpty) {
        continue;
      }
      result.add((label: filter.label, value: formattedValue));
    }
    return result;
  }

  static String? _formatFilterValue(
    AppReportFilterDescriptor filter,
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return _resolveFilterOptionLabel(filter, trimmed);
    }

    if (value is bool) {
      return value ? 'Sim' : 'Não';
    }

    if (value is DateTime) {
      return DateFormat('dd/MM/yyyy').format(value);
    }

    if (value is num) {
      return NumberFormat.decimalPattern('pt_BR').format(value);
    }

    if (value is Iterable) {
      final labels = value
          .map((item) => _formatFilterValue(filter, item))
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (labels.isEmpty) {
        return null;
      }
      return labels.join(', ');
    }

    return value.toString();
  }

  static String _resolveFilterOptionLabel(
    AppReportFilterDescriptor filter,
    String value,
  ) {
    for (final option in filter.options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return value;
  }
}
