import 'package:colmeia/shared/widgets/charts/chart_pdf_page_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pageLabelTemplateFromBuilder extracts placeholders', () {
    final template = pageLabelTemplateFromBuilder(
      (page, pages) => 'Page $page of $pages',
    );

    expect(template, 'Page {page} of {pages}');
    expect(formatPdfPageLabel(template!, 2, 5), 'Page 2 of 5');
  });

  test('pageLabelTemplateFromBuilder supports localized labels', () {
    final template = pageLabelTemplateFromBuilder(
      (page, pages) => 'Página $page de $pages',
    );

    expect(template, 'Página {page} de {pages}');
    expect(formatPdfPageLabel(template!, 1, 3), 'Página 1 de 3');
  });
}
