import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_query_failure_classification.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_itens_repository.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:flutter/foundation.dart';

/// Presentation state for one entrada note's line items.
class SalesNotasEntradaItensController extends ChangeNotifier {
  SalesNotasEntradaItensController({
    required this._sessionService,
    required ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientToken,
    required this._repository,
    required this.compraId,
    this.note,
    String? initialAgentId,
    this._relayCancelScopeBinder,
  }) : _resolveClientToken = resolveSalesAgentClientToken {
    final extraAgentId = initialAgentId?.trim();
    _selectedAgentId = extraAgentId == null || extraAgentId.isEmpty
        ? _sessionService.selectedAgentId
        : extraAgentId;
  }

  final SalesSessionService _sessionService;
  final ResolveSalesAgentClientTokenUseCase _resolveClientToken;
  final NotasEntradaItensRepository _repository;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  final int compraId;
  final NotaEntradaRow? note;

  /// Header and line totals within one cent are treated as the same amount.
  static const double _noteTotalTolerance = 0.01;

  String? _boundUserId;
  String? _selectedAgentId;
  NotasEntradaItensResult? _result;
  AppFailure? _loadFailure;
  bool _isLoading = false;
  bool _missingClientToken = false;
  int _loadGeneration = 0;
  AgentQueriesCancelScope? _cancelScope;
  bool _disposed = false;

  String? get selectedAgentId => _selectedAgentId;
  List<NotaEntradaItemRow> get rows =>
      _result?.items ?? const <NotaEntradaItemRow>[];
  AppFailure? get loadFailure => _loadFailure;
  bool get isLoading => _isLoading;
  bool get missingClientToken => _missingClientToken;
  bool get isTruncated => _result?.isTruncated ?? false;
  bool get isCancelled => _result?.isCancelled ?? false;
  bool get hasValidCompraId => compraId > 0;
  double get totalValorItens => _result?.totalValorItens ?? 0;

  /// `max_rows` of the loaded query when the bridge capped the result.
  int? get truncationLimit {
    final result = _result;
    if (result == null || !result.isTruncated) {
      return null;
    }
    return result.maxRows;
  }

  /// True when the loaded lines do not add up to the note header total.
  ///
  /// Truncated results and a missing header skip the comparison, because the
  /// footer then cannot represent the full purchase.
  bool get totalsDifferFromNote {
    final headerTotal = note?.valorTotalCompra;
    if (headerTotal == null || isTruncated || rows.isEmpty || isLoading) {
      return false;
    }
    return (headerTotal - totalValorItens).abs() > _noteTotalTolerance;
  }

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }

    _boundUserId = userId;
    _loadGeneration += 1;
    _cancelScope?.cancelAll();
    _result = null;
    _loadFailure = null;
    _missingClientToken = false;
    _isLoading = userId != null && hasValidCompraId && _selectedAgentId != null;
    _notifyListenersIfAlive();

    if (userId == null || !hasValidCompraId) {
      return;
    }

    await _loadItems();
  }

  Future<void> reload() => _loadItems();

  Future<void> _loadItems() async {
    final userId = _boundUserId;
    final agentId = _selectedAgentId;
    if (userId == null || agentId == null || !hasValidCompraId) {
      return;
    }

    final generation = ++_loadGeneration;
    final scope = _replaceCancelScope();
    _isLoading = true;
    _loadFailure = null;
    _missingClientToken = false;
    _notifyListenersIfAlive();

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (_isStale(userId, generation: generation)) {
      return;
    }
    if (clientToken == null) {
      _isLoading = false;
      _missingClientToken = true;
      _notifyListenersIfAlive();
      return;
    }

    final result = await _repository.load(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
      filter: _filter(),
      cancelScope: scope,
    );
    if (_isStale(userId, generation: generation)) {
      return;
    }

    result.fold(
      (loaded) {
        _result = loaded;
        _loadFailure = null;
      },
      (failure) {
        if (!shouldSuppressAgentQueryFailureUi(failure)) {
          _loadFailure = failure;
        }
      },
    );
    _isLoading = false;
    _notifyListenersIfAlive();
  }

  NotasEntradaItensFilter _filter() {
    return NotasEntradaItensFilter(compraId: compraId);
  }

  AgentQueriesCancelScope _replaceCancelScope() {
    _cancelScope?.cancelAll();
    final next = AgentQueriesCancelScope();
    _relayCancelScopeBinder?.call(next);
    _cancelScope = next;
    return next;
  }

  bool _isStale(String userId, {int? generation}) {
    return _disposed ||
        _boundUserId != userId ||
        (generation != null && _loadGeneration != generation);
  }

  void _notifyListenersIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelScope?.cancelAll();
    super.dispose();
  }
}
