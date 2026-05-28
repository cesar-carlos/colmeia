import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

const double _kSalesLiveMapInlineIconSize = 18;
const int _kSalesLiveMapMaxVisibleUnmappedBranches = 6;

class SalesLiveMapAttentionPanel extends StatelessWidget {
  const SalesLiveMapAttentionPanel({required this.result, super.key});

  final SalesLiveMapLoadResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = SalesLiveMapViewModel.attentionMessages(result, l10n);

    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: l10n.salesLiveMapPartialTitle,
      message: messages.join('\n'),
      actions:
          result.unmappedBranchOptions.isEmpty &&
              result.noSalesAgentOptions.isEmpty
          ? null
          : _SalesLiveMapAttentionDetails(
              noSalesAgents: result.noSalesAgentOptions,
              unmappedBranches: result.unmappedBranchOptions,
            ),
    );
  }
}

class _SalesLiveMapAttentionDetails extends StatelessWidget {
  const _SalesLiveMapAttentionDetails({
    required this.noSalesAgents,
    required this.unmappedBranches,
  });

  final List<SalesLiveMapAgentOption> noSalesAgents;
  final List<SalesLiveMapBranchOption> unmappedBranches;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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

class _SalesLiveMapNoSalesAgentsList extends StatelessWidget {
  const _SalesLiveMapNoSalesAgentsList({required this.agents});

  final List<SalesLiveMapAgentOption> agents;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: tokens.gapXs),
          child: Text(
            l10n.salesLiveMapNoSalesAgentsTitle,
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
                  Icons.receipt_long_outlined,
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

class _SalesLiveMapUnmappedBranchesList extends StatelessWidget {
  const _SalesLiveMapUnmappedBranchesList({required this.branches});

  final List<SalesLiveMapBranchOption> branches;

  @override
  Widget build(BuildContext context) {
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
                    SalesLiveMapViewModel.formatUnmappedBranchLabel(branch),
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
