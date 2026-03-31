import 'package:colmeia/shared/design_system/app_colors.dart';
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

enum AppRadioGroupVariant {
  stacked,
  compact,
}

/// Single-select options with stacked and compact layout variants.
class AppRadioGroup<T extends Object?> extends StatelessWidget {
  const AppRadioGroup({
    required this.groupValue,
    required this.onChanged,
    required this.options,
    super.key,
    this.enabled = true,
    this.variant = AppRadioGroupVariant.stacked,
  });

  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final List<AppRadioOption<T>> options;
  final bool enabled;
  final AppRadioGroupVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final visualSize = tokens?.formControlRadioOuter ?? 22;
    final gap = tokens?.gapSm ?? 8;

    if (variant == AppRadioGroupVariant.compact) {
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: options.map((option) {
          return _CompactRadioOption<T>(
            option: option,
            selected: groupValue == option.value,
            enabled: enabled,
            visualSize: visualSize,
            onChanged: onChanged,
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        return _StackedRadioOption<T>(
          option: option,
          selected: groupValue == option.value,
          enabled: enabled,
          visualSize: visualSize,
          onChanged: onChanged,
        );
      }).toList(),
    );
  }
}

class _StackedRadioOption<T extends Object?> extends StatelessWidget {
  const _StackedRadioOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.visualSize,
    required this.onChanged,
  });

  final AppRadioOption<T> option;
  final bool selected;
  final bool enabled;
  final double visualSize;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>();
    final radius = BorderRadius.circular(tokens?.formFieldRadius ?? 8);

    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      label: option.label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onChanged(option.value) : null,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primaryContainer.withValues(alpha: 0.4)
                    : scheme.surfaceContainerLowest,
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? colors.primary
                      : colors.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (option.icon case final IconData iconData) ...<Widget>[
                    Icon(
                      iconData,
                      size: 20,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
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
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
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
                            color: enabled
                                ? colors.onSurface
                                : colors.onSurface.withValues(alpha: 0.38),
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
                                color: enabled
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface.withValues(alpha: 0.38),
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
        ),
      ),
    );
  }
}

class _CompactRadioOption<T extends Object?> extends StatelessWidget {
  const _CompactRadioOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.visualSize,
    required this.onChanged,
  });

  final AppRadioOption<T> option;
  final bool selected;
  final bool enabled;
  final double visualSize;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>();
    final radius = BorderRadius.circular(tokens?.formFieldRadius ?? 8);

    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      label: option.label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onChanged(option.value) : null,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primaryContainer.withValues(alpha: 0.52)
                    : scheme.surfaceContainerLowest,
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      ? colors.primary
                      : colors.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (option.icon case final IconData iconData) ...<Widget>[
                    Icon(
                      iconData,
                      size: 18,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    SizedBox(width: tokens?.gapSm ?? 8),
                  ],
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: visualSize - 2,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens?.gapSm ?? 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        option.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? colors.onSurface
                              : colors.onSurface.withValues(alpha: 0.38),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (option.subtitle case final String subtitle)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: enabled
                                  ? colors.onSurfaceVariant
                                  : colors.onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
