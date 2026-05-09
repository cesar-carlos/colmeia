import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/sales_daily_totals_range_policy.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Branch + reference month filters shared by sales charts anchored to a month.
///
/// Daily totals may use [OverviewDateRange] while monthly charts keep using the
/// reference month only.
class SalesBranchAnchorMonthFiltersSheet extends StatefulWidget {
  const SalesBranchAnchorMonthFiltersSheet({
    required this.l10n,
    required this.filtersContext,
    required this.availableAgents,
    required this.initialSelectedAgentId,
    required this.initialAnchorYearMonth,
    required this.onApply,
    this.initialDailyTotalsUseCustomRange = false,
    this.initialDailyTotalsDateRange,
    super.key,
  });

  final AppLocalizations l10n;
  final SalesAnchorMonthFiltersContext filtersContext;
  final List<OverviewAgentOption> availableAgents;
  final String? initialSelectedAgentId;
  final OverviewYearMonth initialAnchorYearMonth;

  /// When true, [initialDailyTotalsDateRange] defines the custom sale-date span.
  final bool initialDailyTotalsUseCustomRange;

  /// Restored custom range for daily totals only; ignored when
  /// [initialDailyTotalsUseCustomRange] is false.
  final OverviewDateRange? initialDailyTotalsDateRange;

  final ValueChanged<Map<String, Object?>> onApply;

  @override
  State<SalesBranchAnchorMonthFiltersSheet> createState() =>
      _SalesBranchAnchorMonthFiltersSheetState();
}

enum _DailyTotalsPeriodMode {
  referenceMonth,
  customRange,
}

class _SalesBranchAnchorMonthFiltersSheetState
    extends State<SalesBranchAnchorMonthFiltersSheet> {
  String? _selectedAgentId;
  late OverviewYearMonth _anchorYearMonth;
  late _DailyTotalsPeriodMode _dailyTotalsMode;
  DateTimeRange? _customSaleDateRange;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.initialSelectedAgentId;
    _anchorYearMonth = widget.initialAnchorYearMonth;
    _dailyTotalsMode = widget.initialDailyTotalsUseCustomRange
        ? _DailyTotalsPeriodMode.customRange
        : _DailyTotalsPeriodMode.referenceMonth;
    final initialRange = widget.initialDailyTotalsDateRange;
    if (initialRange != null && widget.initialDailyTotalsUseCustomRange) {
      _customSaleDateRange = DateTimeRange(
        start: DateTime(
          initialRange.startInclusive.year,
          initialRange.startInclusive.month,
          initialRange.startInclusive.day,
        ),
        end: DateTime(
          initialRange.endInclusive.year,
          initialRange.endInclusive.month,
          initialRange.endInclusive.day,
        ),
      );
    } else {
      _customSaleDateRange = _defaultCustomRangeForAnchor(_anchorYearMonth);
    }
  }

  static DateTimeRange _defaultCustomRangeForAnchor(OverviewYearMonth anchor) {
    return DateTimeRange(
      start: anchor.start,
      end: DateTime(anchor.year, anchor.month + 1, 0),
    );
  }

  bool get _canApplyCustomRange {
    if (_dailyTotalsMode != _DailyTotalsPeriodMode.customRange) {
      return true;
    }
    return _customSaleDateRange != null;
  }

  void _apply() {
    final selectedAgentId = _selectedAgentId;
    if (selectedAgentId == null || selectedAgentId.trim().isEmpty) {
      return;
    }
    if (!_canApplyCustomRange) {
      return;
    }
    OverviewDateRange? dailyTotalsDateRange;
    if (_dailyTotalsMode == _DailyTotalsPeriodMode.customRange) {
      final picked = _customSaleDateRange;
      if (picked == null) {
        return;
      }
      var range = OverviewDateRange.fromOrderedEndpoints(
        picked.start,
        picked.end,
      );
      range = SalesDailyTotalsRangePolicy.normalizedForSalesDailyTotalsPicker(
        range: range,
      );
      if (!SalesDailyTotalsRangePolicy.isAllowed(range)) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              widget.l10n.salesDailyTotalsFilterRangeTooLongSnackbar(
                kSalesDailyTotalsMaxInclusiveDays,
              ),
            ),
          ),
        );
        return;
      }
      dailyTotalsDateRange = range;
    }
    widget.onApply(<String, Object?>{
      'agentId': selectedAgentId,
      'anchorYearMonth': _anchorYearMonth,
      'dailyTotalsDateRange': dailyTotalsDateRange,
    });
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _anchorYearMonth = OverviewYearMonth.fromDate(DateTime.now());
      _dailyTotalsMode = _DailyTotalsPeriodMode.referenceMonth;
      _customSaleDateRange = _defaultCustomRangeForAnchor(_anchorYearMonth);
    });
  }

  void _onDailyModeChanged(_DailyTotalsPeriodMode mode) {
    setState(() {
      _dailyTotalsMode = mode;
      if (mode == _DailyTotalsPeriodMode.customRange &&
          _customSaleDateRange == null) {
        _customSaleDateRange = _defaultCustomRangeForAnchor(_anchorYearMonth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        widget.availableAgents.any(
          (agent) =>
              agent.agentId == _selectedAgentId &&
              agent.missingLocalClientToken,
        );
    final monthOptions = salesAnchorMonthDropdownOptions(
      context: context,
      l10n: l10n,
      selected: _anchorYearMonth,
    );
    final now = DateTime.now();
    final rangePickerLastDate = DateTime(now.year, now.month, now.day);
    final rangePickerFirstDate = DateTime(now.year - 10);

    return SalesFiltersSheetScaffold(
      title: l10n.reportFiltersTitleWithContext(
        widget.filtersContext.filtersSheetTitle(l10n),
      ),
      description: l10n.reportFiltersDescription,
      primaryActionLabel: l10n.reportFiltersApplyAction,
      secondaryActionLabel: l10n.reportFiltersClearAction,
      onPrimaryAction: _apply,
      onSecondaryAction: _clear,
      canPrimaryAction: _selectedAgentId != null && _canApplyCustomRange,
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
              title: l10n.salesBranchFilterLabel,
              subtitle: l10n.salesBranchRequiredMessage,
              requiredBadgeLabel: l10n.reportFiltersRequiredCount(1),
            ),
            SizedBox(height: tokens.gapSm),
            SalesBranchPickerControl(
              l10n: l10n,
              availableBranches: widget.availableAgents,
              selectedBranchId: _selectedAgentId,
              showTrailingFilterButton: false,
              onSelectionChanged: (agentId) {
                setState(() => _selectedAgentId = agentId);
              },
            ),
            if (selectedAgentMissingToken) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                message: l10n.salesBranchFilterMissingClientTokenBanner,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: l10n.salesMonthlyPnlFilterAnchorMonth,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: AppDropdownField<OverviewYearMonth>(
                label: l10n.salesMonthlyPnlFilterAnchorMonth,
                value: _anchorYearMonth,
                density: AppTextFieldDensity.compact,
                options: monthOptions,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _anchorYearMonth = value);
                },
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesFiltersSectionHeader(
              title: l10n.salesDailyTotalsFilterDailyPeriodSectionTitle,
              subtitle: l10n.salesDailyTotalsFilterMonthlyChartsAnchorHint,
            ),
            SizedBox(height: tokens.gapSm),
            AppSectionCard(
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppSegmentedControl<_DailyTotalsPeriodMode>(
                    expandToFill: true,
                    value: _dailyTotalsMode,
                    options: <AppSegmentedControlOption<_DailyTotalsPeriodMode>>[
                      AppSegmentedControlOption<_DailyTotalsPeriodMode>(
                        value: _DailyTotalsPeriodMode.referenceMonth,
                        label: l10n
                            .salesDailyTotalsFilterDailyPeriodSameMonthLabel,
                      ),
                      AppSegmentedControlOption<_DailyTotalsPeriodMode>(
                        value: _DailyTotalsPeriodMode.customRange,
                        label: l10n
                            .salesDailyTotalsFilterDailyPeriodCustomRangeLabel,
                      ),
                    ],
                    onChanged: _onDailyModeChanged,
                  ),
                  if (_dailyTotalsMode ==
                      _DailyTotalsPeriodMode.customRange) ...<Widget>[
                    SizedBox(height: tokens.gapMd),
                    AppInlineErrorPanel(
                      tone: AppInlinePanelTone.informational,
                      message: l10n
                          .salesDailyTotalsFilterCustomRangeAnchorIndependenceBanner,
                    ),
                    SizedBox(height: tokens.gapMd),
                    AppDateRangePickerField(
                      label: l10n.salesDailyTotalsFilterDailyPeriodPickerLabel,
                      helperText: l10n.salesDailyTotalsFilterDailyPeriodHelper(
                        kSalesDailyTotalsMaxInclusiveDays,
                      ),
                      pickerTitle:
                          l10n.salesDailyTotalsFilterDailyPeriodPickerTitle,
                      value: _customSaleDateRange,
                      firstDate: rangePickerFirstDate,
                      lastDate: rangePickerLastDate,
                      density: AppTextFieldDensity.compact,
                      onChanged: (picked) {
                        setState(() {
                          _customSaleDateRange = picked;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
