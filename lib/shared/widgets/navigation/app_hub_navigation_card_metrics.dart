import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:flutter/material.dart';

/// Layout and typography metrics for one [AppHubNavigationCardDensity] preset.
final class AppHubNavigationCardMetrics {
  const AppHubNavigationCardMetrics({
    required this.iconCircleSize,
    required this.iconSize,
    required this.iconLabelGap,
    required this.contentHorizontalPadding,
    required this.readyBadgeSize,
    required this.readyBadgeInset,
    required this.labelMaxLines,
    required this.iconUsesRoundedRect,
    required this.labelStyle,
    this.cardPadding,
    this.cardBorderRadius,
  });

  factory AppHubNavigationCardMetrics.forDensity(
    AppHubNavigationCardDensity density, {
    required AppThemeTokens tokens,
    required AppColors colors,
    required AppTypographyTokens typography,
  }) {
    return switch (density) {
      AppHubNavigationCardDensity.standard => AppHubNavigationCardMetrics(
        iconCircleSize: 48,
        iconSize: 24,
        iconLabelGap: tokens.gapMd,
        contentHorizontalPadding: tokens.gapSm,
        readyBadgeSize: 14,
        readyBadgeInset: tokens.gapXs,
        labelMaxLines: 2,
        iconUsesRoundedRect: false,
        labelStyle: typography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
          height: 1.2,
        ),
      ),
      AppHubNavigationCardDensity.overview => AppHubNavigationCardMetrics(
        iconCircleSize: 28,
        iconSize: 16,
        iconLabelGap: tokens.gapXs,
        contentHorizontalPadding: tokens.gapXs,
        readyBadgeSize: 12,
        readyBadgeInset: 2,
        labelMaxLines: 3,
        iconUsesRoundedRect: false,
        cardPadding: EdgeInsets.symmetric(
          horizontal: tokens.gapXs,
          vertical: tokens.gapSm,
        ),
        labelStyle: typography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
          height: 1.15,
        ),
      ),
      AppHubNavigationCardDensity.chartNav => AppHubNavigationCardMetrics(
        iconCircleSize: 22,
        iconSize: 13,
        iconLabelGap: kAppHubNavigationChartNavIconLabelGap,
        contentHorizontalPadding: tokens.gapXs,
        readyBadgeSize: 11,
        readyBadgeInset: 1,
        labelMaxLines: 2,
        iconUsesRoundedRect: true,
        cardPadding: EdgeInsets.symmetric(
          horizontal: tokens.gapXs,
          vertical: 2,
        ),
        cardBorderRadius: BorderRadius.circular(tokens.formFieldRadius),
        labelStyle: typography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
          height: 1.15,
        ),
      ),
    };
  }

  final double iconCircleSize;
  final double iconSize;
  final double iconLabelGap;
  final double contentHorizontalPadding;
  final double readyBadgeSize;
  final double readyBadgeInset;
  final int labelMaxLines;
  final bool iconUsesRoundedRect;
  final EdgeInsetsGeometry? cardPadding;
  final BorderRadius? cardBorderRadius;
  final TextStyle labelStyle;
}
