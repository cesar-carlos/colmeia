import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:flutter/material.dart';

enum SalesAutoRefreshInterval {
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
}

extension SalesAutoRefreshIntervalProperties on SalesAutoRefreshInterval {
  Duration get duration => switch (this) {
    SalesAutoRefreshInterval.fiveMinutes => const Duration(minutes: 5),
    SalesAutoRefreshInterval.tenMinutes => const Duration(minutes: 10),
    SalesAutoRefreshInterval.fifteenMinutes => const Duration(minutes: 15),
    SalesAutoRefreshInterval.thirtyMinutes => const Duration(minutes: 30),
  };

  String get label => switch (this) {
    SalesAutoRefreshInterval.fiveMinutes => '5 min',
    SalesAutoRefreshInterval.tenMinutes => '10 min',
    SalesAutoRefreshInterval.fifteenMinutes => '15 min',
    SalesAutoRefreshInterval.thirtyMinutes => '30 min',
  };
}

class SalesAutoRefreshControl extends StatelessWidget {
  const SalesAutoRefreshControl({
    required this.value,
    required this.onChanged,
    required this.offLabel,
    required this.tooltipLabel,
    super.key,
    this.enabled = true,
  });

  final SalesAutoRefreshInterval? value;
  final ValueChanged<SalesAutoRefreshInterval?> onChanged;
  final String offLabel;
  final String tooltipLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final selectedLabel = value?.label ?? offLabel;

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
          key: const ValueKey<String>('sales-auto-refresh-off'),
          leadingIcon: _SelectedAutoRefreshIcon(selected: value == null),
          onPressed: enabled ? () => onChanged(null) : null,
          child: Text(offLabel),
        ),
        const Divider(height: 1),
        for (final interval in SalesAutoRefreshInterval.values)
          MenuItemButton(
            key: ValueKey<String>('sales-auto-refresh-${interval.name}'),
            leadingIcon: _SelectedAutoRefreshIcon(selected: value == interval),
            onPressed: enabled ? () => onChanged(interval) : null,
            child: Text(interval.label),
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
