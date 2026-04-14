import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_agent_filter_control.dart';
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
              AppDropdownField<OverviewYearMonth?>(
                label: l10n.dashboardHomeFiltersYearMonthLabel,
                value: filter.yearMonth,
                options: monthDropdownOptions,
                enabled: !isDisabled,
                density: AppTextFieldDensity.compact,
                onChanged: (v) => onFilterChanged!(
                  filter.copyWith(yearMonth: v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
