import 'package:brasil_fields/brasil_fields.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/zard_value_object.dart';
import 'package:zard/zard.dart';

final class Cpf extends ZardValueObject<String> {
  Cpf(String input) : super(_parse(input));

  String get formatted => AppBrFormatters.cpf(value);

  static String _parse(String input) {
    final normalized = ZardValueObject.parse<String>(
      objectName: 'Cpf',
      input: input,
      schema: z.string().trim(),
    );
    final digitsOnly = AppBrFormatters.digitsOnly(normalized);

    ZardValueObject.refine(
      objectName: 'Cpf',
      isValid: UtilBrasilFields.isCPFValido(digitsOnly),
      message: 'Invalid CPF value',
    );

    return digitsOnly;
  }
}
