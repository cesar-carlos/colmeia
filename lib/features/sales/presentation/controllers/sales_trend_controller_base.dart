import 'dart:async';

import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart'
    show AgentQueriesCancelScope, AgentQueriesRelayCancelScopeBinder;
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_trend_reload_outcome.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/material.dart';

/// Shared SQL-load infrastructure for product trend controllers.
abstract class SalesTrendControllerBase extends ChangeNotifier {
  SalesTrendControllerBase({
    required SalesSessionService sessionService,
    required LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase,
    required ResolveSalesAgentClientTokenUseCase
    resolveSalesAgentClientTokenUseCase,
    AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder,
  }) : _sessionService = sessionService,
       _loadAgentsUseCase = loadSalesAvailableAgentsUseCase,
       _resolveClientTokenUseCase = resolveSalesAgentClientTokenUseCase,
       _relayCancelScopeBinder = relayCancelScopeBinder;

  static const List<int> pageSizeOptions = <int>[10, 20, 50, 100];

  final SalesSessionService _sessionService;
  final LoadAvailableAgentsForSales _loadAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  String? _boundUserId;
  String? selectedAgentId;
  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;
  bool _disposed = false;

  String? get boundUserId => _boundUserId;

  AgentQueriesCancelScope? get sqlCancelScope => _sqlCancelScope;

  int get sqlLoadGeneration => _sqlLoadGeneration;

  bool get isDisposed => _disposed;

  void applyAvailableAgents({
    required List<DashboardAgentOption> agents,
    required String? selectedAgentId,
  });

  Future<SalesTrendReloadOutcome> performFullReload();

  Future<SalesTrendReloadOutcome> performDetailsOnlyReload();

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }
    _boundUserId = userId;
    if (userId == null) {
      return;
    }
    await _loadAgents(userId);
  }

  @override
  void dispose() {
    _disposed = true;
    _sqlCancelScope?.cancelAll();
    super.dispose();
  }

  Future<String?> resolveClientToken({
    required String userId,
    required String agentId,
  }) async {
    if (_cachedClientTokenUserId == userId &&
        _cachedClientTokenAgentId == agentId) {
      return _cachedClientToken;
    }
    final resolved = await _resolveClientTokenUseCase(
      userId: userId,
      agentId: agentId,
    );
    if (resolved != null) {
      _cachedClientTokenUserId = userId;
      _cachedClientTokenAgentId = agentId;
      _cachedClientToken = resolved;
    }
    return resolved;
  }

  Future<String?> resolveClientTokenForSelectedAgent() async {
    final userId = _boundUserId;
    final agentId = trendSelectedAgentId?.trim();
    if (userId == null || agentId == null || agentId.isEmpty) {
      return null;
    }
    return resolveClientToken(userId: userId, agentId: agentId);
  }

  ({int generation, AgentQueriesCancelScope scope}) beginSqlLoad() {
    final generation = ++_sqlLoadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    _relayCancelScopeBinder?.call(sqlScope);
    return (generation: generation, scope: sqlScope);
  }

  bool isSuperseded(int generation) =>
      _disposed || generation != _sqlLoadGeneration;

  String? get trendSelectedAgentId;

  Future<void> _loadAgents(String userId) async {
    final agents = await _loadAgentsUseCase(userId);
    if (_isStaleBoundUser(userId)) {
      return;
    }

    final nextSelection = reconcileSelectedSalesAgentId(
      agents: agents,
      previousSelectedId: selectedAgentId,
    );
    selectedAgentId = nextSelection;
    applyAvailableAgents(agents: agents, selectedAgentId: nextSelection);
    if (nextSelection != _sessionService.selectedAgentId) {
      unawaited(_sessionService.setSelectedAgentId(nextSelection));
    }
    if (_isStaleBoundUser(userId)) {
      return;
    }
    await performFullReload();
  }

  bool _isStaleBoundUser(String userId) {
    return _disposed || _boundUserId != userId;
  }

  static int? restorePositiveInt(Object? raw) {
    if (raw is int) {
      return raw > 0 ? raw : null;
    }
    final value = int.tryParse('$raw');
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  static DateTimeRange? restoreDateRange(
    Map<String, Object?> source, {
    required String startKey,
    required String endKey,
  }) {
    final start = source[startKey];
    final end = source[endKey];
    if (start is! int || end is! int) {
      return null;
    }
    final range = DateTimeRange(
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
    );
    return range.end.isBefore(range.start) ? null : range;
  }
}
