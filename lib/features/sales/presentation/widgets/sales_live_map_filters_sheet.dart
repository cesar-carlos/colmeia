import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class SalesLiveMapFiltersSheet extends StatefulWidget {
  const SalesLiveMapFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.availableBranches,
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;
  final List<SalesLiveMapBranchOption> availableBranches;
  final SalesLiveMapFilter initialFilter;
  final ValueChanged<SalesLiveMapFilter> onApply;

  @override
  State<SalesLiveMapFiltersSheet> createState() =>
      _SalesLiveMapFiltersSheetState();
}

class _SalesLiveMapFiltersSheetState extends State<SalesLiveMapFiltersSheet> {
  late Set<String> _selectedBranchIds;
  late SalesLiveMapPeriodMode _periodMode;
  late SalesLiveMapMapDetail _detailLevel;
  late SalesLiveMapMarkerVisual _markerVisual;
  late DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    final branchIds = _branchIds;
    _selectedBranchIds = Set<String>.from(
      widget.initialFilter.selectedBranchIds ?? branchIds,
    );
    _periodMode = widget.initialFilter.periodMode;
    _detailLevel = widget.initialFilter.detailLevel;
    _markerVisual = _normalizeMarkerVisual(
      detailLevel: _detailLevel,
      markerVisual: widget.initialFilter.markerVisual,
    );
    _customRange = _dateTimeRangeFrom(
      widget.initialFilter.customDateRange ??
          const SalesLiveMapFilter().resolveDateRange(),
    );
  }

  Set<String> get _tokenBackedAgentIds => widget.availableAgents
      .where((agent) => !agent.missingLocalClientToken)
      .map((agent) => agent.agentId)
      .toSet();

  Set<String> get _branchIds =>
      widget.availableBranches.map((branch) => branch.id).toSet();

  bool get _hasSelectableBranchData => widget.availableBranches.isNotEmpty;

  bool get _hasSelectedBranch =>
      !_hasSelectableBranchData || _selectedBranchIds.any(_branchIds.contains);

  bool get _hasSelectedTokenBackedAgent {
    if (_hasSelectableBranchData) {
      return _selectedBranchIds
          .map(_agentIdForBranchId)
          .whereType<String>()
          .any(_tokenBackedAgentIds.contains);
    }
    return _tokenBackedAgentIds.isNotEmpty;
  }

  bool get _canApply =>
      _hasSelectedBranch &&
      _hasSelectedTokenBackedAgent &&
      _canApplyCustomRange;

  bool get _canApplyCustomRange {
    if (_periodMode != SalesLiveMapPeriodMode.customRange) {
      return true;
    }
    final range = _customRange;
    if (range == null) {
      return false;
    }
    final normalized = OverviewDateRange.fromOrderedEndpoints(
      range.start,
      range.end,
    );
    return normalized.inclusiveCalendarDayCount <=
        kSalesLiveMapMaxCustomRangeInclusiveDays;
  }

  void _apply() {
    if (!_canApply) {
      return;
    }

    OverviewDateRange? customDateRange;
    if (_periodMode == SalesLiveMapPeriodMode.customRange) {
      final picked = _customRange;
      if (picked == null) {
        return;
      }
      customDateRange =
          OverviewDateRange.fromOrderedEndpoints(
            picked.start,
            picked.end,
          ).clampedToMaxInclusiveCalendarDays(
            kSalesLiveMapMaxCustomRangeInclusiveDays,
          );
    }

    widget.onApply(
      SalesLiveMapFilter(
        selectedAgentIds: _normalizedSelectedAgentIds(),
        selectedBranchIds: _normalizedSelectedBranchIds(),
        periodMode: _periodMode,
        customDateRange: customDateRange,
        detailLevel: _detailLevel,
        markerVisual: _normalizeMarkerVisual(
          detailLevel: _detailLevel,
          markerVisual: _markerVisual,
        ),
        metric: widget.initialFilter.metric,
      ),
    );
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _selectedBranchIds = Set<String>.from(_branchIds);
      _periodMode = SalesLiveMapPeriodMode.today;
      _detailLevel = SalesLiveMapMapDetail.branches;
      _markerVisual = SalesLiveMapMarkerVisual.dot;
      _customRange = _dateTimeRangeFrom(
        const SalesLiveMapFilter().resolveDateRange(),
      );
    });
  }

  Set<String>? _normalizedSelectedAgentIds() {
    final selectedBranches = _normalizedSelectedBranchIds();
    if (selectedBranches == null) {
      return null;
    }

    final selectedAgents = selectedBranches
        .map(_agentIdForBranchId)
        .whereType<String>()
        .toSet();
    return selectedAgents.isEmpty
        ? null
        : Set<String>.unmodifiable(selectedAgents);
  }

  Set<String>? _normalizedSelectedBranchIds() {
    final branchIds = _branchIds;
    if (branchIds.isEmpty) {
      return _selectedBranchIds.isEmpty
          ? null
          : Set<String>.unmodifiable(_selectedBranchIds);
    }
    final selectedBranches = _selectedBranchIds
        .where(branchIds.contains)
        .toSet();
    if (selectedBranches.length == branchIds.length) {
      return null;
    }
    return Set<String>.unmodifiable(selectedBranches);
  }

  String? _agentIdForBranchId(String branchId) {
    for (final branch in widget.availableBranches) {
      if (branch.id == branchId) {
        return branch.agentId;
      }
    }
    return null;
  }

  void _toggleBranch(SalesLiveMapBranchOption branch, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selectedBranchIds.add(branch.id);
      } else {
        _selectedBranchIds.remove(branch.id);
      }
    });
  }

  void _changeDetailLevel(SalesLiveMapMapDetail detailLevel) {
    setState(() {
      _detailLevel = detailLevel;
      _markerVisual = _normalizeMarkerVisual(
        detailLevel: detailLevel,
        markerVisual: _markerVisual,
      );
    });
  }

  static SalesLiveMapMarkerVisual _normalizeMarkerVisual({
    required SalesLiveMapMapDetail detailLevel,
    required SalesLiveMapMarkerVisual markerVisual,
  }) {
    if (detailLevel == SalesLiveMapMapDetail.states) {
      return SalesLiveMapMarkerVisual.bubble;
    }
    return markerVisual;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final now = DateTime.now();
    final rangePickerFirstDate = DateTime(now.year - 2);
    final rangePickerLastDate = DateTime(now.year, now.month, now.day);

    return SalesFiltersSheetScaffold(
      title: widget.l10n.salesLiveMapFiltersTitle,
      description: widget.l10n.salesLiveMapFiltersDescription,
      primaryActionLabel: widget.l10n.reportFiltersApplyAction,
      secondaryActionLabel: widget.l10n.reportFiltersClearAction,
      canPrimaryAction: _canApply,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      bodyBuilder: (scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            0,
            tokens.contentSpacing,
            tokens.contentSpacing,
          ),
          children: <Widget>[
            SalesFiltersSectionHeader(
              title: widget.l10n.salesLiveMapBranchesSectionTitle,
              subtitle: widget.l10n.salesLiveMapBranchesSectionSubtitle,
            ),
            SizedBox(height: tokens.gapSm),
            _BranchSelectionPanel(
              l10n: widget.l10n,
              branches: widget.availableBranches,
              selectedBranchIds: _selectedBranchIds,
              onChanged: ({required branch, required checked}) {
                _toggleBranch(branch, checked);
              },
              onSelectAllBranches: () {
                setState(() => _selectedBranchIds = _branchIds);
              },
              onClearSelection: () {
                setState(_selectedBranchIds.clear);
              },
            ),
            if (!_hasSelectedBranch ||
                !_hasSelectedTokenBackedAgent) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: widget.l10n.salesLiveMapSelectAtLeastOneTokenBranch,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: widget.l10n.salesLiveMapPeriodLabel,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppSegmentedControl<SalesLiveMapPeriodMode>(
                    value: _periodMode,
                    expandToFill: true,
                    options:
                        <AppSegmentedControlOption<SalesLiveMapPeriodMode>>[
                          AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                            value: SalesLiveMapPeriodMode.today,
                            label: widget.l10n.salesLiveMapPeriodToday,
                          ),
                          AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                            value: SalesLiveMapPeriodMode.lastSevenDays,
                            label: widget
                                .l10n
                                .salesLiveMapPeriodLastSevenDaysShort,
                          ),
                          AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                            value: SalesLiveMapPeriodMode.currentMonth,
                            label:
                                widget.l10n.salesLiveMapPeriodCurrentMonthShort,
                          ),
                          AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                            value: SalesLiveMapPeriodMode.customRange,
                            label: widget.l10n.salesLiveMapPeriodCustom,
                          ),
                        ],
                    onChanged: (mode) => setState(() => _periodMode = mode),
                  ),
                  if (_periodMode == SalesLiveMapPeriodMode.customRange) ...[
                    SizedBox(height: tokens.gapMd),
                    AppDateRangePickerField(
                      label: widget.l10n.salesLiveMapCustomPeriodLabel,
                      helperText: widget.l10n.salesLiveMapCustomPeriodHelper(
                        kSalesLiveMapMaxCustomRangeInclusiveDays,
                      ),
                      pickerTitle:
                          widget.l10n.salesLiveMapCustomPeriodPickerTitle,
                      value: _customRange,
                      firstDate: rangePickerFirstDate,
                      lastDate: rangePickerLastDate,
                      density: AppTextFieldDensity.compact,
                      onChanged: (range) => setState(() {
                        _customRange = range;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: widget.l10n.salesLiveMapDetailLabel,
              subtitle: widget.l10n.salesLiveMapDetailSubtitle,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: AppSegmentedControl<SalesLiveMapMapDetail>(
                value: _detailLevel,
                expandToFill: true,
                options: <AppSegmentedControlOption<SalesLiveMapMapDetail>>[
                  AppSegmentedControlOption<SalesLiveMapMapDetail>(
                    value: SalesLiveMapMapDetail.branches,
                    label: widget.l10n.salesLiveMapDetailBranches,
                  ),
                  AppSegmentedControlOption<SalesLiveMapMapDetail>(
                    value: SalesLiveMapMapDetail.municipalities,
                    label: widget.l10n.salesLiveMapDetailMunicipalities,
                  ),
                  AppSegmentedControlOption<SalesLiveMapMapDetail>(
                    value: SalesLiveMapMapDetail.states,
                    label: widget.l10n.salesLiveMapDetailStates,
                  ),
                ],
                onChanged: _changeDetailLevel,
              ),
            ),
            if (_detailLevel != SalesLiveMapMapDetail.states) ...<Widget>[
              SizedBox(height: tokens.sectionSpacing),
              SalesFiltersSectionHeader(
                title: widget.l10n.salesLiveMapVisualLabel,
                subtitle: widget.l10n.salesLiveMapVisualSubtitle,
              ),
              SizedBox(height: tokens.gapSm),
              AppSectionCard(
                color: theme.colorScheme.surfaceContainerLow,
                child: AppSegmentedControl<SalesLiveMapMarkerVisual>(
                  value: _markerVisual,
                  expandToFill: true,
                  options:
                      <AppSegmentedControlOption<SalesLiveMapMarkerVisual>>[
                        AppSegmentedControlOption<SalesLiveMapMarkerVisual>(
                          value: SalesLiveMapMarkerVisual.dot,
                          label: widget.l10n.salesLiveMapVisualDot,
                        ),
                        AppSegmentedControlOption<SalesLiveMapMarkerVisual>(
                          value: SalesLiveMapMarkerVisual.bubble,
                          label: widget.l10n.salesLiveMapVisualBubble,
                        ),
                        AppSegmentedControlOption<SalesLiveMapMarkerVisual>(
                          value: SalesLiveMapMarkerVisual.storeIcon,
                          label: widget.l10n.salesLiveMapVisualStoreIcon,
                        ),
                      ],
                  onChanged: (visual) => setState(() {
                    _markerVisual = visual;
                  }),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static DateTimeRange _dateTimeRangeFrom(OverviewDateRange range) {
    return DateTimeRange(
      start: range.startInclusive,
      end: range.endInclusive,
    );
  }
}

class _BranchSelectionPanel extends StatelessWidget {
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
  final Set<String> selectedBranchIds;
  final void Function({
    required SalesLiveMapBranchOption branch,
    required bool? checked,
  })
  onChanged;
  final VoidCallback onSelectAllBranches;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    if (branches.isEmpty) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        message: l10n.salesLiveMapBranchesLoadBeforeSelection,
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
                onPressed: onSelectAllBranches,
                icon: const Icon(Icons.done_all_rounded),
                label: Text(l10n.salesLiveMapSelectAllTokenBacked),
              ),
              TextButton.icon(
                onPressed: selectedBranchIds.isEmpty ? null : onClearSelection,
                icon: const Icon(Icons.remove_done_rounded),
                label: Text(l10n.salesLiveMapClearSelection),
              ),
            ],
          ),
          SizedBox(height: tokens.gapXs),
          for (final branch in branches)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: selectedBranchIds.contains(branch.id),
              onChanged: (checked) => onChanged(
                branch: branch,
                checked: checked,
              ),
              title: Text(
                branch.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _BranchSelectionSubtitle(branch: branch),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${branch.city}/${branch.uf} - Agente ${branch.agentName}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
        Text(
          'Empresa: ${branch.codEmpresa}  Filial: ${branch.codFilial}',
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
