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

/// Combined floor for every column's minimum share of the table width.
///
/// Five catalog columns then start at 15% each, leaving 25% to follow
/// content length so a long name column cannot starve `Código` or `% Markup`.
const double kChartPdfTableMinColumnShareBudget = 0.75;

/// Cap on the per-column floor so 2–3 column tables stay content-weighted.
const double kChartPdfTableMinColumnShareCap = 0.16;

double chartPdfTableMinColumnShare(int columnCount) {
  if (columnCount <= 0) {
    return 0;
  }
  return math.min(
    kChartPdfTableMinColumnShareCap,
    kChartPdfTableMinColumnShareBudget / columnCount,
  );
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
      maxLengths[index] = math.max(
        maxLengths[index],
        row[index].length.toDouble(),
      );
    }
  }

  return maxLengths
      .map((length) => math.max(length, 4).toDouble())
      .toList(growable: false);
}

/// Width shares after applying a readable floor to short columns.
List<double> chartPdfTableColumnShares({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final weights = chartPdfTableColumnFlexWeights(
    headers: headers,
    rows: rows,
  );
  final columnCount = weights.length;
  if (columnCount == 0) {
    return const <double>[];
  }
  if (columnCount == 1) {
    return const <double>[1];
  }

  final totalWeight = weights.fold<double>(0, (sum, weight) => sum + weight);
  if (totalWeight <= 0) {
    return List<double>.filled(columnCount, 1 / columnCount);
  }

  final minShare = chartPdfTableMinColumnShare(columnCount);
  final remaining = 1 - minShare * columnCount;
  if (remaining <= 0) {
    return List<double>.filled(columnCount, 1 / columnCount);
  }

  return List<double>.generate(
    columnCount,
    (index) => minShare + remaining * (weights[index] / totalWeight),
    growable: false,
  );
}

Map<int, pw.TableColumnWidth> chartPdfTableColumnWidths({
  required List<String> headers,
  required List<List<String>> rows,
  required double availableWidth,
}) {
  final shares = chartPdfTableColumnShares(headers: headers, rows: rows);
  if (shares.isEmpty) {
    return const <int, pw.TableColumnWidth>{};
  }

  final result = <int, pw.TableColumnWidth>{};
  for (var index = 0; index < shares.length; index++) {
    result[index] = pw.FixedColumnWidth(availableWidth * shares[index]);
  }
  return result;
}
