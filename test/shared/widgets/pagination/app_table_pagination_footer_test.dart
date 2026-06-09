import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pumpAndSettle succeeds and shows page size menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    expect(find.byType(MenuAnchor), findsOneWidget);
    expect(find.text('Itens por página:'), findsOneWidget);
  });

  testWidgets('page size menu opens as overlay without growing footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    final footerBox = tester.renderObject<RenderBox>(
      find.byType(AppTablePaginationFooter),
    );
    final heightBefore = footerBox.size.height;

    await tester.tap(find.descendant(
      of: find.byType(MenuAnchor),
      matching: find.text('10'),
    ));
    await tester.pumpAndSettle();

    final heightAfter = footerBox.size.height;
    expect(heightAfter, heightBefore);
    expect(find.byType(MenuItemButton), findsNWidgets(3));
  });

  testWidgets('should invoke onPageSizeChanged when page size changes', (
    tester,
  ) async {
    var pageSize = 10;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    await tester.tap(find.descendant(
      of: find.byType(MenuAnchor),
      matching: find.text('10'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MenuItemButton, '20'));
    await tester.pump();

    expect(pageSize, 20);
  });
}
