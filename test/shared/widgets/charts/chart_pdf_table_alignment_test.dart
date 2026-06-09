import 'package:colmeia/shared/widgets/charts/chart_pdf_table_alignment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('isChartPdfNumericCell', () {
    test('detects integers', () {
      expect(isChartPdfNumericCell('12'), isTrue);
      expect(isChartPdfNumericCell('1'), isTrue);
      expect(isChartPdfNumericCell('-3'), isTrue);
    });

    test('detects Brazilian currency', () {
      expect(isChartPdfNumericCell(r'R$ 1.234,56'), isTrue);
      expect(isChartPdfNumericCell(r'R$ 26,80'), isTrue);
    });

    test('detects compact currency', () {
      expect(isChartPdfNumericCell(r'R$ 1,2 mil'), isTrue);
      expect(isChartPdfNumericCell(r'R$ 2,5 mi'), isTrue);
    });

    test('detects percentages', () {
      expect(isChartPdfNumericCell('40%'), isTrue);
      expect(isChartPdfNumericCell('12,5%'), isTrue);
    });

    test('detects Brazilian and plain decimals', () {
      expect(isChartPdfNumericCell('1.234,56'), isTrue);
      expect(isChartPdfNumericCell('234,56'), isTrue);
      expect(isChartPdfNumericCell('12.5'), isTrue);
    });

    test('rejects text labels and dates', () {
      expect(isChartPdfNumericCell('Agent A'), isFalse);
      expect(isChartPdfNumericCell('2026-06-01'), isFalse);
      expect(isChartPdfNumericCell('01/06/2026'), isFalse);
      expect(isChartPdfNumericCell('Pix'), isFalse);
    });

    test('rejects placeholders', () {
      expect(isChartPdfNumericCell('—'), isFalse);
      expect(isChartPdfNumericCell('-'), isFalse);
    });
  });

  group('resolveChartPdfNumericColumns', () {
    test('marks numeric columns from ranking table shape', () {
      final columns = resolveChartPdfNumericColumns(
        headers: const <String>['Rank', 'Name', 'Sales', 'Amount'],
        rows: const <List<String>>[
          <String>['1', 'Agent A', '12', r'R$ 100,00'],
          <String>['2', 'Agent B', '8', r'R$ 80,00'],
        ],
      );

      expect(columns, <bool>[true, false, true, true]);
    });

    test('marks value and percent columns in donut table shape', () {
      final columns = resolveChartPdfNumericColumns(
        headers: const <String>['Label', 'Value', 'Share'],
        rows: const <List<String>>[
          <String>['Pix', '60', '60%'],
          <String>['Card', '40', '40%'],
        ],
      );

      expect(columns, <bool>[false, true, true]);
    });

    test('keeps mixed column left-aligned', () {
      final columns = resolveChartPdfNumericColumns(
        headers: const <String>['Metric', 'Value'],
        rows: const <List<String>>[
          <String>['Sales', '10'],
          <String>['Branch', 'Main'],
        ],
      );

      expect(columns, <bool>[false, false]);
    });

    test('ignores placeholders when deciding numeric columns', () {
      final columns = resolveChartPdfNumericColumns(
        headers: const <String>['Label', 'Share'],
        rows: const <List<String>>[
          <String>['Pix', '60%'],
          <String>['Empty', '—'],
        ],
      );

      expect(columns, <bool>[false, true]);
    });
  });

  group('isChartPdfDateCell', () {
    test('detects dd/MM/yyyy', () {
      expect(isChartPdfDateCell('01/06/2026'), isTrue);
      expect(isChartPdfDateCell('31/12/2025'), isTrue);
    });

    test('detects yyyy-MM-dd', () {
      expect(isChartPdfDateCell('2026-06-01'), isTrue);
      expect(isChartPdfDateCell('2025-12-31'), isTrue);
    });

    test('detects yyyy/MM', () {
      expect(isChartPdfDateCell('2026/06'), isTrue);
      expect(isChartPdfDateCell('2025/12'), isTrue);
    });

    test('rejects partial or mixed formats', () {
      expect(isChartPdfDateCell('6/2026'), isFalse);
      expect(isChartPdfDateCell('2026-6'), isFalse);
      expect(isChartPdfDateCell('01/06/26'), isFalse);
      expect(isChartPdfDateCell('Sales'), isFalse);
      expect(isChartPdfDateCell('12'), isFalse);
    });

    test('rejects placeholders', () {
      expect(isChartPdfDateCell('—'), isFalse);
      expect(isChartPdfDateCell('-'), isFalse);
    });
  });

  group('resolveChartPdfDateColumns', () {
    test('marks date columns from ISO and Brazilian formats', () {
      final columns = resolveChartPdfDateColumns(
        headers: const <String>['Period', 'Day', 'Sales'],
        rows: const <List<String>>[
          <String>['2026/06', '01/06/2026', '12'],
          <String>['2026/07', '02/07/2026', '8'],
        ],
      );

      expect(columns, <bool>[true, true, false]);
    });

    test('keeps mixed column left-aligned', () {
      final columns = resolveChartPdfDateColumns(
        headers: const <String>['Date'],
        rows: const <List<String>>[
          <String>['2026-06-01'],
          <String>['Pending'],
        ],
      );

      expect(columns, <bool>[false]);
    });

    test('ignores placeholders when deciding date columns', () {
      final columns = resolveChartPdfDateColumns(
        headers: const <String>['Date'],
        rows: const <List<String>>[
          <String>['2026-06-01'],
          <String>['—'],
        ],
      );

      expect(columns, <bool>[true]);
    });
  });

  group('resolveChartPdfTableAlignments', () {
    test('returns center for date columns and right for numeric columns', () {
      final alignments = resolveChartPdfTableAlignments(
        headers: const <String>['Date', 'Sales'],
        rows: const <List<String>>[
          <String>['2026-06-01', '12'],
          <String>['2026-06-02', '8'],
        ],
      );

      expect(alignments.cellAlignments[0], pw.Alignment.center);
      expect(alignments.headerAlignments[0], pw.Alignment.center);
      expect(alignments.cellAlignments[1], pw.Alignment.centerRight);
      expect(alignments.headerAlignments[1], pw.Alignment.centerRight);
    });

    test('returns center alignment for date-only columns', () {
      final alignments = resolveChartPdfTableAlignments(
        headers: const <String>['Period', 'Amount'],
        rows: const <List<String>>[
          <String>['2026/06', r'R$ 100,00'],
          <String>['2026/07', r'R$ 80,00'],
        ],
      );

      expect(alignments.cellAlignments[0], pw.Alignment.center);
      expect(alignments.headerAlignments[0], pw.Alignment.center);
      expect(alignments.cellAlignments[1], pw.Alignment.centerRight);
      expect(alignments.headerAlignments[1], pw.Alignment.centerRight);
    });
  });
}
