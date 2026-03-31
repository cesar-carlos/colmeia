import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppTagChip extends StatelessWidget {
  const AppTagChip({
    required this.label,
    super.key,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final resolvedForeground = foregroundColor ?? cs.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 10),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: resolvedForeground),
              SizedBox(width: tokens.gapXs),
            ],
            Text(
              label,
              style: typography.utilityOverline.copyWith(
                color: resolvedForeground,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
