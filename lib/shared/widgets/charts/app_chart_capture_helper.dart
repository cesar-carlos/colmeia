import 'dart:ui' as ui;

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_pixel_ratio.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_exporter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_bytes_sharer.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';

const Duration _kFrameWaitTimeout = Duration(seconds: 1);

/// Captures the chart behind [key], builds a PDF, and opens the share sheet.
Future<ChartShareResult> captureAndShareChart(
  GlobalKey key, {
  String? subject,
  String? title,
  String? subtitle,
  String? filterSummary,
  ChartShareTableData? tableData,
  WidgetBuilder? chartExportBuilder,
  ChartSharePdfOrientation pdfOrientation = ChartSharePdfOrientation.portrait,
  BuildContext? exportCaptureContext,
  double? pixelRatio,
  String Function(int page, int pages)? pageNumberLabelBuilder,
  ChartShareBytesSharer? shareBytes,
}) async {
  final progressKey = key;
  if (!ChartShareGuard.tryAcquire(progressKey)) {
    return const ChartShareFailure(ChartShareFailureReason.shareInProgress);
  }

  final resolvedTitle = title ?? subject ?? 'chart';
  try {
    Uint8List? pngBytes;
    var skipPngDownscale = false;
    final usesDedicatedExport = chartExportBuilder != null;
    final exportOverlay = usesDedicatedExport && exportCaptureContext != null
        ? Overlay.maybeOf(exportCaptureContext, rootOverlay: true)
        : null;
    final screenDevicePixelRatio = exportCaptureContext == null
        ? key.currentContext == null
            ? null
            : MediaQuery.devicePixelRatioOf(key.currentContext!)
        : MediaQuery.devicePixelRatioOf(exportCaptureContext);
    if (usesDedicatedExport && exportOverlay != null) {
      final capture = await captureChartFromExportBuilder(
        overlay: exportOverlay,
        chartExportBuilder: chartExportBuilder,
        devicePixelRatio: screenDevicePixelRatio,
        pixelRatio: pixelRatio,
      );
      pngBytes = capture?.bytes;
      skipPngDownscale = capture?.fitsPdfEmbedBounds ?? false;
    }

    if (pngBytes == null) {
      final boundaryContext = key.currentContext;
      final renderObject = boundaryContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final capture = await _captureChartPngBytesFromBoundary(
          renderObject,
          devicePixelRatio: screenDevicePixelRatio,
          pixelRatio: pixelRatio,
        );
        pngBytes = capture?.bytes;
        skipPngDownscale = capture?.fitsPdfEmbedBounds ?? false;
      }
    }

    final hasTable = tableData != null && !tableData.isEmpty;
    if (pngBytes == null && !hasTable) {
      final boundaryContext = key.currentContext;
      final renderObject = boundaryContext?.findRenderObject();
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

    final fontsFuture = ChartPdfExporter.warmFonts();
    if (pngBytes != null && !skipPngDownscale) {
      pngBytes = await downscalePngForPdfEmbed(pngBytes);
    }

    await fontsFuture;
    late final Uint8List pdfBytes;
    try {
      pdfBytes = await ChartPdfExporter.build(
        title: resolvedTitle,
        subtitle: subtitle,
        filterSummary: filterSummary,
        tableData: tableData,
        chartImagePngBytes: pngBytes,
        pdfOrientation: pdfOrientation,
        pageNumberLabelBuilder: pageNumberLabelBuilder,
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
    final shareFn = shareBytes ?? shareExportBytes;
    try {
      final shareResult = await shareFn(
        bytes: pdfBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
        subject: subject ?? resolvedTitle,
        title: resolvedTitle,
      );
      if (shareResult.status == ShareResultStatus.dismissed) {
        return const ChartShareFailure(
          ChartShareFailureReason.shareCancelled,
        );
      }
    } on Object {
      return const ChartShareFailure(
        ChartShareFailureReason.sharePlatformFailed,
      );
    }

    return const ChartShareSuccess();
  } finally {
    ChartShareGuard.release(progressKey);
  }
}

typedef ChartPngCapture = ({Uint8List bytes, bool fitsPdfEmbedBounds});

/// Renders [chartExportBuilder] offscreen, captures PNG bytes, then removes it.
@visibleForTesting
Future<ChartPngCapture?> captureChartFromExportBuilder({
  required OverlayState overlay,
  required WidgetBuilder chartExportBuilder,
  double? devicePixelRatio,
  double? pixelRatio,
}) async {
  final captureKey = GlobalKey();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      return Positioned(
        left: -20000,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: captureKey,
            child: chartExportBuilder(overlayContext),
          ),
        ),
      );
    },
  );

  final resolvedDevicePixelRatio = devicePixelRatio ??
      View.of(overlay.context).devicePixelRatio;

  overlay.insert(entry);
  try {
    final renderObject = await _waitForExportCaptureBoundary(captureKey);
    if (renderObject == null) {
      return null;
    }

    return _rasterizeBoundaryToPng(
      renderObject,
      devicePixelRatio: resolvedDevicePixelRatio,
      pixelRatio: pixelRatio,
    );
  } finally {
    entry.remove();
  }
}

/// Captures PNG bytes behind [key] without building or sharing a PDF.
@visibleForTesting
Future<Uint8List?> captureChartPngBytes(
  GlobalKey key, {
  double? pixelRatio,
}) async {
  final boundaryContext = key.currentContext;
  final renderObject = boundaryContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary || boundaryContext == null) {
    return null;
  }
  final capture = await _captureChartPngBytesFromBoundary(
    renderObject,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(boundaryContext),
    pixelRatio: pixelRatio,
  );
  return capture?.bytes;
}

Future<RenderRepaintBoundary?> _waitForExportCaptureBoundary(
  GlobalKey captureKey, {
  int maxAttempts = 10,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final renderObject = captureKey.currentContext?.findRenderObject();
    if (renderObject is RenderRepaintBoundary &&
        renderObject.size.width > 0 &&
        renderObject.size.height > 0) {
      if (await waitForBoundaryReady(renderObject, settlingFrames: 1)) {
        return renderObject;
      }
      return null;
    }
    await _requestEndOfFrame();
  }
  return null;
}

@visibleForTesting
Future<bool> waitForBoundaryReady(
  RenderRepaintBoundary boundary, {
  int settlingFrames = 2,
}) async {
  const maxAttempts = 10;

  var waitedForPaint = false;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (!boundary.debugNeedsPaint) {
      break;
    }
    waitedForPaint = true;
    await _requestEndOfFrame();
  }

  if (boundary.debugNeedsPaint) {
    return false;
  }

  if (waitedForPaint) {
    for (var i = 0; i < settlingFrames; i++) {
      await _requestEndOfFrame();
      if (boundary.debugNeedsPaint) {
        return false;
      }
    }
  }

  return true;
}

Future<void> _requestEndOfFrame() async {
  final binding = WidgetsBinding.instance;
  if (binding.schedulerPhase == SchedulerPhase.idle) {
    binding.scheduleFrame();
  }
  try {
    await binding.endOfFrame.timeout(_kFrameWaitTimeout);
  } on Object {
    // Retry loop or capture fallback handles incomplete frames.
  }
}

Future<ChartPngCapture?> _captureChartPngBytesFromBoundary(
  RenderRepaintBoundary boundary, {
  double? devicePixelRatio,
  double? pixelRatio,
  int settlingFrames = 2,
}) async {
  if (!await waitForBoundaryReady(boundary, settlingFrames: settlingFrames)) {
    return null;
  }

  return _rasterizeBoundaryToPng(
    boundary,
    devicePixelRatio: devicePixelRatio,
    pixelRatio: pixelRatio,
  );
}

Future<ChartPngCapture?> _rasterizeBoundaryToPng(
  RenderRepaintBoundary boundary, {
  double? devicePixelRatio,
  double? pixelRatio,
}) async {
  final logicalWidth = boundary.size.width;
  final logicalHeight = boundary.size.height;
  final resolvedPixelRatio = resolveChartExportPixelRatio(
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
    pixelRatio: pixelRatio,
    devicePixelRatio: devicePixelRatio,
  );
  final fitsPdfEmbedBounds = chartCaptureFitsPdfEmbedBounds(
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
    pixelRatio: resolvedPixelRatio,
  );

  ui.Image? image;
  try {
    image = await boundary.toImage(pixelRatio: resolvedPixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return null;
    }
    return (
      bytes: byteData.buffer.asUint8List(),
      fitsPdfEmbedBounds: fitsPdfEmbedBounds,
    );
  } on Object {
    return null;
  } finally {
    image?.dispose();
  }
}
