import 'package:colmeia/core/value_objects/zard_value_object.dart';
import 'package:zard/zard.dart';

final class ReportId extends ZardValueObject<String> {
  ReportId(String input)
    : super(
        ZardValueObject.parse<String>(
          objectName: 'ReportId',
          input: input,
          schema: z.string().trim().min(1),
        ),
      );
}
