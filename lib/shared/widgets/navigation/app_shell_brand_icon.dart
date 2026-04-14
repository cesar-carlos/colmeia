import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Hexagonal brand icon used in the app bar and navigation panel header.
class AppShellBrandIcon extends StatelessWidget {
  const AppShellBrandIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
    );
  }
}
