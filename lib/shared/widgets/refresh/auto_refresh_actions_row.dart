import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_control.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_countdown_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AutoRefreshStatusTone { neutral, warning }

class AutoRefreshActionsRow extends StatelessWidget {
  const AutoRefreshActionsRow({
    required this.options,
    required this.optionLabelBuilder,
    required this.value,
    required this.onChanged,
    required this.onRefreshNow,
    required this.enabled,
    required this.refreshNowLabel,
    required this.offLabel,
    required this.tooltipLabel,
    super.key,
    this.lastUpdatedLabel,
    this.nextDueAt,
    this.isBackingOff = false,
    this.showAutoRefreshControl = true,
    this.refreshNowEnabled,
    this.controlEnabled,
    this.countdownLabelBuilder,
    this.countdownTicker,
    this.controlKeyPrefix = 'auto-refresh',
    this.statusLabel,
    this.statusTone = AutoRefreshStatusTone.neutral,
  });

  final List<AutoRefreshOption> options;
  final String Function(AutoRefreshOption option) optionLabelBuilder;
  final AutoRefreshOption? value;
  final ValueChanged<AutoRefreshOption?> onChanged;
  final VoidCallback onRefreshNow;
  final bool enabled;
  final String refreshNowLabel;
  final String offLabel;
  final String tooltipLabel;
  final String? lastUpdatedLabel;
  final DateTime? nextDueAt;
  final bool isBackingOff;
  final bool showAutoRefreshControl;
  final bool? refreshNowEnabled;
  final bool? controlEnabled;
  final AutoRefreshCountdownLabelBuilder? countdownLabelBuilder;
  final ValueListenable<DateTime>? countdownTicker;
  final String controlKeyPrefix;
  final String? statusLabel;
  final AutoRefreshStatusTone statusTone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.gapMd,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          if (lastUpdatedLabel != null)
            Text(
              lastUpdatedLabel!,
              style: theme.appTypography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (nextDueAt != null && countdownLabelBuilder != null)
            AutoRefreshCountdownText(
              nextDueAt: nextDueAt!,
              isBackingOff: isBackingOff,
              labelBuilder: countdownLabelBuilder!,
              ticker: countdownTicker,
            ),
          if (statusLabel != null)
            Text(
              statusLabel!,
              style: theme.appTypography.caption.copyWith(
                color: switch (statusTone) {
                  AutoRefreshStatusTone.neutral =>
                    theme.colorScheme.onSurfaceVariant,
                  AutoRefreshStatusTone.warning => tokens.warning,
                },
              ),
            ),
          TextButton.icon(
            onPressed: (refreshNowEnabled ?? enabled) ? onRefreshNow : null,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(refreshNowLabel),
          ),
          if (showAutoRefreshControl)
            AutoRefreshControl(
              options: options,
              optionLabelBuilder: optionLabelBuilder,
              value: value,
              onChanged: onChanged,
              offLabel: offLabel,
              tooltipLabel: tooltipLabel,
              enabled: controlEnabled ?? enabled,
              keyPrefix: controlKeyPrefix,
            ),
        ],
      ),
    );
  }
}
