import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

abstract final class AppBrFormatters {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );

  static final NumberFormat compactCurrencyFormat =
      NumberFormat.compactCurrency(
        locale: 'pt_BR',
        symbol: r'R$',
        decimalDigits: 1,
      );

  /// Compact BRL for chart axes when the UI locale should drive grouping.
  static NumberFormat compactCurrencyFormatForLocale(String localeName) {
    return NumberFormat.compactCurrency(
      locale: localeName,
      symbol: r'R$',
      decimalDigits: 1,
    );
  }

  /// Brazilian calendar display; locale fixed so formatting does not follow
  /// a mismatched UI language (e.g. English app copy with BR-style dates).
  static final DateFormat shortDateFormat =
      DateFormat('dd/MM/yyyy', 'pt_BR');

  static final DateFormat shortDateTimeFormat =
      DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  static List<TextInputFormatter> get cpfInputFormatters =>
      <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        CpfInputFormatter(),
      ];

  static List<TextInputFormatter> get cnpjInputFormatters =>
      <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        CnpjInputFormatter(),
      ];

  static List<TextInputFormatter> get dateInputFormatters =>
      <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        DataInputFormatter(),
      ];

  static String currency(num value) =>
      UtilBrasilFields.obterReal(value.toDouble());

  static String compactCurrency(num value) =>
      compactCurrencyFormat.format(value);

  /// Currency formatter that picks between full and compact notation:
  /// - Below R$ 1.000 (in absolute value), uses [currency] so a tiny bar like
  ///   `R$ 26,80` is not visually confused with `R$ 26,8 mil`.
  /// - From R$ 1.000 onward, uses the locale-aware compact formatter
  ///   (`R$ 1,2 mil`, `R$ 1,2 mi`).
  ///
  /// Useful for chart data labels where bars span several orders of magnitude.
  static String smartCompactCurrency(num value) {
    if (value.abs() < 1000) {
      return currency(value);
    }
    return compactCurrencyFormat.format(value);
  }

  /// Locale-aware variant of [smartCompactCurrency] for chart axes that should
  /// follow the UI locale rather than the fixed `pt_BR` symbol grouping.
  static String smartCompactCurrencyForLocale(num value, String localeName) {
    if (value.abs() < 1000) {
      return currency(value);
    }
    return compactCurrencyFormatForLocale(localeName).format(value);
  }

  static double parseCurrency(String value) =>
      UtilBrasilFields.converterMoedaParaDouble(value);

  static String shortDate(DateTime value) => shortDateFormat.format(value);

  static String shortDateTime(DateTime value) =>
      shortDateTimeFormat.format(value);

  static String cpf(String value) => UtilBrasilFields.obterCpf(value);

  static String cnpj(String value) => UtilBrasilFields.obterCnpj(value);

  static String phone(String value) => UtilBrasilFields.obterTelefone(value);

  static String digitsOnly(String value) =>
      UtilBrasilFields.removeCaracteres(value);
}
