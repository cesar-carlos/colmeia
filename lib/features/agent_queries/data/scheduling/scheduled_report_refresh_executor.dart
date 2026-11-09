import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_query_snapshots.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_report.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';

typedef ScheduledReportHandler = Future<void> Function(
  CacheRefreshSchedule schedule,
  ({DateTime start, DateTime end}) period,
  AgentQueriesCancelScope scope,
);

class RegisteredReportRefreshExecutor
    implements ScheduledReportRefreshExecutor {
  RegisteredReportRefreshExecutor(
    this.reports,
    this.handlers, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final List<CacheRefreshReport> reports;
  final Map<String, ScheduledReportHandler> handlers;
  @override
  Future<Map<String, dynamic>> execute(
    CacheRefreshSchedule schedule,
    ({DateTime start, DateTime end}) period,
    AgentQueriesCancelScope cancelScope,
  ) async {
    final report = reports.where((r) => r.id == schedule.reportId).firstOrNull;
    final handler = handlers[schedule.reportId];
    if (report == null || handler == null) {
      throw const ValidationFailure(message: 'unsupported_scheduled_report');
    }
    report.validate(schedule, _clock());
    if (schedule.reportId == 'offlinePackage') {
      await handler(schedule, period, cancelScope);
      if (cancelScope.isCancelled) throw const OperationCancelledFailure();
      return {'packagePublished': true};
    }
    final capture = ScheduledQueryCapture(cancelScope: cancelScope);
    await capture.run(() => handler(schedule, period, cancelScope));
    if (cancelScope.isCancelled) throw const OperationCancelledFailure();
    if (capture.incomplete) {
      throw const NetworkFailure(message: 'incomplete_scheduled_queries');
    }
    return {'queries': capture.queries};
  }
}
