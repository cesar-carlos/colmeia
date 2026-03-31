import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppProfileStaticField extends StatelessWidget {
  const AppProfileStaticField({
    required this.label,
    required this.value,
    super.key,
    this.trailing,
    this.valueMuted = false,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final bool valueMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final typography = theme.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: typography.utilityOverline.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: tokens.gapXs),
                Text(
                  value,
                  style: typography.sectionHeaderH2.copyWith(
                    fontSize: theme.textTheme.titleSmall?.fontSize,
                    fontWeight: FontWeight.w600,
                    color: valueMuted
                        ? cs.onSurfaceVariant.withValues(alpha: 0.8)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
