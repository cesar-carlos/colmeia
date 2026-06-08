import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows share action when onShare is provided', (tester) async {
    var shareTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppHorizontalProgressChart<_Item>(
            title: 'Ranking',
            items: const <_Item>[_Item(label: 'Coffee', value: 10)],
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.value,
            onShare: () => shareTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Share chart'), findsOneWidget);

    await tester.tap(find.byTooltip('Share chart'));
    await tester.pumpAndSettle();

    expect(shareTapped, isTrue);
  });
}

class _Item {
  const _Item({required this.label, required this.value});

  final String label;
  final double value;
}
