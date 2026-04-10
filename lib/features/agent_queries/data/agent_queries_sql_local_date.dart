import 'package:intl/intl.dart';

/// Formats a calendar [DateTime] for SQL `DATE` parameters (`yyyy-MM-dd`).
///
/// Uses the same locale calendar as [DateFormat] default (typically local).
abstract final class AgentQueriesSqlLocalDate {
  static final DateFormat _format = DateFormat('yyyy-MM-dd');

  static String format(DateTime dateTime) => _format.format(dateTime);
}
