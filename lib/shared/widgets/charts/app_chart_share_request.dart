import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

/// App-agnostic description of a chart that wants to be shared as a PDF.
///
/// Shared chart widgets emit this request instead of depending on the app
/// layer; the app maps it to chart PDF sharing. This keeps the `shared/`
/// layer free of share orchestration details (DIP).
class AppChartShareRequest {
  const AppChartShareRequest({
    required this.captureKey,
    this.subject,
    this.title,
    this.subtitle,
    this.filterSummary,
    this.tableData,
    this.chartExportBuilder,
    this.pdfOrientation = ChartSharePdfOrientation.portrait,
  });

  final GlobalKey captureKey;
  final String? subject;
  final String? title;
  final String? subtitle;
  final String? filterSummary;
  final ChartShareTableData? tableData;
  final WidgetBuilder? chartExportBuilder;
  final ChartSharePdfOrientation pdfOrientation;
}

/// Callback emitted by a shared chart to request sharing its rendered output.
///
/// The [context] is the chart's own context, so callers do not need to capture
/// one separately.
typedef AppChartShareRequestCallback =
    void Function(BuildContext context, AppChartShareRequest request);
