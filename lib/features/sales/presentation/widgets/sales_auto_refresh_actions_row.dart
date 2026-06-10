import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_auto_refresh_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesAutoRefreshActionsRow extends StatelessWidget {
  const SalesAutoRefreshActionsRow({
    required this.value,
    required this.onChanged,
    required this.onRefreshNow,
    required this.enabled,
    required this.lastUpdatedAt,
    required this.l10n,
    this.refreshNowEnabled,
    this.nextDueAt,
    this.isBackingOff = false,
    this.isPaused = false,
    this.pauseReason,
    this.options,
    super.key,
  });

  final List<AutoRefreshOption>? options;
  final AutoRefreshOption? value;
  final ValueChanged<AutoRefreshOption?> onChanged;
  final VoidCallback onRefreshNow;
  final bool enabled;
  final DateTime? lastUpdatedAt;
  final bool? refreshNowEnabled;
  final DateTime? nextDueAt;
  final bool isBackingOff;
  final bool isPaused;
  final AutoRefreshPauseReason? pauseReason;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AutoRefreshActionsRow(
      options: options ?? SalesAutoRefreshOptions.values,
      optionLabelBuilder: (option) =>
          SalesAutoRefreshL10n.intervalLabel(l10n, option),
      value: value,
      onChanged: onChanged,
      onRefreshNow: onRefreshNow,
      enabled: enabled,
      refreshNowLabel: l10n.salesAutoRefreshNow,
      offLabel: l10n.salesAutoRefreshOff,
      tooltipLabel: l10n.salesAutoRefreshTooltip,
      lastUpdatedLabel: lastUpdatedAt == null
          ? null
          : l10n.salesAutoRefreshLastUpdatedAt(
              DateFormat.Hm(l10n.localeName).format(lastUpdatedAt!),
            ),
      refreshNowEnabled: refreshNowEnabled,
      nextDueAt: isPaused ? null : nextDueAt,
      isBackingOff: isBackingOff,
      statusLabel: _resolveStatusLabel(),
      statusTone: pauseReason == AutoRefreshPauseReason.missingLocalToken
          ? AutoRefreshStatusTone.warning
          : AutoRefreshStatusTone.neutral,
      showAutoRefreshControl: AppBreakpoints.isDesktop(context),
      countdownLabelBuilder: (remaining, {required isBackingOff}) {
        final formatted = _format(remaining);
        return isBackingOff
            ? l10n.salesAutoRefreshRetryIn(formatted)
            : l10n.salesAutoRefreshNextIn(formatted);
      },
      controlKeyPrefix: 'sales-auto-refresh',
    );
  }

  String? _resolveStatusLabel() {
    if (!isPaused) {
      return null;
    }
    return switch (pauseReason) {
      AutoRefreshPauseReason.missingLocalToken =>
        l10n.salesAutoRefreshPausedMissingLocalToken,
      AutoRefreshPauseReason.noEligibleSelection =>
        l10n.salesAutoRefreshPausedNoEligibleSelection,
      AutoRefreshPauseReason.pageLoading => l10n.salesAutoRefreshPausedLoading,
      AutoRefreshPauseReason.unsupportedViewport =>
        l10n.salesAutoRefreshPausedUnsupportedViewport,
      AutoRefreshPauseReason.screenHidden => l10n.salesAutoRefreshPausedHidden,
      AutoRefreshPauseReason.routeHidden => l10n.salesAutoRefreshPausedHidden,
      null => l10n.salesAutoRefreshPaused,
    };
  }

  static String _format(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesLabel = minutes.toString().padLeft(1, '0');
    final secondsLabel = seconds.toString().padLeft(2, '0');
    return '$minutesLabel:$secondsLabel';
  }
}
