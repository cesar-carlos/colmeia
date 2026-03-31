import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppShellPageIntro extends StatelessWidget {
  const AppShellPageIntro({
    required this.title,
    required this.subtitle,
    super.key,
    this.eyebrow,
    this.sectionLabel,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;

  /// Muted line under [eyebrow] (e.g. screen section name before the headline).
  final String? sectionLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (eyebrow != null) ...<Widget>[
          Text(
            eyebrow!,
            style: typography.utilityOverline.copyWith(
              color: cs.primary,
            ),
          ),
          SizedBox(height: tokens.gapXs),
        ],
        if (sectionLabel != null) ...<Widget>[
          Text(
            sectionLabel!,
            style: typography.sectionHeaderH2.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
        ],
        Text(
          title,
          style: typography.displayH1,
        ),
        SizedBox(height: tokens.gapSm),
        Text(
          subtitle,
          style: typography.body.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
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
