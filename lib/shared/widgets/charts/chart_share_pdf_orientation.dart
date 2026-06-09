import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Page orientation for chart PDF exports.
enum ChartSharePdfOrientation {
  portrait,
  landscape,
}

/// Resolves [orientation] to an A4 [PdfPageFormat].
PdfPageFormat resolveChartPdfPageFormat(
  ChartSharePdfOrientation orientation, {
  PdfPageFormat base = PdfPageFormat.a4,
}) {
  return switch (orientation) {
    ChartSharePdfOrientation.portrait => base,
    ChartSharePdfOrientation.landscape => base.landscape,
  };
}

/// Layout constants derived from chart PDF orientation.
class ChartPdfLayoutMetrics {
  factory ChartPdfLayoutMetrics.forOrientation(
    ChartSharePdfOrientation orientation, {
    PdfPageFormat base = PdfPageFormat.a4,
  }) {
    final pageFormat = resolveChartPdfPageFormat(orientation, base: base);
    final isLandscape = orientation == ChartSharePdfOrientation.landscape;
    return ChartPdfLayoutMetrics._(
      pageFormat: pageFormat,
      imageMaxHeightFraction: isLandscape ? 0.58 : 0.42,
      sectionGap: isLandscape ? 14 : 12,
      headerBottomGap: isLandscape ? 10 : 8,
    );
  }

  const ChartPdfLayoutMetrics._({
    required this.pageFormat,
    required this.imageMaxHeightFraction,
    required this.sectionGap,
    required this.headerBottomGap,
  });

  final PdfPageFormat pageFormat;
  final double imageMaxHeightFraction;
  final double sectionGap;
  final double headerBottomGap;
}

/// Proportional flex weights for chart share tables from header and cell text.
List<double> chartPdfTableColumnFlexWeights({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final columnCount = headers.length;
  if (columnCount == 0) {
    return const <double>[];
  }

  final maxLengths = List<double>.generate(
    columnCount,
    (index) => headers[index].length.toDouble(),
  );
  for (final row in rows) {
    for (var index = 0; index < columnCount && index < row.length; index++) {
      maxLengths[index] = math.max(maxLengths[index], row[index].length.toDouble());
    }
  }

  return maxLengths
      .map((length) => math.max(length, 4).toDouble())
      .toList(growable: false);
}

Map<int, pw.TableColumnWidth> chartPdfTableColumnWidths({
  required List<String> headers,
  required List<List<String>> rows,
  required double availableWidth,
}) {
  final flexWeights = chartPdfTableColumnFlexWeights(
    headers: headers,
    rows: rows,
  );
  if (flexWeights.isEmpty) {
    return const <int, pw.TableColumnWidth>{};
  }

  final totalWeight = flexWeights.fold<double>(0, (sum, weight) => sum + weight);
  final result = <int, pw.TableColumnWidth>{};
  for (var index = 0; index < flexWeights.length; index++) {
    final share = flexWeights[index] / totalWeight;
    result[index] = pw.FixedColumnWidth(availableWidth * share);
  }
  return result;
}
