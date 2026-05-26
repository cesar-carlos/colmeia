import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
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
      ClientAgentsActionFeedbackKind.success => _SuccessBanner(message: message),
    };
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  /// Mirrors the icon size used by [InlineAlertBanner] so info and success
  /// banners share the same vertical rhythm.
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(tokens.inlineAlertCornerRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.formFieldPaddingHorizontal,
          vertical: tokens.gapMd,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.check_circle_outline_rounded,
              color: colorScheme.onPrimaryContainer,
              size: _iconSize,
            ),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(tokens.cardRadius);

    final tileContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading!,
          SizedBox(width: tokens.gapSm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              SizedBox(height: tokens.gapXs),
              Text(subtitle, style: theme.textTheme.bodySmall),
              if (trailing != null) ...<Widget>[
                SizedBox(height: tokens.gapSm),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    );

    final tap = onTap;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: AppSectionCard(
        color: colorScheme.surface,
        padding: EdgeInsets.zero,
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
        child: tap == null
            ? Padding(
                padding: EdgeInsets.all(tokens.gapMd),
                child: tileContent,
              )
            : InkWell(
                borderRadius: borderRadius,
                onTap: tap,
                child: Padding(
                  padding: EdgeInsets.all(tokens.gapMd),
                  child: tileContent,
                ),
              ),
      ),
    );
  }
}
