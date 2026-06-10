import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Returns `true` when [value] looks like a numeric chart table cell
/// (currency, percentage, integer, or decimal).
bool isChartPdfNumericCell(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || _isChartPdfPlaceholder(trimmed)) {
    return false;
  }

  if (trimmed.endsWith('%')) {
    return _isChartPdfNumericToken(trimmed.substring(0, trimmed.length - 1));
  }

  if (_isChartPdfCurrency(trimmed)) {
    return true;
  }

  return _isChartPdfNumericToken(trimmed);
}

/// Returns `true` when [value] matches a supported date format
/// (`dd/MM/yyyy`, `yyyy-MM-dd`, or `yyyy/MM`).
bool isChartPdfDateCell(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || _isChartPdfPlaceholder(trimmed)) {
    return false;
  }

  return _chartPdfDdMmYyyyPattern.hasMatch(trimmed) ||
      _chartPdfIsoDatePattern.hasMatch(trimmed) ||
      _chartPdfYearMonthPattern.hasMatch(trimmed);
}

/// Column indexes that should be right-aligned in chart PDF tables.
List<bool> resolveChartPdfNumericColumns({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final columnCount = headers.length;
  if (columnCount == 0) {
    return const <bool>[];
  }

  return List<bool>.generate(columnCount, (columnIndex) {
    var hasValue = false;
    for (final row in rows) {
      if (columnIndex >= row.length) {
        continue;
      }
      final cell = row[columnIndex].trim();
      if (cell.isEmpty || _isChartPdfPlaceholder(cell)) {
        continue;
      }
      hasValue = true;
      if (!isChartPdfNumericCell(cell)) {
        return false;
      }
    }
    return hasValue;
  }, growable: false);
}

/// Column indexes that should be center-aligned in chart PDF tables.
List<bool> resolveChartPdfDateColumns({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final columnCount = headers.length;
  if (columnCount == 0) {
    return const <bool>[];
  }

  return List<bool>.generate(columnCount, (columnIndex) {
    var hasValue = false;
    for (final row in rows) {
      if (columnIndex >= row.length) {
        continue;
      }
      final cell = row[columnIndex].trim();
      if (cell.isEmpty || _isChartPdfPlaceholder(cell)) {
        continue;
      }
      hasValue = true;
      if (!isChartPdfDateCell(cell)) {
        return false;
      }
    }
    return hasValue;
  }, growable: false);
}

/// Per-column cell and header alignments for chart PDF tables.
({
  Map<int, pw.Alignment> cellAlignments,
  Map<int, pw.Alignment> headerAlignments,
})
resolveChartPdfTableAlignments({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final numericColumns = resolveChartPdfNumericColumns(
    headers: headers,
    rows: rows,
  );
  final dateColumns = resolveChartPdfDateColumns(
    headers: headers,
    rows: rows,
  );
  final cellAlignments = <int, pw.Alignment>{};
  final headerAlignments = <int, pw.Alignment>{};

  for (var index = 0; index < numericColumns.length; index++) {
    if (numericColumns[index]) {
      cellAlignments[index] = pw.Alignment.centerRight;
      headerAlignments[index] = pw.Alignment.centerRight;
    } else if (dateColumns[index]) {
      cellAlignments[index] = pw.Alignment.center;
      headerAlignments[index] = pw.Alignment.center;
    }
  }

  return (
    cellAlignments: cellAlignments,
    headerAlignments: headerAlignments,
  );
}

/// Alternating row backgrounds for long paginated PDF tables.
({pw.BoxDecoration rowDecoration, pw.BoxDecoration oddRowDecoration})
chartPdfTableZebraRowDecorations() {
  return (
    rowDecoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
    ),
    oddRowDecoration: const pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
    ),
  );
}

bool _isChartPdfPlaceholder(String value) {
  return value == '—' || value == '-' || value == '–';
}

bool _isChartPdfCurrency(String value) {
  if (value.startsWith(r'R$')) {
    return true;
  }
  return _chartPdfCompactCurrencyPattern.hasMatch(value);
}

bool _isChartPdfNumericToken(String value) {
  final token = value.trim();
  if (token.isEmpty) {
    return false;
  }
  return _chartPdfIntegerPattern.hasMatch(token) ||
      _chartPdfBrazilianNumberPattern.hasMatch(token) ||
      _chartPdfPlainDecimalPattern.hasMatch(token);
}

final RegExp _chartPdfIntegerPattern = RegExp(r'^-?\d+$');

final RegExp _chartPdfPlainDecimalPattern = RegExp(r'^-?\d+\.\d+$');

final RegExp _chartPdfBrazilianNumberPattern = RegExp(
  r'^-?\d{1,3}(\.\d{3})*(,\d+)?$',
);

final RegExp _chartPdfCompactCurrencyPattern = RegExp(
  r'^R\$\s*.+\b(mil|mi|bi)\b',
  caseSensitive: false,
);

final RegExp _chartPdfDdMmYyyyPattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');

final RegExp _chartPdfIsoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

final RegExp _chartPdfYearMonthPattern = RegExp(r'^\d{4}/\d{2}$');
