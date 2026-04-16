import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_weekday_sales_trend_l10n.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps weekday numbers to English labels', () {
    final l10n = AppLocalizationsEn();

    check(overviewWeekdaySalesLabel(1, l10n)).equals('Sunday');
    check(overviewWeekdaySalesLabel(7, l10n)).equals('Saturday');
  });

  test('maps weekday numbers to Portuguese labels', () {
    final l10n = AppLocalizationsPt();

    check(overviewWeekdaySalesLabel(2, l10n)).equals('Segunda-feira');
    check(overviewWeekdaySalesLabel(6, l10n)).equals('Sexta-feira');
  });
}
