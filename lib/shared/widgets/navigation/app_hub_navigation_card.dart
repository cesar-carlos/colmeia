import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Resolves the tooltip body shown on long-press for hub navigation cards.
String resolveAppHubNavigationTooltipMessage({
  required String label,
  String? subtitle,
  String? tooltipMessage,
}) {
  if (tooltipMessage != null) {
    return tooltipMessage;
  }
  final resolvedSubtitle = subtitle;
  if (resolvedSubtitle == null || resolvedSubtitle.isEmpty) {
    return label;
  }
  return '$label\n$resolvedSubtitle';
}

/// Tappable card for hub-style navigation grids (icon + short label).
class AppHubNavigationCard extends StatelessWidget {
  const AppHubNavigationCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.density = AppHubNavigationCardDensity.standard,
    this.aspectRatio = kAppHubNavigationStandardCardAspectRatio,
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

  bool get _usesFixedGridTile =>
      density != AppHubNavigationCardDensity.standard;

  String get _resolvedSemanticsLabel => semanticsLabel ?? label;

  String get _resolvedTooltipMessage => resolveAppHubNavigationTooltipMessage(
    label: label,
    tooltipMessage: tooltipMessage,
  );

  TooltipTriggerMode? get _tooltipTriggerMode {
    if (kIsWeb) {
      return TooltipTriggerMode.longPress;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => TooltipTriggerMode.longPress,
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

    final metrics = AppHubNavigationCardMetrics.forDensity(
      density,
      tokens: tokens,
      colors: colors,
      typography: typography,
    );
    final resolvedLabelStyle = labelStyle ?? metrics.labelStyle;
    final readyBadgeOnIcon = _readyBadgeOnIcon;
    final inkWellBorderRadius =
        metrics.cardBorderRadius ?? BorderRadius.circular(tokens.cardRadius);

    final iconCircle = DecoratedBox(
      decoration: metrics.iconUsesRoundedRect
          ? BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: metrics.cardBorderRadius,
            )
          : BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
      child: SizedBox(
        width: metrics.iconCircleSize,
        height: metrics.iconCircleSize,
        child: Center(
          child: Icon(
            icon,
            size: metrics.iconSize,
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
                    size: metrics.readyBadgeSize,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          )
        : iconCircle;

    final cardContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: iconBadge),
        SizedBox(height: metrics.iconLabelGap),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: metrics.labelMaxLines,
            overflow: TextOverflow.ellipsis,
            style: resolvedLabelStyle,
          ),
        ),
      ],
    );

    final paddedContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.contentHorizontalPadding,
      ),
      child: cardContent,
    );

    final cardBody = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        Center(child: paddedContent),
        if (showReadyBadge && !readyBadgeOnIcon)
          Positioned(
            top: metrics.readyBadgeInset,
            right: metrics.readyBadgeInset,
            child: Semantics(
              label: _resolvedSemanticsLabel,
              child: Icon(
                Icons.check_circle_outline,
                size: metrics.readyBadgeSize,
                color: colors.primary,
              ),
            ),
          ),
      ],
    );

    final sectionCard = AppSectionCard(
      padding: metrics.cardPadding,
      borderRadius: metrics.cardBorderRadius,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          label: _resolvedSemanticsLabel,
          button: true,
          enabled: onTap != null,
          child: InkWell(
            onTap: onTap,
            borderRadius: inkWellBorderRadius,
            child: ExcludeSemantics(
              child: SizedBox.expand(child: cardBody),
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

    return _wrapWithTooltip(resolvedCard);
  }

  Widget _wrapWithTooltip(Widget child) {
    return Tooltip(
      message: _resolvedTooltipMessage,
      triggerMode: _tooltipTriggerMode,
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 4),
      child: child,
    );
  }
}
