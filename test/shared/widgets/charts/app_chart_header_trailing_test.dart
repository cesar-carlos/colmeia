import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows share before fullscreen when both actions are provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppChartHeaderTrailing(
            onShare: () {},
            onOpenFullscreen: () {},
          ),
        ),
      ),
    );

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons.length, 2);
    expect(icons.first.icon, isNot(Icons.open_in_full));
    expect(icons.last.icon, Icons.open_in_full);
  });

  testWidgets('hides trailing when no actions are configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: AppChartHeaderTrailing(),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('shows progress indicator when share is in progress', (
    tester,
  ) async {
    const progressKey = Object();
    ChartShareGuard.tryAcquire(progressKey);
    addTearDown(() => ChartShareGuard.release(progressKey));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppChartHeaderTrailing(
            shareProgressKey: progressKey,
            onShare: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);
  });

  testWidgets('includes custom titleTrailing before share action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppChartHeaderTrailing(
            titleTrailing: const Text('Custom'),
            onShare: () {},
          ),
        ),
      ),
    );

    expect(find.text('Custom'), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);
  });
}
