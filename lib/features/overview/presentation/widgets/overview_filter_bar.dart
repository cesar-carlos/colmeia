import 'package:colmeia/features/overview/presentation/widgets/overview_home_agent_filter_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewFilterBar extends StatefulWidget {
  const OverviewFilterBar({
    required this.l10n,
    required this.filter,
    required this.availableAgents,
    this.isLoading = false,
    this.onFilterChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final DashboardFilter filter;
  final List<DashboardAgentOption> availableAgents;
  final bool isLoading;
  final ValueChanged<DashboardFilter>? onFilterChanged;

  @override
  State<OverviewFilterBar> createState() => _OverviewFilterBarState();
}

enum _DateFilterMode { month, customRange }

class _OverviewFilterBarState extends State<OverviewFilterBar> {
  late _DateFilterMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.filter.referenceRange != null
        ? _DateFilterMode.customRange
        : _DateFilterMode.month;
  }

  @override
  void didUpdateWidget(covariant OverviewFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.referenceRange != null &&
        _mode == _DateFilterMode.month) {
      _mode = _DateFilterMode.customRange;
    } else if (widget.filter.referenceRange == null &&
        oldWidget.filter.referenceRange != null &&
        _mode == _DateFilterMode.customRange) {
      // If the filter was cleared externally, reset to month mode
      _mode = _DateFilterMode.month;
    }
  }

  static List<DashboardYearMonth> _buildPastMonthOptions({
    required DateTime now,
    int monthsBack = 12,
  }) {
    return List<DashboardYearMonth>.generate(monthsBack, (i) {
      var month = now.month - (i + 1);
      var year = now.year;
      while (month < 1) {
        month += 12;
        year -= 1;
      }
      return DashboardYearMonth(year: year, month: month);
    });
  }

  static String _monthLabel(BuildContext context, DashboardYearMonth ym) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateTime(ym.year, ym.month);
    return DateFormat.yMMM(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final colors = theme.appColors;
    final now = DateTime.now();
    final currentYm = DashboardYearMonth.fromDate(now);
    final pastMonthOptions = _buildPastMonthOptions(now: now);
    final isDisabled = widget.onFilterChanged == null || widget.isLoading;
    final hasActiveFilter = !widget.filter.isDefault;
    final hasAgentFilter = widget.filter.selectedAgentIds != null;

    final selectedYm = widget.filter.yearMonth ?? currentYm;
    final rangePickerLastDate = DateTime(now.year, now.month, now.day);
    final rangePickerFirstDate = DateTime(now.year - 10);
    var monthDropdownOptions = <AppDropdownOption<DashboardYearMonth>>[
      AppDropdownOption<DashboardYearMonth>(
        value: currentYm,
        label: widget.l10n.dashboardHomeFiltersCurrentMonth,
      ),
      for (final ym in pastMonthOptions)
        AppDropdownOption<DashboardYearMonth>(
          value: ym,
          label: _monthLabel(context, ym),
        ),
    ];
    if (!monthDropdownOptions.any((o) => o.value == selectedYm)) {
      monthDropdownOptions = <AppDropdownOption<DashboardYearMonth>>[
        AppDropdownOption<DashboardYearMonth>(
          value: selectedYm,
          label: _monthLabel(context, selectedYm),
        ),
        ...monthDropdownOptions,
      ];
    }

    return AppSectionCard(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.tune_rounded,
                size: 14,
                color: hasActiveFilter ? cs.primary : colors.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapXs),
              Expanded(
                child: Text(
                  widget.l10n.reportFiltersTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.utilityOverline.copyWith(
                    color: hasActiveFilter
                        ? cs.primary
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (hasAgentFilter) ...<Widget>[
                TextButton(
                  onPressed: isDisabled
                      ? null
                      : () => widget.onFilterChanged!(
                          widget.filter.copyWith(selectedAgentIds: null),
                        ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
                    textStyle: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(widget.l10n.reportInlineFiltersAllOption),
                ),
                SizedBox(width: tokens.gapXs),
              ],
              if (hasActiveFilter)
                TextButton(
                  onPressed: isDisabled
                      ? null
                      : () => widget.onFilterChanged!(DashboardFilter.initial()),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
                    textStyle: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(widget.l10n.reportFiltersClearAction),
                ),
            ],
          ),
          SizedBox(height: tokens.gapXs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.availableAgents.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      widget.l10n.dashboardHomeFiltersBranchesLabel,
                      style: typography.utilityOverline.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs),
                    Text(
                      widget.l10n.dashboardHomeFiltersBranchesEmptyHint,
                      style: typography.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                OverviewHomeAgentFilterControl(
                  l10n: widget.l10n,
                  availableAgents: widget.availableAgents,
                  selectedAgentIds: widget.filter.selectedAgentIds,
                  enabled: !isDisabled,
                  onSelectionChanged: (ids) {
                    if (ids == null) {
                      widget.onFilterChanged?.call(
                        widget.filter.copyWith(selectedAgentIds: null),
                      );
                      return;
                    }
                    widget.onFilterChanged?.call(
                      widget.filter.copyWith(selectedAgentIds: ids),
                    );
                  },
                ),
              SizedBox(height: tokens.gapMd),
              AppSegmentedControl<_DateFilterMode>(
                expandToFill: true,
                value: _mode,
                options: [
                  AppSegmentedControlOption(
                    value: _DateFilterMode.month,
                    label: widget.l10n.dashboardHomeFiltersYearMonthLabel,
                  ),
                  AppSegmentedControlOption(
                    value: _DateFilterMode.customRange,
                    label: widget.l10n.dashboardHomeFiltersReferenceRangeLabel,
                  ),
                ],
                onChanged: isDisabled
                    ? null
                    : (mode) {
                        setState(() => _mode = mode);
                        if (mode == _DateFilterMode.month) {
                          widget.onFilterChanged!(
                            widget.filter.copyWith(
                              referenceRange: null,
                              yearMonth: selectedYm,
                            ),
                          );
                        }
                      },
              ),
              SizedBox(height: tokens.gapMd),
              if (_mode == _DateFilterMode.customRange)
                AppDateRangePickerField(
                  label: widget.l10n.dashboardHomeFiltersReferenceRangeLabel,
                  helperText: widget.l10n
                      .dashboardHomeFiltersReferenceRangeHelper(
                        kDashboardCustomReferenceRangeMaxInclusiveDays,
                      ),
                  pickerTitle:
                      widget.l10n.dashboardHomeFiltersReferenceRangePickerTitle,
                  value: widget.filter.referenceRange == null
                      ? null
                      : DateTimeRange(
                          start: widget.filter.referenceRange!.startInclusive,
                          end: widget.filter.referenceRange!.endInclusive,
                        ),
                  firstDate: rangePickerFirstDate,
                  lastDate: rangePickerLastDate,
                  enabled: !isDisabled,
                  density: AppTextFieldDensity.compact,
                  onChanged: (picked) {
                    if (picked == null) {
                      widget.onFilterChanged!(
                        widget.filter.copyWith(referenceRange: null),
                      );
                      return;
                    }
                    final range = DashboardDateRange.fromOrderedEndpoints(
                      picked.start,
                      picked.end,
                    );
                    if (!range.withinHomeDashboardMaxInclusiveDays) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            widget.l10n
                                .dashboardHomeFiltersReferenceRangeMaxDurationSnackbar(
                                  kDashboardCustomReferenceRangeMaxInclusiveDays,
                                ),
                          ),
                        ),
                      );
                      return;
                    }
                    widget.onFilterChanged!(
                      widget.filter.copyWith(
                        referenceRange: range,
                        yearMonth: DashboardYearMonth.fromDate(
                          range.endInclusive,
                        ),
                      ),
                    );
                  },
                )
              else
                AppDropdownField<DashboardYearMonth>(
                  label: widget.l10n.dashboardHomeFiltersYearMonthLabel,
                  value: selectedYm,
                  options: monthDropdownOptions,
                  enabled: !isDisabled,
                  density: AppTextFieldDensity.compact,
                  onChanged: (v) {
                    if (v == null) {
                      return;
                    }
                    widget.onFilterChanged!(
                      widget.filter.copyWith(
                        yearMonth: v,
                        referenceRange: null,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
