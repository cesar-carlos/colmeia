import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(
      context,
    ).extension<AppThemeTokens>()!;

    return Card(
      child: Padding(
        padding: padding ?? EdgeInsets.all(tokens.contentSpacing),
        child: child,
      ),
    );
  }
}
