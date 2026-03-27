import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/zard_value_object.dart';
import 'package:zard/zard.dart';

final class PhoneNumber extends ZardValueObject<String> {
  PhoneNumber(String input) : super(_parse(input));

  String get formatted => AppBrFormatters.phone(value);

  static String _parse(String input) {
    final normalized = ZardValueObject.parse<String>(
      objectName: 'PhoneNumber',
      input: input,
      schema: z.string().trim(),
    );
    final digitsOnly = AppBrFormatters.digitsOnly(normalized);

    ZardValueObject.refine(
      objectName: 'PhoneNumber',
      isValid: digitsOnly.length == 10 || digitsOnly.length == 11,
      message: 'Invalid phone number value',
    );

    return digitsOnly;
  }
}
