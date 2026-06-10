import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const int kSalesAnchorMonthChoiceCount = 36;

/// Anchor months for sales charts (current month plus prior months).
List<DashboardYearMonth> salesMonthlyPnlAnchorMonthChoices() {
  final now = DateTime.now();
  final current = DashboardYearMonth.fromDate(now);
  final list = <DashboardYearMonth>[current];
  for (var i = 1; i < kSalesAnchorMonthChoiceCount; i++) {
    var month = now.month - i;
    var year = now.year;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    list.add(DashboardYearMonth(year: year, month: month));
  }
  return list;
}

String formatSalesAnchorMonthLabel(
  BuildContext context,
  DashboardYearMonth ym,
) {
  final locale = Localizations.localeOf(context).toString();
  final date = DateTime(ym.year, ym.month);
  return DateFormat.yMMM(locale).format(date);
}

List<AppDropdownOption<DashboardYearMonth>> salesAnchorMonthDropdownOptions({
  required BuildContext context,
  required AppLocalizations l10n,
  required DashboardYearMonth selected,
}) {
  final base = salesMonthlyPnlAnchorMonthChoices();
  var options = <AppDropdownOption<DashboardYearMonth>>[
    AppDropdownOption<DashboardYearMonth>(
      value: base.first,
      label: l10n.dashboardHomeFiltersCurrentMonth,
    ),
    for (var i = 1; i < base.length; i++)
      AppDropdownOption<DashboardYearMonth>(
        value: base[i],
        label: formatSalesAnchorMonthLabel(context, base[i]),
      ),
  ];
  if (!options.any((o) => o.value == selected)) {
    options = <AppDropdownOption<DashboardYearMonth>>[
      AppDropdownOption<DashboardYearMonth>(
        value: selected,
        label: formatSalesAnchorMonthLabel(context, selected),
      ),
      ...options,
    ];
  }
  return options;
}
