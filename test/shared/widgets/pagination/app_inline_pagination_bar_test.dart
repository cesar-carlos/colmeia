import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/widgets/pagination/app_inline_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('centerLabel is exposed on center Semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppInlinePaginationBar(
            centerLabel: 'Pagina 1 de 3',
            previousLabel: 'Ant',
            nextLabel: 'Prox',
          ),
        ),
      ),
    );

    expect(find.text('Pagina 1 de 3'), findsOneWidget);
    final semanticsWithCenterLabel = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Pagina 1 de 3',
    );
    expect(semanticsWithCenterLabel, findsOneWidget);
  });

  testWidgets('centerSemanticsLabel is used for custom center', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppInlinePaginationBar(
            centerSemanticsLabel: 'Pagina 2 de 8, 152 resultados',
            center: const Text('Custom'),
            previousLabel: 'Ant',
            nextLabel: 'Prox',
          ),
        ),
      ),
    );

    expect(find.text('Custom'), findsOneWidget);
    final semanticsWithCenterLabel = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Pagina 2 de 8, 152 resultados',
    );
    expect(semanticsWithCenterLabel, findsOneWidget);
  });

  testWidgets('narrow width does not throw layout overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: AppInlinePaginationBar(
              centerLabel: 'Pagina 1 de 2',
              previousLabel: 'Anterior',
              nextLabel: 'Proxima',
              style: const AppInlinePaginationBarStyle(
                buttonsExpanded: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(AppBreakpoints.mobile > 400, isTrue);
    expect(tester.takeException(), isNull);
    expect(find.text('Pagina 1 de 2'), findsOneWidget);
  });
}
