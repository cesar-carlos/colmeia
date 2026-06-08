import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_live_map_l10n.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Branch picker section of the sales live map filters sheet.
///
/// Shows the available branches with checkbox selection, search filtering,
/// and select-all / clear-all shortcuts. Also displays an informational
/// banner when the current selection is empty or lacks token-backed agents.
class SalesLiveMapFiltersBranchSection extends StatelessWidget {
  const SalesLiveMapFiltersBranchSection({
    required this.l10n,
    required this.tokens,
    required this.availableAgents,
    required this.branches,
    required this.selectedBranchIds,
    required this.hasSelectedBranch,
    required this.hasSelectedTokenBackedAgent,
    required this.onToggleBranch,
    required this.onSelectAllBranches,
    required this.onClearSelection,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final List<DashboardAgentOption> availableAgents;
  final List<SalesLiveMapBranchOption> branches;
  final Set<SalesLiveMapBranchRef> selectedBranchIds;
  final bool hasSelectedBranch;
  final bool hasSelectedTokenBackedAgent;
  final void Function({
    required SalesLiveMapBranchOption branch,
    required bool? checked,
  })
  onToggleBranch;
  final VoidCallback onSelectAllBranches;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesFiltersSectionHeader(
          title: l10n.salesLiveMapBranchesSectionTitle,
          subtitle: l10n.salesLiveMapBranchesSectionSubtitle,
        ),
        SizedBox(height: tokens.gapSm),
        _BranchSelectionPanel(
          l10n: l10n,
          availableAgents: availableAgents,
          branches: branches,
          selectedBranchIds: selectedBranchIds,
          onChanged: onToggleBranch,
          onSelectAllBranches: onSelectAllBranches,
          onClearSelection: onClearSelection,
        ),
        if (!hasSelectedBranch || !hasSelectedTokenBackedAgent) ...<Widget>[
          SizedBox(height: tokens.gapMd),
          AppInlineErrorPanel(
            tone: AppInlinePanelTone.informational,
            message: l10n.salesLiveMapSelectAtLeastOneTokenBranch,
          ),
        ],
      ],
    );
  }
}

class _BranchSelectionPanel extends StatefulWidget {
  const _BranchSelectionPanel({
    required this.l10n,
    required this.availableAgents,
    required this.branches,
    required this.selectedBranchIds,
    required this.onChanged,
    required this.onSelectAllBranches,
    required this.onClearSelection,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final List<SalesLiveMapBranchOption> branches;
  final Set<SalesLiveMapBranchRef> selectedBranchIds;
  final void Function({
    required SalesLiveMapBranchOption branch,
    required bool? checked,
  })
  onChanged;
  final VoidCallback onSelectAllBranches;
  final VoidCallback onClearSelection;

  @override
  State<_BranchSelectionPanel> createState() => _BranchSelectionPanelState();
}

class _BranchSelectionPanelState extends State<_BranchSelectionPanel> {
  final TextEditingController _searchController = TextEditingController();
  late List<_PreparedBranch> _preparedBranches;

  @override
  void initState() {
    super.initState();
    _preparedBranches = _prepareBranches(widget.branches);
  }

  @override
  void didUpdateWidget(covariant _BranchSelectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.branches, widget.branches)) {
      _preparedBranches = _prepareBranches(widget.branches);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, DashboardAgentOption> get _agentsById => {
    for (final agent in widget.availableAgents) agent.agentId: agent,
  };

  static List<_PreparedBranch> _prepareBranches(
    List<SalesLiveMapBranchOption> branches,
  ) {
    return branches.map(_PreparedBranch.fromOption).toList(growable: false);
  }

  List<_PreparedBranch> _filterBranches(String rawQuery) {
    final normalizedQuery = AppLocationLookupNormalizer.normalizeAddressLine(
      rawQuery,
    );
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return _preparedBranches;
    }
    return _preparedBranches
        .where(
          (prepared) =>
              prepared.normalizedSearchText?.contains(normalizedQuery) ?? false,
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    if (widget.branches.isEmpty) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        message: widget.l10n.salesLiveMapBranchesLoadBeforeSelection,
      );
    }

    return AppSectionCard(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.end,
            spacing: tokens.gapSm,
            runSpacing: tokens.gapXs,
            children: <Widget>[
              TextButton.icon(
                onPressed: widget.onSelectAllBranches,
                icon: const Icon(Icons.done_all_rounded),
                label: Text(widget.l10n.salesLiveMapSelectAllTokenBacked),
              ),
              TextButton.icon(
                onPressed: widget.selectedBranchIds.isEmpty
                    ? null
                    : widget.onClearSelection,
                icon: const Icon(Icons.remove_done_rounded),
                label: Text(widget.l10n.salesLiveMapClearSelection),
              ),
            ],
          ),
          SizedBox(height: tokens.gapXs),
          AppTextField(
            controller: _searchController,
            hintText: widget.l10n.brazilStoreSalesMapSidebarSearchPlaceholder,
            prefixIcon: Icons.search_rounded,
            density: AppTextFieldDensity.compact,
            semanticsLabel:
                widget.l10n.brazilStoreSalesMapSidebarSearchSemanticsLabel,
            textInputAction: TextInputAction.search,
          ),
          SizedBox(height: tokens.gapSm),
          // ValueListenableBuilder rebuilds on every TextEditingValue change
          // (text + selection + composition). We only care about the text, so
          // a Selector-like equality on .text would also work; the cost is
          // dominated by the list rebuild below, which is now cheap because
          // _preparedBranches is pre-computed.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              final filteredBranches = _filterBranches(value.text);
              if (filteredBranches.isEmpty) {
                return AppInlineErrorPanel(
                  tone: AppInlinePanelTone.informational,
                  message: widget
                      .l10n
                      .brazilStoreSalesMapSidebarSearchEmptyStateMessage,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final prepared in filteredBranches)
                    _BranchCheckboxTile(
                      key: ValueKey<SalesLiveMapBranchRef>(
                        prepared.branch.branchRef,
                      ),
                      l10n: widget.l10n,
                      prepared: prepared,
                      agent: _agentsById[prepared.branch.agentId],
                      checked: widget.selectedBranchIds.contains(
                        prepared.branch.branchRef,
                      ),
                      onChanged: (checked) => widget.onChanged(
                        branch: prepared.branch,
                        checked: checked,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Cached projection of a `SalesLiveMapBranchOption` used by the branch
/// picker — pre-computes the normalized search corpus and the primary /
/// secondary display names once per `widget.branches` update so each
/// keystroke avoids per-row allocations.
@immutable
class _PreparedBranch {
  const _PreparedBranch({
    required this.branch,
    required this.primaryName,
    required this.secondaryName,
    required this.normalizedSearchText,
  });

  factory _PreparedBranch.fromOption(SalesLiveMapBranchOption branch) {
    final display = resolveAppBranchDisplayModel(
      registrationName: branch.registrationName,
      fantasyName: branch.fantasyName,
      fallbackName: branch.registrationName,
      extraSearchTerms: <String>[
        branch.city,
        branch.uf,
        branch.agentName,
      ],
    );
    return _PreparedBranch(
      branch: branch,
      primaryName: display.primaryName,
      secondaryName: display.secondaryName,
      normalizedSearchText: AppLocationLookupNormalizer.normalizeAddressLine(
        display.searchTokens,
      ),
    );
  }

  final SalesLiveMapBranchOption branch;
  final String primaryName;
  final String? secondaryName;
  final String? normalizedSearchText;
}

class _BranchSelectionSubtitle extends StatelessWidget {
  const _BranchSelectionSubtitle({required this.prepared});

  final _PreparedBranch prepared;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryName = prepared.secondaryName;
    final branch = prepared.branch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (secondaryName != null)
          Text(
            secondaryName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          AppLocalizations.of(context).salesLiveMapFilterBranchSummaryLine(
            SalesLiveMapL10n.displayCity(
              AppLocalizations.of(context),
              branch.city,
            ),
            branch.uf,
            appBranchDisplayName(branch.agentName),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
        Text(
          AppLocalizations.of(context).salesLiveMapFilterBranchCodesLine(
            branch.codEmpresa.toString(),
            branch.codFilial.toString(),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BranchCheckboxTile extends StatelessWidget {
  const _BranchCheckboxTile({
    required this.l10n,
    required this.prepared,
    required this.agent,
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final _PreparedBranch prepared;
  final DashboardAgentOption? agent;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final agentOption = agent;
    final isOffline =
        agentOption?.connectionStatus == AgentConnectionStatus.offline;
    final missingToken = agentOption?.missingLocalClientToken ?? false;
    final canSelect = !isOffline;
    final titleColor = _branchAgentNameColor(
      agentOption?.connectionStatus ?? AgentConnectionStatus.unknown,
      colorScheme,
    );
    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (isOffline) ...<Widget>[
          Icon(Icons.cloud_off_outlined, size: 18, color: colorScheme.error),
          SizedBox(width: theme.appTokens.gapXs),
        ],
        if (missingToken) ...<Widget>[
          Icon(
            Icons.vpn_key_off_outlined,
            size: 18,
            color: colorScheme.tertiary,
          ),
          SizedBox(width: theme.appTokens.gapXs),
        ],
        Expanded(
          child: Text(
            prepared.primaryName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    final tooltipLines = <String>[
      if (isOffline) l10n.agentConnectionOffline,
      if (missingToken)
        l10n.overviewHomeBranchFilterMissingClientTokenRowSubtitle,
    ];

    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: checked,
      onChanged: canSelect ? onChanged : null,
      title: tooltipLines.isEmpty
          ? title
          : Tooltip(message: tooltipLines.join('\n'), child: title),
      subtitle: _BranchSelectionSubtitle(prepared: prepared),
      secondary: isOffline
          ? Icon(Icons.cloud_off_outlined, color: colorScheme.error)
          : missingToken
          ? Icon(Icons.vpn_key_off_outlined, color: colorScheme.tertiary)
          : null,
    );
  }
}

Color _branchAgentNameColor(
  AgentConnectionStatus status,
  ColorScheme scheme,
) {
  return switch (status) {
    AgentConnectionStatus.offline => scheme.error,
    AgentConnectionStatus.online ||
    AgentConnectionStatus.unknown =>
      scheme.onSurface,
  };
}
