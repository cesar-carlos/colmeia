import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('resolveChartPdfPageFormat uses portrait A4 by default', () {
    final format = resolveChartPdfPageFormat(
      ChartSharePdfOrientation.portrait,
    );

    expect(format.width, PdfPageFormat.a4.width);
    expect(format.height, PdfPageFormat.a4.height);
  });

  test('resolveChartPdfPageFormat swaps dimensions for landscape', () {
    final format = resolveChartPdfPageFormat(
      ChartSharePdfOrientation.landscape,
    );

    expect(format.width, PdfPageFormat.a4.height);
    expect(format.height, PdfPageFormat.a4.width);
  });

  test('chartPdfTableColumnFlexWeights favors wider content columns', () {
    final weights = chartPdfTableColumnFlexWeights(
      headers: const <String>['Date', 'Amount'],
      rows: const <List<String>>[
        <String>['2026-06-01', r'R$ 1.234.567,89'],
      ],
    );

    expect(weights.length, 2);
    expect(weights[1], greaterThan(weights[0]));
  });

  test('chartPdfTableColumnWidths sums to available width', () {
    const availableWidth = 500.0;
    final widths = chartPdfTableColumnWidths(
      headers: const <String>['A', 'B', 'C'],
      rows: const <List<String>>[
        <String>['1', '22', '333'],
      ],
      availableWidth: availableWidth,
    );

    final total = widths.values.fold<double>(
      0,
      (sum, width) => sum + (width as pw.FixedColumnWidth).width,
    );
    expect(total, closeTo(availableWidth, 0.01));
  });

  test(
    'should keep short catalog columns readable when a name column is long',
    () {
      const headers = <String>[
        'Código',
        'Nome produto',
        'Custo reposição',
        'Preço de venda',
        '% Markup',
      ];
      const rows = <List<String>>[
        <String>[
          '514',
          'MACA PERUANA VITAMINA C+ZINCO 60 CAPS',
          r'R$ 47,90',
          r'R$ 119,80',
          '1.082,9%',
        ],
      ];

      final weights = chartPdfTableColumnFlexWeights(
        headers: headers,
        rows: rows,
      );
      final naiveTotal = weights.fold<double>(
        0,
        (sum, weight) => sum + weight,
      );
      final shares = chartPdfTableColumnShares(headers: headers, rows: rows);
      final minShare = chartPdfTableMinColumnShare(headers.length);

      expect(shares.length, 5);
      expect(shares.reduce((a, b) => a + b), closeTo(1, 0.001));
      expect(shares[0], greaterThan(weights[0] / naiveTotal));
      expect(shares[4], greaterThan(weights[4] / naiveTotal));
      expect(shares[0], greaterThanOrEqualTo(minShare));
      expect(shares[4], greaterThanOrEqualTo(minShare));
      expect(shares[1], greaterThan(shares[0]));
      expect(shares[1], lessThan(0.40));
    },
  );

  test('ChartPdfLayoutMetrics allocates more image height in landscape', () {
    final portrait = ChartPdfLayoutMetrics.forOrientation(
      ChartSharePdfOrientation.portrait,
    );
    final landscape = ChartPdfLayoutMetrics.forOrientation(
      ChartSharePdfOrientation.landscape,
    );

    expect(
      landscape.imageMaxHeightFraction,
      greaterThan(portrait.imageMaxHeightFraction),
    );
    expect(
      landscape.pageFormat.availableWidth,
      greaterThan(portrait.pageFormat.availableWidth),
    );
  });
}
