import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    super.key,
    this.padding,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// When null, [Card] uses [ThemeData.cardTheme] (tonal surface).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(
      context,
    ).extension<AppThemeTokens>()!;

    return Card(
      color: color,
      child: Padding(
        padding: padding ?? EdgeInsets.all(tokens.contentSpacing),
        child: child,
      ),
    );
  }
}
