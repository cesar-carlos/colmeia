import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';

class ChartDemoShowcaseCard extends StatelessWidget {
  const ChartDemoShowcaseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlights,
    super.key,
    this.badgeLabel = 'Charts',
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> highlights;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCardWithHeading(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing + tokens.gapSm,
      ),
      titleWidget: _ChartDemoShowcaseHeading(
        icon: icon,
        title: title,
      ),
      subtitle: subtitle,
      headingTrailing: _ChartDemoShowcaseBadge(label: badgeLabel),
      headingBottom: _ChartDemoShowcaseLegend(highlights: highlights),
      style: AppSectionCardWithHeadingStyle(
        titleTextStyle: theme.appTypography.sectionHeaderH2.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: theme.appTypography.caption.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: highlights
            .map((item) => AppTagChip(label: item))
            .toList(growable: false),
      ),
    );
  }
}

class _ChartDemoShowcaseHeading extends StatelessWidget {
  const _ChartDemoShowcaseHeading({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.gapSm),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Expanded(
          child: Text(
            title,
            style: theme.appTypography.sectionHeaderH2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartDemoShowcaseBadge extends StatelessWidget {
  const _ChartDemoShowcaseBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _ChartDemoShowcaseLegend extends StatelessWidget {
  const _ChartDemoShowcaseLegend({required this.highlights});

  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: highlights
          .map(
            (item) => DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.formFieldRadius + 8),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.gapMd,
                  vertical: tokens.gapXs,
                ),
                child: Text(
                  item,
                  style: theme.appTypography.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
