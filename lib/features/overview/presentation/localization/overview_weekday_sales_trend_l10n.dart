import 'package:colmeia/l10n/app_localizations.dart';

String overviewWeekdaySalesLabel(
  int weekdayNumber,
  AppLocalizations l10n,
) {
  return switch (weekdayNumber) {
    1 => l10n.overviewWeekdaySunday,
    2 => l10n.overviewWeekdayMonday,
    3 => l10n.overviewWeekdayTuesday,
    4 => l10n.overviewWeekdayWednesday,
    5 => l10n.overviewWeekdayThursday,
    6 => l10n.overviewWeekdayFriday,
    7 => l10n.overviewWeekdaySaturday,
    _ => weekdayNumber.toString(),
  };
}
