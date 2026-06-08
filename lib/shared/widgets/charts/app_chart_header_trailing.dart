import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_action_icon.dart';
import 'package:flutter/material.dart';

/// Header trailing actions shared by chart cards: custom slot, share, fullscreen.
class AppChartHeaderTrailing extends StatelessWidget {
  const AppChartHeaderTrailing({
    super.key,
    this.titleTrailing,
    this.onShare,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
  });

  final Widget? titleTrailing;
  final VoidCallback? onShare;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final String? openFullscreenTooltip;
  final String? openFullscreenSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    final actions = <Widget>[
      ?titleTrailing,
      if (onShare != null)
        _ChartHeaderIconAction(
          onPressed: onShare!,
          tooltip: openShareTooltip ?? l10n.chartShareTooltip,
          semanticsLabel: openShareSemanticLabel ?? l10n.chartShareTooltip,
          icon: chartShareActionIcon(),
        ),
      if (onOpenFullscreen != null)
        _ChartHeaderIconAction(
          onPressed: onOpenFullscreen!,
          tooltip: openFullscreenTooltip ?? l10n.chartOpenFullscreenTooltip,
          semanticsLabel:
              openFullscreenSemanticLabel ?? l10n.chartOpenFullscreenTooltip,
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
