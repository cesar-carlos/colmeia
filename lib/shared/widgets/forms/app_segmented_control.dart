import 'package:flutter/material.dart';

class AppSegmentedControlOption<T> {
  const AppSegmentedControlOption({
    required this.value,
    required this.label,
    this.tooltip,
  });

  final T value;
  final String label;
  final String? tooltip;
}

/// Shared single-select segmented control for inline filters.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.options,
    required this.value,
    this.onChanged,
    super.key,
    this.expandToFill = false,
  });

  final List<AppSegmentedControlOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    final control = SegmentedButton<T>(
      segments: options
          .map(
            (option) => ButtonSegment<T>(
              value: option.value,
              label: option.tooltip == null
                  ? Text(option.label)
                  : Tooltip(
                      message: option.tooltip,
                      child: Text(option.label),
                    ),
            ),
          )
          .toList(growable: false),
      selected: <T>{value},
      showSelectedIcon: false,
      onSelectionChanged: onChanged == null
          ? null
          : (selection) => onChanged!(selection.first),
    );

    if (expandToFill) {
      return SizedBox(width: double.infinity, child: control);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: control,
    );
  }
}
