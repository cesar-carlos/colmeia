import 'dart:typed_data';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_table_alignment.dart';
import 'package:colmeia/shared/widgets/export/pdf_export_font_cache.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Produces and shares/prints PDF output for a typed report.
abstract final class ReportPdfExporter {
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

    final headerFont = await PdfExportFontCache.headerFont();
    final bodyFont = await PdfExportFontCache.bodyFont();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        header: request.includeHeaders
            ? (ctx) => _buildHeader(ctx, title, subtitle, headerFont)
            : null,
        footer: (ctx) => _buildFooter(ctx, bodyFont),
        build: (ctx) => <pw.Widget>[
          if (request.includeFilters && (resolvedFilters?.isNotEmpty ?? false))
            _buildFilters(
              resolvedFilters!,
              bodyFont,
              headerFont,
              filtersTitle,
            ),
          if (request.includeFilters && (resolvedFilters?.isNotEmpty ?? false))
            pw.SizedBox(height: 8),
          if (request.includeSummary && (summaryItems?.isNotEmpty ?? false))
            _buildSummary(summaryItems!, bodyFont, headerFont),
          pw.SizedBox(height: 8),
          _buildTable<T>(
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
      await shareReportExportBytes(
        format: AppReportExportFormat.pdf,
        bytes: Uint8List.fromList(await doc.save()),
        title: title,
      );
    }
  }

  static pw.Widget _buildHeader(
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

  static pw.Widget _buildSummary(
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

  static pw.Widget _buildFilters(
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

  static pw.Widget _buildTable<T>({
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
    final alignments = resolveChartPdfTableAlignments(
      headers: headers,
      rows: data,
    );
    final zebra = chartPdfTableZebraRowDecorations();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 9),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      rowDecoration: zebra.rowDecoration,
      oddRowDecoration: zebra.oddRowDecoration,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      cellAlignments: alignments.cellAlignments,
      headerAlignments: alignments.headerAlignments,
      columnWidths: _columnWidths(columns, pageFormat),
    );
  }

  static Map<int, pw.TableColumnWidth> _columnWidths<T>(
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
}
