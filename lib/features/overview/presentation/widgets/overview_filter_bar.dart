import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
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

  static List<OverviewYearMonth> _buildMonthOptions() {
    final now = DateTime.now();
    return List<OverviewYearMonth>.generate(13, (i) {
      var month = now.month - i;
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
    final monthOptions = _buildMonthOptions();
    final isDisabled = onFilterChanged == null;
    final hasActiveFilter = !filter.isDefault;
    final hasAgentFilter = filter.selectedAgentIds != null;

    final actionStyle = typography.caption.copyWith(
      color: cs.primary,
      decoration: TextDecoration.underline,
      decorationColor: cs.primary,
      fontSize: 11,
    );

    final agentOptions = availableAgents
        .map(
          (a) => AppDropdownOption<String>(
            value: a.agentId,
            label: a.name,
          ),
        )
        .toList(growable: false);
    // `null` in the domain means "all agents". The multi-select needs an
    // explicit id list to render chips and row selection; mapping null → all
    // ids keeps UI in sync when we normalize a full explicit pick to `null`.
    final multiSelectSelectedAgentIds = filter.selectedAgentIds == null
        ? availableAgents.map((a) => a.agentId).toList(growable: false)
        : filter.selectedAgentIds!.toList(growable: false);

    final monthDropdownOptions = <AppDropdownOption<OverviewYearMonth?>>[
      AppDropdownOption<OverviewYearMonth?>(
        value: null,
        label: l10n.dashboardHomeFiltersPeriodLast30Days,
      ),
      for (final ym in monthOptions)
        AppDropdownOption<OverviewYearMonth?>(
          value: ym,
          label: _monthLabel(context, ym),
        ),
    ];

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
                      : () => onFilterChanged!(const OverviewFilter()),
                  child: Text(
                    l10n.reportFiltersClearAction,
                    style: actionStyle,
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.gapXs),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;

              final Widget agentField;
              if (availableAgents.isEmpty) {
                agentField = Column(
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
                );
              } else {
                agentField = AppMultiSelectSearchField<String>(
                  label: l10n.dashboardHomeFiltersAgentsLabel,
                  options: agentOptions,
                  selectedValues: multiSelectSelectedAgentIds,
                  enabled: !isDisabled,
                  density: AppTextFieldDensity.compact,
                  searchHintText: l10n.reportInlineFiltersHint,
                  onChanged: (ids) {
                    // Empty selection maps to null ("all agents"). Removing
                    // the last chip triggers a full-agent load again.
                    if (ids.isEmpty) {
                      onFilterChanged?.call(
                        filter.copyWith(selectedAgentIds: null),
                      );
                      return;
                    }
                    final allIds =
                        availableAgents.map((e) => e.agentId).toSet();
                    if (ids.length == allIds.length &&
                        ids.toSet().containsAll(allIds)) {
                      onFilterChanged?.call(
                        filter.copyWith(selectedAgentIds: null),
                      );
                    } else {
                      onFilterChanged?.call(
                        filter.copyWith(
                          selectedAgentIds: Set<String>.from(ids),
                        ),
                      );
                    }
                  },
                );
              }

              final monthField = AppDropdownField<OverviewYearMonth?>(
                label: l10n.dashboardHomeFiltersYearMonthLabel,
                value: filter.yearMonth,
                options: monthDropdownOptions,
                enabled: !isDisabled,
                density: AppTextFieldDensity.compact,
                onChanged: (v) => onFilterChanged!(
                  filter.copyWith(yearMonth: v),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    agentField,
                    SizedBox(height: tokens.gapMd),
                    monthField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: agentField),
                  SizedBox(width: tokens.gapMd),
                  Expanded(child: monthField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
