import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppHubNavigationGridLayout?> pumpGrid(
    WidgetTester tester, {
    required double viewportWidth,
    required AppHubNavigationCardDensity density,
    double? minCardWidth,
  }) async {
    AppHubNavigationGridLayout? capturedLayout;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: viewportWidth,
              child: AppHubNavigationGrid(
                density: density,
                minCardWidth: minCardWidth,
                itemCount: 3,
                itemBuilder: (context, index, layout) {
                  capturedLayout ??= layout;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );

    return capturedLayout;
  }

  testWidgets(
    'uses narrow label style at minimum card width for overview density',
    (tester) async {
      final layout = await pumpGrid(
        tester,
        viewportWidth: kAppHubNavigationCardMinWidth * 3 + 16,
        density: AppHubNavigationCardDensity.overview,
        minCardWidth: kAppHubNavigationCardMinWidth,
      );

      expect(layout, isNotNull);
      expect(layout!.narrowLabelStyle, isNotNull);
      expect(
        layout.narrowLabelStyle!.fontSize,
        kAppHubNavigationNarrowLabelFontSizeDefault,
      );
    },
  );

  testWidgets(
    'drops narrow label style when card width exceeds threshold',
    (tester) async {
      final layout = await pumpGrid(
        tester,
        viewportWidth: 400,
        density: AppHubNavigationCardDensity.overview,
      );

      expect(layout, isNotNull);
      expect(layout!.narrowLabelStyle, isNull);
    },
  );

  testWidgets(
    'uses chart-nav narrow label font size at minimum width',
    (tester) async {
      final layout = await pumpGrid(
        tester,
        viewportWidth: kAppHubNavigationCardMinWidth * 3 + 16,
        density: AppHubNavigationCardDensity.chartNav,
        minCardWidth: kAppHubNavigationCardMinWidth,
      );

      expect(layout, isNotNull);
      expect(layout!.narrowLabelStyle, isNotNull);
      expect(
        layout.narrowLabelStyle!.fontSize,
        kAppHubNavigationNarrowLabelFontSizeChartNav,
      );
      expect(layout.cardHeight, kAppHubNavigationChartNavCardMinHeight);
    },
  );

  testWidgets(
    'derives standard density height from aspect ratio',
    (tester) async {
      final layout = await pumpGrid(
        tester,
        viewportWidth: 400,
        density: AppHubNavigationCardDensity.standard,
        minCardWidth: kAppHubNavigationCardMinWidth,
      );

      expect(layout, isNotNull);
      expect(
        layout!.cardHeight,
        (layout.cardWidth / kAppHubNavigationStandardCardAspectRatio)
            .floorToDouble(),
      );
    },
  );
}
