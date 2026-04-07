import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:flutter/material.dart';

class ClientAgentsFilterButton extends StatelessWidget {
  const ClientAgentsFilterButton({
    required this.activeCount,
    required this.l10n,
    super.key,
    this.onPressed,
  });

  final int activeCount;
  final AppLocalizations l10n;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters = activeCount > 0;

    return Tooltip(
      message: hasActiveFilters
          ? l10n.clientAgentsFiltersTooltipActive(activeCount)
          : l10n.clientAgentsFiltersTooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Badge.count(
          isLabelVisible: hasActiveFilters,
          count: activeCount,
          child: Icon(
            Icons.filter_list_rounded,
            color: hasActiveFilters ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}

class ClientAgentsActionFeedbackBanner extends StatelessWidget {
  const ClientAgentsActionFeedbackBanner({
    required this.message,
    required this.kind,
    super.key,
  });

  final String message;
  final ClientAgentsActionFeedbackKind? kind;

  @override
  Widget build(BuildContext context) {
    final resolvedKind = kind ?? ClientAgentsActionFeedbackKind.info;
    return switch (resolvedKind) {
      ClientAgentsActionFeedbackKind.info => InlineAlertBanner(
        message: message,
        icon: Icons.schedule_send_rounded,
      ),
      ClientAgentsActionFeedbackKind.success => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(
            Theme.of(context).extension<AppThemeTokens>()?.gapSm ?? 8,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            Theme.of(context).extension<AppThemeTokens>()?.gapMd ?? 12,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 18,
              ),
              SizedBox(
                width:
                    Theme.of(context).extension<AppThemeTokens>()?.gapSm ?? 8,
              ),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

enum ClientAgentsStatusChipKind { info, success, error, neutral }

class ClientAgentsStatusChip extends StatelessWidget {
  const ClientAgentsStatusChip({
    required this.label,
    required this.kind,
    super.key,
  });

  final String label;
  final ClientAgentsStatusChipKind kind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (backgroundColor, foregroundColor) = switch (kind) {
      ClientAgentsStatusChipKind.info => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      ClientAgentsStatusChipKind.success => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      ClientAgentsStatusChipKind.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      ClientAgentsStatusChipKind.neutral => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        backgroundColor: backgroundColor,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foregroundColor),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class ClientAgentsAgentTile extends StatelessWidget {
  const ClientAgentsAgentTile({
    required this.title,
    required this.subtitle,
    super.key,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final card = Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.gapMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: tokens.gapXs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (trailing != null) ...<Widget>[
                SizedBox(height: tokens.gapSm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null) {
      return card;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      onTap: onTap,
      child: card,
    );
  }
}
