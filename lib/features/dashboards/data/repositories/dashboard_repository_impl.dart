import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_produto_vendido_forma_pagamento_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_filial_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:result_dart/result_dart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardLocalDataSource localDataSource,
    required ClientAgentsRepository clientAgentsRepository,
    required LocalAgentClientTokenStore clientTokenStore,
    required LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase loadResumo,
    DateTime Function()? now,
  }) : _localDataSource = localDataSource,
       _clientAgentsRepository = clientAgentsRepository,
       _clientTokenStore = clientTokenStore,
       _loadResumo = loadResumo,
       _now = now ?? DateTime.now;

  final DashboardLocalDataSource _localDataSource;
  final ClientAgentsRepository _clientAgentsRepository;
  final LocalAgentClientTokenStore _clientTokenStore;
  final LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase _loadResumo;
  final DateTime Function() _now;

  static const int _approvedAgentsPageSize = 50;
  static const int _maxApprovedAgentsPaginationPages = 400;
  static const int _resumoLoadConcurrency = 4;
  static const String _paginationSignatureSeparator = '\u001f';
  static const Duration _dashboardCacheMaxAge = Duration(hours: 48);

  @override
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
  }) async {
    final period = _buildPeriod(filter);
    try {
      final approvedAgentsResult = await _loadAllApprovedAgents(userId: userId);
      final approvedAgents = approvedAgentsResult.getOrNull();
      if (approvedAgents == null) {
        final failure = approvedAgentsResult.exceptionOrNull()!;
        return _recoverOrFail(
          failure: failure,
          userId: userId,
          policy: policy,
          period: period,
          sourceAgentIds: null,
        );
      }
      if (approvedAgents.isEmpty) {
        return Failure<DashboardOverview, AppFailure>(
          ValidationFailure(
            message: 'No approved agents available for dashboard overview',
            userMessage:
                'Nenhum agente aprovado esta disponivel '
                'para carregar o dashboard.',
            context: <String, Object?>{
              'operation': 'loadDashboardOverview',
              'userId': userId,
            },
          ),
        );
      }

      // When a specific agent is selected, restrict to that agent only.
      final filteredAgents = filter.selectedAgentId == null
          ? approvedAgents
          : approvedAgents
                .where((a) => a.agentId == filter.selectedAgentId)
                .toList(growable: false);

      final effectiveAgents = filteredAgents.isEmpty
          ? approvedAgents
          : filteredAgents;

      final sortedApprovedAgents = effectiveAgents.toList(growable: false)
        ..sort((left, right) => left.agentId.compareTo(right.agentId));
      final sortedAgentIds = sortedApprovedAgents
          .map((a) => a.agentId)
          .toList(growable: false);
      final approvedAgentsById = <String, ClientAgent>{
        for (final agent in sortedApprovedAgents) agent.agentId: agent,
      };

      final resumoBatch = await _loadResumoQueryResults(
        userId: userId,
        sortedAgentIds: sortedAgentIds,
        filter: period.filter,
      );
      final queryResults = resumoBatch.results;
      final agentIdsMissingClientToken = resumoBatch.agentIdsMissingClientToken;
      final agentNamesMissingClientToken = _resolveAgentNames(
        agentIdsMissingClientToken,
        approvedAgentsById: approvedAgentsById,
      );

      if (agentIdsMissingClientToken.isNotEmpty) {
        AppLogger.warning(
          'Dashboard overview: agents skipped (no local client_token)',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'missingTokenCount': agentIdsMissingClientToken.length,
            'missingTokenAgentIds': agentIdsMissingClientToken.join(', '),
          },
        );
      }

      final rows = <ResumoParcelaProdutoVendidoFormaPagamentoRow>[];
      final failedQueryAgentIds = <String>[];
      var hasAnySuccess = false;
      AppFailure? firstFailure;
      String? firstFailedAgentId;
      final missingTokenSet = agentIdsMissingClientToken.toSet();

      for (var i = 0; i < queryResults.length; i++) {
        final queryResult = queryResults[i];
        final agentId = sortedAgentIds[i];
        final batch = queryResult.getOrNull();
        if (batch != null) {
          hasAnySuccess = true;
          rows.addAll(batch);
          continue;
        }
        final failure = queryResult.exceptionOrNull()!;
        if (missingTokenSet.contains(agentId)) {
          firstFailure ??= failure;
          firstFailedAgentId ??= agentId;
          continue;
        }
        failedQueryAgentIds.add(agentId);
        firstFailure ??= failure;
        firstFailedAgentId ??= agentId;
      }

      final failedQueryAgentNames = _resolveAgentNames(
        failedQueryAgentIds,
        approvedAgentsById: approvedAgentsById,
      );

      if (!hasAnySuccess &&
          failedQueryAgentIds.isEmpty &&
          agentIdsMissingClientToken.isNotEmpty) {
        final cachedOverview = await _readCachedOverviewForMissingClientTokens(
          userId: userId,
          policy: policy,
          period: period,
          expectedSortedAgentIds: sortedAgentIds,
          agentIdsMissingClientToken: agentIdsMissingClientToken,
          agentNamesMissingClientToken: agentNamesMissingClientToken,
        );
        if (cachedOverview != null) {
          return Success<DashboardOverview, AppFailure>(cachedOverview);
        }

        return Success<DashboardOverview, AppFailure>(
          _buildOverview(
            const <ResumoParcelaProdutoVendidoFormaPagamentoRow>[],
            periodStart: period.start,
            periodEnd: period.end,
            approvedAgentCount: sortedAgentIds.length,
            agentIdsMissingClientToken: agentIdsMissingClientToken,
            agentNamesMissingClientToken: agentNamesMissingClientToken,
          ),
        );
      }

      if (!hasAnySuccess && firstFailure != null) {
        return _recoverOrFail(
          failure: firstFailure,
          userId: userId,
          policy: policy,
          period: period,
          sourceAgentIds: sortedAgentIds,
          failedAgentId: firstFailedAgentId,
        );
      }

      if (failedQueryAgentIds.isNotEmpty) {
        AppLogger.warning(
          'Dashboard overview: partial agent resumo results',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'failedAgentCount': failedQueryAgentIds.length,
            'failedAgentIds': failedQueryAgentIds.join(', '),
          },
        );
      }

      final overview = _buildOverview(
        rows,
        periodStart: period.start,
        periodEnd: period.end,
        approvedAgentCount: sortedAgentIds.length,
        agentIdsExcludedFromQueryFailure: failedQueryAgentIds,
        agentNamesExcludedFromQueryFailure: failedQueryAgentNames,
        agentIdsMissingClientToken: agentIdsMissingClientToken,
        agentNamesMissingClientToken: agentNamesMissingClientToken,
      );

      final stamp = _now();
      final model = DashboardOverviewModel.fromEntity(
        overview,
        cachedAt: stamp,
        sourceAgentIds: sortedAgentIds,
      );

      try {
        await _localDataSource.saveOverview(
          userId: userId,
          overview: model,
        );
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Dashboard overview cache save failed; returning computed overview',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
          },
          error: error,
          stackTrace: stackTrace,
        );
      }

      AppLogger.info(
        'Dashboard overview loaded from agent query',
        context: <String, Object?>{
          'operation': 'loadDashboardOverview',
          'userId': userId,
          'agentCount': sortedAgentIds.length,
          'periodStart': period.start.toIso8601String(),
          'periodEnd': period.end.toIso8601String(),
          'paymentMethods': overview.paymentMethods.length,
          'partialQueryFailures':
              overview.agentIdsExcludedFromQueryFailure.length,
          'agentsMissingClientToken':
              overview.agentIdsMissingClientToken.length,
        },
      );

      return Success<DashboardOverview, AppFailure>(overview);
    } on Object catch (error, stackTrace) {
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to load dashboard overview',
        fallbackUserMessage: 'Nao foi possivel carregar o dashboard.',
        context: <String, Object?>{
          'operation': 'loadDashboardOverview',
          'userId': userId,
          'policy': policy.name,
        },
      );
      return _recoverOrFail(
        failure: failure,
        userId: userId,
        policy: policy,
        period: period,
        sourceAgentIds: null,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Loads resumo rows per agent with bounded parallelism to avoid spiking the
  /// SQL bridge when many agents are approved.
  ///
  /// Agents without a locally stored client token do not call the bridge; they
  /// surface as `ValidationFailure` results and are listed in the returned
  /// missing-token id list.
  Future<
    ({
      List<AppResult<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>>>
      results,
      List<String> agentIdsMissingClientToken,
    })
  >
  _loadResumoQueryResults({
    required String userId,
    required List<String> sortedAgentIds,
    required ResumoParcelaProdutoVendidoFormaPagamentoFilter filter,
  }) async {
    // Keys are trimmed agent ids (same ids as sortedAgentIds); see
    // LocalAgentClientTokenStore.readMany.
    final tokensByAgentId = await _clientTokenStore.readMany(
      userId: userId,
      agentIds: sortedAgentIds,
    );

    final missingTokenIds = <String>[];
    final slot =
        List<
          AppResult<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>>?
        >.filled(
          sortedAgentIds.length,
          null,
        );

    final indicesWithToken = <int>[];
    for (var i = 0; i < sortedAgentIds.length; i++) {
      final id = sortedAgentIds[i];
      final token = tokensByAgentId[id];
      if (token == null || token.isEmpty) {
        missingTokenIds.add(id);
        slot[i] = _missingLocalClientTokenFailure(agentId: id);
      } else {
        indicesWithToken.add(i);
      }
    }

    const concurrency = _resumoLoadConcurrency;
    for (var start = 0; start < indicesWithToken.length; start += concurrency) {
      final end = start + concurrency > indicesWithToken.length
          ? indicesWithToken.length
          : start + concurrency;
      final chunkIndices = indicesWithToken.sublist(start, end);
      final chunkResults = await Future.wait(
        chunkIndices.map((i) {
          final id = sortedAgentIds[i];
          return _loadResumo(
            agentId: id,
            filter: filter,
            clientToken: tokensByAgentId[id],
          );
        }),
      );
      for (var j = 0; j < chunkIndices.length; j++) {
        slot[chunkIndices[j]] = chunkResults[j];
      }
    }

    return (
      results:
          List<
            AppResult<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>>
          >.from(
            slot.map(
              (r) => r!,
            ),
          ),
      agentIdsMissingClientToken: missingTokenIds,
    );
  }

  AppResult<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>>
  _missingLocalClientTokenFailure({required String agentId}) {
    return Failure<
      List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
      AppFailure
    >(
      ValidationFailure(
        message: 'Missing local client token for agent $agentId',
        userMessage:
            'Cadastre o token do cliente para este agente para consultar '
            'dados.',
        context: <String, Object?>{
          'operation': 'loadDashboardResumo',
          'agentId': agentId,
          'reason': 'missing_local_client_token',
        },
      ),
    );
  }

  Future<AppResult<List<ClientAgent>>> _loadAllApprovedAgents({
    required String userId,
  }) async {
    final agents = <ClientAgent>[];
    var page = 1;
    String? previousPageSignature;
    while (true) {
      if (page > _maxApprovedAgentsPaginationPages) {
        AppLogger.warning(
          'Approved agents pagination stopped at safety page limit',
          context: <String, Object?>{
            'operation': 'loadDashboardApprovedAgents',
            'userId': userId,
            'maxPages': _maxApprovedAgentsPaginationPages,
            'loadedCount': agents.length,
          },
        );
        break;
      }
      final query = PaginatedQuery(
        page: page,
        pageSize: _approvedAgentsPageSize,
      );
      final result = await _clientAgentsRepository.loadApprovedAgents(
        userId: userId,
        query: query,
        includeOnlineStatus: false,
      );
      final batch = result.getOrNull();
      if (batch == null) {
        final failure = result.exceptionOrNull()!;
        return Failure<List<ClientAgent>, AppFailure>(failure);
      }
      if (batch.items.isEmpty) {
        break;
      }

      final pageItemsSignature = batch.items
          .map((a) => a.agentId)
          .join(_paginationSignatureSeparator);
      final pageSignature =
          '${batch.page}$_paginationSignatureSeparator$pageItemsSignature';
      if (pageSignature == previousPageSignature) {
        AppLogger.warning(
          'Approved agents pagination: duplicate page payload; stopping',
          context: <String, Object?>{
            'operation': 'loadDashboardApprovedAgents',
            'userId': userId,
            'page': batch.page,
          },
        );
        break;
      }
      previousPageSignature = pageSignature;

      agents.addAll(batch.items);

      final loadedAllKnownTotal =
          batch.total > 0 && agents.length >= batch.total;
      final lastPage = batch.items.length < query.pageSize;
      if (loadedAllKnownTotal || lastPage) {
        break;
      }
      page++;
    }
    return Success<List<ClientAgent>, AppFailure>(agents);
  }

  Future<AppResult<DashboardOverview>> _recoverOrFail({
    required AppFailure failure,
    required String userId,
    required DashboardLoadPolicy policy,
    required _DashboardPeriod period,
    required List<String>? sourceAgentIds,
    String? failedAgentId,
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
      failedAgentId: failedAgentId,
    );
    if (cachedOverview != null) {
      return Success<DashboardOverview, AppFailure>(
        cachedOverview.toEntity(isStaleCache: true),
      );
    }

    final logContext = <String, Object?>{
      'operation': 'loadDashboardOverview',
      'userId': userId,
      'policy': policy.name,
      'failureType': failure.runtimeType.toString(),
    };
    if (failedAgentId != null) {
      logContext['agentId'] = failedAgentId;
    }

    AppLogger.error(
      'Unable to load dashboard overview',
      context: logContext,
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace,
    );
    return Failure<DashboardOverview, AppFailure>(failure);
  }

  Future<DashboardOverviewModel?> _readCachedOverviewIfAllowed({
    required String userId,
    required DashboardLoadPolicy policy,
    required AppFailure failure,
    required _DashboardPeriod period,
    required List<String>? expectedSortedAgentIds,
    required Object error,
    required StackTrace stackTrace,
    String? failedAgentId,
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
      'operation': 'loadDashboardOverview',
      'userId': userId,
      'policy': policy.name,
      'failureType': failure.runtimeType.toString(),
    };
    if (failedAgentId != null) {
      warningContext['agentId'] = failedAgentId;
    }
    if (cachedOverview.sourceAgentIds == null) {
      warningContext['legacyCacheMissingAgentSignature'] = true;
    }

    AppLogger.warning(
      'Dashboard overview fallback to cached data',
      context: warningContext,
      error: error,
      stackTrace: stackTrace,
    );
    return cachedOverview;
  }

  Future<DashboardOverview?> _readCachedOverviewForMissingClientTokens({
    required String userId,
    required DashboardLoadPolicy policy,
    required _DashboardPeriod period,
    required List<String> expectedSortedAgentIds,
    required List<String> agentIdsMissingClientToken,
    required List<String> agentNamesMissingClientToken,
  }) async {
    if (policy == DashboardLoadPolicy.forceRefresh) {
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
      'Dashboard overview fallback to cached data (missing local client token)',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
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
    required DashboardOverviewModel cached,
    required _DashboardPeriod period,
    required List<String>? expectedSortedAgentIds,
  }) {
    if (!_sameCalendarDay(cached.periodStart, period.start) ||
        !_sameCalendarDay(cached.periodEnd, period.end)) {
      return false;
    }

    if (cached.cachedAt != null) {
      final age = _now().difference(cached.cachedAt!);
      if (age > _dashboardCacheMaxAge) {
        return false;
      }
    }

    if (expectedSortedAgentIds != null) {
      if (cached.sourceAgentIds == null) {
        return false;
      }
      final a = List<String>.from(expectedSortedAgentIds)..sort();
      final b = List<String>.from(cached.sourceAgentIds!)..sort();
      if (!_listEquals(a, b)) {
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
    required DashboardLoadPolicy policy,
    required AppFailure failure,
  }) {
    if (policy == DashboardLoadPolicy.forceRefresh) {
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

  _DashboardPeriod _buildPeriod(DashboardFilter filter) {
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

    return _DashboardPeriod(
      start: start,
      end: end,
      filter: ResumoParcelaProdutoVendidoFormaPagamentoFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      ),
    );
  }

  /// Aggregates SQL rows across agents by summing measures into shared buckets.
  ///
  /// If two agents expose overlapping business data for the same sale,
  /// totals may be double-counted; the backend is expected to partition
  /// work per agent.
  DashboardOverview _buildOverview(
    List<ResumoParcelaProdutoVendidoFormaPagamentoRow> rows, {
    required DateTime periodStart,
    required DateTime periodEnd,
    required int approvedAgentCount,
    List<String> agentIdsExcludedFromQueryFailure = const <String>[],
    List<String> agentNamesExcludedFromQueryFailure = const <String>[],
    List<String> agentIdsMissingClientToken = const <String>[],
    List<String> agentNamesMissingClientToken = const <String>[],
  }) {
    final paymentBuckets = <String, _PaymentMethodAggregate>{};
    final filialBuckets = <String, _FilialAggregate>{};
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

      final filialKey = '${row.codEmpresa}|${row.codFilial}';
      filialBuckets
          .putIfAbsent(
            filialKey,
            () => _FilialAggregate(
              codEmpresa: row.codEmpresa,
              codFilial: row.codFilial,
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
              (item) => DashboardPaymentMethodBreakdown(
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

    final filialRankings =
        filialBuckets.values
            .map(
              (item) => DashboardFilialRanking(
                codEmpresa: item.codEmpresa,
                codFilial: item.codFilial,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
              ),
            )
            .toList(growable: false)
          ..sort(_compareFiliais);

    final userRankings =
        userBuckets.values
            .map(
              (item) => DashboardUserRanking(
                userName: item.userName,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
                averageTicket: item.averageTicket,
              ),
            )
            .toList(growable: false)
          ..sort(_compareUsers);

    return DashboardOverview(
      periodStart: periodStart,
      periodEnd: periodEnd,
      kpis: DashboardPaymentKpis(
        totalSalesCount: totalSalesCount,
        totalAmount: totalAmount,
        averageTicket: totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount,
        paymentMethodCount: paymentMethods.length,
      ),
      paymentMethods: paymentMethods,
      filialRankings: filialRankings,
      userRankings: userRankings,
      approvedAgentCount: approvedAgentCount,
      agentIdsExcludedFromQueryFailure: agentIdsExcludedFromQueryFailure,
      agentNamesExcludedFromQueryFailure: agentNamesExcludedFromQueryFailure,
      agentIdsMissingClientToken: agentIdsMissingClientToken,
      agentNamesMissingClientToken: agentNamesMissingClientToken,
    );
  }

  List<String> _resolveAgentNames(
    Iterable<String> agentIds, {
    required Map<String, ClientAgent> approvedAgentsById,
  }) {
    return agentIds
        .map(
          (agentId) =>
              _resolveAgentDisplayName(approvedAgentsById[agentId], agentId),
        )
        .toList(growable: false);
  }

  String _resolveAgentDisplayName(ClientAgent? agent, String fallbackAgentId) {
    final tradeName = agent?.tradeName?.trim();
    if (tradeName != null && tradeName.isNotEmpty) {
      return tradeName;
    }

    final name = agent?.name.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    return fallbackAgentId.trim();
  }

  String _resolvePaymentMethodLabel(
    ResumoParcelaProdutoVendidoFormaPagamentoRow row,
  ) {
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
    DashboardPaymentMethodBreakdown left,
    DashboardPaymentMethodBreakdown right,
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

  static int _compareFiliais(
    DashboardFilialRanking left,
    DashboardFilialRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    final empresa = left.codEmpresa.compareTo(right.codEmpresa);
    if (empresa != 0) {
      return empresa;
    }
    return left.codFilial.compareTo(right.codFilial);
  }

  static int _compareUsers(
    DashboardUserRanking left,
    DashboardUserRanking right,
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

class _DashboardPeriod {
  const _DashboardPeriod({
    required this.start,
    required this.end,
    required this.filter,
  });

  final DateTime start;
  final DateTime end;
  final ResumoParcelaProdutoVendidoFormaPagamentoFilter filter;
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

class _FilialAggregate {
  _FilialAggregate({
    required this.codEmpresa,
    required this.codFilial,
  });

  final int codEmpresa;
  final int codFilial;
  int totalSalesCount = 0;
  double totalAmount = 0;

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
