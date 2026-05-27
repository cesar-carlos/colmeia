import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Period selector section of the sales live map filters sheet — toggles
/// between predefined ranges (today / last 7 / current month) and a custom
/// inclusive date range with its own picker.
class SalesLiveMapFiltersPeriodSection extends StatelessWidget {
  const SalesLiveMapFiltersPeriodSection({
    required this.l10n,
    required this.tokens,
    required this.theme,
    required this.periodMode,
    required this.customRange,
    required this.rangePickerFirstDate,
    required this.rangePickerLastDate,
    required this.onPeriodModeChanged,
    required this.onCustomRangeChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final SalesLiveMapPeriodMode periodMode;
  final DateTimeRange? customRange;
  final DateTime rangePickerFirstDate;
  final DateTime rangePickerLastDate;
  final ValueChanged<SalesLiveMapPeriodMode> onPeriodModeChanged;
  final ValueChanged<DateTimeRange?> onCustomRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesFiltersSectionHeader(title: l10n.salesLiveMapPeriodLabel),
        SizedBox(height: tokens.gapSm),
        AppSectionCard(
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSegmentedControl<SalesLiveMapPeriodMode>(
                value: periodMode,
                expandToFill: true,
                options: <AppSegmentedControlOption<SalesLiveMapPeriodMode>>[
                  AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                    value: SalesLiveMapPeriodMode.today,
                    label: l10n.salesLiveMapPeriodToday,
                  ),
                  AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                    value: SalesLiveMapPeriodMode.lastSevenDays,
                    label: l10n.salesLiveMapPeriodLastSevenDaysShort,
                  ),
                  AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                    value: SalesLiveMapPeriodMode.currentMonth,
                    label: l10n.salesLiveMapPeriodCurrentMonthShort,
                  ),
                  AppSegmentedControlOption<SalesLiveMapPeriodMode>(
                    value: SalesLiveMapPeriodMode.customRange,
                    label: l10n.salesLiveMapPeriodCustom,
                  ),
                ],
                onChanged: onPeriodModeChanged,
              ),
              if (periodMode == SalesLiveMapPeriodMode.customRange) ...[
                SizedBox(height: tokens.gapMd),
                AppDateRangePickerField(
                  label: l10n.salesLiveMapCustomPeriodLabel,
                  helperText: l10n.salesLiveMapCustomPeriodHelper(
                    kSalesLiveMapMaxCustomRangeInclusiveDays,
                  ),
                  pickerTitle: l10n.salesLiveMapCustomPeriodPickerTitle,
                  value: customRange,
                  firstDate: rangePickerFirstDate,
                  lastDate: rangePickerLastDate,
                  density: AppTextFieldDensity.compact,
                  onChanged: onCustomRangeChanged,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
