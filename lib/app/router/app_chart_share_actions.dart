import 'dart:async';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/utils/open_local_file.dart';
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

bool shouldPromptChartShareIncludeImage(AppChartShareRequest request) {
  final tableData = request.tableData;
  final hasTable = tableData != null && !tableData.isEmpty;
  return request.chartExportBuilder != null &&
      hasTable &&
      request.includeChartImage == null;
}

Future<bool?> showChartShareIncludeImageDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  var includeChartImage = false;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.chartShareIncludeChartImageTitle),
            content: CheckboxListTile(
              value: includeChartImage,
              onChanged: (value) {
                setState(() => includeChartImage = value ?? false);
              },
              title: Text(l10n.chartShareIncludeChartImage),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(includeChartImage),
                child: Text(l10n.chartShareTooltip),
              ),
            ],
          );
        },
      );
    },
  );
}

void showChartShareFailureSnackBar(
  BuildContext context,
  ChartShareFailure failure,
) {
  if (failure.reason == ChartShareFailureReason.shareCancelled) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  final message = chartShareFailureMessage(l10n, failure.reason);
  if (message.isEmpty) {
    return;
  }

  final pdfFilePath = failure.pdfFilePath;
  final canOpenPdf =
      pdfFilePath != null &&
      pdfFilePath.isNotEmpty &&
      failure.reason == ChartShareFailureReason.sharePlatformFailed;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: canOpenPdf
          ? SnackBarAction(
              label: l10n.chartShareOpenPdf,
              onPressed: () {
                unawaited(openLocalFile(pdfFilePath));
              },
            )
          : null,
    ),
  );
}

void showChartShareSuccessSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.chartShareSuccess)),
  );
}

/// Captures the chart described by [request], builds a PDF, and opens share.
Future<ChartShareResult> shareChartCapture(
  BuildContext context,
  AppChartShareRequest request,
) async {
  var resolvedRequest = request;
  if (shouldPromptChartShareIncludeImage(resolvedRequest)) {
    final includeChartImage = await showChartShareIncludeImageDialog(context);
    if (includeChartImage == null) {
      return const ChartShareFailure(ChartShareFailureReason.shareCancelled);
    }
    if (!context.mounted) {
      return const ChartShareFailure(ChartShareFailureReason.shareCancelled);
    }
    resolvedRequest = resolvedRequest.copyWith(
      includeChartImage: includeChartImage,
    );
  }

  late final ChartShareResult result;
  try {
    final l10n = AppLocalizations.of(context);
    result = await captureAndShareChart(
      resolvedRequest.captureKey,
      subject: resolvedRequest.subject,
      title: resolvedRequest.title ?? resolvedRequest.subject,
      subtitle: resolvedRequest.subtitle,
      filterSummary: resolvedRequest.filterSummary,
      tableData: resolvedRequest.tableData,
      chartExportBuilder: resolvedRequest.chartExportBuilder,
      includeChartImage: resolvedRequest.includeChartImage,
      pdfOrientation: resolvedRequest.pdfOrientation,
      exportCaptureContext: context,
      pageNumberLabelBuilder: l10n.chartSharePdfPageNumber,
    );
  } on Object {
    result = const ChartShareFailure(
      ChartShareFailureReason.pdfGenerationFailed,
    );
  }
  if (!context.mounted) {
    return result;
  }
  switch (result) {
    case final ChartShareFailure failure:
      showChartShareFailureSnackBar(context, failure);
    case ChartShareSuccess():
      showChartShareSuccessSnackBar(context);
  }
  return result;
}
