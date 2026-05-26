import 'package:checks/checks.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps weekday numbers to English labels', () {
    final l10n = AppLocalizationsEn();

    check(dailySalesWeekdayLabel(1, l10n)).equals('Sun');
    check(dailySalesWeekdayLabel(7, l10n)).equals('Sat');
  });

  test('maps weekday numbers to Portuguese labels', () {
    final l10n = AppLocalizationsPt();

    check(dailySalesWeekdayLabel(2, l10n)).equals('Segunda');
    check(dailySalesWeekdayLabel(6, l10n)).equals('Sexta');
  });
}
