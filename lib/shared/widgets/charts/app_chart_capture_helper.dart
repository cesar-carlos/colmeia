import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colmeia/shared/widgets/charts/chart_pdf_exporter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double _kDefaultChartCapturePixelRatio = 3;

bool _chartShareInProgress = false;

/// Captures the chart behind [key], builds a PDF, and opens the share sheet.
Future<ChartShareResult> captureAndShareChart(
  GlobalKey key, {
  String? subject,
  String? title,
  String? subtitle,
  String? filterSummary,
  ChartShareTableData? tableData,
  double? pixelRatio,
}) async {
  if (_chartShareInProgress) {
    return const ChartShareFailure(ChartShareFailureReason.shareInProgress);
  }

  _chartShareInProgress = true;
  try {
    final boundaryContext = key.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    Uint8List? pngBytes;
    if (renderObject is RenderRepaintBoundary && boundaryContext != null) {
      pngBytes = await _captureChartPngBytesFromBoundary(
        renderObject,
        boundaryContext,
        pixelRatio: pixelRatio,
      );
    }

    final hasTable = tableData != null && !tableData.isEmpty;
    if (pngBytes == null && !hasTable) {
      if (boundaryContext == null) {
        return const ChartShareFailure(
          ChartShareFailureReason.missingBoundary,
        );
      }
      if (renderObject is! RenderRepaintBoundary) {
        return const ChartShareFailure(
          ChartShareFailureReason.invalidRenderObject,
        );
      }
      return const ChartShareFailure(
        ChartShareFailureReason.imageEncodingFailed,
      );
    }

    final resolvedTitle = title ?? subject ?? 'chart';
    Uint8List pdfBytes;
    try {
      pdfBytes = await ChartPdfExporter.build(
        title: resolvedTitle,
        subtitle: subtitle,
        filterSummary: filterSummary,
        tableData: tableData,
        chartImagePngBytes: pngBytes,
      );
    } on Object {
      return const ChartShareFailure(
        ChartShareFailureReason.pdfGenerationFailed,
      );
    }

    if (pdfBytes.isEmpty) {
      return const ChartShareFailure(
        ChartShareFailureReason.pdfGenerationFailed,
      );
    }

    final fileName = '${sanitizeReportFileName(resolvedTitle)}.pdf';

    try {
      await shareExportBytes(
        bytes: pdfBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
        subject: subject ?? resolvedTitle,
      );
    } on Object {
      return const ChartShareFailure(
        ChartShareFailureReason.sharePlatformFailed,
      );
    }

    return const ChartShareSuccess();
  } finally {
    _chartShareInProgress = false;
  }
}

Future<Uint8List?> _captureChartPngBytesFromBoundary(
  RenderRepaintBoundary boundary,
  BuildContext boundaryContext, {
  double? pixelRatio,
}) async {
  ui.Image? image;
  try {
    final resolvedPixelRatio =
        pixelRatio ?? MediaQuery.devicePixelRatioOf(boundaryContext);
    image = await boundary.toImage(
      pixelRatio: resolvedPixelRatio.clamp(1, _kDefaultChartCapturePixelRatio),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return null;
    }
    return byteData.buffer.asUint8List();
  } finally {
    image?.dispose();
  }
}
