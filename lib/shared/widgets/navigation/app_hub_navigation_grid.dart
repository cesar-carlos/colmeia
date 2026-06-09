import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:flutter/material.dart';

/// Layout metrics computed for one item in [AppHubNavigationGrid].
final class AppHubNavigationGridLayout {
  const AppHubNavigationGridLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.narrowLabelStyle,
  });

  final double cardWidth;
  final double cardHeight;

  /// Smaller label style when the tile is at minimum width.
  final TextStyle? narrowLabelStyle;
}

/// Responsive wrap grid for hub navigation card tiles.
class AppHubNavigationGrid extends StatelessWidget {
  const AppHubNavigationGrid({
    required this.itemCount,
    required this.itemBuilder,
    required this.density,
    super.key,
    this.minCardWidth,
    this.minCardHeight,
    this.standardAspectRatio,
    this.maxColumns,
    this.maxCardWidth,
    this.spacing,
    this.runSpacing,
    this.wrapAlignment = WrapAlignment.start,
  });

  final int itemCount;
  final AppHubNavigationCardDensity density;
  final Widget Function(
    BuildContext context,
    int index,
    AppHubNavigationGridLayout layout,
  )
  itemBuilder;
  final double? minCardWidth;
  final double? minCardHeight;
  final double? standardAspectRatio;
  final int? maxColumns;
  final double? maxCardWidth;
  final double? spacing;
  final double? runSpacing;
  final WrapAlignment wrapAlignment;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final typography = Theme.of(context).appTypography;
    final resolvedMinCardWidth =
        minCardWidth ?? density.gridMinCardWidth;
    final resolvedMinCardHeight =
        minCardHeight ?? density.gridMinCardHeight;
    final resolvedStandardAspectRatio =
        standardAspectRatio ?? kAppHubNavigationStandardCardAspectRatio;

    assert(
      density == AppHubNavigationCardDensity.standard ||
          resolvedMinCardHeight != null,
      'AppHubNavigationGrid requires a minCardHeight for $density',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = spacing ?? tokens.gapSm;
        final maxCols = maxColumns != null
            ? math.max(1, math.min(maxColumns!, itemCount))
            : math.max(
                1,
                math.min(
                  itemCount,
                  ((constraints.maxWidth + gap) /
                          (resolvedMinCardWidth + gap))
                      .floor(),
                ),
              );
        var cardWidth = math
            .max(
              resolvedMinCardWidth,
              (constraints.maxWidth - gap * (maxCols - 1)) / maxCols,
            )
            .floorToDouble();
        final resolvedMaxCardWidth = maxCardWidth;
        if (resolvedMaxCardWidth != null) {
          cardWidth = math
              .min(cardWidth, resolvedMaxCardWidth)
              .floorToDouble();
        }
        final cardHeight = switch (density) {
          AppHubNavigationCardDensity.chartNav => resolvedMinCardHeight!,
          AppHubNavigationCardDensity.standard =>
            (cardWidth / resolvedStandardAspectRatio).floorToDouble(),
          _ => (cardWidth *
                  resolvedMinCardHeight! /
                  resolvedMinCardWidth)
              .floorToDouble(),
        };
        final narrowLabelStyle =
            cardWidth <=
                    resolvedMinCardWidth +
                        kAppHubNavigationNarrowLabelWidthThreshold
                ? switch (density) {
                    AppHubNavigationCardDensity.chartNav =>
                      typography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: kAppHubNavigationNarrowLabelFontSizeChartNav,
                        height: 1.15,
                      ),
                    _ => typography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize:
                            kAppHubNavigationNarrowLabelFontSizeDefault,
                        height: 1.15,
                      ),
                  }
                : null;
        final layout = AppHubNavigationGridLayout(
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          narrowLabelStyle: narrowLabelStyle,
        );

        return Wrap(
          alignment: wrapAlignment,
          spacing: gap,
          runSpacing: runSpacing ?? gap,
          children: List<Widget>.generate(itemCount, (index) {
            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: itemBuilder(context, index, layout),
            );
          }, growable: false),
        );
      },
    );
  }
}
