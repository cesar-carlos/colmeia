import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';

/// In-memory, ID-keyed view of the user's pending actions used during a
/// sync run.
///
/// Replaces the recurring `working.map(...).toList(growable: false)`
/// rebuild pattern (which was O(n) per mutation and had to be repeated
/// inline at every state transition) with O(1) per-ID updates. Consumers
/// emit the current snapshot via [toList] before persisting it.
class PendingClientAgentActionsView {
  PendingClientAgentActionsView(Iterable<PendingAgentAction> initial)
      : _byId = <String, PendingAgentAction>{
          for (final action in initial) action.id: action,
        };

  final Map<String, PendingAgentAction> _byId;

  /// Snapshot of the current state as a fixed-length list, suitable for
  /// passing to `ClientAgentsLocalDataSource.savePendingActions`.
  List<PendingAgentAction> toList() =>
      _byId.values.toList(growable: false);

  PendingAgentAction? operator [](String id) => _byId[id];

  /// Applies [mutator] to the entry with [id] when present. No-op when
  /// the action no longer exists in the view.
  void update(
    String id,
    PendingAgentAction Function(PendingAgentAction current) mutator,
  ) {
    final current = _byId[id];
    if (current == null) {
      return;
    }
    _byId[id] = mutator(current);
  }

  /// Applies [mutator] to every entry whose id is in [ids].
  void updateAll(
    Iterable<String> ids,
    PendingAgentAction Function(PendingAgentAction current) mutator,
  ) {
    for (final id in ids) {
      update(id, mutator);
    }
  }

  /// Removes entries whose id is in [ids]. Missing ids are ignored.
  void removeIds(Iterable<String> ids) {
    ids.forEach(_byId.remove);
  }
}
