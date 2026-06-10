import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_action_icon.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Header trailing actions shared by chart cards: custom slot, share, fullscreen.
class AppChartHeaderTrailing extends StatefulWidget {
  const AppChartHeaderTrailing({
    super.key,
    this.titleTrailing,
    this.onShare,
    this.shareProgressKey,
    this.shareEnabled = true,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
  });

  final Widget? titleTrailing;
  final VoidCallback? onShare;
  final Object? shareProgressKey;
  final bool shareEnabled;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final String? openFullscreenTooltip;
  final String? openFullscreenSemanticLabel;

  @override
  State<AppChartHeaderTrailing> createState() => _AppChartHeaderTrailingState();
}

class _AppChartHeaderTrailingState extends State<AppChartHeaderTrailing> {
  ValueListenable<int>? _shareListenable;

  @override
  void initState() {
    super.initState();
    _attachShareListener(widget.shareProgressKey);
  }

  @override
  void didUpdateWidget(covariant AppChartHeaderTrailing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shareProgressKey != widget.shareProgressKey) {
      _detachShareListener(oldWidget.shareProgressKey);
      _attachShareListener(widget.shareProgressKey);
    }
  }

  @override
  void dispose() {
    _detachShareListener(widget.shareProgressKey);
    super.dispose();
  }

  void _attachShareListener(Object? key) {
    if (key == null) {
      return;
    }
    _shareListenable = ChartShareGuard.listenableFor(key);
    _shareListenable!.addListener(_onShareProgressChanged);
  }

  void _detachShareListener(Object? key) {
    if (key == null || _shareListenable == null) {
      return;
    }
    _shareListenable!.removeListener(_onShareProgressChanged);
    _shareListenable = null;
  }

  void _onShareProgressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _shareInProgress {
    final key = widget.shareProgressKey;
    return key != null && ChartShareGuard.isInProgress(key);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    final actions = <Widget>[
      ?widget.titleTrailing,
      if (widget.onShare != null)
        _ChartHeaderShareAction(
          onPressed: widget.onShare!,
          inProgress: _shareInProgress,
          enabled: widget.shareEnabled,
          tooltip: widget.openShareTooltip ?? l10n.chartShareTooltip,
          semanticsLabel:
              widget.openShareSemanticLabel ?? l10n.chartShareTooltip,
        ),
      if (widget.onOpenFullscreen != null)
        _ChartHeaderIconAction(
          onPressed: widget.onOpenFullscreen!,
          tooltip:
              widget.openFullscreenTooltip ?? l10n.chartOpenFullscreenTooltip,
          semanticsLabel:
              widget.openFullscreenSemanticLabel ??
              l10n.chartOpenFullscreenTooltip,
          icon: Icons.open_in_full,
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    if (actions.length == 1) {
      return actions.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var index = 0; index < actions.length; index++) ...<Widget>[
          if (index > 0) SizedBox(width: tokens.gapXs),
          actions[index],
        ],
      ],
    );
  }
}

class _ChartHeaderShareAction extends StatelessWidget {
  const _ChartHeaderShareAction({
    required this.onPressed,
    required this.inProgress,
    required this.enabled,
    required this.tooltip,
    required this.semanticsLabel,
  });

  final VoidCallback onPressed;
  final bool inProgress;
  final bool enabled;
  final String tooltip;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !inProgress;
    Widget action = IconButton(
      onPressed: canPress ? onPressed : null,
      tooltip: tooltip,
      icon: inProgress
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
    final trimmedSemanticsLabel = semanticsLabel.trim();
    if (trimmedSemanticsLabel.isNotEmpty) {
      action = Semantics(
        button: true,
        label: trimmedSemanticsLabel,
        child: action,
      );
    }
    return action;
  }
}

class _ChartHeaderIconAction extends StatelessWidget {
  const _ChartHeaderIconAction({
    required this.onPressed,
    required this.tooltip,
    required this.semanticsLabel,
    required this.icon,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final String semanticsLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Widget action = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
    );
    final trimmedSemanticsLabel = semanticsLabel.trim();
    if (trimmedSemanticsLabel.isNotEmpty) {
      action = Semantics(
        button: true,
        label: trimmedSemanticsLabel,
        child: action,
      );
    }
    return action;
  }
}
