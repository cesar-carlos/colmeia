import 'package:colmeia/core/value_objects/zard_value_object.dart';
import 'package:zard/zard.dart';

final class EmailAddress extends ZardValueObject<String> {
  EmailAddress(String input) : super(_parse(input));

  static String _parse(String input) {
    final normalized = ZardValueObject.parse<String>(
      objectName: 'EmailAddress',
      input: input,
      schema: z.string().trim().toLowerCase(),
    );

    return ZardValueObject.parse<String>(
      objectName: 'EmailAddress',
      input: normalized,
      schema: z.string().email(pattern: z.regexes.email),
    );
  }
}
