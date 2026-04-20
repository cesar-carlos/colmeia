import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/mappers/overview_agent_resumo_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_monthly_parcel_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_user_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:result_dart/result_dart.dart';

class OverviewRepositoryImpl implements OverviewRepository {
  OverviewRepositoryImpl({
    required OverviewLocalDataSource localDataSource,
    required ResumoParcelaFormaPagamentoAcrossAgentsRepository
    resumoAcrossAgentsRepository,
    required LoadResumoParcelasMensalAcrossAgentsUseCase
    loadResumoParcelasMensalAcrossAgents,
    required LoadResumoParcelasDiaSemanaAcrossAgentsUseCase
    loadResumoParcelasDiaSemanaAcrossAgents,
    required LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase
    loadResumoParcelasDiaSemanaUsuarioAcrossAgents,
    DateTime Function()? now,
  }) : _localDataSource = localDataSource,
       _resumoAcrossAgentsRepository = resumoAcrossAgentsRepository,
       _loadResumoParcelasMensalAcrossAgents =
           loadResumoParcelasMensalAcrossAgents,
       _loadResumoParcelasDiaSemanaAcrossAgents =
           loadResumoParcelasDiaSemanaAcrossAgents,
       _loadResumoParcelasDiaSemanaUsuarioAcrossAgents =
           loadResumoParcelasDiaSemanaUsuarioAcrossAgents,
       _now = now ?? DateTime.now;

  final OverviewLocalDataSource _localDataSource;
  final ResumoParcelaFormaPagamentoAcrossAgentsRepository
  _resumoAcrossAgentsRepository;
  final LoadResumoParcelasMensalAcrossAgentsUseCase
  _loadResumoParcelasMensalAcrossAgents;
  final LoadResumoParcelasDiaSemanaAcrossAgentsUseCase
  _loadResumoParcelasDiaSemanaAcrossAgents;
  final LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase
  _loadResumoParcelasDiaSemanaUsuarioAcrossAgents;
  final DateTime Function() _now;

  static const String _sourceAgentIdsContextField = 'sourceAgentIds';
  static const Duration _overviewCacheMaxAge = Duration(hours: 48);

  /// Monthly resumo SQL is heavier than the rolling payment mix query; allow
  /// a longer bridge wait so merge-all runs do not all fail on slow agents.
  static const int _overviewMonthlyParcelSqlBridgeTimeoutMs = 300000;
  static const int _overviewWeekdaySalesSqlBridgeTimeoutMs = 300000;

  /// Higher cardinality than the aggregate weekday query; allow merge-all a
  /// little longer before the bridge times out.
  static const int _overviewWeekdayUserSqlBridgeTimeoutMs = 360000;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) async {
    final resolvedRowLabels = rowLabels ?? OverviewLoadLabels.englishFallback;
    final period = _buildPeriod(filter);
    final last12Range = OverviewLast12MonthsVendaRange.fromOverviewFilter(
      filter,
      clock: _now,
    );
    final mensalFilter = ResumoParcelasMensalFilter(
      dataVendaInicio: last12Range.dataVendaInicio,
      dataVendaFim: last12Range.dataVendaFim,
    );
    final weekdayFilter = ResumoParcelasDiaSemanaFilter(
      dataVendaInicio: period.start,
      dataVendaFim: period.end,
    );
    final executionStrategy = _resolveExecutionStrategy(filter);
    final monthlyParcelFuture = _loadResumoParcelasMensalAcrossAgents(
      userId: userId,
      filter: mensalFilter,
      selectedAgentIds: filter.selectedAgentIds,
      strategy: executionStrategy,
      bridgeTimeoutMs: _overviewMonthlyParcelSqlBridgeTimeoutMs,
    );
    final weekdaySalesFuture = _loadResumoParcelasDiaSemanaAcrossAgents(
      userId: userId,
      filter: weekdayFilter,
      selectedAgentIds: filter.selectedAgentIds,
      strategy: executionStrategy,
      bridgeTimeoutMs: _overviewWeekdaySalesSqlBridgeTimeoutMs,
    );
    Future<AppResult<AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>>>?
        weekdayUserBridgeFuture;
    try {
      final reportResult = await _resumoAcrossAgentsRepository.load(
        userId: userId,
        filter: _resumoFilter(period),
        selectedAgentIds: filter.selectedAgentIds,
        strategy: executionStrategy,
      );
      final report = reportResult.getOrNull();
      if (report != null && report.consideredApprovedAgentCount > 0) {
        weekdayUserBridgeFuture = _loadResumoParcelasDiaSemanaUsuarioAcrossAgents(
          userId: userId,
          filter: weekdayFilter,
          selectedAgentIds: filter.selectedAgentIds,
          strategy: executionStrategy,
          bridgeTimeoutMs: _overviewWeekdayUserSqlBridgeTimeoutMs,
        );
      }
      if (report == null) {
        await monthlyParcelFuture;
        await weekdaySalesFuture;
        final failure = _mapOverviewFailure(
          reportResult.exceptionOrNull()!,
          userId: userId,
        );
        return _recoverOrFail(
          failure: failure,
          userId: userId,
          policy: policy,
          period: period,
          sourceAgentIds: _resolveFailureSourceAgentIds(
            failure,
            fallbackSelectedAgentIds: filter.selectedAgentIds,
          ),
        );
      }

      if (report.consideredApprovedAgentCount == 0) {
        final monthlyF = _resolveMonthlyParcelTrend(
          monthlyParcelFuture,
          mensalFilter,
        );
        final weekdayF = _resolveWeekdaySalesTrend(weekdaySalesFuture);
        final userF = _resolveWeekdayUserSalesTrendOptional(
          weekdayUserBridgeFuture,
        );
        final monthly = await monthlyF;
        final weekday = await weekdayF;
        final weekdayUser = await userF;
        return Success<Overview, AppFailure>(
          _buildOverview(
            const <OverviewPaymentResumoRow>[],
            rowsByAgentId: const <String, List<OverviewPaymentResumoRow>>{},
            agentDisplayNamesById: const <String, String>{},
            periodStart: period.start,
            periodEnd: period.end,
            approvedAgentCount: 0,
            rowLabels: resolvedRowLabels,
            monthlyParcelTrend: monthly.points,
            monthlyParcelTrendLoadFailed: monthly.loadFailed,
            monthlyParcelTrendLoadFailureMessage: monthly.loadFailureMessage,
            weekdaySalesTrend: weekday.points,
            weekdaySalesTrendLoadFailed: weekday.loadFailed,
            weekdaySalesTrendLoadFailureMessage: weekday.loadFailureMessage,
            weekdayUserSalesTrend: weekdayUser.points,
            weekdayUserSalesTrendLoadFailed: weekdayUser.loadFailed,
            weekdayUserSalesTrendLoadFailureMessage:
                weekdayUser.loadFailureMessage,
          ),
        );
      }

      final sourceAgentIds = _resolveSourceAgentIds(report);
      if (report.missingClientTokenAgentIds.isNotEmpty) {
        AppLogger.warning(
          'Overview: agents skipped (no local client_token)',
          context: <String, Object?>{
            'operation': 'loadOverview',
            'userId': userId,
            'missingTokenCount': report.missingClientTokenAgentIds.length,
            'missingTokenAgentIds': report.missingClientTokenAgentIds.join(
              ', ',
            ),
          },
        );
      }

      if (report.requiresClientTokenSetup) {
        final cachedOverview = await _readCachedOverviewForMissingClientTokens(
          userId: userId,
          policy: policy,
          period: period,
          expectedSortedAgentIds: sourceAgentIds,
          agentIdsMissingClientToken: report.missingClientTokenAgentIds,
          agentNamesMissingClientToken: report.missingClientTokenAgentNames,
        );
        if (cachedOverview != null) {
          final monthlyF = _resolveMonthlyParcelTrend(
            monthlyParcelFuture,
            mensalFilter,
          );
          final weekdayF = _resolveWeekdaySalesTrend(weekdaySalesFuture);
          final userF = _resolveWeekdayUserSalesTrendOptional(
            weekdayUserBridgeFuture,
          );
          final monthly = await monthlyF;
          final weekday = await weekdayF;
          final weekdayUser = await userF;
          return Success<Overview, AppFailure>(
            cachedOverview.copyWith(
              monthlyParcelTrend: monthly.points,
              monthlyParcelTrendLoadFailed: monthly.loadFailed,
              monthlyParcelTrendLoadFailureMessage: monthly.loadFailureMessage,
              weekdaySalesTrend: weekday.points,
              weekdaySalesTrendLoadFailed: weekday.loadFailed,
              weekdaySalesTrendLoadFailureMessage: weekday.loadFailureMessage,
              weekdayUserSalesTrend: weekdayUser.points,
              weekdayUserSalesTrendLoadFailed: weekdayUser.loadFailed,
              weekdayUserSalesTrendLoadFailureMessage:
                  weekdayUser.loadFailureMessage,
            ),
          );
        }
      }

      if (report.failedAgentIds.isNotEmpty) {
        AppLogger.warning(
          'Overview: partial agent resumo results',
          context: <String, Object?>{
            'operation': 'loadOverview',
            'userId': userId,
            'failedAgentCount': report.failedAgentIds.length,
            'failedAgentIds': report.failedAgentIds.join(', '),
          },
        );
      }

      final monthlyF = _resolveMonthlyParcelTrend(
        monthlyParcelFuture,
        mensalFilter,
      );
      final weekdayF = _resolveWeekdaySalesTrend(weekdaySalesFuture);
      final userF = _resolveWeekdayUserSalesTrendOptional(
        weekdayUserBridgeFuture,
      );
      final monthly = await monthlyF;
      final weekday = await weekdayF;
      final weekdayUser = await userF;
      final overview = _buildOverview(
        _mapOverviewRows(report.mergedRows),
        rowsByAgentId: _mapRowsByAgentId(report.rowsByAgentId),
        agentDisplayNamesById: _resolveAgentDisplayNames(report),
        periodStart: period.start,
        periodEnd: period.end,
        approvedAgentCount: report.consideredApprovedAgentCount,
        rowLabels: resolvedRowLabels,
        agentIdsExcludedFromQueryFailure: report.failedAgentIds,
        agentNamesExcludedFromQueryFailure: report.failedAgentNames,
        agentIdsMissingClientToken: report.missingClientTokenAgentIds,
        agentNamesMissingClientToken: report.missingClientTokenAgentNames,
        agentIdsSkippedDueToHubPresence:
            report.skippedDueToHubPresenceAgentIds,
        agentNamesSkippedDueToHubPresence:
            report.skippedDueToHubPresenceAgentNames,
        monthlyParcelTrend: monthly.points,
        monthlyParcelTrendLoadFailed: monthly.loadFailed,
        monthlyParcelTrendLoadFailureMessage: monthly.loadFailureMessage,
        weekdaySalesTrend: weekday.points,
        weekdaySalesTrendLoadFailed: weekday.loadFailed,
        weekdaySalesTrendLoadFailureMessage: weekday.loadFailureMessage,
        weekdayUserSalesTrend: weekdayUser.points,
        weekdayUserSalesTrendLoadFailed: weekdayUser.loadFailed,
        weekdayUserSalesTrendLoadFailureMessage:
            weekdayUser.loadFailureMessage,
        mainResumoHadPlannedTargets: report.plannedTargets.isNotEmpty,
      );

      final stamp = _now();
      final model = OverviewModel.fromEntity(
        overview,
        cachedAt: stamp,
        sourceAgentIds: sourceAgentIds,
      );

      try {
        await _localDataSource.saveOverview(userId: userId, overview: model);
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Overview cache save failed; returning computed overview',
          context: <String, Object?>{
            'operation': 'loadOverview',
            'userId': userId,
          },
          error: error,
          stackTrace: stackTrace,
        );
      }

      AppLogger.info(
        'Overview loaded from agent query',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'userId': userId,
          'agentCount': report.consideredApprovedAgentCount,
          'periodStart': period.start.toIso8601String(),
          'periodEnd': period.end.toIso8601String(),
          'paymentMethods': overview.paymentMethods.length,
          'partialQueryFailures':
              overview.agentIdsExcludedFromQueryFailure.length,
          'agentsMissingClientToken':
              overview.agentIdsMissingClientToken.length,
        },
      );

      return Success<Overview, AppFailure>(overview);
    } on Object catch (error, stackTrace) {
      await monthlyParcelFuture;
      await weekdaySalesFuture;
      if (weekdayUserBridgeFuture != null) {
        await weekdayUserBridgeFuture;
      }
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to load overview',
        fallbackUserMessage: 'Unable to load the overview.',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'userId': userId,
          'policy': policy.name,
          OverviewFailureUiKey.field: OverviewFailureUiKey.loadFailed,
        },
      );
      return _recoverOrFail(
        failure: failure,
        userId: userId,
        policy: policy,
        period: period,
        sourceAgentIds: _resolveFailureSourceAgentIds(
          failure,
          fallbackSelectedAgentIds: filter.selectedAgentIds,
        ),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Merge-all loads every planned agent in parallel and merges rows (required
  /// for consolidated KPIs). Race would keep only the first successful agent.
  /// Single-source when exactly one agent is selected.
  AgentQueryExecutionStrategy _resolveExecutionStrategy(
    OverviewFilter filter,
  ) {
    final selectedAgentIds = filter.selectedAgentIds;
    if (selectedAgentIds != null && selectedAgentIds.length == 1) {
      return AgentQueryExecutionStrategy.singleSource;
    }
    return AgentQueryExecutionStrategy.mergeAll;
  }

  Future<
    ({
      List<OverviewMonthlyParcelPoint> points,
      bool loadFailed,
      String? loadFailureMessage,
    })
  >
  _resolveMonthlyParcelTrend(
    Future<AppResult<AgentQueryExecutionReport<ResumoParcelasMensalRow>>>
    monthlyParcelFuture,
    ResumoParcelasMensalFilter mensalFilter,
  ) async {
    return _resolveOptionalChartData<
      ResumoParcelasMensalRow,
      OverviewMonthlyParcelPoint
    >(
      future: monthlyParcelFuture,
      mapSuccess: (report) {
        final rows = report.chartRowsFilledPeriod(mensalFilter);
        return overviewMonthlyParcelPointsFromRows(rows);
      },
      failureLogMessage: 'Overview: monthly parcel trend query failed',
      emptyValue: const <OverviewMonthlyParcelPoint>[],
    );
  }

  Future<
    ({
      List<OverviewWeekdaySalesTrendPoint> points,
      bool loadFailed,
      String? loadFailureMessage,
    })
  >
  _resolveWeekdaySalesTrend(
    Future<AppResult<AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>>>
    weekdaySalesFuture,
  ) async {
    return _resolveOptionalChartData<
      ResumoParcelasDiaSemanaRow,
      OverviewWeekdaySalesTrendPoint
    >(
      future: weekdaySalesFuture,
      mapSuccess: (report) =>
          overviewWeekdaySalesTrendPointsFromRows(report.chartRowsWeek),
      failureLogMessage: 'Overview: weekday sales trend query failed',
      emptyValue: const <OverviewWeekdaySalesTrendPoint>[],
    );
  }

  /// When [future] is null (no approved agents), skips the bridge call.
  Future<
    ({
      List<OverviewWeekdayUserSalesTrendPoint> points,
      bool loadFailed,
      String? loadFailureMessage,
    })
  >
  _resolveWeekdayUserSalesTrendOptional(
    Future<
      AppResult<
        AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>
      >
    >?
    future,
  ) async {
    if (future == null) {
      return (
        points: const <OverviewWeekdayUserSalesTrendPoint>[],
        loadFailed: false,
        loadFailureMessage: null,
      );
    }
    return _resolveWeekdayUserSalesTrend(future);
  }

  Future<
    ({
      List<OverviewWeekdayUserSalesTrendPoint> points,
      bool loadFailed,
      String? loadFailureMessage,
    })
  >
  _resolveWeekdayUserSalesTrend(
    Future<
      AppResult<
        AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>
      >
    >
    weekdayUserSalesFuture,
  ) async {
    return _resolveOptionalChartData<
      ResumoParcelasDiaSemanaUsuarioRow,
      OverviewWeekdayUserSalesTrendPoint
    >(
      future: weekdayUserSalesFuture,
      mapSuccess: (report) {
        final rows = report.aggregatedMergedRows;
        if (rows.length >=
            AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemanaUsuario) {
          AppLogger.info(
            'Overview: weekday-by-user rows at max_rows cap; chart may be incomplete',
            context: <String, Object?>{
              'operation': 'loadOverview',
              'rowCount': rows.length,
              'maxRows':
                  AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemanaUsuario,
            },
          );
        }
        return overviewWeekdayUserSalesTrendPointsFromRows(rows);
      },
      failureLogMessage: 'Overview: weekday-by-user sales trend query failed',
      emptyValue: const <OverviewWeekdayUserSalesTrendPoint>[],
    );
  }

  Future<
    ({
      List<TPoint> points,
      bool loadFailed,
      String? loadFailureMessage,
    })
  >
  _resolveOptionalChartData<TRow, TPoint>({
    required Future<AppResult<AgentQueryExecutionReport<TRow>>> future,
    required List<TPoint> Function(AgentQueryExecutionReport<TRow> report)
    mapSuccess,
    required String failureLogMessage,
    required List<TPoint> emptyValue,
  }) async {
    final result = await future;
    return result.fold(
      (report) => (
        points: mapSuccess(report),
        loadFailed: false,
        loadFailureMessage: null,
      ),
      (failure) {
        AppLogger.warning(
          failureLogMessage,
          context: <String, Object?>{
            'operation': 'loadOverview',
            'failureType': failure.runtimeType.toString(),
          },
          error: failure,
        );
        // BUG #4 fix: forward the user-facing message from the underlying
        // AppFailure (e.g. "Voce nao tem acesso a este agente.", or the
        // RPC-resolved PT message) so the chart can show it instead of a
        // generic "Não foi possível carregar este gráfico". `userMessage`
        // can be null when the failure layer chose not to surface one
        // (e.g. cancelled/disposed); in that case the chart falls back to
        // the existing l10n label.
        return (
          points: emptyValue,
          loadFailed: true,
          loadFailureMessage: failure.userMessage,
        );
      },
    );
  }

  ResumoParcelaFormaPagamentoFilter _resumoFilter(_OverviewPeriod period) {
    return ResumoParcelaFormaPagamentoFilter(
      dataVendaInicio: period.start,
      dataVendaFim: period.end,
    );
  }

  List<OverviewPaymentResumoRow> _mapOverviewRows(
    List<ResumoParcelaFormaPagamentoRow> rows,
  ) {
    return rows
        .map(overviewPaymentResumoRowFromAgentRow)
        .toList(growable: false);
  }

  Map<String, List<OverviewPaymentResumoRow>> _mapRowsByAgentId(
    Map<String, List<ResumoParcelaFormaPagamentoRow>> rowsByAgentId,
  ) {
    return <String, List<OverviewPaymentResumoRow>>{
      for (final entry in rowsByAgentId.entries)
        entry.key: _mapOverviewRows(entry.value),
    };
  }

  Map<String, String> _resolveAgentDisplayNames(
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow> report,
  ) {
    return <String, String>{
      for (final target in report.plannedTargets)
        target.agentId: target.displayName,
      for (final target in report.missingClientTokenTargets)
        target.agentId: target.displayName,
    };
  }

  List<String> _resolveSourceAgentIds(
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow> report,
  ) {
    final ids = <String>{
      for (final target in report.plannedTargets) target.agentId,
      for (final target in report.missingClientTokenTargets) target.agentId,
    }.toList(growable: false)..sort();
    return ids;
  }

  List<String>? _normalizeSelectedAgentIds(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null) {
      return null;
    }
    final ids =
        selectedAgentIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false)
          ..sort();
    return ids;
  }

  List<String>? _resolveFailureSourceAgentIds(
    AppFailure failure, {
    required Set<String>? fallbackSelectedAgentIds,
  }) {
    final rawSourceAgentIds = failure.context[_sourceAgentIdsContextField];
    if (rawSourceAgentIds is Iterable<Object?>) {
      final ids =
          rawSourceAgentIds
              .map((id) => id?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(growable: false)
            ..sort();
      return ids;
    }
    return _normalizeSelectedAgentIds(fallbackSelectedAgentIds);
  }

  AppFailure _mapOverviewFailure(
    AppFailure failure, {
    required String userId,
  }) {
    if (failure is ValidationFailure &&
        failure.context['reason'] == 'no_approved_agents') {
      return ValidationFailure(
        message: 'No approved agents available for overview',
        userMessage: failure.userMessage,
        cause: failure.cause ?? failure,
        stackTrace: failure.stackTrace,
        context: <String, Object?>{
          ...failure.context,
          'operation': 'loadOverview',
          'userId': userId,
          OverviewFailureUiKey.field: OverviewFailureUiKey.noApprovedAgents,
        },
      );
    }

    return failure;
  }

  Future<AppResult<Overview>> _recoverOrFail({
    required AppFailure failure,
    required String userId,
    required OverviewLoadPolicy policy,
    required _OverviewPeriod period,
    required List<String>? sourceAgentIds,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final cachedOverview = await _readCachedOverviewIfAllowed(
      userId: userId,
      policy: policy,
      failure: failure,
      period: period,
      expectedSortedAgentIds: sourceAgentIds,
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace ?? StackTrace.current,
    );
    if (cachedOverview != null) {
      return Success<Overview, AppFailure>(
        cachedOverview.toEntity(isStaleCache: true),
      );
    }

    _logTerminalFailure(
      failure: failure,
      userId: userId,
      policy: policy,
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace,
    );
    return Failure<Overview, AppFailure>(failure);
  }

  void _logTerminalFailure({
    required AppFailure failure,
    required String userId,
    required OverviewLoadPolicy policy,
    required Object error,
    required StackTrace? stackTrace,
  }) {
    final context = <String, Object?>{
      'operation': 'loadOverview',
      'userId': userId,
      'policy': policy.name,
      'failureType': failure.runtimeType.toString(),
    };

    if (_isNoApprovedAgentsFailure(failure)) {
      AppLogger.info(
        'Overview unavailable: no approved agents',
        context: context,
      );
      return;
    }

    if (failure is ValidationFailure ||
        failure is SessionFailure ||
        failure is AuthorizationFailure) {
      AppLogger.warning(
        'Unable to load overview',
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    AppLogger.error(
      'Unable to load overview',
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<OverviewModel?> _readCachedOverviewIfAllowed({
    required String userId,
    required OverviewLoadPolicy policy,
    required AppFailure failure,
    required _OverviewPeriod period,
    required List<String>? expectedSortedAgentIds,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    if (!_shouldFallbackToCache(policy: policy, failure: failure)) {
      return null;
    }

    final cachedOverview = await _localDataSource.readOverview(userId: userId);
    if (cachedOverview == null) {
      return null;
    }

    if (!_isCacheAcceptable(
      cached: cachedOverview,
      period: period,
      expectedSortedAgentIds: expectedSortedAgentIds,
    )) {
      return null;
    }

    final warningContext = <String, Object?>{
      'operation': 'loadOverview',
      'userId': userId,
      'policy': policy.name,
      'failureType': failure.runtimeType.toString(),
    };
    if (cachedOverview.sourceAgentIds == null) {
      warningContext['legacyCacheMissingAgentSignature'] = true;
    }

    AppLogger.warning(
      'Overview fallback to cached data',
      context: warningContext,
      error: error,
      stackTrace: stackTrace,
    );
    return cachedOverview;
  }

  Future<Overview?> _readCachedOverviewForMissingClientTokens({
    required String userId,
    required OverviewLoadPolicy policy,
    required _OverviewPeriod period,
    required List<String> expectedSortedAgentIds,
    required List<String> agentIdsMissingClientToken,
    required List<String> agentNamesMissingClientToken,
  }) async {
    final cachedOverview = await _localDataSource.readOverview(userId: userId);
    if (cachedOverview == null) {
      return null;
    }

    if (!_isCacheAcceptable(
      cached: cachedOverview,
      period: period,
      expectedSortedAgentIds: expectedSortedAgentIds,
    )) {
      return null;
    }

    AppLogger.warning(
      policy == OverviewLoadPolicy.forceRefresh
          ? 'Overview fallback to cached data (missing local client_token; '
                'force refresh cannot run queries)'
          : 'Overview fallback to cached data (missing local client token)',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'policy': policy.name,
        'missingTokenCount': agentIdsMissingClientToken.length,
        'missingTokenAgentIds': agentIdsMissingClientToken.join(', '),
      },
    );

    return cachedOverview
        .toEntity(isStaleCache: true)
        .copyWith(
          approvedAgentCount: expectedSortedAgentIds.length,
          agentIdsMissingClientToken: agentIdsMissingClientToken,
          agentNamesMissingClientToken: agentNamesMissingClientToken,
        );
  }

  bool _isCacheAcceptable({
    required OverviewModel cached,
    required _OverviewPeriod period,
    required List<String>? expectedSortedAgentIds,
  }) {
    if (!_sameCalendarDay(cached.periodStart, period.start) ||
        !_sameCalendarDay(cached.periodEnd, period.end)) {
      return false;
    }

    if (cached.cachedAt != null) {
      final age = _now().difference(cached.cachedAt!);
      if (age > _overviewCacheMaxAge) {
        return false;
      }
    }

    if (expectedSortedAgentIds != null) {
      if (cached.sourceAgentIds == null) {
        return false;
      }
      final actual = List<String>.from(cached.sourceAgentIds!)..sort();
      final expected = List<String>.from(expectedSortedAgentIds)..sort();
      if (!_listEquals(expected, actual)) {
        return false;
      }
    }

    return true;
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _shouldFallbackToCache({
    required OverviewLoadPolicy policy,
    required AppFailure failure,
  }) {
    if (policy == OverviewLoadPolicy.forceRefresh) {
      return false;
    }
    if (failure is ValidationFailure ||
        failure is SessionFailure ||
        failure is AuthorizationFailure) {
      return false;
    }
    if (failure case RpcFailure(:final retryable)) {
      return retryable;
    }
    return failure.isTransient || failure is UnknownFailure;
  }

  bool _isNoApprovedAgentsFailure(AppFailure failure) {
    return failure is ValidationFailure &&
        failure.context[OverviewFailureUiKey.field] ==
            OverviewFailureUiKey.noApprovedAgents;
  }

  _OverviewPeriod _buildPeriod(OverviewFilter filter) {
    final rr = filter.referenceRange;
    if (rr != null) {
      final start = DateTime(
        rr.startInclusive.year,
        rr.startInclusive.month,
        rr.startInclusive.day,
      );
      final end = DateTime(
        rr.endInclusive.year,
        rr.endInclusive.month,
        rr.endInclusive.day,
        23,
        59,
        59,
        999,
      );
      return _OverviewPeriod(start: start, end: end);
    }

    final yearMonth = filter.yearMonth;
    final DateTime start;
    final DateTime end;

    if (yearMonth != null) {
      start = yearMonth.start;
      end = yearMonth.end;
    } else {
      final now = _now();
      end = DateTime(now.year, now.month, now.day);
      start = end.subtract(const Duration(days: 29));
    }

    return _OverviewPeriod(start: start, end: end);
  }

  Overview _buildOverview(
    List<OverviewPaymentResumoRow> rows, {
    required Map<String, List<OverviewPaymentResumoRow>> rowsByAgentId,
    required Map<String, String> agentDisplayNamesById,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int approvedAgentCount,
    required OverviewLoadLabels rowLabels,
    List<String> agentIdsExcludedFromQueryFailure = const <String>[],
    List<String> agentNamesExcludedFromQueryFailure = const <String>[],
    List<String> agentIdsMissingClientToken = const <String>[],
    List<String> agentNamesMissingClientToken = const <String>[],
    List<String> agentIdsSkippedDueToHubPresence = const <String>[],
    List<String> agentNamesSkippedDueToHubPresence = const <String>[],
    List<OverviewMonthlyParcelPoint> monthlyParcelTrend =
        const <OverviewMonthlyParcelPoint>[],
    bool monthlyParcelTrendLoadFailed = false,
    String? monthlyParcelTrendLoadFailureMessage,
    List<OverviewWeekdaySalesTrendPoint> weekdaySalesTrend =
        const <OverviewWeekdaySalesTrendPoint>[],
    bool weekdaySalesTrendLoadFailed = false,
    String? weekdaySalesTrendLoadFailureMessage,
    List<OverviewWeekdayUserSalesTrendPoint> weekdayUserSalesTrend =
        const <OverviewWeekdayUserSalesTrendPoint>[],
    bool weekdayUserSalesTrendLoadFailed = false,
    String? weekdayUserSalesTrendLoadFailureMessage,
    bool mainResumoHadPlannedTargets = false,
  }) {
    final paymentBuckets = <String, _PaymentMethodAggregate>{};
    final userBuckets = <String, _UserAggregate>{};

    var totalSalesCount = 0;
    var totalAmount = 0.0;

    for (final row in rows) {
      totalSalesCount += row.qtdVendas;
      totalAmount += row.valorParcela;

      final paymentKey =
          '${row.codFormaPagamento.trim()}'
          '|${row.descricaoFormaPagamento.trim()}';
      paymentBuckets
          .putIfAbsent(
            paymentKey,
            () => _PaymentMethodAggregate(
              code: row.codFormaPagamento.trim(),
              label: _resolvePaymentMethodLabel(row, rowLabels),
            ),
          )
          .add(row.qtdVendas, row.valorParcela);

      final userKey = _normalizeUserKey(row.nomeUsuario, rowLabels);
      userBuckets
          .putIfAbsent(
            userKey,
            () => _UserAggregate(
              userName: _resolveUserName(row.nomeUsuario, rowLabels),
            ),
          )
          .add(row.qtdVendas, row.valorParcela);
    }

    final paymentMethods =
        paymentBuckets.values
            .map(
              (item) => OverviewPaymentMethodBreakdown(
                code: item.code,
                label: item.label,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
                averageTicket: item.averageTicket,
                sharePercent: totalAmount <= 0
                    ? 0
                    : item.totalAmount / totalAmount * 100,
              ),
            )
            .toList(growable: false)
          ..sort(_compareBreakdowns);

    final agentRankings =
        rowsByAgentId.entries
            .map((entry) {
              final agentId = entry.key;
              var sales = 0;
              var amount = 0.0;
              for (final row in entry.value) {
                sales += row.qtdVendas;
                amount += row.valorParcela;
              }
              return OverviewAgentRanking(
                agentId: agentId,
                displayName: agentDisplayNamesById[agentId] ?? agentId.trim(),
                totalSalesCount: sales,
                totalAmount: amount,
              );
            })
            .toList(growable: false)
          ..sort(_compareAgents);

    final userRankings =
        userBuckets.values
            .map(
              (item) => OverviewUserRanking(
                userName: item.userName,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
                averageTicket: item.averageTicket,
              ),
            )
            .toList(growable: false)
          ..sort(_compareUsers);

    return Overview(
      periodStart: periodStart,
      periodEnd: periodEnd,
      kpis: OverviewPaymentKpis(
        totalSalesCount: totalSalesCount,
        totalAmount: totalAmount,
        averageTicket: totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount,
        paymentMethodCount: paymentMethods.length,
      ),
      paymentMethods: paymentMethods,
      agentRankings: agentRankings,
      userRankings: userRankings,
      monthlyParcelTrend: monthlyParcelTrend,
      monthlyParcelTrendLoadFailed: monthlyParcelTrendLoadFailed,
      monthlyParcelTrendLoadFailureMessage:
          monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: weekdaySalesTrend,
      weekdaySalesTrendLoadFailed: weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailureMessage:
          weekdaySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend: weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed: weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailureMessage:
          weekdayUserSalesTrendLoadFailureMessage,
      approvedAgentCount: approvedAgentCount,
      agentIdsExcludedFromQueryFailure: agentIdsExcludedFromQueryFailure,
      agentNamesExcludedFromQueryFailure: agentNamesExcludedFromQueryFailure,
      agentIdsMissingClientToken: agentIdsMissingClientToken,
      agentNamesMissingClientToken: agentNamesMissingClientToken,
      agentIdsSkippedDueToHubPresence: agentIdsSkippedDueToHubPresence,
      agentNamesSkippedDueToHubPresence: agentNamesSkippedDueToHubPresence,
      mainResumoHadPlannedTargets: mainResumoHadPlannedTargets,
    );
  }

  String _resolvePaymentMethodLabel(
    OverviewPaymentResumoRow row,
    OverviewLoadLabels labels,
  ) {
    final description = row.descricaoFormaPagamento.trim();
    if (description.isNotEmpty) {
      return description;
    }
    final code = row.codFormaPagamento.trim();
    return code.isEmpty ? labels.unknownPaymentMethodLabel : code;
  }

  String _resolveUserName(String rawUserName, OverviewLoadLabels labels) {
    final normalized = rawUserName.trim();
    return normalized.isEmpty ? labels.unknownUserNameLabel : normalized;
  }

  String _normalizeUserKey(String rawUserName, OverviewLoadLabels labels) {
    final normalized = _resolveUserName(rawUserName, labels);
    return normalized.toLowerCase();
  }

  static int _compareBreakdowns(
    OverviewPaymentMethodBreakdown left,
    OverviewPaymentMethodBreakdown right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.label.compareTo(right.label);
  }

  static int _compareAgents(
    OverviewAgentRanking left,
    OverviewAgentRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.displayName.compareTo(right.displayName);
  }

  static int _compareUsers(
    OverviewUserRanking left,
    OverviewUserRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.userName.compareTo(right.userName);
  }
}

class _OverviewPeriod {
  const _OverviewPeriod({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

class _PaymentMethodAggregate {
  _PaymentMethodAggregate({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
  int totalSalesCount = 0;
  double totalAmount = 0;

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }
}

class _UserAggregate {
  _UserAggregate({required this.userName});

  final String userName;
  int totalSalesCount = 0;
  double totalAmount = 0;

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }
}
