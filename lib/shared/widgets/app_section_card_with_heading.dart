import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

class AppSectionCardWithHeadingStyle {
  const AppSectionCardWithHeadingStyle({
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.titleTextAlign,
    this.subtitleTextAlign,
    this.crossAxisAlignment,
    this.headerBottomSpacing,
  });

  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextAlign? titleTextAlign;
  final TextAlign? subtitleTextAlign;
  final CrossAxisAlignment? crossAxisAlignment;
  final double? headerBottomSpacing;
}

/// [AppSectionCard] with a standard section title and optional subtitle above
/// [child].
class AppSectionCardWithHeading extends StatelessWidget {
  const AppSectionCardWithHeading({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.subtitleWidget,
    this.headingTrailing,
    this.headingBottom,
    this.style = const AppSectionCardWithHeadingStyle(),
    this.color,
    this.padding,
    this.borderRadius,
    this.borderSide,
    this.decoration,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? subtitleWidget;
  final Widget? headingTrailing;
  final Widget? headingBottom;
  final AppSectionCardWithHeadingStyle style;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final BorderSide? borderSide;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final crossAxisAlignment =
        style.crossAxisAlignment ?? CrossAxisAlignment.start;
    final resolvedTitleStyle =
        style.titleTextStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final resolvedSubtitleStyle =
        style.subtitleTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        );
    final headerBottomSpacing = style.headerBottomSpacing ?? tokens.gapMd;

    final hasTitle = titleWidget != null || (title?.trim().isNotEmpty ?? false);
    final hasSubtitle =
        subtitleWidget != null || (subtitle?.trim().isNotEmpty ?? false);

    return AppSectionCard(
      color: color,
      padding: padding,
      borderRadius: borderRadius,
      borderSide: borderSide,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: <Widget>[
          if (hasTitle || headingTrailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child:
                      titleWidget ??
                      Text(
                        title!,
                        style: resolvedTitleStyle,
                        textAlign: style.titleTextAlign,
                      ),
                ),
                if (headingTrailing != null) ...<Widget>[
                  SizedBox(width: tokens.gapMd),
                  headingTrailing!,
                ],
              ],
            ),
          if (hasSubtitle) ...<Widget>[
            SizedBox(height: tokens.gapXs),
            subtitleWidget ??
                Text(
                  subtitle!,
                  style: resolvedSubtitleStyle,
                  textAlign: style.subtitleTextAlign,
                ),
          ],
          if (headingBottom != null) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            headingBottom!,
          ],
          if (hasTitle || hasSubtitle || headingBottom != null)
            SizedBox(height: headerBottomSpacing),
          child,
        ],
      ),
    );
  }
}
