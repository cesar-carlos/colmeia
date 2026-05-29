import 'dart:developer' as developer;

import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/export/report_excel_exporter.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_filter_formatter.dart';
import 'package:colmeia/shared/widgets/reports/export/report_pdf_exporter.dart';
import 'package:colmeia/shared/widgets/reports/export/report_text_exporter.dart';
import 'package:flutter/material.dart';

/// Facade that dispatches report export requests to the per-format exporter
/// (PDF, Excel, JSON, CSV). Each format lives in its own class under
/// `reports/export/` so this entry point stays a thin coordinator.
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
    List<AppReportFilterDescriptor>? filters,
    Map<String, Object?>? filterValues,
    BuildContext? context,
  }) async {
    final effectiveTitle = request.title ?? title;
    final effectiveSubtitle = request.subtitle ?? subtitle;
    final resolvedFilters = ReportExportFilterFormatter.resolve(
      filters,
      filterValues,
    );

    try {
      switch (request.format) {
        case AppReportExportFormat.pdf:
          await ReportPdfExporter.export<T>(
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
          await ReportExcelExporter.export<T>(
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
          await ReportTextExporter.exportJson<T>(
            columns: columns,
            rows: rows,
            title: effectiveTitle,
          );
        case AppReportExportFormat.csv:
          await ReportTextExporter.exportCsv<T>(
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
}
