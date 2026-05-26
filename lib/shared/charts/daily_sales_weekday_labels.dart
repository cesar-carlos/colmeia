import 'package:colmeia/l10n/app_localizations.dart';

/// API weekday numbers from agent resumo: 1 = Sunday … 7 = Saturday.
///
/// Labels use [AppLocalizations.overviewDailySalesAxisDow*] — single source for
/// short weekday strings across daily and weekday overview charts.
String dailySalesWeekdayLabel(int weekdayNumber, AppLocalizations l10n) {
  return switch (weekdayNumber) {
    1 => l10n.overviewDailySalesAxisDowSun,
    2 => l10n.overviewDailySalesAxisDowMon,
    3 => l10n.overviewDailySalesAxisDowTue,
    4 => l10n.overviewDailySalesAxisDowWed,
    5 => l10n.overviewDailySalesAxisDowThu,
    6 => l10n.overviewDailySalesAxisDowFri,
    7 => l10n.overviewDailySalesAxisDowSat,
    _ => weekdayNumber.toString(),
  };
}

/// [DateTime.weekday]: Monday = 1 … Sunday = 7 (same mapping as axis strings).
String dailySalesShortWeekdayFromDateTime(AppLocalizations l10n, DateTime d) {
  switch (d.weekday) {
    case DateTime.monday:
      return l10n.overviewDailySalesAxisDowMon;
    case DateTime.tuesday:
      return l10n.overviewDailySalesAxisDowTue;
    case DateTime.wednesday:
      return l10n.overviewDailySalesAxisDowWed;
    case DateTime.thursday:
      return l10n.overviewDailySalesAxisDowThu;
    case DateTime.friday:
      return l10n.overviewDailySalesAxisDowFri;
    case DateTime.saturday:
      return l10n.overviewDailySalesAxisDowSat;
    case DateTime.sunday:
      return l10n.overviewDailySalesAxisDowSun;
    default:
      return '';
  }
}
