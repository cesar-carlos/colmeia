import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_capture_helper.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:flutter/material.dart';

String chartShareFailureMessage(
  AppLocalizations l10n,
  ChartShareFailureReason reason,
) {
  return switch (reason) {
    ChartShareFailureReason.missingBoundary =>
      l10n.chartShareFailedMissingBoundary,
    ChartShareFailureReason.invalidRenderObject =>
      l10n.chartShareFailedInvalidRenderObject,
    ChartShareFailureReason.imageEncodingFailed =>
      l10n.chartShareFailedImageEncoding,
    ChartShareFailureReason.pdfGenerationFailed =>
      l10n.chartShareFailedPdfGeneration,
    ChartShareFailureReason.shareInProgress => l10n.chartShareFailedInProgress,
    ChartShareFailureReason.sharePlatformFailed => l10n.chartShareFailed,
    ChartShareFailureReason.shareCancelled => '',
  };
}

void showChartShareFailureSnackBar(
  BuildContext context,
  ChartShareFailureReason reason,
) {
  if (reason == ChartShareFailureReason.shareCancelled) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  final message = chartShareFailureMessage(l10n, reason);
  if (message.isEmpty) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Captures the chart described by [request], builds a PDF, and opens share.
Future<ChartShareResult> shareChartCapture(
  BuildContext context,
  AppChartShareRequest request,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await captureAndShareChart(
    request.captureKey,
    subject: request.subject,
    title: request.title ?? request.subject,
    subtitle: request.subtitle,
    filterSummary: request.filterSummary,
    tableData: request.tableData,
    chartExportBuilder: request.chartExportBuilder,
    exportCaptureContext: context,
    pageNumberLabelBuilder: l10n.chartSharePdfPageNumber,
  );
  if (!context.mounted) {
    return result;
  }
  if (result is ChartShareFailure) {
    showChartShareFailureSnackBar(context, result.reason);
  }
  return result;
}
