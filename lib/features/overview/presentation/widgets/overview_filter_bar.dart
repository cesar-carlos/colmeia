import 'package:colmeia/features/overview/presentation/widgets/overview_home_agent_filter_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mode toggle: full month vs. ad-hoc date range.
///
/// Kept as local UI state (not derived from `filter.referenceRange`) so we
/// can show the range picker while the user has not yet selected a range
/// — switching to "Custom range" without losing the picker view.
enum _DateFilterMode { month, customRange }

/// Number of past calendar months offered in the month dropdown.
const int _kPastMonthOptions = 12;

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
      _mode = _DateFilterMode.month;
    }
  }

  void _onModeChanged(_DateFilterMode next, DashboardYearMonth selectedYm) {
    setState(() => _mode = next);
    if (next == _DateFilterMode.month) {
      widget.onFilterChanged?.call(
        widget.filter.copyWith(
          referenceRange: null,
          yearMonth: selectedYm,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final currentYm = DashboardYearMonth.fromDate(now);
    final isDisabled = widget.onFilterChanged == null || widget.isLoading;
    final selectedYm = widget.filter.yearMonth ?? currentYm;

    return AppSectionCard(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OverviewFilterHeader(
            l10n: widget.l10n,
            filter: widget.filter,
            isDisabled: isDisabled,
            onFilterChanged: widget.onFilterChanged,
          ),
          SizedBox(height: tokens.gapXs),
          _OverviewBranchSection(
            l10n: widget.l10n,
            filter: widget.filter,
            availableAgents: widget.availableAgents,
            isDisabled: isDisabled,
            onFilterChanged: widget.onFilterChanged,
          ),
          SizedBox(height: tokens.gapMd),
          AppSegmentedControl<_DateFilterMode>(
            expandToFill: true,
            value: _mode,
            options: <AppSegmentedControlOption<_DateFilterMode>>[
              AppSegmentedControlOption<_DateFilterMode>(
                value: _DateFilterMode.month,
                label: widget.l10n.dashboardHomeFiltersYearMonthLabel,
              ),
              AppSegmentedControlOption<_DateFilterMode>(
                value: _DateFilterMode.customRange,
                label: widget.l10n.dashboardHomeFiltersReferenceRangeLabel,
              ),
            ],
            onChanged: isDisabled
                ? null
                : (mode) => _onModeChanged(mode, selectedYm),
          ),
          SizedBox(height: tokens.gapMd),
          if (_mode == _DateFilterMode.customRange)
            _OverviewReferenceRangeField(
              l10n: widget.l10n,
              filter: widget.filter,
              now: now,
              isDisabled: isDisabled,
              onFilterChanged: widget.onFilterChanged,
            )
          else
            _OverviewMonthDropdown(
              l10n: widget.l10n,
              filter: widget.filter,
              now: now,
              currentYm: currentYm,
              selectedYm: selectedYm,
              isDisabled: isDisabled,
              onFilterChanged: widget.onFilterChanged,
            ),
        ],
      ),
    );
  }
}

/// Title row with the optional "All branches" and "Clear" text actions.
class _OverviewFilterHeader extends StatelessWidget {
  const _OverviewFilterHeader({
    required this.l10n,
    required this.filter,
    required this.isDisabled,
    required this.onFilterChanged,
  });

  final AppLocalizations l10n;
  final DashboardFilter filter;
  final bool isDisabled;
  final ValueChanged<DashboardFilter>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final colors = theme.appColors;
    final hasActiveFilter = !filter.isDefault;
    final hasAgentFilter = filter.selectedAgentIds != null;

    return Row(
      children: <Widget>[
        Icon(
          Icons.tune_rounded,
          size: 14,
          color: hasActiveFilter ? cs.primary : colors.onSurfaceVariant,
        ),
        SizedBox(width: tokens.gapXs),
        Expanded(
          child: Text(
            l10n.reportFiltersTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.utilityOverline.copyWith(
              color: hasActiveFilter ? cs.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
        if (hasAgentFilter) ...<Widget>[
          AppTextActionButton(
            label: l10n.reportInlineFiltersAllOption,
            onPressed: isDisabled
                ? null
                : () => onFilterChanged?.call(
                      filter.copyWith(selectedAgentIds: null),
                    ),
          ),
          SizedBox(width: tokens.gapXs),
        ],
        if (hasActiveFilter)
          AppTextActionButton(
            label: l10n.reportFiltersClearAction,
            onPressed: isDisabled
                ? null
                : () => onFilterChanged?.call(DashboardFilter.initial()),
          ),
      ],
    );
  }
}

/// Branches block: shows the empty hint when no agents are available, or
/// the tappable agent filter control otherwise.
class _OverviewBranchSection extends StatelessWidget {
  const _OverviewBranchSection({
    required this.l10n,
    required this.filter,
    required this.availableAgents,
    required this.isDisabled,
    required this.onFilterChanged,
  });

  final AppLocalizations l10n;
  final DashboardFilter filter;
  final List<DashboardAgentOption> availableAgents;
  final bool isDisabled;
  final ValueChanged<DashboardFilter>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    if (availableAgents.isEmpty) {
      final theme = Theme.of(context);
      final tokens = theme.extension<AppThemeTokens>()!;
      final typography = theme.appTypography;
      final colors = theme.appColors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.dashboardHomeFiltersBranchesLabel,
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            l10n.dashboardHomeFiltersBranchesEmptyHint,
            style: typography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return OverviewHomeAgentFilterControl(
      l10n: l10n,
      availableAgents: availableAgents,
      selectedAgentIds: filter.selectedAgentIds,
      enabled: !isDisabled,
      onSelectionChanged: (ids) {
        onFilterChanged?.call(
          filter.copyWith(selectedAgentIds: ids),
        );
      },
    );
  }
}

/// Calendar-month dropdown. Builds the rolling list of recent months plus
/// the optional "out-of-list" current selection so externally set months
/// (e.g. from a saved filter) remain visible.
class _OverviewMonthDropdown extends StatelessWidget {
  const _OverviewMonthDropdown({
    required this.l10n,
    required this.filter,
    required this.now,
    required this.currentYm,
    required this.selectedYm,
    required this.isDisabled,
    required this.onFilterChanged,
  });

  final AppLocalizations l10n;
  final DashboardFilter filter;
  final DateTime now;
  final DashboardYearMonth currentYm;
  final DashboardYearMonth selectedYm;
  final bool isDisabled;
  final ValueChanged<DashboardFilter>? onFilterChanged;

  static List<DashboardYearMonth> _buildPastMonthOptions({
    required DateTime now,
    int monthsBack = _kPastMonthOptions,
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
    final pastMonthOptions = _buildPastMonthOptions(now: now);
    var monthDropdownOptions = <AppDropdownOption<DashboardYearMonth>>[
      AppDropdownOption<DashboardYearMonth>(
        value: currentYm,
        label: l10n.dashboardHomeFiltersCurrentMonth,
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

    return AppDropdownField<DashboardYearMonth>(
      label: l10n.dashboardHomeFiltersYearMonthLabel,
      value: selectedYm,
      options: monthDropdownOptions,
      enabled: !isDisabled,
      density: AppTextFieldDensity.compact,
      onChanged: (v) {
        if (v == null) {
          return;
        }
        onFilterChanged?.call(
          filter.copyWith(yearMonth: v, referenceRange: null),
        );
      },
    );
  }
}

/// Custom date-range picker field. Enforces
/// [kDashboardCustomReferenceRangeMaxInclusiveDays] and surfaces a snackbar
/// when the user picks a range that exceeds the cap.
class _OverviewReferenceRangeField extends StatelessWidget {
  const _OverviewReferenceRangeField({
    required this.l10n,
    required this.filter,
    required this.now,
    required this.isDisabled,
    required this.onFilterChanged,
  });

  final AppLocalizations l10n;
  final DashboardFilter filter;
  final DateTime now;
  final bool isDisabled;
  final ValueChanged<DashboardFilter>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final rangePickerLastDate = DateTime(now.year, now.month, now.day);
    final rangePickerFirstDate = DateTime(now.year - 10);

    return AppDateRangePickerField(
      label: l10n.dashboardHomeFiltersReferenceRangeLabel,
      helperText: l10n.dashboardHomeFiltersReferenceRangeHelper(
        kDashboardCustomReferenceRangeMaxInclusiveDays,
      ),
      pickerTitle: l10n.dashboardHomeFiltersReferenceRangePickerTitle,
      value: filter.referenceRange == null
          ? null
          : DateTimeRange(
              start: filter.referenceRange!.startInclusive,
              end: filter.referenceRange!.endInclusive,
            ),
      firstDate: rangePickerFirstDate,
      lastDate: rangePickerLastDate,
      enabled: !isDisabled,
      density: AppTextFieldDensity.compact,
      onChanged: (picked) {
        if (picked == null) {
          onFilterChanged?.call(filter.copyWith(referenceRange: null));
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
                l10n.dashboardHomeFiltersReferenceRangeMaxDurationSnackbar(
                  kDashboardCustomReferenceRangeMaxInclusiveDays,
                ),
              ),
            ),
          );
          return;
        }
        onFilterChanged?.call(
          filter.copyWith(
            referenceRange: range,
            yearMonth: DashboardYearMonth.fromDate(range.endInclusive),
          ),
        );
      },
    );
  }
}
