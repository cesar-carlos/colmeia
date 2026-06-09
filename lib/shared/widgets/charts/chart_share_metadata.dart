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
    this.pdfOrientation = ChartSharePdfOrientation.portrait,
    String? subject,
  }) : subject = subject ?? title;

  final String title;
  final String? subtitle;
  final String? filterSummary;
  final ChartShareTableData? tableData;
  final ChartSharePdfOrientation pdfOrientation;

  /// When set, builds a full-width chart for PDF capture instead of the
  /// on-screen scroll viewport behind the share capture key.
  final WidgetBuilder? chartExportBuilder;
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
