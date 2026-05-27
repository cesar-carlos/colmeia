import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

typedef OverviewRelayCancelScopeBinder = void Function(
  AgentQueriesCancelScope cancelScope,
);

/// Encapsulates the per-load mutable state of the overview controller:
/// monotonic generation counter (for stale-response detection), the
/// "in-flight signature" used for deduping requests, the "last successful
/// signature" used to decide whether a refresh should keep prior content
/// visible, and the SQL fan-out cancel scope.
///
/// Centralizing these four values makes the load lifecycle obvious in one
/// place and removes the temptation to mutate them piecemeal from inside
/// the controller's load methods.
class OverviewLoadSession {
  OverviewLoadSession({OverviewRelayCancelScopeBinder? relayCancelScopeBinder})
      : _relayCancelScopeBinder = relayCancelScopeBinder;

  final OverviewRelayCancelScopeBinder? _relayCancelScopeBinder;

  int _generation = 0;
  String? _requestedSignature;
  String? _loadedSignature;
  AgentQueriesCancelScope? _cancelScope;
  bool _disposed = false;

  /// True when nothing has been requested or the request was reset.
  bool get hasPendingRequest => _requestedSignature != null;

  String? get requestedSignature => _requestedSignature;
  String? get loadedSignature => _loadedSignature;
  AgentQueriesCancelScope? get cancelScope => _cancelScope;

  /// True when the in-flight request matches a previously loaded signature
  /// and the caller can keep stale content visible while reloading.
  bool isReloadingSameSignature(String signature) {
    return _loadedSignature == signature;
  }

  /// Records the desired signature without starting a new generation. Used
  /// by `scheduleOverviewLoadIfNeeded`-style code paths that dedupe
  /// repeated requests before any work begins.
  set requestedSignature(String signature) {
    _requestedSignature = signature;
  }

  /// True when [signature] still matches the most recently recorded request.
  /// `addPostFrameCallback` consumers use this to bail out when a newer
  /// request arrived in the meantime.
  bool isRequestStillCurrent(String signature) {
    return _requestedSignature == signature;
  }

  /// Begins a new load: bumps the generation, swaps the SQL cancel scope
  /// (cancelling the previous one) and re-binds the relay scope. Returns the
  /// generation snapshot the caller should compare against [isStale].
  int begin(String signature) {
    _requestedSignature = signature;
    _generation++;
    _cancelScope?.cancelAll();
    final next = AgentQueriesCancelScope();
    _cancelScope = next;
    _relayCancelScopeBinder?.call(next);
    return _generation;
  }

  /// True when [generation] is older than the latest one started by [begin],
  /// or after [dispose] runs. Stale responses from older loads must not
  /// publish state changes.
  bool isStale(int generation) {
    return _disposed || generation != _generation;
  }

  /// Marks the current request as successfully loaded. Subsequent calls to
  /// [isReloadingSameSignature] for the same signature return true.
  set loadedSignature(String signature) {
    _loadedSignature = signature;
  }

  /// Clears the loaded signature without touching the in-flight one.
  /// Callers use this on failure paths where prior content is discarded.
  void clearLoaded() {
    _loadedSignature = null;
  }

  /// Resets the in-flight signature so the next caller is forced to record
  /// a fresh request. Used by `applyFilter`-style operations that must
  /// always reload regardless of dedupe.
  void resetRequested() {
    _requestedSignature = null;
  }

  void dispose() {
    _disposed = true;
    _cancelScope?.cancelAll();
    _cancelScope = null;
  }
}
