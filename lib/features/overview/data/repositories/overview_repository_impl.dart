import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/mappers/overview_agent_resumo_mapper.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:result_dart/result_dart.dart';

class OverviewRepositoryImpl implements OverviewRepository {
  OverviewRepositoryImpl({
    required OverviewLocalDataSource localDataSource,
    required ResumoParcelaFormaPagamentoAcrossAgentsRepository
    resumoAcrossAgentsRepository,
    DateTime Function()? now,
  }) : _localDataSource = localDataSource,
       _resumoAcrossAgentsRepository = resumoAcrossAgentsRepository,
       _now = now ?? DateTime.now;

  final OverviewLocalDataSource _localDataSource;
  final ResumoParcelaFormaPagamentoAcrossAgentsRepository
  _resumoAcrossAgentsRepository;
  final DateTime Function() _now;

  static const String _sourceAgentIdsContextField = 'sourceAgentIds';
  static const Duration _overviewCacheMaxAge = Duration(hours: 48);

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
  }) async {
    final period = _buildPeriod(filter);
    try {
      final reportResult = await _resumoAcrossAgentsRepository.load(
        userId: userId,
        filter: _resumoFilter(period),
        selectedAgentIds: filter.selectedAgentIds,
        strategy: _resolveExecutionStrategy(filter),
      );
      final report = reportResult.getOrNull();
      if (report == null) {
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
        return Success<Overview, AppFailure>(
          _buildOverview(
            const <OverviewPaymentResumoRow>[],
            rowsByAgentId: const <String, List<OverviewPaymentResumoRow>>{},
            agentDisplayNamesById: const <String, String>{},
            periodStart: period.start,
            periodEnd: period.end,
            approvedAgentCount: 0,
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
          return Success<Overview, AppFailure>(cachedOverview);
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

      final overview = _buildOverview(
        _mapOverviewRows(report.mergedRows),
        rowsByAgentId: _mapRowsByAgentId(report.rowsByAgentId),
        agentDisplayNamesById: _resolveAgentDisplayNames(report),
        periodStart: period.start,
        periodEnd: period.end,
        approvedAgentCount: report.consideredApprovedAgentCount,
        agentIdsExcludedFromQueryFailure: report.failedAgentIds,
        agentNamesExcludedFromQueryFailure: report.failedAgentNames,
        agentIdsMissingClientToken: report.missingClientTokenAgentIds,
        agentNamesMissingClientToken: report.missingClientTokenAgentNames,
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

  AgentQueryExecutionStrategy _resolveExecutionStrategy(
    OverviewFilter filter,
  ) {
    final selectedAgentIds = filter.selectedAgentIds;
    if (selectedAgentIds != null && selectedAgentIds.length == 1) {
      return AgentQueryExecutionStrategy.singleSource;
    }
    return AgentQueryExecutionStrategy.mergeAll;
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
    if (policy == OverviewLoadPolicy.forceRefresh) {
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

    AppLogger.warning(
      'Overview fallback to cached data (missing local client token)',
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
    List<String> agentIdsExcludedFromQueryFailure = const <String>[],
    List<String> agentNamesExcludedFromQueryFailure = const <String>[],
    List<String> agentIdsMissingClientToken = const <String>[],
    List<String> agentNamesMissingClientToken = const <String>[],
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
              label: _resolvePaymentMethodLabel(row),
            ),
          )
          .add(row.qtdVendas, row.valorParcela);

      final userKey = _normalizeUserKey(row.nomeUsuario);
      userBuckets
          .putIfAbsent(
            userKey,
            () => _UserAggregate(
              userName: _resolveUserName(row.nomeUsuario),
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
      approvedAgentCount: approvedAgentCount,
      agentIdsExcludedFromQueryFailure: agentIdsExcludedFromQueryFailure,
      agentNamesExcludedFromQueryFailure: agentNamesExcludedFromQueryFailure,
      agentIdsMissingClientToken: agentIdsMissingClientToken,
      agentNamesMissingClientToken: agentNamesMissingClientToken,
    );
  }

  String _resolvePaymentMethodLabel(OverviewPaymentResumoRow row) {
    final description = row.descricaoFormaPagamento.trim();
    if (description.isNotEmpty) {
      return description;
    }
    final code = row.codFormaPagamento.trim();
    return code.isEmpty ? 'Forma nao informada' : code;
  }

  String _resolveUserName(String rawUserName) {
    final normalized = rawUserName.trim();
    return normalized.isEmpty ? 'Usuario nao informado' : normalized;
  }

  String _normalizeUserKey(String rawUserName) {
    final normalized = _resolveUserName(rawUserName);
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
