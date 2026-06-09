import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_pre_warmer.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';

/// Resolves the list of agent ids that the [RelayConversationPreWarmer]
/// should open conversations for, by reading the active session and asking
/// [LoadClientApprovedAgentsUseCase] for the first page of approved agents.
///
/// Exists as a class (rather than a closure) so:
/// - production and E2E dependency wiring share the same source of truth;
/// - it can be unit-tested in isolation from the relay socket plumbing;
/// - the pagination knob lives in a single place that the pre-warmer
///   only references as a defensive upper bound.
class ClientApprovedAgentsRelayPreWarmLoader {
  const ClientApprovedAgentsRelayPreWarmLoader({
    required AuthSessionAccessor sessionAccessor,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    int pageSize = defaultPageSize,
  }) : _sessionAccessor = sessionAccessor,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _pageSize = pageSize;

  /// Mirrors `mergeAllConcurrency = 8` from the across-agent executors so
  /// the pre-warm sweep covers exactly the first cross-agent wave. Kept in
  /// sync with [RelayConversationPreWarmer]'s defensive cap.
  static const int defaultPageSize = 8;

  final AuthSessionAccessor _sessionAccessor;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final int _pageSize;

  /// Tear-off friendly: pass `loader.loadApprovedAgentIds` as a
  /// [RelayPreWarmAgentIdsLoader] without extra adapter code.
  Future<List<String>> loadApprovedAgentIds() async {
    final session = await _sessionAccessor.read();
    final userId = session?.userId;
    if (userId == null || userId.isEmpty) {
      return const <String>[];
    }
    final result = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: PaginatedQuery(pageSize: _pageSize),
      includeOnlineStatus: false,
      loadAllPages: false,
    );
    return result.fold(
      (paginated) =>
          paginated.items.map((agent) => agent.agentId).toList(growable: false),
      (_) => const <String>[],
    );
  }
}
