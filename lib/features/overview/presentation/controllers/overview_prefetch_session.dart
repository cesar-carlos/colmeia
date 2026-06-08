import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Tracks in-flight overview chart-section prefetch work so it can be cancelled
/// when the user changes filters or starts a new home load.
final class OverviewPrefetchSession {
  int _generation = 0;
  AgentQueriesCancelScope? _cancelScope;

  int begin() {
    _generation++;
    _cancelScope?.cancelAll();
    final next = AgentQueriesCancelScope();
    _cancelScope = next;
    return _generation;
  }

  void cancel() {
    _generation++;
    _cancelScope?.cancelAll();
    _cancelScope = null;
  }

  bool isStale(int generation) => generation != _generation;

  AgentQueriesCancelScope? get cancelScope => _cancelScope;

  void dispose() {
    cancel();
  }
}
