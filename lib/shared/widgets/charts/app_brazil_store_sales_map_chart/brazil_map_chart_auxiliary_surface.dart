import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class BrazilMapChartAuxiliarySurface extends StatelessWidget {
  const BrazilMapChartAuxiliarySurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapSm,
        ),
        child: child,
      ),
    );
  }
}
