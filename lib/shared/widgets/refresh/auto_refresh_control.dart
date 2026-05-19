import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:flutter/material.dart';

class AutoRefreshControl extends StatelessWidget {
  const AutoRefreshControl({
    required this.options,
    required this.optionLabelBuilder,
    required this.value,
    required this.onChanged,
    required this.offLabel,
    required this.tooltipLabel,
    super.key,
    this.enabled = true,
    this.keyPrefix = 'auto-refresh',
  });

  final List<AutoRefreshOption> options;
  final String Function(AutoRefreshOption option) optionLabelBuilder;
  final AutoRefreshOption? value;
  final ValueChanged<AutoRefreshOption?> onChanged;
  final String offLabel;
  final String tooltipLabel;
  final bool enabled;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final selectedLabel = value == null ? offLabel : optionLabelBuilder(value!);

    return MenuAnchor(
      builder: (context, controller, child) {
        return Tooltip(
          message: tooltipLabel,
          child: AppFlatButton(
            fillWidth: false,
            semanticsLabel: '$tooltipLabel: $selectedLabel',
            onPressed: enabled
                ? () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.autorenew_rounded, size: 18),
                SizedBox(width: tokens.gapXs),
                Text(selectedLabel),
                SizedBox(width: tokens.gapXs),
                const Icon(Icons.arrow_drop_down_rounded, size: 18),
              ],
            ),
          ),
        );
      },
      menuChildren: <Widget>[
        MenuItemButton(
          key: ValueKey<String>('$keyPrefix-off'),
          leadingIcon: _SelectedAutoRefreshIcon(selected: value == null),
          onPressed: enabled ? () => onChanged(null) : null,
          child: Text(offLabel),
        ),
        const Divider(height: 1),
        for (final option in options)
          MenuItemButton(
            key: ValueKey<String>('$keyPrefix-${option.id}'),
            leadingIcon: _SelectedAutoRefreshIcon(selected: value == option),
            onPressed: enabled ? () => onChanged(option) : null,
            child: Text(optionLabelBuilder(option)),
          ),
      ],
    );
  }
}

class _SelectedAutoRefreshIcon extends StatelessWidget {
  const _SelectedAutoRefreshIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return const SizedBox(width: 24, height: 24);
    }
    return const Icon(Icons.check_rounded);
  }
}
