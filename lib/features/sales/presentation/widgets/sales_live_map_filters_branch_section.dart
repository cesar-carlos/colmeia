import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
    required this.branches,
    required this.selectedBranchIds,
    required this.onChanged,
    required this.onSelectAllBranches,
    required this.onClearSelection,
  });

  final AppLocalizations l10n;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SalesLiveMapBranchOption> _filterBranches(String rawQuery) {
    final normalizedQuery = AppLocationLookupNormalizer.normalizeAddressLine(
      rawQuery,
    );
    final branches = widget.branches;
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return branches;
    }
    return branches
        .where((branch) {
          final searchTokens = resolveAppBranchDisplayModel(
            registrationName: branch.registrationName,
            fantasyName: branch.fantasyName,
            fallbackName: branch.registrationName,
            extraSearchTerms: <String>[
              branch.city,
              branch.uf,
              branch.agentName,
            ],
          ).searchTokens;
          final normalizedTokens =
              AppLocationLookupNormalizer.normalizeAddressLine(
                searchTokens,
              );
          return normalizedTokens?.contains(normalizedQuery) ?? false;
        })
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
                  for (final branch in filteredBranches)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: widget.selectedBranchIds.contains(
                        branch.branchRef,
                      ),
                      onChanged: (checked) => widget.onChanged(
                        branch: branch,
                        checked: checked,
                      ),
                      title: Text(
                        resolveAppBranchDisplayModel(
                          registrationName: branch.registrationName,
                          fantasyName: branch.fantasyName,
                          fallbackName: branch.registrationName,
                        ).primaryName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _BranchSelectionSubtitle(branch: branch),
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

class _BranchSelectionSubtitle extends StatelessWidget {
  const _BranchSelectionSubtitle({required this.branch});

  final SalesLiveMapBranchOption branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final display = resolveAppBranchDisplayModel(
      registrationName: branch.registrationName,
      fantasyName: branch.fantasyName,
      fallbackName: branch.registrationName,
    );
    final secondaryName = display.secondaryName;

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
            branch.city,
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
