import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/value_object.dart';
import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';

final class MoneyAmount extends ValueObject<double> {
  MoneyAmount(num input) : super(_normalize(input));

  String get formatted => AppBrFormatters.currency(value);

  static double _normalize(num input) {
    final normalized = input.toDouble();

    if (!normalized.isFinite) {
      throw const ValueObjectValidationException(
        objectName: 'MoneyAmount',
        messages: <String>['Invalid money amount'],
      );
    }

    return normalized;
  }
}
