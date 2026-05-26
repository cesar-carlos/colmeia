import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Cooperative cancellation handle for an in-flight live map load.
///
/// Holds an [AgentQueriesCancelScope] so the underlying SQL transports
/// are unsubscribed/cancelled when [cancel] is invoked, plus a synchronous
/// flag the use case polls between async stages.
class SalesLiveMapLoadCancelToken {
  bool _isCancelled = false;

  final AgentQueriesCancelScope sqlCancelScope = AgentQueriesCancelScope();

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    sqlCancelScope.cancelAll();
  }
}
