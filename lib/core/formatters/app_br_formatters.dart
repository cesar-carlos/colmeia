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

  static final DateFormat shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat shortDateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

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
