import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_chip_container.dart';
import 'package:flutter/material.dart';

class AppTagChip extends StatelessWidget {
  const AppTagChip({
    required this.label,
    super.key,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.onRemove,
    this.removeSemanticsLabel,
  });

  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onRemove;
  final String? removeSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final resolvedForeground = foregroundColor ?? cs.onSurfaceVariant;

    return AppChipContainer(
      backgroundColor:
          backgroundColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.72),
      borderColor: borderColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: resolvedForeground),
            SizedBox(width: tokens.gapXs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.utilityOverline.copyWith(
                color: resolvedForeground,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (onRemove != null) ...<Widget>[
            SizedBox(width: tokens.gapXs),
            Semantics(
              button: true,
              label: removeSemanticsLabel ?? 'Remove $label',
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: resolvedForeground,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
