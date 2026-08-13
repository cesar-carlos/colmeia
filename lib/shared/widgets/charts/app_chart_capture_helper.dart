import 'dart:async';
import 'dart:ui' as ui;

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_pixel_ratio.dart';
import 'package:colmeia/shared/widgets/charts/chart_pdf_exporter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_bytes_sharer.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
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
const Duration _kDedicatedExportTimeout = Duration(seconds: 8);
const Duration _kRasterizeTimeout = Duration(seconds: 20);
const Duration _kPdfBuildTimeout = Duration(seconds: 60);
const Duration _kShareSheetTimeout = Duration(seconds: 90);

/// Captures the chart behind [key], builds a PDF, and opens the share sheet.
Future<ChartShareResult> captureAndShareChart(
  GlobalKey key, {
  String? subject,
  String? title,
  String? subtitle,
  String? filterSummary,
  ChartShareTableData? tableData,
  WidgetBuilder? chartExportBuilder,
  bool? includeChartImage,
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
    final hasTable = tableData != null && !tableData.isEmpty;
    final fontsFuture = ChartPdfExporter.warmFonts();

    Uint8List? pngBytes;
    var skipPngDownscale = false;
    final usesDedicatedExport = chartExportBuilder != null;
    final shouldCaptureChartImage = resolveChartShareIncludeChartImage(
      includeChartImage: includeChartImage,
      hasTable: hasTable,
      hasExportBuilder: usesDedicatedExport,
    );
    final exportOverlay =
        shouldCaptureChartImage &&
            usesDedicatedExport &&
            exportCaptureContext != null
        ? _resolveExportOverlay(exportCaptureContext)
        : null;
    final screenDevicePixelRatio = exportCaptureContext == null
        ? key.currentContext == null
              ? null
              : MediaQuery.devicePixelRatioOf(key.currentContext!)
        : MediaQuery.devicePixelRatioOf(exportCaptureContext);
    if (shouldCaptureChartImage &&
        usesDedicatedExport &&
        exportOverlay != null) {
      ChartPngCapture? capture;
      try {
        capture = await captureChartFromExportBuilder(
          overlay: exportOverlay,
          chartExportBuilder: chartExportBuilder,
          devicePixelRatio: screenDevicePixelRatio,
          pixelRatio: pixelRatio,
        ).timeout(_kDedicatedExportTimeout);
      } on Object {
        capture = null;
      }
      pngBytes = capture?.bytes;
      skipPngDownscale = capture?.fitsPdfEmbedBounds ?? false;
    }

    final skipBoundaryCapture =
        !shouldCaptureChartImage ||
        (includeChartImage == null && hasTable && !usesDedicatedExport);
    final skipBoundaryFallback = hasTable && usesDedicatedExport;
    if (pngBytes == null && !skipBoundaryCapture && !skipBoundaryFallback) {
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

    if (pngBytes != null && !skipPngDownscale) {
      try {
        pngBytes = await downscalePngForPdfEmbed(
          pngBytes,
        ).timeout(_kRasterizeTimeout);
      } on Object {
        pngBytes = null;
      }
    }

    try {
      await fontsFuture.timeout(_kPdfBuildTimeout);
    } on Object {
      return const ChartShareFailure(
        ChartShareFailureReason.pdfGenerationFailed,
      );
    }
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
      ).timeout(_kPdfBuildTimeout);
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
    final shareExportResult = await shareFn(
      bytes: pdfBytes,
      fileName: fileName,
      mimeType: 'application/pdf',
      subject: subject ?? resolvedTitle,
      title: resolvedTitle,
    ).timeout(_kShareSheetTimeout);
    final shareResult = shareExportResult.shareResult;
    if (shareResult.status == ShareResultStatus.dismissed) {
      return const ChartShareFailure(
        ChartShareFailureReason.shareCancelled,
      );
    }
    if (shareResult.status != ShareResultStatus.success) {
      return ChartShareFailure(
        ChartShareFailureReason.sharePlatformFailed,
        pdfFilePath: shareExportResult.tempFilePath,
      );
    }

    return const ChartShareSuccess();
  } finally {
    ChartShareGuard.release(progressKey);
  }
}

typedef ChartPngCapture = ({Uint8List bytes, bool fitsPdfEmbedBounds});

OverlayState? _resolveExportOverlay(BuildContext context) {
  final rootOverlay = Overlay.maybeOf(context, rootOverlay: true);
  if (rootOverlay != null) {
    return rootOverlay;
  }
  return Overlay.maybeOf(context);
}

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

  final resolvedDevicePixelRatio =
      devicePixelRatio ?? View.of(overlay.context).devicePixelRatio;

  overlay.insert(entry);
  try {
    final renderObject = await _waitForExportCaptureBoundary(captureKey);
    if (renderObject == null) {
      return null;
    }

    return await _rasterizeBoundaryToPng(
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
    image = await boundary
        .toImage(pixelRatio: resolvedPixelRatio)
        .timeout(_kRasterizeTimeout);
    final byteData = await image
        .toByteData(format: ui.ImageByteFormat.png)
        .timeout(_kRasterizeTimeout);
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
