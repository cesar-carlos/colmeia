import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_constants.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_style.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:flutter/material.dart';

class CategoryDonutCardHeader extends StatelessWidget {
  const CategoryDonutCardHeader({
    required this.title,
    required this.style,
    this.subtitle,
    this.accentColor,
    this.titleTrailing,
    this.onShare,
    this.shareProgressKey,
    this.shareEnabled = true,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Color? accentColor;
  final Widget? titleTrailing;
  final VoidCallback? onShare;
  final Object? shareProgressKey;
  final bool shareEnabled;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final String? openFullscreenTooltip;
  final String? openFullscreenSemanticLabel;
  final AppCategoryDonutCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: tightenCategoryDonutTypographyFontSize(
            typography.sectionHeaderH2,
          ).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          SizedBox(height: tokens.gapXs),
          Text(
            subtitle!,
            style: tightenCategoryDonutTypographyFontSize(typography.body),
          ),
        ],
      ],
    );

    final accent = accentColor;
    final leading = accent != null
        ? Padding(
            padding: EdgeInsets.only(right: tokens.gapSm),
            child: Semantics(
              excludeSemantics: true,
              child: Container(
                width: style.titleAccentWidth,
                height: style.titleAccentHeight,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(
                    style.titleAccentWidth * 0.5,
                  ),
                ),
              ),
            ),
          )
        : null;

    final trailing =
        (titleTrailing == null && onShare == null && onOpenFullscreen == null)
        ? null
        : AppChartHeaderTrailing(
            titleTrailing: titleTrailing,
            onShare: onShare,
            shareProgressKey: shareProgressKey,
            shareEnabled: shareEnabled,
            openShareTooltip: openShareTooltip,
            openShareSemanticLabel: openShareSemanticLabel,
            onOpenFullscreen: onOpenFullscreen,
            openFullscreenTooltip: openFullscreenTooltip,
            openFullscreenSemanticLabel: openFullscreenSemanticLabel,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ?leading,
        Expanded(child: titleBlock),
        if (trailing != null) ...<Widget>[
          SizedBox(width: tokens.gapSm),
          trailing,
        ],
      ],
    );
  }
}
