import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppProfileSectionTitle extends StatelessWidget {
  const AppProfileSectionTitle({
    required this.icon,
    required this.title,
    super.key,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;

    return Row(
      children: <Widget>[
        Icon(icon, size: 22, color: cs.primary),
        SizedBox(width: tokens.gapSm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
