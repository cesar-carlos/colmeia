import 'package:colmeia/core/value_objects/value_object.dart';
import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';
import 'package:zard/zard.dart';

abstract class ZardValueObject<T> extends ValueObject<T> {
  const ZardValueObject(super.value);

  static T parse<T>({
    required String objectName,
    required Schema<T> schema,
    required Object? input,
  }) {
    final result = schema.safeParse(input);

    if (result.success && result.data != null) {
      return result.data as T;
    }

    final messages = result.error?.format() ?? <String>[];

    throw ValueObjectValidationException(
      objectName: objectName,
      messages: messages.isEmpty
          ? <String>['Invalid value provided']
          : messages,
    );
  }

  static void refine({
    required String objectName,
    required bool isValid,
    required String message,
  }) {
    if (isValid) {
      return;
    }

    throw ValueObjectValidationException(
      objectName: objectName,
      messages: <String>[message],
    );
  }
}
