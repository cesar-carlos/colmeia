import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/mappers/daily_sales_trend_point_mapper.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_complete_period.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/sales/application/sales_monthly_pnl_points_mapper.dart';
import 'package:colmeia/features/sales/data/sales_monthly_pnl_batch_command_builder.dart';
import 'package:colmeia/features/sales/data/sales_monthly_pnl_batch_load_config.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

typedef SalesMonthlyPnlScreenBatchLoadResult = ({
  List<SalesMonthlyPnlPoint> monthlyPoints,
  bool monthlyLoadFailed,
  AppFailure? monthlyLoadFailure,
  List<DailySalesTrendPoint> dailyPoints,
  bool dailyLoadFailed,
  AppFailure? dailyLoadFailure,
});

/// Loads Resultado mensal charts in one `sql.executeBatch` round-trip
/// (lucratividade mensal + totais diários) for the same agent/token.
class LoadSalesMonthlyPnlScreenBatchUseCase {
  LoadSalesMonthlyPnlScreenBatchUseCase(
    this._agentQueriesRepository, {
    AgentQueryTransportPolicy? transportPolicy,
    int? maxParallelReadOnlyBatchItems,
    Duration? emptySuccessRetryDelay,
    Future<void> Function(Duration duration)? delay,
  }) : _transportPolicy =
           transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           ),
       _maxParallelReadOnlyBatchItems =
           maxParallelReadOnlyBatchItems ??
           AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems,
       _emptySuccessRetryDelay =
           emptySuccessRetryDelay ?? defaultEmptySuccessRetryDelay,
       _delay =
           delay ??
           // ignore: unnecessary_lambdas — tear-off has an optional 2nd arg.
           ((duration) => Future<void>.delayed(duration));

  static const String _operation = 'loadSalesMonthlyPnlScreenBatch';
  static const Duration defaultEmptySuccessRetryDelay = Duration(seconds: 2);

  /// Kept for call-site compatibility with older tests/docs.
  static const Duration emptySuccessRetryDelay = defaultEmptySuccessRetryDelay;

  final AgentQueriesRepository _agentQueriesRepository;
  final AgentQueryTransportPolicy _transportPolicy;
  final int _maxParallelReadOnlyBatchItems;
  final Duration _emptySuccessRetryDelay;
  final Future<void> Function(Duration duration) _delay;

  Future<SalesMonthlyPnlScreenBatchLoadResult> call({
    required String userId,
    required String agentId,
    required DashboardYearMonth anchor,
    DashboardDateRange? dailySaleDateRange,
    String? clientToken,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final trimmedAgentId = agentId.trim();
    final last12 = OverviewLast12MonthsVendaRange.fromPeriodEnd(anchor.end);
    final monthlyFilter = ResumoProdutoVendaLucratividadeMensalFilter(
      dataVendaInicio: last12.dataVendaInicio,
      dataVendaFim: last12.dataVendaFim,
    );

    final DateTime dailyStart;
    final DateTime dailyEnd;
    if (dailySaleDateRange != null) {
      final r = dailySaleDateRange;
      dailyStart = DateTime(
        r.startInclusive.year,
        r.startInclusive.month,
        r.startInclusive.day,
      );
      dailyEnd = DateTime(
        r.endInclusive.year,
        r.endInclusive.month,
        r.endInclusive.day,
      );
    } else {
      dailyStart = anchor.start;
      dailyEnd = DateTime(anchor.year, anchor.month + 1, 0);
    }
    final dailyFilter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: dailyStart,
      dataVendaFim: dailyEnd,
    );

    final monthlyValidation = monthlyFilter.validationError();
    if (monthlyValidation != null) {
      final failure = ValidationFailure(
        message: monthlyValidation,
        userMessage: 'Os filtros da consulta sao invalidos.',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': trimmedAgentId,
        },
      );
      return _bothFailed(failure);
    }
    final dailyValidation = dailyFilter.validationError();
    if (dailyValidation != null) {
      final failure = ValidationFailure(
        message: dailyValidation,
        userMessage: 'Os filtros da consulta sao invalidos.',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': trimmedAgentId,
        },
      );
      return _bothFailed(failure);
    }

    final batch = SalesMonthlyPnlBatchCommandBuilder.build(
      monthlyFilter: monthlyFilter,
      dailyFilter: dailyFilter,
    );

    Future<SalesMonthlyPnlScreenBatchLoadResult> executeBatch(
      SalesMonthlyPnlBatchCommands commands, {
      SalesMonthlyPnlScreenBatchLoadResult? preserveDailyFrom,
    }) async {
      final request = _transportPolicy.applyBatch(
        AgentSqlExecuteBatchRequest(
          agentId: trimmedAgentId,
          requestingUserId: userId,
          clientToken: clientToken,
          bridgeTimeoutMs: SalesMonthlyPnlBatchLoadConfig.bridgeTimeoutMs,
          commands: commands.commands,
          options: AgentSqlReadOnlyBatchOptions.dashboard(
            sqlTimeoutMs: SalesMonthlyPnlBatchLoadConfig.sqlTimeoutMs,
            maxRows: SalesMonthlyPnlBatchLoadConfig.batchMaxRows,
            maxParallelReadOnlyBatchItems: _maxParallelReadOnlyBatchItems,
          ),
          skipTransportCache: true,
          useRelay: true,
        ),
        dashboardBatch: true,
      );

      final result = await _agentQueriesRepository.executeSqlBatch(
        request,
        cancelScope: cancelScope,
      );
      final execution = result.getOrNull();
      if (execution == null) {
        final failure = result.exceptionOrNull()!;
        AppLogger.warning(
          'Sales: monthly pnl screen batch failed',
          context: <String, Object?>{
            'operation': _operation,
            'failureType': failure.runtimeType.toString(),
          },
          error: failure,
        );
        if (preserveDailyFrom != null) {
          return (
            monthlyPoints: const <SalesMonthlyPnlPoint>[],
            monthlyLoadFailed: true,
            monthlyLoadFailure: failure,
            dailyPoints: preserveDailyFrom.dailyPoints,
            dailyLoadFailed: preserveDailyFrom.dailyLoadFailed,
            dailyLoadFailure: preserveDailyFrom.dailyLoadFailure,
          );
        }
        return _bothFailed(failure);
      }

      return _mapExecution(
        execution: execution,
        indexes: commands.indexes,
        agentId: trimmedAgentId,
        monthlyStart: last12.dataVendaInicio,
        monthlyEnd: last12.dataVendaFim,
        dailyStart: dailyStart,
        dailyEnd: dailyEnd,
        preserveDailyFrom: preserveDailyFrom,
      );
    }

    final first = await executeBatch(batch);
    if (first.monthlyLoadFailed || first.monthlyPoints.isNotEmpty) {
      return first;
    }

    AppLogger.info(
      'Retrying empty monthly slot for $_operation',
      context: <String, Object?>{
        'operation': _operation,
        'agentId': trimmedAgentId,
        'retryDelayMs': _emptySuccessRetryDelay.inMilliseconds,
        'monthlyOnly': true,
      },
    );
    await _delay(_emptySuccessRetryDelay);
    final monthlyOnly = SalesMonthlyPnlBatchCommandBuilder.buildMonthlyOnly(
      monthlyFilter: monthlyFilter,
    );
    return executeBatch(monthlyOnly, preserveDailyFrom: first);
  }

  SalesMonthlyPnlScreenBatchLoadResult _mapExecution({
    required AgentSqlBatchExecutionResult execution,
    required SalesMonthlyPnlBatchCommandIndexes indexes,
    required String agentId,
    required DateTime monthlyStart,
    required DateTime monthlyEnd,
    required DateTime dailyStart,
    required DateTime dailyEnd,
    SalesMonthlyPnlScreenBatchLoadResult? preserveDailyFrom,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };

    final monthlyMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<
          ResumoProdutoVendaLucratividadeMensalRow
        >(
          byIndex,
          indexes.monthlyPnl,
          (row) => ResumoProdutoVendaLucratividadeMensalRowModel.fromMap(
            row,
          ).toEntity(),
          operation: _operation,
        );

    agentQueriesWarnIfSqlRowsAtCap(
      operation: _operation,
      agentId: agentId,
      returnedRowCount: monthlyMapped.rows.length,
      maxRows: SalesMonthlyPnlBatchLoadConfig.monthlyWarnMaxRows,
    );

    final monthlyFailure = monthlyMapped.failure;

    final List<SalesMonthlyPnlPoint> monthlyPoints;
    if (monthlyFailure != null) {
      monthlyPoints = const <SalesMonthlyPnlPoint>[];
    } else if (monthlyMapped.rows.isEmpty) {
      AppLogger.info(
        'Sales: monthly pnl batch slot returned no rows',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
      );
      monthlyPoints = const <SalesMonthlyPnlPoint>[];
    } else {
      monthlyPoints = SalesMonthlyPnlPointsMapper.fromRows(
        monthlyMapped.rows,
        start: monthlyStart,
        end: monthlyEnd,
      );
    }

    if (preserveDailyFrom != null || indexes.dailyTotals < 0) {
      final daily = preserveDailyFrom;
      return (
        monthlyPoints: monthlyPoints,
        monthlyLoadFailed: monthlyFailure != null,
        monthlyLoadFailure: monthlyFailure,
        dailyPoints: daily?.dailyPoints ?? const <DailySalesTrendPoint>[],
        dailyLoadFailed: daily?.dailyLoadFailed ?? false,
        dailyLoadFailure: daily?.dailyLoadFailure,
      );
    }

    final dailyMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<ResumoTotalDiarioVendasRow>(
          byIndex,
          indexes.dailyTotals,
          (row) => ResumoTotalDiarioVendasRowModel.fromMap(row).toEntity(),
          operation: _operation,
        );

    agentQueriesWarnIfSqlRowsAtCap(
      operation: _operation,
      agentId: agentId,
      returnedRowCount: dailyMapped.rows.length,
      maxRows: SalesMonthlyPnlBatchLoadConfig.dailyWarnMaxRows,
    );

    final dailyFailure = dailyMapped.failure;

    final List<DailySalesTrendPoint> dailyPoints;
    if (dailyFailure != null) {
      dailyPoints = const <DailySalesTrendPoint>[];
    } else {
      final filled = ResumoTotalDiarioVendasCompletePeriod.fill(
        dataVendaInicio: dailyStart,
        dataVendaFim: dailyEnd,
        rows: dailyMapped.rows,
      );
      dailyPoints = dailySalesTrendPointsFromRows(filled);
    }

    return (
      monthlyPoints: monthlyPoints,
      monthlyLoadFailed: monthlyFailure != null,
      monthlyLoadFailure: monthlyFailure,
      dailyPoints: dailyPoints,
      dailyLoadFailed: dailyFailure != null,
      dailyLoadFailure: dailyFailure,
    );
  }

  SalesMonthlyPnlScreenBatchLoadResult _bothFailed(AppFailure failure) {
    return (
      monthlyPoints: const <SalesMonthlyPnlPoint>[],
      monthlyLoadFailed: true,
      monthlyLoadFailure: failure,
      dailyPoints: const <DailySalesTrendPoint>[],
      dailyLoadFailed: true,
      dailyLoadFailure: failure,
    );
  }
}
