import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppShellPageIntro extends StatelessWidget {
  const AppShellPageIntro({
    required this.subtitle,
    super.key,
    this.title,
    this.eyebrow,
    this.sectionLabel,
    this.onSectionLabelTap,
    this.footer,
    this.leading,
  });

  final String? title;
  final String subtitle;
  final String? eyebrow;

  /// Muted line under [eyebrow] (e.g. screen section name before the headline).
  final String? sectionLabel;

  /// When set with [sectionLabel], the section line behaves as a link (e.g.
  /// navigate to the shell section root).
  final VoidCallback? onSectionLabelTap;

  final Widget? footer;

  /// Optional control aligned to the start of the title block (e.g. section back).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    final titles = _IntroTitles(
      typography: typography,
      colorScheme: cs,
      tokens: tokens,
      eyebrow: eyebrow,
      sectionLabel: sectionLabel,
      onSectionLabelTap: onSectionLabelTap,
      title: title,
      subtitle: subtitle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (leading != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              leading!,
              SizedBox(width: tokens.gapSm),
              Expanded(child: titles),
            ],
          )
        else
          titles,
        if (footer != null) ...<Widget>[
          SizedBox(height: tokens.gapMd),
          Material(
            type: MaterialType.transparency,
            child: footer,
          ),
        ],
      ],
    );
  }
}

class _IntroTitles extends StatelessWidget {
  const _IntroTitles({
    required this.typography,
    required this.colorScheme,
    required this.tokens,
    required this.subtitle,
    this.title,
    this.eyebrow,
    this.sectionLabel,
    this.onSectionLabelTap,
  });

  final AppTypographyTokens typography;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;
  final String? title;
  final String subtitle;
  final String? eyebrow;
  final String? sectionLabel;
  final VoidCallback? onSectionLabelTap;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final sectionStyle = typography.sectionHeaderH2.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (eyebrow != null) ...<Widget>[
          Text(
            eyebrow!,
            style: typography.utilityOverline.copyWith(
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: tokens.gapXs),
        ],
        if (sectionLabel != null) ...<Widget>[
          if (onSectionLabelTap != null)
            Semantics(
              button: true,
              label: AppLocalizations.of(context)
                  .shellSectionBreadcrumbSemantics(sectionLabel!),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onSectionLabelTap,
                  child: ExcludeSemantics(
                    child: Text(
                      sectionLabel!,
                      style: sectionStyle.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor:
                            colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(
              sectionLabel!,
              style: sectionStyle,
            ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        if (hasTitle) ...<Widget>[
          Text(
            title!.trim(),
            style: typography.displayH1,
          ),
          SizedBox(height: tokens.gapSm),
        ] else if (eyebrow != null) ...<Widget>[
          SizedBox(height: tokens.gapSm),
        ],
        Text(
          subtitle,
          style: typography.body.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
