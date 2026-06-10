import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/zard_value_object.dart';
import 'package:zard/zard.dart';

/// Brazilian mobile (celular) with the 9th digit after the area code.
final class BrazilianCelular extends ZardValueObject<String> {
  BrazilianCelular(String input) : super(_parse(input));

  static String _parse(String input) {
    final normalized = ZardValueObject.parse<String>(
      objectName: 'BrazilianCelular',
      input: input,
      schema: z.string().trim(),
    );
    final digitsOnly = AppBrFormatters.digitsOnly(normalized);

    ZardValueObject.refine(
      objectName: 'BrazilianCelular',
      isValid: digitsOnly.length == 11,
      message: 'Brazilian celular must have 11 digits',
    );

    ZardValueObject.refine(
      objectName: 'BrazilianCelular',
      isValid: digitsOnly[2] == '9',
      message: 'Brazilian celular must start with 9 after the area code',
    );

    return digitsOnly;
  }
}
