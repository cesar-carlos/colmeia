import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppShellDrawerHeader extends StatelessWidget {
  const AppShellDrawerHeader({
    super.key,
    this.title = 'Colmeia',
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              Icons.hexagon_rounded,
              size: 18,
              color: colors.onPrimary,
            ),
          ),
        ),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: typography.sectionHeaderH2.copyWith(
                  fontSize: theme.textTheme.titleMedium?.fontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                SizedBox(height: tokens.gapXs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
