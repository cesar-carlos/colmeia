import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Scrollable list of drawer navigation rows; add items via [children].
class AppShellDrawerMenuList extends StatelessWidget {
  const AppShellDrawerMenuList({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: tokens.gapSm),
      itemBuilder: (context, index) => children[index],
    );
  }
}
