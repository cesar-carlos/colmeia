import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

/// Typography foundation preview aligned with the Colmeia design system.
class AppTypographyDemoPage extends StatelessWidget {
  const AppTypographyDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Foundations',
          title: 'Typography',
          subtitle:
              'Escala semantica do Colmeia para titulos, secoes, corpo e '
              'metadados.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          color: cs.surfaceContainerLowest,
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.contentSpacing,
            tokens.contentSpacing,
            tokens.contentSpacing + tokens.gapSm,
          ),
          titleWidget: _TypographyShowcaseHeading(
            titleStyle: typography.sectionHeaderH2,
            accentColor: cs.primary,
            tokens: tokens,
          ),
          subtitle:
              'Hierarquia editorial para telas, secoes, corpo e metadados do '
              'Colmeia.',
          headingTrailing: const _TypographyShowcaseBadge(),
          headingBottom: const _TypographyShowcaseLegend(),
          style: AppSectionCardWithHeadingStyle(
            headerBottomSpacing: tokens.sectionSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TypographySpecBlock(
                label: 'HEADLINE / MANROPE BOLD',
                accent: true,
                child: Text(
                  'Display H1',
                  style: typography.displayH1,
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              _TypographySpecBlock(
                label: 'HEADLINE / MANROPE SEMIBOLD',
                child: Text(
                  'Section Header H2',
                  style: typography.sectionHeaderH2,
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              _TypographySpecBlock(
                label: 'BODY / INTER REGULAR',
                child: Text(
                  'Standard UI body text for dashboards, descriptions, and '
                  'data narratives.',
                  style: typography.body.copyWith(color: cs.onSurface),
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              _TypographySpecBlock(
                label: 'CAPTION / INTER MEDIUM',
                child: Text(
                  'Utility labels, timestamp signatures, and metadata.',
                  style: typography.caption.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypographyShowcaseHeading extends StatelessWidget {
  const _TypographyShowcaseHeading({
    required this.titleStyle,
    required this.accentColor,
    required this.tokens,
  });

  final TextStyle titleStyle;
  final Color accentColor;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Type System',
          style: Theme.of(context).appTypography.utilityOverline.copyWith(
            color: accentColor,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Text(
              'Tt',
              style: titleStyle.copyWith(
                color: accentColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(width: tokens.gapSm),
            Text(
              'Typography',
              style: titleStyle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypographyShowcaseBadge extends StatelessWidget {
  const _TypographyShowcaseBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 6),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          'Scale',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _TypographyShowcaseLegend extends StatelessWidget {
  const _TypographyShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _TypographyLegendChip(label: 'Display'),
        _TypographyLegendChip(label: 'Section'),
        _TypographyLegendChip(label: 'Body'),
        _TypographyLegendChip(label: 'Caption'),
      ],
    );
  }
}

class _TypographyLegendChip extends StatelessWidget {
  const _TypographyLegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TypographySpecBlock extends StatelessWidget {
  const _TypographySpecBlock({
    required this.label,
    required this.child,
    this.accent = false,
  });

  final String label;
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: accent ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        child,
      ],
    );
  }
}
