import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Editorial card with a media hero and text content below.
class AppEditorialMediaCard extends StatelessWidget {
  const AppEditorialMediaCard({
    required this.hero,
    required this.title,
    required this.description,
    super.key,
    this.footer,
    this.heroHeight = 176,
    this.contentPadding,
    this.heroBackgroundColor,
    this.onTap,
  });

  final Widget hero;
  final String title;
  final String description;
  final Widget? footer;
  final double heroHeight;
  final EdgeInsetsGeometry? contentPadding;
  final Color? heroBackgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final resolvedPadding =
        contentPadding ?? EdgeInsets.all(tokens.contentSpacing);
    final borderRadius = BorderRadius.circular(tokens.cardRadius);

    final cardChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: heroHeight,
          width: double.infinity,
          color: heroBackgroundColor ?? cs.surfaceContainerLowest,
          child: hero,
        ),
        Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: typography.sectionHeaderH2.copyWith(
                  fontSize: theme.textTheme.titleLarge?.fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.gapSm),
              Text(
                description,
                style: typography.body.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (footer != null) ...<Widget>[
                SizedBox(height: tokens.contentSpacing),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );

    return Material(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? cardChild
          : InkWell(
              onTap: onTap,
              child: cardChild,
            ),
    );
  }
}
