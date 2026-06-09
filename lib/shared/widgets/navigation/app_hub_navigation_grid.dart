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
    required this.aspectRatio,
    required this.narrowLabelStyle,
  });

  final double cardWidth;
  final double cardHeight;
  final double aspectRatio;

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

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final typography = Theme.of(context).appTypography;
    final resolvedMinCardWidth =
        minCardWidth ?? density.gridMinCardWidth;
    final resolvedMinCardHeight =
        minCardHeight ?? density.gridMinCardHeight;
    assert(
      resolvedMinCardHeight != null,
      'AppHubNavigationGrid requires a minCardHeight for $density',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = tokens.gapSm;
        final maxCols = math.max(
          1,
          math.min(
            itemCount,
            ((constraints.maxWidth + gap) / (resolvedMinCardWidth + gap))
                .floor(),
          ),
        );
        final cardWidth = math
            .max(
              resolvedMinCardWidth,
              (constraints.maxWidth - gap * (maxCols - 1)) / maxCols,
            )
            .floorToDouble();
        final cardHeight = (cardWidth *
                resolvedMinCardHeight! /
                resolvedMinCardWidth)
            .floorToDouble();
        final aspectRatio = cardWidth / cardHeight;
        final narrowLabelStyle = cardWidth <= resolvedMinCardWidth + 4
            ? switch (density) {
                AppHubNavigationCardDensity.chartNav =>
                  typography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    height: 1.1,
                  ),
                _ => typography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    height: 1.15,
                  ),
              }
            : null;
        final layout = AppHubNavigationGridLayout(
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          aspectRatio: aspectRatio,
          narrowLabelStyle: narrowLabelStyle,
        );

        return Wrap(
          spacing: gap,
          runSpacing: gap,
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
