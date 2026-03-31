import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Switch row with a compact card surface aligned to the design system.
class AppSwitchField extends StatelessWidget {
  const AppSwitchField({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
    this.enabled = true,
    this.helperText,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool enabled;
  final String? helperText;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>();
    final radius = BorderRadius.circular(tokens?.formFieldRadius ?? 8);
    final containerColor = value
        ? scheme.primaryContainer.withValues(alpha: 0.52)
        : scheme.surfaceContainerLowest;
    final borderColor = enabled
        ? (value
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0.72))
        : colors.onSurface.withValues(alpha: 0.12);
    final titleColor = enabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.38);
    final helperColor = enabled
        ? colors.onSurfaceVariant
        : colors.onSurface.withValues(alpha: 0.38);

    return Semantics(
      label: semanticLabel ?? label,
      enabled: enabled,
      toggled: value,
      child: MergeSemantics(
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? () => onChanged(!value) : null,
              borderRadius: radius,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: radius,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (helperText case final String resolvedHelperText)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                resolvedHelperText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: helperColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: tokens?.gapMd ?? 12),
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: Switch.adaptive(
                          value: value,
                          onChanged: enabled ? onChanged : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
