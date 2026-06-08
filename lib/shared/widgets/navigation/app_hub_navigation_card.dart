import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

/// Compact tappable card for hub-style navigation grids (icon + short label).
class AppHubNavigationCard extends StatelessWidget {
  const AppHubNavigationCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.aspectRatio = 1.15,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double aspectRatio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    final iconCircleSize = compact ? 28.0 : 48.0;
    final iconSize = compact ? 16.0 : 24.0;
    final iconLabelGap = compact ? tokens.gapXs : tokens.gapMd;
    final labelStyle = compact
        ? typography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
            height: 1.15,
          )
        : typography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
            height: 1.2,
          );
    final cardPadding = compact
        ? EdgeInsets.symmetric(
            horizontal: tokens.gapXs,
            vertical: tokens.gapSm,
          )
        : null;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: AppSectionCard(
        padding: cardPadding,
        child: Material(
          type: MaterialType.transparency,
          child: Semantics(
            label: label,
            button: true,
            enabled: onTap != null,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              child: ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? tokens.gapXs : tokens.gapSm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      DecoratedBox(
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
                      ),
                      SizedBox(height: iconLabelGap),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
