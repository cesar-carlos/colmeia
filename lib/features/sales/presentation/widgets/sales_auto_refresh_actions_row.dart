import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
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
    this.nextDueAt,
    this.isBackingOff = false,
    super.key,
  });

  final AutoRefreshOption? value;
  final ValueChanged<AutoRefreshOption?> onChanged;
  final VoidCallback onRefreshNow;
  final bool enabled;
  final DateTime? lastUpdatedAt;
  final DateTime? nextDueAt;
  final bool isBackingOff;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AutoRefreshActionsRow(
      options: SalesAutoRefreshOptions.values,
      optionLabelBuilder: (option) => option.salesLabel,
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
      nextDueAt: nextDueAt,
      isBackingOff: isBackingOff,
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

  static String _format(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesLabel = minutes.toString().padLeft(1, '0');
    final secondsLabel = seconds.toString().padLeft(2, '0');
    return '$minutesLabel:$secondsLabel';
  }
}
