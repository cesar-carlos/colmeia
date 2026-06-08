import 'dart:async' show unawaited;

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fullscreen scaffold fills the full screen width on mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppChartFullscreenScaffold(
          title: 'Chart',
          child: SizedBox.expand(
            key: ValueKey<String>('fullscreen-child'),
            child: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(tester.getTopLeft(scaffoldFinder).dx, 0);
    expect(tester.getSize(scaffoldFinder).width, 390);
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('fullscreen-child')))
          .width,
      greaterThan(370),
    );
  });

  testWidgets('landscape uses compact vertical spacing', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppChartFullscreenScaffold(
          title: 'Chart',
          subtitle: 'Subtitle',
          child: SizedBox.expand(
            key: ValueKey<String>('landscape-child'),
            child: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );

    final childHeight = tester
        .getSize(find.byKey(const ValueKey<String>('landscape-child')))
        .height;
    final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
    final appBarHeight = tester.getSize(find.byType(AppBar)).height;

    expect(childHeight, greaterThan(scaffoldHeight - appBarHeight - 120));
    expect(find.text('Subtitle'), findsNothing);
  });

  testWidgets('Escape closes fullscreen scaffold when a route is on top', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const AppChartFullscreenScaffold(
                                title: 'Chart',
                                child: SizedBox.expand(
                                  child: ColoredBox(color: Color(0xFFE0E0E0)),
                                ),
                              ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppChartFullscreenScaffold), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AppChartFullscreenScaffold), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
