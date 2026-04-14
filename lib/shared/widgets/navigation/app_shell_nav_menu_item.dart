import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppShellNavMenuItem extends StatelessWidget {
  const AppShellNavMenuItem({
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
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final enabled = onTap != null;

    final borderRadius = BorderRadius.circular(tokens.inlineAlertCornerRadius);
    final backgroundColor = selected ? colors.primary : Colors.transparent;
    final iconColor = selected ? colors.onPrimary : colors.onSurfaceVariant;
    final titleStyle = typography.sectionHeaderH2.copyWith(
      fontSize: theme.textTheme.titleSmall?.fontSize,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: selected ? colors.onPrimary : colors.onSurface,
    );
    final subtitleStyle = typography.caption.copyWith(
      color: selected
          ? colors.onPrimary.withValues(alpha: 0.78)
          : colors.onSurfaceVariant,
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      child: Material(
        color: backgroundColor,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.gapMd,
              vertical: tokens.gapSm + tokens.gapXs,
            ),
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.onPrimary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      tokens.formFieldRadius,
                    ),
                  ),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
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
