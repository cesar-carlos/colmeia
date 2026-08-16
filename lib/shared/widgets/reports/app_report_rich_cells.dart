import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';

class AppReportIconTitleSubtitleCell extends StatelessWidget {
  const AppReportIconTitleSubtitleCell({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.leadingBackgroundColor,
    this.leadingForegroundColor,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Color? leadingBackgroundColor;
  final Color? leadingForegroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final subtitleText = subtitle;
    final resolvedRadius = BorderRadius.circular(tokens.gapMd);

    final leadingWidget =
        leading ??
        (icon == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      leadingBackgroundColor ??
                      theme.colorScheme.surfaceContainerHighest,
                  borderRadius: resolvedRadius,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.28,
                    ),
                  ),
                ),
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color:
                          leadingForegroundColor ??
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ));

    return Row(
      children: <Widget>[
        if (leadingWidget != null) ...<Widget>[
          leadingWidget,
          SizedBox(width: tokens.gapSm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                style: typography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitleText != null && subtitleText.isNotEmpty)
                Text(
                  subtitleText,
                  style: typography.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppReportStatusPillCell extends StatelessWidget {
  const AppReportStatusPillCell({
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
    return AppTagChip(
      label: label,
      icon: icon,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
  }
}

class AppReportIconActionCell extends StatelessWidget {
  const AppReportIconActionCell({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(tokens.formFieldRadius + 8);
    final foreground =
        color ??
        (enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5));

    final message = tooltip?.trim();
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: (message != null && message.isNotEmpty) ? message : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  backgroundColor ??
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
              borderRadius: radius,
              border: Border.all(
                color:
                    borderColor ??
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Center(
              child: Icon(icon, size: iconSize, color: foreground),
            ),
          ),
        ),
      ),
    );

    if (message == null || message.isEmpty) {
      return button;
    }

    return Tooltip(message: message, child: button);
  }
}
