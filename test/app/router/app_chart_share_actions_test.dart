import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shareChartFromRequest shows SnackBar when capture fails', (
    tester,
  ) async {
    final shareKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  context.shareChartFromRequest(
                    AppChartShareRequest(captureKey: shareKey),
                  );
                },
                child: const Text('Share'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Share'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Chart is not ready to share yet. Try again.'),
      findsOneWidget,
    );
  });

  test('shouldPromptChartShareIncludeImage when builder and table exist', () {
    final request = AppChartShareRequest(
      captureKey: GlobalKey(),
      chartExportBuilder: _noopBuilder,
      tableData: const ChartShareTableData(
        headers: <String>['A'],
        rows: <List<String>>[
          <String>['1'],
        ],
      ),
    );

    expect(shouldPromptChartShareIncludeImage(request), isTrue);
  });

  test('shouldPromptChartShareIncludeImage skips table-only exports', () {
    final request = AppChartShareRequest(
      captureKey: GlobalKey(),
      tableData: const ChartShareTableData(
        headers: <String>['A'],
        rows: <List<String>>[
          <String>['1'],
        ],
      ),
    );

    expect(shouldPromptChartShareIncludeImage(request), isFalse);
  });

  testWidgets('showChartShareIncludeImageDialog defaults checkbox to off', (
    tester,
  ) async {
    bool? includeChartImage;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  includeChartImage = await showChartShareIncludeImageDialog(
                    context,
                  );
                },
                child: const Text('Open dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Include chart image'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(includeChartImage, isFalse);
  });

  testWidgets(
    'shows Open PDF action when share platform fails with temp path',
    (
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
                body: TextButton(
                  onPressed: () {
                    showChartShareFailureSnackBar(
                      context,
                      const ChartShareFailure(
                        ChartShareFailureReason.sharePlatformFailed,
                        pdfFilePath: r'C:\temp\chart.pdf',
                      ),
                    );
                  },
                  child: const Text('Show failure'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show failure'));
      await tester.pump();

      expect(find.text('Could not share chart. Try again.'), findsOneWidget);
      expect(find.text('Open PDF'), findsOneWidget);
    },
  );
}

Widget _noopBuilder(BuildContext context) => const SizedBox.shrink();
