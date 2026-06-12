import 'dart:async';

import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_action_icon.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:flutter/material.dart';

/// Share action for fullscreen chart scaffolds (header trailing slot).
Widget buildChartFullscreenShareTrailing({
  required BuildContext context,
  required GlobalKey shareKey,
  ChartShareMetadata? metadata,
  String? subject,
  String? subtitle,
  String? filterSummary,
}) {
  final l10n = AppLocalizations.of(context);
  final resolved =
      metadata ??
      ChartShareMetadata(
        title: subject ?? l10n.chartShareDefaultTitle,
        subtitle: subtitle,
        filterSummary: filterSummary,
        subject: subject,
      );
  return ChartShareIconButton(
    captureKey: shareKey,
    metadata: resolved,
  );
}

/// Header share icon with loading state and disabled-when-busy behavior.
class ChartShareIconButton extends StatefulWidget {
  const ChartShareIconButton({
    required this.captureKey,
    required this.metadata,
    this.enabled = true,
    super.key,
  });

  final GlobalKey captureKey;
  final ChartShareMetadata metadata;
  final bool enabled;

  @override
  State<ChartShareIconButton> createState() => _ChartShareIconButtonState();
}

class _ChartShareIconButtonState extends State<ChartShareIconButton> {
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    ChartShareGuard.listenableFor(
      widget.captureKey,
    ).addListener(_onShareProgressChanged);
  }

  @override
  void didUpdateWidget(covariant ChartShareIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.captureKey != widget.captureKey) {
      ChartShareGuard.listenableFor(
        oldWidget.captureKey,
      ).removeListener(_onShareProgressChanged);
      ChartShareGuard.listenableFor(
        widget.captureKey,
      ).addListener(_onShareProgressChanged);
    }
  }

  @override
  void dispose() {
    ChartShareGuard.listenableFor(
      widget.captureKey,
    ).removeListener(_onShareProgressChanged);
    super.dispose();
  }

  void _onShareProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _inProgress =>
      _generating || ChartShareGuard.isInProgress(widget.captureKey);

  Future<void> _onPressed() async {
    if (!widget.enabled || _inProgress) {
      return;
    }
    setState(() => _generating = true);
    try {
      final context = this.context;
      await shareChartCapture(
        context,
        widget.metadata.toShareRequest(widget.captureKey),
      );
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canPress = widget.enabled && !_inProgress;

    final action = IconButton(
      onPressed: canPress ? () => unawaited(_onPressed()) : null,
      tooltip: l10n.chartShareTooltip,
      icon: _inProgress
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(chartShareActionIcon()),
    );
    return Semantics(
      button: true,
      label: l10n.chartShareTooltip,
      child: action,
    );
  }
}
