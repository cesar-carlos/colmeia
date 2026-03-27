import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/value_object.dart';
import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';

typedef DateRangeValue = ({DateTime start, DateTime end});

final class DateRange extends ValueObject<DateRangeValue> {
  DateRange({
    required DateTime start,
    required DateTime end,
  }) : super(_normalize(start: start, end: end));

  DateTime get start => value.start;
  DateTime get end => value.end;

  String get formatted =>
      '${AppBrFormatters.shortDate(start)} - '
      '${AppBrFormatters.shortDate(end)}';

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static DateRangeValue _normalize({
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = DateTime(
      start.year,
      start.month,
      start.day,
    );
    final normalizedEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
      999,
    );

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const ValueObjectValidationException(
        objectName: 'DateRange',
        messages: <String>['End date must be after start date'],
      );
    }

    return (start: normalizedStart, end: normalizedEnd);
  }
}
