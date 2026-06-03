import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_branch_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_detail_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_period_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_visual_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/material.dart';

const int _kSalesLiveMapFilterMinYearsBack = 2;

class SalesLiveMapFiltersSheet extends StatefulWidget {
  const SalesLiveMapFiltersSheet({
    required this.l10n,
    required this.availableAgents,
    required this.availableBranches,
    required this.initialFilter,
    required this.onApply,
    this.isApplyEnabled = true,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;
  final List<SalesLiveMapBranchOption> availableBranches;
  final SalesLiveMapFilter initialFilter;
  final ValueChanged<SalesLiveMapFilter> onApply;
  final bool isApplyEnabled;

  @override
  State<SalesLiveMapFiltersSheet> createState() =>
      _SalesLiveMapFiltersSheetState();
}

class _SalesLiveMapFiltersSheetState extends State<SalesLiveMapFiltersSheet> {
  late Set<SalesLiveMapBranchRef> _selectedBranchIds;
  late SalesLiveMapPeriodMode _periodMode;
  late SalesLiveMapMapDetail _detailLevel;
  late SalesLiveMapMarkerVisual _markerVisual;
  late DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    final branchIds = _branchIds;
    _selectedBranchIds = Set<SalesLiveMapBranchRef>.from(
      widget.initialFilter.selectedBranchIds ?? branchIds,
    );
    _periodMode = widget.initialFilter.periodMode;
    _detailLevel = widget.initialFilter.detailLevel;
    _markerVisual = SalesLiveMapVisualSpec.resolveMarkerVisual(
      detailLevel: _detailLevel,
      markerVisual: widget.initialFilter.markerVisual,
    );
    _customRange = _dateTimeRangeFrom(
      widget.initialFilter.customDateRange ??
          const SalesLiveMapFilter().resolveDateRange(),
    );
  }

  Set<String> get _tokenBackedAgentIds =>
      widget.availableAgents.tokenBackedAgentIds();

  Set<SalesLiveMapBranchRef> get _branchIds =>
      widget.availableBranches.map((branch) => branch.branchRef).toSet();

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
    final normalized = DashboardDateRange.fromOrderedEndpoints(
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

    DashboardDateRange? customDateRange;
    if (_periodMode == SalesLiveMapPeriodMode.customRange) {
      final picked = _customRange;
      if (picked == null) {
        return;
      }
      customDateRange =
          DashboardDateRange.fromOrderedEndpoints(
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
        markerVisual: SalesLiveMapVisualSpec.resolveMarkerVisual(
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
      _selectedBranchIds = Set<SalesLiveMapBranchRef>.from(_branchIds);
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

  Set<SalesLiveMapBranchRef>? _normalizedSelectedBranchIds() {
    final branchIds = _branchIds;
    if (branchIds.isEmpty) {
      return _selectedBranchIds.isEmpty
          ? null
          : Set<SalesLiveMapBranchRef>.unmodifiable(_selectedBranchIds);
    }
    final selectedBranches = _selectedBranchIds
        .where(branchIds.contains)
        .toSet();
    if (selectedBranches.length == branchIds.length) {
      return null;
    }
    return Set<SalesLiveMapBranchRef>.unmodifiable(selectedBranches);
  }

  String? _agentIdForBranchId(SalesLiveMapBranchRef branchRef) {
    for (final branch in widget.availableBranches) {
      if (branch.branchRef == branchRef) {
        return branch.agentId;
      }
    }
    return null;
  }

  void _toggleBranch(SalesLiveMapBranchOption branch, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selectedBranchIds.add(branch.branchRef);
      } else {
        _selectedBranchIds.remove(branch.branchRef);
      }
    });
  }

  void _changeDetailLevel(SalesLiveMapMapDetail detailLevel) {
    setState(() {
      _detailLevel = detailLevel;
      _markerVisual = SalesLiveMapVisualSpec.resolveMarkerVisual(
        detailLevel: detailLevel,
        markerVisual: _markerVisual,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final now = DateTime.now();
    final rangePickerFirstDate = DateTime(
      now.year - _kSalesLiveMapFilterMinYearsBack,
    );
    final rangePickerLastDate = DateTime(now.year, now.month, now.day);

    return SalesFiltersSheetScaffold(
      title: widget.l10n.salesLiveMapFiltersTitle,
      description: widget.l10n.salesLiveMapFiltersDescription,
      primaryActionLabel: widget.l10n.reportFiltersApplyAction,
      secondaryActionLabel: widget.l10n.reportFiltersClearAction,
      canPrimaryAction: widget.isApplyEnabled && _canApply,
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
            SalesLiveMapFiltersBranchSection(
              l10n: widget.l10n,
              tokens: tokens,
              branches: widget.availableBranches,
              selectedBranchIds: Set<SalesLiveMapBranchRef>.unmodifiable(
                _selectedBranchIds,
              ),
              hasSelectedBranch: _hasSelectedBranch,
              hasSelectedTokenBackedAgent: _hasSelectedTokenBackedAgent,
              onToggleBranch: ({required branch, required checked}) {
                _toggleBranch(branch, checked);
              },
              onSelectAllBranches: () {
                setState(() => _selectedBranchIds = _branchIds);
              },
              onClearSelection: () {
                setState(_selectedBranchIds.clear);
              },
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesLiveMapFiltersPeriodSection(
              l10n: widget.l10n,
              tokens: tokens,
              theme: theme,
              periodMode: _periodMode,
              customRange: _customRange,
              rangePickerFirstDate: rangePickerFirstDate,
              rangePickerLastDate: rangePickerLastDate,
              onPeriodModeChanged: (mode) =>
                  setState(() => _periodMode = mode),
              onCustomRangeChanged: (range) => setState(() {
                _customRange = range;
              }),
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesLiveMapFiltersDetailSection(
              l10n: widget.l10n,
              tokens: tokens,
              theme: theme,
              detailLevel: _detailLevel,
              onDetailLevelChanged: _changeDetailLevel,
            ),
            if (_detailLevel != SalesLiveMapMapDetail.states) ...<Widget>[
              SizedBox(height: tokens.sectionSpacing),
              SalesLiveMapFiltersVisualSection(
                l10n: widget.l10n,
                tokens: tokens,
                theme: theme,
                markerVisual: _markerVisual,
                onMarkerVisualChanged: (visual) => setState(() {
                  _markerVisual = visual;
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  static DateTimeRange _dateTimeRangeFrom(DashboardDateRange range) {
    return DateTimeRange(
      start: range.startInclusive,
      end: range.endInclusive,
    );
  }
}
