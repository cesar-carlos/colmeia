import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Single navigation row for the app shell drawer (compact corners, M3 colors).
class AppShellDrawerMenuItem extends StatelessWidget {
  const AppShellDrawerMenuItem({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    final borderRadius = BorderRadius.circular(tokens.inlineAlertCornerRadius);
    final iconColor = selected ? colors.onPrimaryContainer : colors.onSurface;
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: selected ? colors.onPrimaryContainer : null,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: selected
          ? colors.onPrimaryContainer.withValues(alpha: 0.8)
          : colors.onSurfaceVariant,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.gapMd,
              vertical: tokens.gapSm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
                SizedBox(width: tokens.gapMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: titleStyle,
                      ),
                      if (subtitle != null) ...<Widget>[
                        SizedBox(height: tokens.gapXs),
                        Text(
                          subtitle!,
                          style: subtitleStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
