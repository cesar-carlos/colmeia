/// Local-calendar rules for when ERP buckets are treated as closed.
abstract final class CalendarBucketClosure {
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static bool isCalendarDayClosed({
    required DateTime day,
    required DateTime clock,
  }) {
    return startOfDay(day).isBefore(startOfDay(clock));
  }

  static bool isCalendarMonthClosed({
    required int year,
    required int month,
    required DateTime clock,
  }) {
    final now = startOfDay(clock);
    if (year < now.year) {
      return true;
    }
    if (year > now.year) {
      return false;
    }
    return month < now.month;
  }

  /// Inclusive local calendar days from [start] through [end] (date-only).
  static List<DateTime> daysInRange({
    required DateTime start,
    required DateTime end,
  }) {
    var cursor = startOfDay(start);
    final last = startOfDay(end);
    if (last.isBefore(cursor)) {
      return const <DateTime>[];
    }
    final days = <DateTime>[];
    while (!cursor.isAfter(last)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  static String dayBucketId(DateTime day) {
    final d = startOfDay(day);
    final m = d.month.toString().padLeft(2, '0');
    final dayNum = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dayNum';
  }

  static String monthBucketId({required int year, required int month}) {
    final m = month.toString().padLeft(2, '0');
    return '$year-$m';
  }

  /// Inclusive calendar months overlapping [start]..[end] (date-only).
  static List<({int year, int month})> monthsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    var y = start.year;
    var m = start.month;
    final endY = end.year;
    final endM = end.month;
    final months = <({int year, int month})>[];
    while (y < endY || (y == endY && m <= endM)) {
      months.add((year: y, month: m));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return months;
  }

  static ({int year, int month})? parseMonthBucketId(String bucketId) {
    final parts = bucketId.split('-');
    if (parts.length != 2) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) {
      return null;
    }
    return (year: year, month: month);
  }

  static DateTime? parseDayBucketId(String bucketId) {
    final parts = bucketId.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}
