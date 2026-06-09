import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:flutter/material.dart';

/// Tappable card for hub-style navigation grids (icon + short label).
class AppHubNavigationCard extends StatelessWidget {
  const AppHubNavigationCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.density = AppHubNavigationCardDensity.standard,
    this.aspectRatio = 1.15,
    this.labelStyle,
    this.showReadyBadge = false,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AppHubNavigationCardDensity density;
  final double aspectRatio;
  final TextStyle? labelStyle;
  final bool showReadyBadge;
  final String? semanticsLabel;

  bool get _usesFixedGridTile => density != AppHubNavigationCardDensity.standard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    final iconCircleSize = switch (density) {
      AppHubNavigationCardDensity.standard => 48.0,
      AppHubNavigationCardDensity.overview => 28.0,
      AppHubNavigationCardDensity.chartNav => 32.0,
    };
    final iconSize = switch (density) {
      AppHubNavigationCardDensity.standard => 24.0,
      AppHubNavigationCardDensity.overview => 16.0,
      AppHubNavigationCardDensity.chartNav => 18.0,
    };
    final iconLabelGap = switch (density) {
      AppHubNavigationCardDensity.standard => tokens.gapMd,
      AppHubNavigationCardDensity.overview => tokens.gapXs,
      AppHubNavigationCardDensity.chartNav => tokens.gapSm,
    };
    final resolvedLabelStyle = labelStyle ??
        switch (density) {
          AppHubNavigationCardDensity.standard => typography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              height: 1.2,
            ),
          AppHubNavigationCardDensity.overview => typography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              height: 1.15,
            ),
          AppHubNavigationCardDensity.chartNav => typography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              height: 1.2,
            ),
        };
    final cardPadding = switch (density) {
      AppHubNavigationCardDensity.standard => null,
      AppHubNavigationCardDensity.overview => EdgeInsets.symmetric(
          horizontal: tokens.gapXs,
          vertical: tokens.gapSm,
        ),
      AppHubNavigationCardDensity.chartNav => EdgeInsets.symmetric(
          horizontal: tokens.gapSm,
          vertical: tokens.gapSm,
        ),
    };
    final contentHorizontalPadding = switch (density) {
      AppHubNavigationCardDensity.standard => tokens.gapSm,
      AppHubNavigationCardDensity.overview => tokens.gapXs,
      AppHubNavigationCardDensity.chartNav => tokens.gapSm,
    };
    final readyBadgeSize = switch (density) {
      AppHubNavigationCardDensity.standard => 14.0,
      AppHubNavigationCardDensity.overview => 12.0,
      AppHubNavigationCardDensity.chartNav => 12.0,
    };
    final readyBadgeInset = switch (density) {
      AppHubNavigationCardDensity.standard => tokens.gapXs,
      AppHubNavigationCardDensity.overview => 2.0,
      AppHubNavigationCardDensity.chartNav => tokens.gapXs,
    };

    final iconBadge = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: iconCircleSize,
        height: iconCircleSize,
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: colors.primary,
          ),
        ),
      ),
    );

    final labelWidget = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: resolvedLabelStyle,
    );

    final cardBody = Stack(
      fit: _usesFixedGridTile ? StackFit.expand : StackFit.loose,
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: iconBadge),
                SizedBox(height: iconLabelGap),
                labelWidget,
              ],
            ),
          ),
        ),
        if (showReadyBadge)
          Positioned(
            top: readyBadgeInset,
            right: readyBadgeInset,
            child: Semantics(
              label: label,
              child: Icon(
                Icons.check_circle_outline,
                size: readyBadgeSize,
                color: colors.primary,
              ),
            ),
          ),
      ],
    );

    final sectionCard = AppSectionCard(
      padding: cardPadding,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          label: semanticsLabel ?? label,
          button: true,
          enabled: onTap != null,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            child: ExcludeSemantics(
              child: _usesFixedGridTile
                  ? SizedBox.expand(child: cardBody)
                  : cardBody,
            ),
          ),
        ),
      ),
    );

    final card = _usesFixedGridTile
        ? sectionCard
        : AspectRatio(aspectRatio: aspectRatio, child: sectionCard);

    final resolvedCard = onTap == null
        ? Opacity(
            opacity: 0.45,
            child: card,
          )
        : card;

    if (_usesFixedGridTile) {
      return Tooltip(message: label, child: resolvedCard);
    }
    return resolvedCard;
  }
}
