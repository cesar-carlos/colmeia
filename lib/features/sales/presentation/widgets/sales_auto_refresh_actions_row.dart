import 'dart:async';

import 'package:colmeia/features/sales/domain/entities/sales_auto_refresh_preference.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
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

  final SalesAutoRefreshInterval? value;
  final ValueChanged<SalesAutoRefreshInterval?> onChanged;
  final VoidCallback onRefreshNow;
  final bool enabled;
  final DateTime? lastUpdatedAt;
  final DateTime? nextDueAt;
  final bool isBackingOff;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final updatedAt = lastUpdatedAt;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.gapMd,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          if (updatedAt != null)
            Text(
              l10n.salesAutoRefreshLastUpdatedAt(
                DateFormat.Hm(l10n.localeName).format(updatedAt),
              ),
              style: theme.appTypography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (value != null && nextDueAt != null)
            _SalesAutoRefreshCountdownLabel(
              nextDueAt: nextDueAt!,
              isBackingOff: isBackingOff,
              l10n: l10n,
            ),
          TextButton.icon(
            onPressed: enabled ? onRefreshNow : null,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.salesAutoRefreshNow),
          ),
          SalesAutoRefreshControl(
            value: value,
            onChanged: onChanged,
            offLabel: l10n.salesAutoRefreshOff,
            tooltipLabel: l10n.salesAutoRefreshTooltip,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class _SalesAutoRefreshCountdownLabel extends StatefulWidget {
  const _SalesAutoRefreshCountdownLabel({
    required this.nextDueAt,
    required this.isBackingOff,
    required this.l10n,
  });

  final DateTime nextDueAt;
  final bool isBackingOff;
  final AppLocalizations l10n;

  @override
  State<_SalesAutoRefreshCountdownLabel> createState() =>
      _SalesAutoRefreshCountdownLabelState();
}

class _SalesAutoRefreshCountdownLabelState
    extends State<_SalesAutoRefreshCountdownLabel> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _SalesAutoRefreshCountdownLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextDueAt != widget.nextDueAt) {
      _now = DateTime.now();
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = widget.nextDueAt.difference(_now);
    final clamped = remaining <= Duration.zero ? Duration.zero : remaining;
    final label = widget.isBackingOff
        ? widget.l10n.salesAutoRefreshRetryIn(_format(clamped))
        : widget.l10n.salesAutoRefreshNextIn(_format(clamped));
    return Text(
      label,
      style: theme.appTypography.caption.copyWith(
        color: widget.isBackingOff
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: widget.isBackingOff ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  String _format(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesLabel = minutes.toString().padLeft(1, '0');
    final secondsLabel = seconds.toString().padLeft(2, '0');
    return '$minutesLabel:$secondsLabel';
  }
}
