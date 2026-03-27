import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppShellPageIntro extends StatelessWidget {
  const AppShellPageIntro({
    required this.title,
    required this.subtitle,
    super.key,
    this.eyebrow,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (eyebrow != null) ...<Widget>[
          Text(
            eyebrow!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: tokens.gapXs),
        ],
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
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
