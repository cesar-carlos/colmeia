import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
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
    final typography = theme.appTypography;
    final colors = theme.appColors;

    final borderRadius = BorderRadius.circular(tokens.inlineAlertCornerRadius);
    final iconColor = selected ? colors.primary : colors.onSurface;
    final titleStyle = typography.sectionHeaderH2.copyWith(
      fontSize: theme.textTheme.titleSmall?.fontSize,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: selected ? colors.primary : null,
    );
    final subtitleStyle = typography.caption.copyWith(
      color: selected
          ? colors.primary.withValues(alpha: 0.85)
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
          child: Stack(
            children: <Widget>[
              Padding(
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
              if (selected)
                PositionedDirectional(
                  top: 8,
                  bottom: 8,
                  end: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
