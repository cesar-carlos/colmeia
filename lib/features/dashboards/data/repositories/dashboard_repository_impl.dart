import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository.dart';
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
    required ResumoParcelaProdutoVendidoFormaPagamentoRepository
    resumoRepository,
    DateTime Function()? now,
  }) : _localDataSource = localDataSource,
       _clientAgentsRepository = clientAgentsRepository,
       _resumoRepository = resumoRepository,
       _now = now ?? DateTime.now;

  final DashboardLocalDataSource _localDataSource;
  final ClientAgentsRepository _clientAgentsRepository;
  final ResumoParcelaProdutoVendidoFormaPagamentoRepository _resumoRepository;
  final DateTime Function() _now;
  static const PaginatedQuery _firstAgentQuery = PaginatedQuery(pageSize: 1);

  @override
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
  }) async {
    final period = _buildDefaultPeriod();
    try {
      final approvedAgentsResult =
          await _clientAgentsRepository.loadApprovedAgents(
        userId: userId,
        query: _firstAgentQuery,
      );
      final approvedAgents = approvedAgentsResult.getOrNull();
      if (approvedAgents == null) {
        final failure = approvedAgentsResult.exceptionOrNull()!;
        return _recoverOrFail(
          failure: failure,
          userId: userId,
          policy: policy,
        );
      }
      if (approvedAgents.items.isEmpty) {
        return Failure<DashboardOverview, AppFailure>(
          ValidationFailure(
            message: 'No approved agents available for dashboard overview',
            userMessage: 'Nenhum agente aprovado esta disponivel '
                'para carregar o dashboard.',
            context: <String, Object?>{
              'operation': 'loadDashboardOverview',
              'userId': userId,
            },
          ),
        );
      }

      final agentId = approvedAgents.items.first.agentId;
      final queryResult = await _resumoRepository.load(
        agentId: agentId,
        filter: period.filter,
      );
      final rows = queryResult.getOrNull();
      if (rows == null) {
        final failure = queryResult.exceptionOrNull()!;
        return _recoverOrFail(
          failure: failure,
          userId: userId,
          policy: policy,
          agentId: agentId,
        );
      }

      final overview = _buildOverview(
        rows,
        periodStart: period.start,
        periodEnd: period.end,
      );
      await _localDataSource.saveOverview(
        userId: userId,
        overview: DashboardOverviewModel.fromEntity(overview),
      );
      AppLogger.info(
        'Dashboard overview loaded from agent query',
        context: <String, Object?>{
          'operation': 'loadDashboardOverview',
          'userId': userId,
          'agentId': agentId,
          'periodStart': period.start.toIso8601String(),
          'periodEnd': period.end.toIso8601String(),
          'paymentMethods': overview.paymentMethods.length,
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
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AppResult<DashboardOverview>> _recoverOrFail({
    required AppFailure failure,
    required String userId,
    required DashboardLoadPolicy policy,
    String? agentId,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final cachedOverview = await _readCachedOverviewIfAllowed(
      userId: userId,
      policy: policy,
      failure: failure,
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace ?? StackTrace.current,
      agentId: agentId,
    );
    if (cachedOverview != null) {
      return Success<DashboardOverview, AppFailure>(cachedOverview.toEntity());
    }

    AppLogger.error(
      'Unable to load dashboard overview',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
        'userId': userId,
        'policy': policy.name,
        'agentId': ?agentId,
        'failureType': failure.runtimeType.toString(),
      },
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace,
    );
    return Failure<DashboardOverview, AppFailure>(failure);
  }

  Future<DashboardOverviewModel?> _readCachedOverviewIfAllowed({
    required String userId,
    required DashboardLoadPolicy policy,
    required AppFailure failure,
    required Object error,
    required StackTrace stackTrace,
    String? agentId,
  }) async {
    if (!_shouldFallbackToCache(policy: policy, failure: failure)) {
      return null;
    }

    final cachedOverview = await _localDataSource.readOverview(userId: userId);
    if (cachedOverview == null) {
      return null;
    }

    AppLogger.warning(
      'Dashboard overview fallback to cached data',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
        'userId': userId,
        'policy': policy.name,
        'agentId': ?agentId,
        'failureType': failure.runtimeType.toString(),
      },
      error: error,
      stackTrace: stackTrace,
    );
    return cachedOverview;
  }

  bool _shouldFallbackToCache({
    required DashboardLoadPolicy policy,
    required AppFailure failure,
  }) {
    if (policy == DashboardLoadPolicy.forceRefresh) {
      return false;
    }
    if (failure is ValidationFailure || failure is SessionFailure) {
      return false;
    }
    if (failure case RpcFailure(:final retryable)) {
      return retryable;
    }
    return failure.isTransient || failure is UnknownFailure;
  }

  _DashboardPeriod _buildDefaultPeriod() {
    final now = _now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 29));
    return _DashboardPeriod(
      start: start,
      end: end,
      filter: ResumoParcelaProdutoVendidoFormaPagamentoFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      ),
    );
  }

  DashboardOverview _buildOverview(
    List<ResumoParcelaProdutoVendidoFormaPagamentoRow> rows, {
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final paymentBuckets = <String, _PaymentMethodAggregate>{};
    final filialBuckets = <String, _FilialAggregate>{};
    final userBuckets = <String, _UserAggregate>{};

    var totalSalesCount = 0;
    var totalAmount = 0.0;

    for (final row in rows) {
      totalSalesCount += row.qtdVendas;
      totalAmount += row.valorParcela;

      final paymentKey = '${row.codFormaPagamento.trim()}'
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

    final paymentMethods = paymentBuckets.values
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

    final filialRankings = filialBuckets.values
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

    final userRankings = userBuckets.values
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
    );
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
