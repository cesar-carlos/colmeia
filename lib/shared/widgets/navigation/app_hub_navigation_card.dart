import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:flutter/foundation.dart';
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
    this.tooltipMessage,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AppHubNavigationCardDensity density;
  final double aspectRatio;
  final TextStyle? labelStyle;
  final bool showReadyBadge;
  final String? semanticsLabel;
  final String? tooltipMessage;

  bool get _usesFixedGridTile => density != AppHubNavigationCardDensity.standard;

  bool get _usesExpandFill =>
      density == AppHubNavigationCardDensity.overview;

  String get _resolvedTooltipMessage => tooltipMessage ?? label;

  TooltipTriggerMode? get _tooltipTriggerMode {
    if (kIsWeb) {
      return TooltipTriggerMode.longPress;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        TooltipTriggerMode.longPress,
      _ => null,
    };
  }

  bool get _readyBadgeOnIcon =>
      showReadyBadge && density == AppHubNavigationCardDensity.chartNav;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    final iconCircleSize = switch (density) {
      AppHubNavigationCardDensity.standard => 48.0,
      AppHubNavigationCardDensity.overview => 28.0,
      AppHubNavigationCardDensity.chartNav => 22.0,
    };
    final iconSize = switch (density) {
      AppHubNavigationCardDensity.standard => 24.0,
      AppHubNavigationCardDensity.overview => 16.0,
      AppHubNavigationCardDensity.chartNav => 13.0,
    };
    final iconLabelGap = switch (density) {
      AppHubNavigationCardDensity.standard => tokens.gapMd,
      AppHubNavigationCardDensity.overview => tokens.gapXs,
      AppHubNavigationCardDensity.chartNav => 2.0,
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
              height: 1.15,
            ),
        };
    final cardPadding = switch (density) {
      AppHubNavigationCardDensity.standard => null,
      AppHubNavigationCardDensity.overview => EdgeInsets.symmetric(
          horizontal: tokens.gapXs,
          vertical: tokens.gapSm,
        ),
      AppHubNavigationCardDensity.chartNav => EdgeInsets.symmetric(
          horizontal: tokens.gapXs,
          vertical: 2,
        ),
    };
    final contentHorizontalPadding = switch (density) {
      AppHubNavigationCardDensity.standard => tokens.gapSm,
      AppHubNavigationCardDensity.overview => tokens.gapXs,
      AppHubNavigationCardDensity.chartNav => tokens.gapXs,
    };
    final readyBadgeSize = switch (density) {
      AppHubNavigationCardDensity.standard => 14.0,
      AppHubNavigationCardDensity.overview => 12.0,
      AppHubNavigationCardDensity.chartNav => 11.0,
    };
    final readyBadgeInset = switch (density) {
      AppHubNavigationCardDensity.standard => tokens.gapXs,
      AppHubNavigationCardDensity.overview => 2.0,
      AppHubNavigationCardDensity.chartNav => 1.0,
    };
    final readyBadgeOnIcon = _readyBadgeOnIcon;
    final cardBorderRadius = switch (density) {
      AppHubNavigationCardDensity.chartNav =>
        BorderRadius.circular(tokens.formFieldRadius),
      _ => null,
    };
    final inkWellBorderRadius =
        cardBorderRadius ?? BorderRadius.circular(tokens.cardRadius);

    final iconCircle = DecoratedBox(
      decoration: switch (density) {
        AppHubNavigationCardDensity.chartNav => BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          ),
        _ => BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
      },
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

    final iconBadge = readyBadgeOnIcon
        ? Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              iconCircle,
              Positioned(
                right: -2,
                top: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: readyBadgeSize,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          )
        : iconCircle;

    final labelMaxLines = switch (density) {
      AppHubNavigationCardDensity.chartNav => 2,
      _ => 2,
    };
    final labelWidget = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: labelMaxLines,
      overflow: TextOverflow.ellipsis,
      style: resolvedLabelStyle,
    );

    final cardContent = Column(
      mainAxisSize:
          _usesFixedGridTile ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: iconBadge),
        SizedBox(height: iconLabelGap),
        if (_usesFixedGridTile)
          Flexible(
            child: Align(
              alignment: Alignment.topCenter,
              child: labelWidget,
            ),
          )
        else
          labelWidget,
      ],
    );

    final paddedContent = Padding(
      padding: EdgeInsets.symmetric(horizontal: contentHorizontalPadding),
      child: cardContent,
    );

    final cardBody = Stack(
      fit: _usesExpandFill ? StackFit.expand : StackFit.loose,
      clipBehavior: Clip.none,
      children: <Widget>[
        if (_usesExpandFill)
          Positioned.fill(
            child: Align(child: paddedContent),
          )
        else
          paddedContent,
        if (showReadyBadge && !readyBadgeOnIcon)
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
      borderRadius: cardBorderRadius,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          label: semanticsLabel ?? label,
          tooltip: _resolvedTooltipMessage,
          button: true,
          enabled: onTap != null,
          child: InkWell(
            onTap: onTap,
            borderRadius: inkWellBorderRadius,
            child: ExcludeSemantics(
              child: switch (density) {
                AppHubNavigationCardDensity.standard => cardBody,
                AppHubNavigationCardDensity.overview =>
                  SizedBox.expand(child: cardBody),
                AppHubNavigationCardDensity.chartNav => SizedBox.expand(
                    child: cardBody,
                  ),
              },
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
      return Tooltip(
        message: _resolvedTooltipMessage,
        triggerMode: _tooltipTriggerMode,
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(seconds: 4),
        child: resolvedCard,
      );
    }
    return resolvedCard;
  }
}
