import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns single page list when total is one', () {
    expect(
      buildPaginationPageSlots(currentPage: 1, totalPages: 1),
      <int?>[1],
    );
  });

  test('lists all pages when total is small', () {
    expect(
      buildPaginationPageSlots(currentPage: 3, totalPages: 7),
      <int?>[1, 2, 3, 4, 5, 6, 7],
    );
  });

  test('inserts ellipsis for large totals near first page', () {
    expect(
      buildPaginationPageSlots(currentPage: 1, totalPages: 62),
      <int?>[1, 2, null, 62],
    );
  });

  test('inserts ellipsis on both sides around middle page', () {
    expect(
      buildPaginationPageSlots(currentPage: 30, totalPages: 62),
      <int?>[1, null, 29, 30, 31, null, 62],
    );
  });

  test('clamps current page into range', () {
    expect(
      buildPaginationPageSlots(currentPage: 99, totalPages: 5),
      <int?>[1, 2, 3, 4, 5],
    );
  });

  test('uses the same control size for arrows and page numbers', () {
    const style = AppTablePaginationFooterStyle();
    expect(style.iconButtonSize, kAppTablePaginationControlSize);
    expect(style.pageNumberMinSize, kAppTablePaginationControlSize);
    expect(style.iconButtonSize, style.pageNumberMinSize);
  });
}
