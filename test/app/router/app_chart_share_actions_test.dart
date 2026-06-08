import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
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
}
