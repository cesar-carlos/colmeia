import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_live_map_l10n.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

const double _kSalesLiveMapInlineIconSize = 18;
const int _kSalesLiveMapMaxVisibleUnmappedBranches = 6;

class SalesLiveMapAttentionPanel extends StatelessWidget {
  const SalesLiveMapAttentionPanel({
    required this.result,
    this.onRetry,
    this.onConfigureToken,
    this.canRetry = true,
    super.key,
  });

  final SalesLiveMapLoadResult result;
  final VoidCallback? onRetry;
  final VoidCallback? onConfigureToken;
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = SalesLiveMapViewModel.attentionMessages(result, l10n);
    final showConfigureToken =
        SalesLiveMapViewModel.shouldShowConfigureTokenAction(result);
    final hasDetailLists =
        result.failedAgentOptions.isNotEmpty ||
        result.missingClientTokenAgentOptions.isNotEmpty ||
        result.skippedOfflineAgentOptions.isNotEmpty ||
        result.noSalesAgentOptions.isNotEmpty ||
        result.unmappedBranchOptions.isNotEmpty;
    final hasActions = (canRetry && onRetry != null) || showConfigureToken;

    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: l10n.salesLiveMapPartialTitle,
      message: messages.join('\n'),
      onRetry: hasDetailLists || hasActions ? null : (canRetry ? onRetry : null),
      actions: hasDetailLists || hasActions
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (hasDetailLists)
                  _SalesLiveMapAttentionDetails(
                    failedAgents: result.failedAgentOptions,
                    missingTokenAgents: result.missingClientTokenAgentOptions,
                    offlineAgents: result.skippedOfflineAgentOptions,
                    noSalesAgents: result.noSalesAgentOptions,
                    unmappedBranches: result.unmappedBranchOptions,
                  ),
                if (hasActions) ...<Widget>[
                  if (hasDetailLists) SizedBox(height: context.appTokens.gapMd),
                  _SalesLiveMapAttentionActions(
                    l10n: l10n,
                    onRetry: canRetry ? onRetry : null,
                    onConfigureToken:
                        showConfigureToken ? onConfigureToken : null,
                  ),
                ],
              ],
            )
          : null,
    );
  }
}

class _SalesLiveMapAttentionActions extends StatelessWidget {
  const _SalesLiveMapAttentionActions({
    required this.l10n,
    this.onRetry,
    this.onConfigureToken,
  });

  final AppLocalizations l10n;
  final VoidCallback? onRetry;
  final VoidCallback? onConfigureToken;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: <Widget>[
        if (onRetry != null)
          FilledButton(
            onPressed: onRetry,
            child: Text(l10n.salesLiveMapRetryAction),
          ),
        if (onConfigureToken != null)
          AppSecondaryButton(
            label: l10n.salesLiveMapConfigureTokenAction,
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: onConfigureToken,
          ),
      ],
    );
  }
}

class _SalesLiveMapAttentionDetails extends StatelessWidget {
  const _SalesLiveMapAttentionDetails({
    required this.failedAgents,
    required this.missingTokenAgents,
    required this.offlineAgents,
    required this.noSalesAgents,
    required this.unmappedBranches,
  });

  final List<SalesLiveMapAgentOption> failedAgents;
  final List<SalesLiveMapAgentOption> missingTokenAgents;
  final List<SalesLiveMapAgentOption> offlineAgents;
  final List<SalesLiveMapAgentOption> noSalesAgents;
  final List<SalesLiveMapBranchOption> unmappedBranches;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (failedAgents.isNotEmpty)
          _SalesLiveMapAgentIssueList(
            title: AppLocalizations.of(context).salesLiveMapFailedAgentsTitle,
            agents: failedAgents,
            icon: Icons.error_outline,
          ),
        if (failedAgents.isNotEmpty &&
            (missingTokenAgents.isNotEmpty ||
                offlineAgents.isNotEmpty ||
                noSalesAgents.isNotEmpty ||
                unmappedBranches.isNotEmpty))
          SizedBox(height: tokens.gapSm),
        if (missingTokenAgents.isNotEmpty)
          _SalesLiveMapAgentIssueList(
            title: AppLocalizations.of(context)
                .salesLiveMapMissingTokenAgentsTitle,
            agents: missingTokenAgents,
            icon: Icons.vpn_key_off_outlined,
          ),
        if (missingTokenAgents.isNotEmpty &&
            (offlineAgents.isNotEmpty ||
                noSalesAgents.isNotEmpty ||
                unmappedBranches.isNotEmpty))
          SizedBox(height: tokens.gapSm),
        if (offlineAgents.isNotEmpty)
          _SalesLiveMapAgentIssueList(
            title: AppLocalizations.of(context).salesLiveMapOfflineAgentsTitle,
            agents: offlineAgents,
            icon: Icons.cloud_off_outlined,
          ),
        if (offlineAgents.isNotEmpty &&
            (noSalesAgents.isNotEmpty || unmappedBranches.isNotEmpty))
          SizedBox(height: tokens.gapSm),
        if (noSalesAgents.isNotEmpty)
          _SalesLiveMapNoSalesAgentsList(agents: noSalesAgents),
        if (noSalesAgents.isNotEmpty && unmappedBranches.isNotEmpty)
          SizedBox(height: tokens.gapSm),
        if (unmappedBranches.isNotEmpty)
          _SalesLiveMapUnmappedBranchesList(branches: unmappedBranches),
      ],
    );
  }
}

class _SalesLiveMapAgentIssueList extends StatelessWidget {
  const _SalesLiveMapAgentIssueList({
    required this.title,
    required this.agents,
    required this.icon,
  });

  final String title;
  final List<SalesLiveMapAgentOption> agents;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: tokens.gapXs),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final agent in agents)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  icon,
                  size: _kSalesLiveMapInlineIconSize,
                  color: colorScheme.primary,
                ),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Text(
                    appBranchDisplayName(agent.name),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SalesLiveMapNoSalesAgentsList extends StatelessWidget {
  const _SalesLiveMapNoSalesAgentsList({required this.agents});

  final List<SalesLiveMapAgentOption> agents;

  @override
  Widget build(BuildContext context) {
    return _SalesLiveMapAgentIssueList(
      title: AppLocalizations.of(context).salesLiveMapNoSalesAgentsTitle,
      agents: agents,
      icon: Icons.receipt_long_outlined,
    );
  }
}

class _SalesLiveMapUnmappedBranchesList extends StatelessWidget {
  const _SalesLiveMapUnmappedBranchesList({required this.branches});

  final List<SalesLiveMapBranchOption> branches;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final visibleBranches = branches
        .take(_kSalesLiveMapMaxVisibleUnmappedBranches)
        .toList(growable: false);
    final hiddenBranchCount = branches.length - visibleBranches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final branch in visibleBranches)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.location_off_outlined,
                  size: _kSalesLiveMapInlineIconSize,
                  color: colorScheme.primary,
                ),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Text(
                    SalesLiveMapL10n.formatUnmappedBranchLabel(l10n, branch),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hiddenBranchCount > 0)
          Padding(
            padding: EdgeInsets.only(
              left: _kSalesLiveMapInlineIconSize + tokens.gapSm,
            ),
            child: Text(
              '+ $hiddenBranchCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
