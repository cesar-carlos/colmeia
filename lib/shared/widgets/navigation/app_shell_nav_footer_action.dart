import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppShellNavFooterAction extends StatelessWidget {
  const AppShellNavFooterAction({
    required this.icon,
    required this.label,
    super.key,
    this.onTap,
    this.isLoading = false,
    this.loadingSemanticsLabel = 'Encerrando sessao',
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final String loadingSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final enabled = onTap != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      liveRegion: isLoading,
      label: isLoading ? loadingSemanticsLabel : label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.inlineAlertCornerRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.gapSm,
              vertical: tokens.gapMd,
            ),
            child: Row(
              children: <Widget>[
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 20,
                    color: enabled
                        ? colors.onSurfaceVariant
                        : colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                SizedBox(width: tokens.gapMd),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.6),
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
