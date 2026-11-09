import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';

enum RefreshFilterType { text, integer }

class CacheRefreshReport {
  const CacheRefreshReport(
    this.id,
    this.label, {
    this.fields = const {},
    this.supportsFixedPeriod = true,
    this.note,
  });
  final String id;
  final String label;
  final Map<String, RefreshFilterType> fields;
  final bool supportsFixedPeriod;
  final String? note;
  Map<String, Object?> normalizedFilters(CacheRefreshSchedule schedule) {
    return schedule.filters;
  }

  void validate(CacheRefreshSchedule schedule, DateTime now) {
    schedule.validate(now);
    final range = schedule.resolvePeriod(now);
    if (id.startsWith('overview.') &&
        range.end.difference(range.start).inDays >= 366) {
      throw const ValidationFailure(
        message: 'overview_schedule_period_too_long',
        userMessage: 'Selecione um período de até 366 dias.',
      );
    }
    if (!supportsFixedPeriod && schedule.period == CacheRefreshPeriod.fixed) {
      throw const ValidationFailure(
        message: 'unsupported_fixed_period',
        userMessage: 'Esta consulta utiliza seu período próprio.',
      );
    }
    for (final entry in schedule.filters.entries) {
      final type = fields[entry.key];
      if (type == null ||
          (type == RefreshFilterType.integer && entry.value is! int) ||
          (type == RefreshFilterType.text && entry.value is! String)) {
        throw const ValidationFailure(message: 'invalid_report_filters');
      }
    }
  }
}
