import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_agent_filter_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewFilterBar extends StatelessWidget {
  const OverviewFilterBar({
    required this.l10n,
    required this.filter,
    required this.availableAgents,
    this.onFilterChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final OverviewFilter filter;
  final List<OverviewAgentOption> availableAgents;
  final ValueChanged<OverviewFilter>? onFilterChanged;

  /// Months strictly before [OverviewYearMonth.fromDate] (no current month).
  static List<OverviewYearMonth> _buildPastMonthOptions({int monthsBack = 12}) {
    final now = DateTime.now();
    return List<OverviewYearMonth>.generate(monthsBack, (i) {
      var month = now.month - (i + 1);
      var year = now.year;
      while (month < 1) {
        month += 12;
        year -= 1;
      }
      return OverviewYearMonth(year: year, month: month);
    });
  }

  static String _monthLabel(BuildContext context, OverviewYearMonth ym) {
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
    final currentYm = OverviewYearMonth.fromDate(DateTime.now());
    final pastMonthOptions = _buildPastMonthOptions();
    final isDisabled = onFilterChanged == null;
    final hasActiveFilter = !filter.isDefault;
    final hasAgentFilter = filter.selectedAgentIds != null;

    final actionStyle = typography.caption.copyWith(
      color: cs.primary,
      decoration: TextDecoration.underline,
      decorationColor: cs.primary,
      fontSize: 11,
    );

    final selectedYm = filter.yearMonth ?? currentYm;
    final now = DateTime.now();
    final rangePickerLastDate = DateTime(now.year, now.month, now.day);
    final rangePickerFirstDate = DateTime(now.year - 10);
    var monthDropdownOptions = <AppDropdownOption<OverviewYearMonth>>[
      AppDropdownOption<OverviewYearMonth>(
        value: currentYm,
        label: l10n.dashboardHomeFiltersCurrentMonth,
      ),
      for (final ym in pastMonthOptions)
        AppDropdownOption<OverviewYearMonth>(
          value: ym,
          label: _monthLabel(context, ym),
        ),
    ];
    if (!monthDropdownOptions.any((o) => o.value == selectedYm)) {
      monthDropdownOptions = <AppDropdownOption<OverviewYearMonth>>[
        AppDropdownOption<OverviewYearMonth>(
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
              Text(
                l10n.reportFiltersTitle,
                style: typography.utilityOverline.copyWith(
                  color: hasActiveFilter ? cs.primary : colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (hasAgentFilter) ...<Widget>[
                GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => onFilterChanged!(
                            filter.copyWith(selectedAgentIds: null),
                          ),
                  child: Text(
                    l10n.reportInlineFiltersAllOption,
                    style: actionStyle,
                  ),
                ),
                SizedBox(width: tokens.gapSm),
              ],
              if (hasActiveFilter)
                GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => onFilterChanged!(OverviewFilter.initial()),
                  child: Text(
                    l10n.reportFiltersClearAction,
                    style: actionStyle,
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.gapXs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (availableAgents.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.dashboardHomeFiltersAgentsLabel.toUpperCase(),
                      style: typography.utilityOverline.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs),
                    Text(
                      l10n.dashboardHomeFiltersAgentsEmptyHint,
                      style: typography.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                OverviewHomeAgentFilterControl(
                  l10n: l10n,
                  availableAgents: availableAgents,
                  selectedAgentIds: filter.selectedAgentIds,
                  enabled: !isDisabled,
                  onSelectionChanged: (ids) {
                    if (ids == null) {
                      onFilterChanged?.call(
                        filter.copyWith(selectedAgentIds: null),
                      );
                      return;
                    }
                    onFilterChanged?.call(
                      filter.copyWith(selectedAgentIds: ids),
                    );
                  },
                ),
              SizedBox(height: tokens.gapMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.dashboardHomeFiltersReferenceRangeLabel.toUpperCase(),
                    style: typography.utilityOverline.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.gapSm),
                  AppDateRangePickerField(
                    helperText: l10n.dashboardHomeFiltersReferenceRangeHelper(
                      kOverviewCustomReferenceRangeMaxInclusiveDays,
                    ),
                    pickerTitle:
                        l10n.dashboardHomeFiltersReferenceRangePickerTitle,
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
                        onFilterChanged!(
                          filter.copyWith(referenceRange: null),
                        );
                        return;
                      }
                      final range = OverviewDateRange.fromOrderedEndpoints(
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
                                kOverviewCustomReferenceRangeMaxInclusiveDays,
                              ),
                            ),
                          ),
                        );
                        return;
                      }
                      onFilterChanged!(
                        filter.copyWith(
                          referenceRange: range,
                          yearMonth: OverviewYearMonth.fromDate(
                            range.endInclusive,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: tokens.gapMd),
              AppDropdownField<OverviewYearMonth>(
                label: l10n.dashboardHomeFiltersYearMonthLabel,
                value: selectedYm,
                options: monthDropdownOptions,
                selectedDisplayLabel: filter.referenceRange != null
                    ? l10n.dashboardHomeFiltersYearMonthCustomDisplay
                    : null,
                semanticsLabel: filter.referenceRange != null
                    ? '${l10n.dashboardHomeFiltersYearMonthLabel}. '
                        '${l10n.dashboardHomeFiltersYearMonthCustomDisplay}. '
                        '${_monthLabel(context, selectedYm)}.'
                    : null,
                enabled: !isDisabled,
                density: AppTextFieldDensity.compact,
                onChanged: (v) {
                  if (v == null) {
                    return;
                  }
                  onFilterChanged!(
                    filter.copyWith(
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
