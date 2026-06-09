import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

/// Share + PDF metadata built once per chart and reused for inline and
/// fullscreen share actions.
class ChartShareMetadata {
  const ChartShareMetadata({
    required this.title,
    this.subtitle,
    this.filterSummary,
    this.tableData,
    this.chartExportBuilder,
    this.includeChartImage,
    this.pdfOrientation = ChartSharePdfOrientation.portrait,
    String? subject,
  }) : subject = subject ?? title;

  final String title;
  final String? subtitle;
  final String? filterSummary;
  final ChartShareTableData? tableData;
  final ChartSharePdfOrientation pdfOrientation;

  /// When set, builds a full-width chart for offscreen PDF capture instead of
  /// the on-screen scroll viewport behind the share capture key.
  ///
  /// Leave null to use the table-only fast path when [tableData] is non-empty:
  /// share capture skips boundary and dedicated export rasterization and
  /// builds a PDF from the table alone.
  final WidgetBuilder? chartExportBuilder;

  /// When `null` (default), chart image capture follows the current auto rules:
  /// skip when [tableData] is non-empty and [chartExportBuilder] is null.
  /// Set to `false` to skip capture even when [chartExportBuilder] is set (table
  /// export only, faster share). Set to `true` to force capture attempts.
  final bool? includeChartImage;
  final String subject;

  AppChartShareRequest toShareRequest(GlobalKey captureKey) {
    return AppChartShareRequest(
      captureKey: captureKey,
      subject: subject,
      title: title,
      subtitle: subtitle,
      filterSummary: filterSummary,
      tableData: tableData,
      chartExportBuilder: chartExportBuilder,
      includeChartImage: includeChartImage,
      pdfOrientation: pdfOrientation,
    );
  }

  AppChartFullscreenRequest toFullscreenRequest({
    required WidgetBuilder chartBuilder,
    required GlobalKey shareCaptureKey,
    String? semanticsLabel,
    AppChartFullscreenHeaderTrailingBuilder? headerTrailingBuilder,
  }) {
    return AppChartFullscreenRequest(
      title: title,
      subtitle: subtitle,
      filterSummary: filterSummary,
      semanticsLabel: semanticsLabel,
      shareCaptureKey: shareCaptureKey,
      shareSubject: subject,
      tableData: tableData,
      chartBuilder: chartBuilder,
      headerTrailingBuilder: headerTrailingBuilder,
    );
  }
}

/// Resolves whether chart image capture should run for a PDF share request.
bool resolveChartShareIncludeChartImage({
  required bool? includeChartImage,
  required bool hasTable,
  required bool hasExportBuilder,
}) {
  if (includeChartImage == false) {
    return false;
  }
  if (includeChartImage == true) {
    return true;
  }
  return !(hasTable && !hasExportBuilder);
}
