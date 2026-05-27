import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filter_circle_palette.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/bottom_sheet_compact_drag_handle.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

const double _kAgentFilterCircleSize = 44;

class SalesBranchFilterCopy {
  const SalesBranchFilterCopy({
    required this.label,
    required this.emptyHint,
    required this.selectionEmpty,
    required this.sheetTitle,
    required this.sheetSearchHint,
    required this.noSearchResults,
    required this.missingClientTokenBanner,
  });

  factory SalesBranchFilterCopy.sales(AppLocalizations l10n) {
    return SalesBranchFilterCopy(
      label: l10n.salesBranchFilterLabel,
      emptyHint: l10n.salesBranchFilterEmptyHint,
      selectionEmpty: l10n.salesBranchPickerEmpty,
      sheetTitle: l10n.salesBranchFilterSheetTitle,
      sheetSearchHint: l10n.salesBranchFilterSheetSearchHint,
      noSearchResults: l10n.salesBranchFilterNoSearchResults,
      missingClientTokenBanner: l10n.salesBranchFilterMissingClientTokenBanner,
    );
  }

  final String label;
  final String emptyHint;
  final String selectionEmpty;
  final String sheetTitle;
  final String sheetSearchHint;
  final String noSearchResults;
  final String missingClientTokenBanner;
}

DashboardAgentOption? _salesFindBranch(
  List<DashboardAgentOption> branches,
  String? id,
) {
  if (id == null) {
    return null;
  }
  for (final branch in branches) {
    if (branch.agentId == id) {
      return branch;
    }
  }
  return null;
}

class SalesBranchPickerControl extends StatelessWidget {
  const SalesBranchPickerControl({
    required this.l10n,
    required this.availableBranches,
    required this.selectedBranchId,
    required this.onSelectionChanged,
    super.key,
    this.enabled = true,
    this.showTrailingFilterButton = true,
    this.copy,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableBranches;
  final String? selectedBranchId;
  final ValueChanged<String> onSelectionChanged;
  final bool enabled;
  final bool showTrailingFilterButton;
  final SalesBranchFilterCopy? copy;

  Future<void> _openSheet(BuildContext context) async {
    if (!enabled || availableBranches.isEmpty) {
      return;
    }

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (ctx) => _SalesBranchSelectionSheet(
        l10n: l10n,
        availableBranches: availableBranches,
        initialSelectedBranchId: selectedBranchId,
        copy: copy ?? SalesBranchFilterCopy.sales(l10n),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }
    onSelectionChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final labelToFieldGap = tokens.gapXs;
    final branchCopy = copy ?? SalesBranchFilterCopy.sales(l10n);

    if (availableBranches.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            branchCopy.label.toUpperCase(),
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: labelToFieldGap),
          Text(
            branchCopy.emptyHint,
            style: typography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final selectedBranch = _salesFindBranch(
      availableBranches,
      selectedBranchId,
    );
    final hasSelection = selectedBranch != null;

    void openSheet() => _openSheet(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          branchCopy.label.toUpperCase(),
          style: typography.utilityOverline.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: labelToFieldGap),
        Semantics(
          button: true,
          label: hasSelection
              ? '${branchCopy.label}: ${_branchPrimaryName(selectedBranch)}'
              : branchCopy.selectionEmpty,
          child: InkWell(
            onTap: enabled ? openSheet : null,
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
              child: Text(
                hasSelection
                    ? _branchPrimaryName(selectedBranch)
                    : branchCopy.selectionEmpty,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: typography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasSelection
                      ? scheme.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!showTrailingFilterButton) {
      return AppSectionCard(child: content);
    }

    return AppSectionCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: _kAgentFilterCircleSize + tokens.gapSm,
            ),
            child: content,
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Semantics(
              button: true,
              label: l10n.overviewAgentFilterEditAction,
              child: Material(
                color: SalesFilterCirclePalette.fill,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? openSheet : null,
                  child: SizedBox(
                    width: _kAgentFilterCircleSize,
                    height: _kAgentFilterCircleSize,
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 22,
                      color: enabled
                          ? SalesFilterCirclePalette.icon
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Deprecated('Use SalesBranchPickerControl instead.')
class SalesSingleAgentPickerControl extends StatelessWidget {
  @Deprecated('Use SalesBranchPickerControl instead.')
  const SalesSingleAgentPickerControl({
    required this.l10n,
    required this.availableAgents,
    required this.selectedAgentId,
    required this.onSelectionChanged,
    super.key,
    this.enabled = true,
    this.showTrailingFilterButton = true,
    this.copy,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final String? selectedAgentId;
  final ValueChanged<String> onSelectionChanged;
  final bool enabled;
  final bool showTrailingFilterButton;
  final SalesBranchFilterCopy? copy;

  @override
  Widget build(BuildContext context) {
    return SalesBranchPickerControl(
      l10n: l10n,
      availableBranches: availableAgents,
      selectedBranchId: selectedAgentId,
      onSelectionChanged: onSelectionChanged,
      enabled: enabled,
      showTrailingFilterButton: showTrailingFilterButton,
      copy: copy,
    );
  }
}

class _SalesBranchSelectionSheet extends StatefulWidget {
  const _SalesBranchSelectionSheet({
    required this.l10n,
    required this.availableBranches,
    required this.initialSelectedBranchId,
    required this.copy,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableBranches;
  final String? initialSelectedBranchId;
  final SalesBranchFilterCopy copy;

  @override
  State<_SalesBranchSelectionSheet> createState() =>
      _SalesBranchSelectionSheetState();
}

class _SalesBranchSelectionSheetState
    extends State<_SalesBranchSelectionSheet> {
  static const Duration _searchDebounceDelay = Duration(milliseconds: 120);

  String? _selectedBranchId;
  late final TextEditingController _searchController;
  Timer? _searchDebounceTimer;
  Map<String, DashboardAgentOption> _branchById =
      <String, DashboardAgentOption>{};
  late String _appliedFilterQuery;

  List<DashboardAgentOption>? _memoFilteredBranches;
  Object? _memoBranchesListIdentity;
  String? _memoFilterQuery;

  @override
  void initState() {
    super.initState();
    _rebuildBranchByIdMap();
    _appliedFilterQuery = '';
    _selectedBranchId = reconcileSelectedSalesAgentId(
      agents: widget.availableBranches,
      previousSelectedId: widget.initialSelectedBranchId,
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SalesBranchSelectionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.availableBranches, widget.availableBranches)) {
      return;
    }
    _rebuildBranchByIdMap();
    _invalidateFilteredBranchesCache();
    final nextId = reconcileSelectedSalesAgentId(
      agents: widget.availableBranches,
      previousSelectedId: _selectedBranchId,
    );
    if (nextId == _selectedBranchId) {
      return;
    }
    setState(() {
      _selectedBranchId = nextId;
    });
  }

  void _rebuildBranchByIdMap() {
    _branchById = <String, DashboardAgentOption>{
      for (final branch in widget.availableBranches) branch.agentId: branch,
    };
  }

  void _invalidateFilteredBranchesCache() {
    _memoFilteredBranches = null;
    _memoBranchesListIdentity = null;
    _memoFilterQuery = null;
  }

  void _scheduleSearchFilterRebuild() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (!mounted) {
        return;
      }
      final next = _searchController.text.trim().toLowerCase();
      if (!mounted || next == _appliedFilterQuery) {
        return;
      }
      setState(() {
        _appliedFilterQuery = next;
      });
    });
  }

  List<DashboardAgentOption> _getFilteredBranches() {
    final branches = widget.availableBranches;
    final q = _appliedFilterQuery;
    if (identical(_memoBranchesListIdentity, branches) &&
        _memoFilterQuery == q &&
        _memoFilteredBranches != null) {
      return _memoFilteredBranches!;
    }
    final result = q.isEmpty
        ? branches
        : branches
              .where(
                (branch) =>
                    _branchSearchTokens(branch).toLowerCase().contains(q),
              )
              .toList(growable: false);
    _memoBranchesListIdentity = branches;
    _memoFilterQuery = q;
    _memoFilteredBranches = result;
    return result;
  }

  void _toggleBranch(String branchId, bool? checked) {
    if (checked ?? false) {
      setState(() => _selectedBranchId = branchId);
    } else {
      setState(() => _selectedBranchId = null);
    }
  }

  void _apply() {
    Navigator.of(context).pop(_selectedBranchId);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.appTokens;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final filtered = _getFilteredBranches();

    final selectedBranchMissingToken =
        _selectedBranchId != null &&
        (_branchById[_selectedBranchId]?.missingLocalClientToken ?? false);

    final minChromePx = 232.0 + (selectedBranchMissingToken ? 88.0 : 0.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: draggableSheetMinChildFractionForChrome(
          viewportHeight: viewportHeight,
          minChromePixels: minChromePx,
        ),
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(560, MediaQuery.sizeOf(context).width),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BottomSheetCompactDragHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      0,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.copy.sheetTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _cancel,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.contentSpacing,
                      vertical: tokens.gapSm,
                    ),
                    child: AppTextField(
                      controller: _searchController,
                      autofocus: true,
                      hintText: widget.copy.sheetSearchHint,
                      prefixIcon: Icons.search_rounded,
                      density: AppTextFieldDensity.compact,
                      onChanged: (_) => _scheduleSearchFilterRebuild(),
                    ),
                  ),
                  if (selectedBranchMissingToken)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        0,
                        tokens.contentSpacing,
                        tokens.gapSm,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(tokens.gapSm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: scheme.primary,
                              ),
                              SizedBox(width: tokens.gapSm),
                              Expanded(
                                child: Text(
                                  widget.copy.missingClientTokenBanner,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(tokens.contentSpacing),
                              child: Text(
                                widget.copy.noSearchResults,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.contentSpacing,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final branch = filtered[index];
                              return _SalesBranchSheetCheckboxRow(
                                key: ValueKey(branch.agentId),
                                l10n: widget.l10n,
                                branch: branch,
                                scheme: scheme,
                                tokens: tokens,
                                theme: theme,
                                selected: _selectedBranchId == branch.agentId,
                                onChanged: (v) =>
                                    _toggleBranch(branch.agentId, v),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(tokens.contentSpacing),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancel,
                              child: Text(
                                widget.l10n.overviewAgentFilterCancel,
                              ),
                            ),
                          ),
                          SizedBox(width: tokens.gapMd),
                          Expanded(
                            child: FilledButton(
                              onPressed: _selectedBranchId != null
                                  ? _apply
                                  : null,
                              child: Text(widget.l10n.overviewAgentFilterApply),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SalesBranchSheetCheckboxRow extends StatelessWidget {
  const _SalesBranchSheetCheckboxRow({
    required this.l10n,
    required this.branch,
    required this.scheme,
    required this.tokens,
    required this.theme,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final DashboardAgentOption branch;
  final ColorScheme scheme;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final nameColor = _salesBranchNameColor(
      branch.connectionStatus,
      scheme,
    );
    final isOffline = branch.connectionStatus == AgentConnectionStatus.offline;

    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (isOffline) ...<Widget>[
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: scheme.error,
          ),
          SizedBox(width: tokens.gapXs),
        ],
        if (branch.missingLocalClientToken) ...<Widget>[
          Icon(
            Icons.vpn_key_off_outlined,
            size: 18,
            color: scheme.tertiary,
          ),
          SizedBox(width: tokens.gapXs),
        ],
        Expanded(
          child: Text(
            _branchPrimaryName(branch),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: nameColor),
          ),
        ),
      ],
    );

    final tooltipLines = <String>[
      if (isOffline) l10n.agentConnectionOffline,
      if (branch.missingLocalClientToken)
        l10n.overviewAgentFilterMissingClientTokenRowSubtitle,
    ];
    final titleWidget = tooltipLines.isEmpty
        ? title
        : Tooltip(
            message: tooltipLines.join('\n'),
            child: title,
          );

    return CheckboxListTile(
      title: titleWidget,
      subtitle: branch.missingLocalClientToken
          ? Text(
              l10n.overviewAgentFilterMissingClientTokenRowSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      dense: true,
      value: selected,
      onChanged: onChanged,
    );
  }
}

Color _salesBranchNameColor(
  AgentConnectionStatus status,
  ColorScheme scheme,
) {
  return switch (status) {
    AgentConnectionStatus.offline => scheme.error,
    AgentConnectionStatus.online ||
    AgentConnectionStatus.unknown => scheme.onSurface,
  };
}

String _branchPrimaryName(DashboardAgentOption branch) {
  return resolveAppBranchDisplayModel(fallbackName: branch.name).primaryName;
}

String _branchSearchTokens(DashboardAgentOption branch) {
  return resolveAppBranchDisplayModel(fallbackName: branch.name).searchTokens;
}
