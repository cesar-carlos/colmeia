import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppProfileInteractiveField extends StatelessWidget {
  const AppProfileInteractiveField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
    this.emphasizeValue = false,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool emphasizeValue;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    final TextStyle? valueStyle;
    if (isPlaceholder) {
      valueStyle = theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant.withValues(alpha: 0.72),
        fontStyle: FontStyle.italic,
      );
    } else if (emphasizeValue) {
      valueStyle = theme.textTheme.titleSmall?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.w700,
      );
    } else {
      valueStyle = theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        child: Padding(
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs),
                    Text(value, style: valueStyle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
