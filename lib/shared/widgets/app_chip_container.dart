import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Pill-shaped surface shared by chip/badge atoms (`AppTagChip`,
/// `AppStatusBadge`).
///
/// Owns the common chrome — rounded background, optional border and the
/// standard inner padding — so each chip variant only provides its content and
/// resolved colors.
class AppChipContainer extends StatelessWidget {
  const AppChipContainer({
    required this.child,
    required this.backgroundColor,
    super.key,
    this.borderColor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: child,
      ),
    );
  }
}
