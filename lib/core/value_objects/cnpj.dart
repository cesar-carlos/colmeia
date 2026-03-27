import 'package:brasil_fields/brasil_fields.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/zard_value_object.dart';
import 'package:zard/zard.dart';

final class Cnpj extends ZardValueObject<String> {
  Cnpj(String input) : super(_parse(input));

  String get formatted => AppBrFormatters.cnpj(value);

  static String _parse(String input) {
    final normalized = ZardValueObject.parse<String>(
      objectName: 'Cnpj',
      input: input,
      schema: z.string().trim(),
    );
    final digitsOnly = AppBrFormatters.digitsOnly(normalized);

    ZardValueObject.refine(
      objectName: 'Cnpj',
      isValid: UtilBrasilFields.isCNPJValido(digitsOnly),
      message: 'Invalid CNPJ value',
    );

    return digitsOnly;
  }
}
