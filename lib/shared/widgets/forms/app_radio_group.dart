import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppRadioOption<T> {
  const AppRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Vertically stacked single-select options (radio semantics without [Radio]).
class AppRadioGroup<T extends Object?> extends StatelessWidget {
  const AppRadioGroup({
    required this.groupValue,
    required this.onChanged,
    required this.options,
    super.key,
    this.enabled = true,
  });

  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final List<AppRadioOption<T>> options;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>();
    final visualSize = tokens?.formControlRadioOuter ?? 22;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        final selected = groupValue == option.value;

        return Semantics(
          selected: selected,
          button: true,
          enabled: enabled,
          label: option.label,
          child: InkWell(
            onTap: enabled
                ? () {
                    onChanged(option.value);
                  }
                : null,
            borderRadius: BorderRadius.circular(
              tokens?.formFieldRadius ?? 12,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (option.icon case final IconData iconData) ...<Widget>[
                    Icon(
                      iconData,
                      size: 22,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    SizedBox(width: tokens?.gapSm ?? 8),
                  ],
                  SizedBox(
                    width: visualSize,
                    height: visualSize,
                    child: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: visualSize,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: tokens?.gapSm ?? 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        if (option.subtitle case final String subtitle)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
