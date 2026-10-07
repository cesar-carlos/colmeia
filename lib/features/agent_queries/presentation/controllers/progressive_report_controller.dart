import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

class ProgressiveReportController<Row> extends ChangeNotifier {
  static const notificationInterval = Duration(milliseconds: 100);
  final List<Row> _rows = [];
  List<Row> get rows => List.unmodifiable(_rows);
  List<Row> rowsForPage({required int page, required int pageSize}) {
    final start = ((page - 1) * pageSize).clamp(0, _rows.length);
    final end = (start + pageSize).clamp(start, _rows.length);
    return List.unmodifiable(_rows.sublist(start, end));
  }

  bool isLoading = false;
  bool isComplete = false;
  AppFailure? failure;
  bool get canExport => isComplete && !isLoading && failure == null;
  bool get isIncomplete => !isComplete && _rows.isNotEmpty;
  StreamSubscription<AppResult<AgentQueryProgress<Row>>>? _subscription;
  AgentQueriesCancelScope? _scope;
  Timer? _notification;
  int _generation = 0;
  Completer<AppResult<List<Row>>>? _completion;
  void Function()? _unregisterParent;

  Future<AppResult<List<Row>>> load(
    Stream<AppResult<AgentQueryProgress<Row>>> Function(AgentQueriesCancelScope)
    load, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    final generation = ++_generation;
    _stop();
    _rows.clear();
    failure = null;
    isComplete = false;
    isLoading = true;
    final completion = Completer<AppResult<List<Row>>>();
    _completion = completion;
    final scope =
        AgentQueriesCancelScope(
            traceId: cancelScope?.traceId,
            deadline: cancelScope?.deadline,
            diagnostics: cancelScope?.diagnostics,
          )
          ..relayCancelHandler = cancelScope?.relayCancelHandler
          ..socketRpcCancelHandler = cancelScope?.socketRpcCancelHandler
          ..streamingSqlCancelHandler = cancelScope?.streamingSqlCancelHandler;
    _scope = scope;
    notifyListeners();
    if (generation != _generation) return completion.future;
    _unregisterParent = cancelScope?.registerLocalCancellation(() {
      if (generation != _generation || isComplete || failure != null) return;
      failure = const OperationCancelledFailure();
      isLoading = false;
      scope.cancelAll();
      unawaited(_subscription?.cancel());
      _notifyNow();
    });
    if (scope.isCancelled) return completion.future;
    try {
      _subscription = load(scope).listen(
        (result) {
          if (generation != _generation || isComplete || failure != null) {
            return;
          }
          result.fold(
            (progress) {
              final first = _rows.isEmpty;
              if (progress.isComplete) _rows.clear();
              _rows.addAll(progress.rows);
              isComplete = progress.isComplete;
              isLoading = !progress.isComplete;
              if (progress.isComplete) _scope = null;
              if (first || progress.isComplete) {
                _notifyNow();
              } else {
                _notification ??= Timer(notificationInterval, _notifyNow);
              }
            },
            (error) {
              failure = error;
              isLoading = false;
              isComplete = false;
              scope.cancelAll();
              unawaited(_subscription?.cancel());
              _notifyNow();
            },
          );
        },
        onError: (Object error, StackTrace stack) {
          if (generation != _generation || isComplete || failure != null) {
            return;
          }
          failure = UnknownFailure(
            message: 'Progressive report stream failed',
            cause: error,
            stackTrace: stack,
          );
          isLoading = false;
          isComplete = false;
          scope.cancelAll();
          unawaited(_subscription?.cancel());
          _notifyNow();
        },
        onDone: () {
          if (generation != _generation || isComplete || failure != null) {
            return;
          }
          scope.cancelAll();
          failure = const UnknownFailure(
            message: 'Progressive report ended without completion',
          );
          isLoading = false;
          _notifyNow();
        },
      );
    } on Object catch (error, stack) {
      scope.cancelAll();
      failure = UnknownFailure(
        message: 'Progressive report could not be started',
        cause: error,
        stackTrace: stack,
        context: const {
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
        },
      );
      isLoading = false;
      _notifyNow();
    }
    return completion.future;
  }

  void _notifyNow() {
    _notification?.cancel();
    _notification = null;
    if (!isLoading) {
      _unregisterParent?.call();
      _unregisterParent = null;
      final completion = _completion;
      if (completion != null && !completion.isCompleted) {
        completion.complete(
          failure == null && isComplete
              ? Success(rows)
              : Failure(failure ?? const OperationCancelledFailure()),
        );
      }
    }
    notifyListeners();
  }

  void _stop() {
    _notification?.cancel();
    _notification = null;
    _unregisterParent?.call();
    _unregisterParent = null;
    final completion = _completion;
    _completion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(const Failure(OperationCancelledFailure()));
    }
    _scope?.cancelAll();
    unawaited(_subscription?.cancel());
    _subscription = null;
    _scope = null;
  }

  void cancel() {
    _generation++;
    _stop();
    _rows.clear();
    failure = null;
    isComplete = false;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    _stop();
    super.dispose();
  }
}
