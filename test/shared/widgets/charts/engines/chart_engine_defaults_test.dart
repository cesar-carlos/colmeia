import 'package:checks/checks.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  group('AppChartEngineAnimationDefaults', () {
    test('exposes the design-system default for cartesian series', () {
      check(AppChartEngineAnimationDefaults.cartesianSeriesMs).equals(350);
    });

    test('exposes the design-system default for circular series', () {
      check(AppChartEngineAnimationDefaults.circularSeriesMs).equals(500);
    });

    test('keeps the gauge default a touch slower than circular', () {
      check(AppChartEngineAnimationDefaults.gaugeMs).equals(600);
    });
  });

  group('resolveChartAnimationDurationMs', () {
    testWidgets(
      'returns the engine default when no style override is provided and '
      'reduce-motion is off',
      (tester) async {
        late double resolved;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                resolved = resolveChartAnimationDurationMs(
                  context: context,
                  styleDuration: null,
                  defaultMs: 350,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        check(resolved).equals(350);
      },
    );

    testWidgets(
      'honours an explicit style duration over the default',
      (tester) async {
        late double resolved;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                resolved = resolveChartAnimationDurationMs(
                  context: context,
                  styleDuration: const Duration(milliseconds: 750),
                  defaultMs: 350,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        check(resolved).equals(750);
      },
    );

    testWidgets(
      'returns 0 when MediaQuery requests reduced motion, regardless of style',
      (tester) async {
        late double resolved;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  resolved = resolveChartAnimationDurationMs(
                    context: context,
                    styleDuration: const Duration(milliseconds: 750),
                    defaultMs: 350,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        check(resolved).equals(0);
      },
    );
  });

  group('buildSanitizingTooltipRenderer', () {
    test('clears the Syncfusion default header even with no body resolver', () {
      final renderer = buildSanitizingTooltipRenderer();
      final args = TooltipArgs(0, <dynamic>[1], null, null)
        ..header = 'Series 0'
        ..text = 'PIX SICOOB 1: 12000';
      renderer(args);
      check(args.header).equals('');
      // Body untouched when no resolver is provided.
      check(args.text).equals('PIX SICOOB 1: 12000');
    });

    test('clears header and applies the body resolver when provided', () {
      final renderer = buildSanitizingTooltipRenderer(
        bodyResolver: (args) => r'CARTÃO: R$ 12.345',
      );
      final args = TooltipArgs(0, <dynamic>[1], null, null)
        ..header = 'Series 0'
        ..text = 'old body';
      renderer(args);
      check(args.header).equals('');
      check(args.text).equals(r'CARTÃO: R$ 12.345');
    });

    test('keeps the previous body when the resolver returns null/empty', () {
      final renderer = buildSanitizingTooltipRenderer(
        bodyResolver: (args) => null,
      );
      final args = TooltipArgs(0, <dynamic>[1], null, null)
        ..header = 'Series 0'
        ..text = 'preserved body';
      renderer(args);
      check(args.header).equals('');
      check(args.text).equals('preserved body');
    });
  });

  testWidgets(
    'buildChartTooltipBehavior uses inverseSurface coloring + bold body text',
    (tester) async {
      late TooltipBehavior behavior;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              behavior = buildChartTooltipBehavior(context, enable: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final colorScheme = ThemeData.light().colorScheme;
      check(behavior.enable).isTrue();
      check(behavior.color).equals(colorScheme.inverseSurface);
      check(behavior.borderWidth).equals(0);
      final textStyle = behavior.textStyle!;
      check(textStyle.color).equals(colorScheme.onInverseSurface);
      check(textStyle.fontWeight).equals(FontWeight.w600);
    },
  );
}
