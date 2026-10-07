import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

class SalesDailyTotalsController extends ChangeNotifier {
  SalesDailyTotalsController({
    required this._loadDailyTotals,
    required this._resolveClientToken,
    this._bindCancelScope,
  });

  final LoadSalesDailyTotalsUseCase _loadDailyTotals;
  final ResolveSalesAgentClientTokenUseCase _resolveClientToken;
  final AgentQueriesRelayCancelScopeBinder? _bindCancelScope;
  AgentQueriesCancelScope? _scope;
  int _generation = 0;
  bool _disposed = false;
  bool _loading = false;
  List<DailySalesTrendPoint> _points = const [];
  AppFailure? _failure;
  (String, String, String)? _cachedToken;

  bool get loading => _loading;
  List<DailySalesTrendPoint> get points => _points;
  AppFailure? get failure => _failure;

  Future<SalesDailyTotalsLoadResult?> load({
    required String userId,
    required String agentId,
    required DashboardYearMonth anchor,
    DashboardDateRange? dailySaleDateRange,
  }) async {
    if (_disposed) return null;
    final generation = ++_generation;
    _scope?.cancelAll();
    final scope = AgentQueriesCancelScope();
    _scope = scope;
    _bindCancelScope?.call(scope);
    final cancelled = Completer<SalesDailyTotalsLoadResult?>();
    final unregister = scope.registerLocalCancellation(() {
      if (!cancelled.isCompleted) cancelled.complete(null);
    });
    _loading = true;
    _points = const [];
    _failure = null;
    notifyListeners();
    try {
      if (scope.isCancelled || _disposed) return null;
      final result = await Future.any<SalesDailyTotalsLoadResult?>([
        _execute(
          userId: userId,
          agentId: agentId.trim(),
          anchor: anchor,
          dailySaleDateRange: dailySaleDateRange,
          scope: scope,
          generation: generation,
        ),
        cancelled.future,
      ]);
      if (_disposed || generation != _generation || scope.isCancelled) {
        return null;
      }
      if (result != null) {
        _points = List.unmodifiable(result.points);
        _failure = result.loadFailure;
      }
      return result;
    } finally {
      unregister();
      if (!_disposed && generation == _generation) {
        _scope = null;
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<SalesDailyTotalsLoadResult> _execute({
    required String userId,
    required String agentId,
    required DashboardYearMonth anchor,
    required DashboardDateRange? dailySaleDateRange,
    required AgentQueriesCancelScope scope,
    required int generation,
  }) async {
    try {
      final cached = _cachedToken;
      final token =
          cached != null && cached.$1 == userId && cached.$2 == agentId
          ? cached.$3
          : await _resolveClientToken(userId: userId, agentId: agentId);
      if (scope.isCancelled || _disposed || generation != _generation) {
        return _failed(const OperationCancelledFailure());
      }
      if (token == null) {
        return _failed(
          const SessionFailure(
            message: 'Agent client token unavailable.',
            context: {
              AgentSqlRpcFailureUiKey.field:
                  AgentSqlRpcFailureUiKey.authenticationFailed,
            },
          ),
        );
      }
      _cachedToken = (userId, agentId, token);
      return await _loadDailyTotals(
        userId: userId,
        agentId: agentId,
        anchor: anchor,
        dailySaleDateRange: dailySaleDateRange,
        clientToken: token,
        cancelScope: scope,
      );
    } on Object catch (error, stackTrace) {
      return _failed(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          context: const {'operation': 'loadSalesDailyTotals'},
        ),
      );
    }
  }

  static SalesDailyTotalsLoadResult _failed(AppFailure failure) => (
    points: const <DailySalesTrendPoint>[],
    loadFailed: true,
    loadFailure: failure,
  );

  void cancel() {
    if (_disposed) return;
    ++_generation;
    _scope?.cancelAll();
    _scope = null;
    _loading = false;
    _points = const [];
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _scope?.cancelAll();
    _scope = null;
    _cachedToken = null;
    super.dispose();
  }
}
