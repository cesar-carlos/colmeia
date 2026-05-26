import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pumpAndSettle succeeds and shows page size dropdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Scaffold(
            body: AppTablePaginationFooter(
              currentPage: 2,
              totalPages: 5,
              pageSize: 10,
              rangeStart: 11,
              rangeEnd: 20,
              totalItems: 42,
              entityLabel: 'itens',
              pageSizeOptions: const <int>[10, 20, 50],
              onPageSizeChanged: (_) {},
              onPrevious: () {},
              onNext: () {},
              onPageSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppDropdownField<int>), findsOneWidget);
    expect(find.text('Itens por página:'), findsOneWidget);
  });

  testWidgets('should invoke onPageSizeChanged when page size changes', (
    tester,
  ) async {
    var pageSize = 10;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppTablePaginationFooter(
                  currentPage: 2,
                  totalPages: 5,
                  pageSize: pageSize,
                  rangeStart: 11,
                  rangeEnd: 20,
                  totalItems: 42,
                  entityLabel: 'itens',
                  pageSizeOptions: const <int>[10, 20, 50],
                  onPageSizeChanged: (value) =>
                      setState(() => pageSize = value),
                  onPrevious: () {},
                  onNext: () {},
                  onPageSelected: (_) {},
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20'));
    await tester.pump();

    expect(pageSize, 20);
  });
}
