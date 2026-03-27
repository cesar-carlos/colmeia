import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:intl/intl.dart';

abstract final class AppChartFormatters {
  static NumberFormat get compactCurrencyFormat =>
      AppBrFormatters.compactCurrencyFormat;

  static String compactCurrency(num value) =>
      compactCurrencyFormat.format(value);
}
