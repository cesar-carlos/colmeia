import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required String label,
    VoidCallback? onTap,
    String? tooltipMessage,
    AppHubNavigationCardDensity density = AppHubNavigationCardDensity.standard,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: density == AppHubNavigationCardDensity.standard
                  ? 148
                  : 90,
              child: AppHubNavigationCard(
                icon: Icons.insights,
                label: label,
                onTap: onTap,
                density: density,
                tooltipMessage: tooltipMessage,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('invokes onTap when enabled', (tester) async {
    var tapped = false;

    await pumpCard(
      tester,
      label: 'Vendas',
      onTap: () => tapped = true,
    );

    await tester.tap(find.text('Vendas'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('does not invoke onTap when disabled', (tester) async {
    await pumpCard(
      tester,
      label: 'Vendas',
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.45);
  });

  testWidgets('wraps every density with Tooltip', (tester) async {
    for (final density in AppHubNavigationCardDensity.values) {
      await pumpCard(
        tester,
        label: 'Nav item',
        onTap: () {},
        tooltipMessage: 'Full navigation label',
        density: density,
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Full navigation label');

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  test('resolveAppHubNavigationTooltipMessage joins subtitle', () {
    expect(
      resolveAppHubNavigationTooltipMessage(
        label: 'Title',
        subtitle: 'Subtitle body',
      ),
      'Title\nSubtitle body',
    );
    expect(
      resolveAppHubNavigationTooltipMessage(label: 'Title only'),
      'Title only',
    );
  });

  testWidgets(
    'overview density fits three label lines at text scale 1.3',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: kAppHubNavigationCardMinWidth,
                  height: kAppHubNavigationOverviewCardMinHeight,
                  child: AppHubNavigationCard(
                    icon: Icons.show_chart,
                    label: 'Line one two three four five six',
                    onTap: () {},
                    density: AppHubNavigationCardDensity.overview,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}
