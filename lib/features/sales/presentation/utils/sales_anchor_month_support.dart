import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const int kSalesAnchorMonthChoiceCount = 36;

/// Anchor months for sales charts (current month plus prior months).
List<OverviewYearMonth> salesMonthlyPnlAnchorMonthChoices() {
  final now = DateTime.now();
  final current = OverviewYearMonth.fromDate(now);
  final list = <OverviewYearMonth>[current];
  for (var i = 1; i < kSalesAnchorMonthChoiceCount; i++) {
    var month = now.month - i;
    var year = now.year;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    list.add(OverviewYearMonth(year: year, month: month));
  }
  return list;
}

String formatSalesAnchorMonthLabel(BuildContext context, OverviewYearMonth ym) {
  final locale = Localizations.localeOf(context).toString();
  final date = DateTime(ym.year, ym.month);
  return DateFormat.yMMM(locale).format(date);
}

List<AppDropdownOption<OverviewYearMonth>> salesAnchorMonthDropdownOptions({
  required BuildContext context,
  required AppLocalizations l10n,
  required OverviewYearMonth selected,
}) {
  final base = salesMonthlyPnlAnchorMonthChoices();
  var options = <AppDropdownOption<OverviewYearMonth>>[
    AppDropdownOption<OverviewYearMonth>(
      value: base.first,
      label: l10n.dashboardHomeFiltersCurrentMonth,
    ),
    for (var i = 1; i < base.length; i++)
      AppDropdownOption<OverviewYearMonth>(
        value: base[i],
        label: formatSalesAnchorMonthLabel(context, base[i]),
      ),
  ];
  if (!options.any((o) => o.value == selected)) {
    options = <AppDropdownOption<OverviewYearMonth>>[
      AppDropdownOption<OverviewYearMonth>(
        value: selected,
        label: formatSalesAnchorMonthLabel(context, selected),
      ),
      ...options,
    ];
  }
  return options;
}
