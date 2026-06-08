import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveFullscreenChartHeight', () {
    test('returns at least min height when viewport is tall enough', () {
      expect(
        resolveFullscreenChartHeight(
          maxHeight: 600,
          reservedHeight: 64,
        ),
        536,
      );
    });

    test('does not throw when maxHeight is below min chart height', () {
      expect(
        () => resolveFullscreenChartHeight(
          maxHeight: 150,
          reservedHeight: 64,
        ),
        returnsNormally,
      );
      expect(
        resolveFullscreenChartHeight(
          maxHeight: 150,
          reservedHeight: 64,
        ),
        86,
      );
    });

    test('clamps to zero when reserved height exceeds viewport', () {
      expect(
        resolveFullscreenChartHeight(
          maxHeight: 100,
          reservedHeight: 120,
        ),
        0,
      );
    });

    test('never returns negative height', () {
      expect(
        resolveFullscreenChartHeight(
          maxHeight: 50,
          reservedHeight: 48,
        ),
        greaterThanOrEqualTo(0),
      );
    });

    test('uses compact min height on short viewports', () {
      expect(
        resolveFullscreenChartMinHeight(220),
        greaterThanOrEqualTo(kFullscreenChartMinHeightCompact),
      );
      expect(
        resolveFullscreenChartMinHeight(220),
        lessThan(kFullscreenChartMinHeight),
      );
    });
  });

  group('resolveFullscreenBodyChartHeight', () {
    testWidgets('landscape uses full remaining height', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(844, 390);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double resolvedHeight;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              resolvedHeight = resolveFullscreenBodyChartHeight(
                context: context,
                maxHeight: 280,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedHeight, 280);
    });

    testWidgets('portrait keeps minimum chart height policy', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double resolvedHeight;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              resolvedHeight = resolveFullscreenBodyChartHeight(
                context: context,
                maxHeight: 600,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedHeight, 600);
    });
  });

  testWidgets('chart area expands to fill remaining landscape height', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const controlKey = ValueKey<String>('fullscreen-control');
    const chartKey = ValueKey<String>('fullscreen-chart');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final tokens = Theme.of(context).extension<AppThemeTokens>()!;
              return SizedBox(
                height: constraints.maxHeight,
                child: buildSegmentedControlFullscreenBody(
                  tokens: tokens,
                  control: const SizedBox(
                    key: controlKey,
                    height: 40,
                    child: Text('Control'),
                  ),
                  chartBuilder: (height) => SizedBox(
                    key: chartKey,
                    height: height,
                    child: Text('Chart $height'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final bodyHeight = tester.getSize(find.byType(Scaffold)).height;
    final controlHeight = tester.getSize(find.byKey(controlKey)).height;
    final chartHeight = tester.getSize(find.byKey(chartKey)).height;
    final tokens = AppTheme.light().extension<AppThemeTokens>()!;
    final gap = tokens.gapXs;

    expect(chartHeight, closeTo(bodyHeight - controlHeight - gap, 1));
    expect(chartHeight, greaterThan(bodyHeight * 0.5));
  });
}
