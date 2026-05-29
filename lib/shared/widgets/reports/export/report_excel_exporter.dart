import 'dart:typed_data';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

/// Produces and shares an XLSX workbook for a typed report.
abstract final class ReportExcelExporter {
  static Future<void> export<T>({
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

    await shareReportExportBytes(
      format: AppReportExportFormat.excel,
      bytes: bytes,
      title: title,
    );
  }

  static String _sanitizeSheetName(String name) {
    final clean = name.replaceAll(RegExp(r'[/\\?*\[\]:]'), '');
    return clean.length > 31 ? clean.substring(0, 31) : clean;
  }
}
