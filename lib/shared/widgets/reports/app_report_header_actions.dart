import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

enum AppReportHeaderActionTone { neutral, primary }

class AppReportHeaderActionButton extends StatelessWidget {
  const AppReportHeaderActionButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.tooltip,
    this.tone = AppReportHeaderActionTone.neutral,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? tooltip;
  final AppReportHeaderActionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final enabled = onPressed != null;
    final isPrimary = tone == AppReportHeaderActionTone.primary;
    final radius = BorderRadius.circular(tokens.formFieldRadius + 8);

    final foreground = enabled
        ? (isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    final background = isPrimary
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.42)
        : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.92);
    final border = isPrimary
        ? theme.colorScheme.primary.withValues(alpha: 0.22)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.gapMd,
            vertical: tokens.gapXs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 15, color: foreground),
                SizedBox(width: tokens.gapXs),
              ],
              Text(
                label,
                style: theme.appTypography.caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final message = tooltip;
    if (message == null || message.isEmpty) {
      return button;
    }

    return Tooltip(message: message, child: button);
  }
}

class AppReportHeaderActionsBar extends StatelessWidget {
  const AppReportHeaderActionsBar({
    required this.children,
    super.key,
    this.alignment = WrapAlignment.end,
  });

  final List<Widget> children;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Wrap(
      alignment: alignment,
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: children,
    );
  }
}
