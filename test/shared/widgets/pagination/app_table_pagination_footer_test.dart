import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/localization/app_locale_resolution.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('pumpAndSettle succeeds and shows page size menu', (
    tester,
  ) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('pt'),
          localizationsDelegates: colmeiaLocalizationsDelegates,
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
      final selectedMaterial = tester.widget<Material>(
        find
            .ancestor(of: find.text('2'), matching: find.byType(Material))
            .first,
      );
      final border =
          (selectedMaterial.shape! as RoundedRectangleBorder).side.color;
      final background = selectedMaterial.color!;
      final a = Color.alphaBlend(border, background).computeLuminance();
      final b = background.computeLuminance();
      expect(
        a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05),
        greaterThanOrEqualTo(3),
      );
    }
  });

  testWidgets('page size menu opens as overlay without growing footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pt'),
        localizationsDelegates: colmeiaLocalizationsDelegates,
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

    await tester.tap(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.text('10'),
      ),
    );
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
        localizationsDelegates: colmeiaLocalizationsDelegates,
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

    await tester.tap(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.text('10'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MenuItemButton, '20'));
    await tester.pump();

    expect(pageSize, 20);
  });

  testWidgets('should show page-of label instead of page numbers on mobile', (
    tester,
  ) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      for (final width in [320.0, 540.0]) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              locale: const Locale('pt'),
              localizationsDelegates: colmeiaLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(1200, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: width,
                      child: AppTablePaginationFooter(
                        currentPage: 1,
                        totalPages: 49,
                        pageSize: 20,
                        rangeStart: 1,
                        rangeEnd: 20,
                        totalItems: 973,
                        entityLabel: 'produtos',
                        pageSizeOptions: const <int>[10, 20, 50],
                        onPageSizeChanged: (_) {},
                        onPrevious: () {},
                        onNext: () {},
                        onPageSelected: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Página 1 de 49'), findsOneWidget);
          expect(find.text('2'), findsNothing);
          expect(find.text('49'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });
}
