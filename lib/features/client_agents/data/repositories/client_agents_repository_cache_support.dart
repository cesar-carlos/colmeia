import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/hub_presence_synthesizer.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';

/// Shared local-cache helpers for online presence and approved-agent snapshot
/// mirroring. Injected into the segregated repository implementations so hub
/// presence semantics stay consistent without duplicating the logic.
class ClientAgentsRepositoryCacheSupport {
  ClientAgentsRepositoryCacheSupport(this._localDataSource);

  static const Duration onlineStatusMaxAge = Duration(minutes: 1);

  /// When the hub cannot be reached, use cached online presence only if it is
  /// newer than this limit; otherwise treat presence as unknown.
  static const Duration onlineStatusOfflineFallbackMaxAge = Duration(days: 7);

  static const PaginatedQuery defaultRefreshQuery = PaginatedQuery(
    pageSize: kClientAgentsListPageSize,
  );

  final ClientAgentsLocalDataSource _localDataSource;

  /// Persists a synthetic `OnlineAgentsResponseDto` when [profiles] include
  /// `is_hub_connected`, so [readOnlineAgentIds] and overview can resolve
  /// online ids without `GET /api/v1/agents` (user-only).
  Future<void> persistHubPresenceCacheFromProfiles({
    required String userId,
    required Iterable<ClientAgentProfileDto> profiles,
  }) async {
    final synthetic = synthesizeOnlineAgentsDtoFromProfiles(
      profiles: profiles,
      stamp: DateTime.now(),
    );
    if (synthetic == null) {
      return;
    }
    await _localDataSource.saveOnlineAgents(
      userId: userId,
      payload: synthetic,
    );
  }

  /// Cached hub presence only (no `GET /api/v1/agents` — client JWT is 403).
  /// When [fallbackToOfflineCache] is true, falls back to the wider
  /// [onlineStatusOfflineFallbackMaxAge] window when the fresh window
  /// returns nothing.
  Future<Set<String>?> readOnlineAgentIds({
    required String userId,
    required Duration maxAge,
    bool fallbackToOfflineCache = false,
  }) async {
    final primary = await _localDataSource.readOnlineAgents(
      userId: userId,
      maxAge: maxAge,
    );
    if (primary != null) {
      return primary.agents.map((item) => item.agentId).toSet();
    }
    if (!fallbackToOfflineCache) {
      return null;
    }
    final fallback = await _localDataSource.readOnlineAgents(
      userId: userId,
      maxAge: onlineStatusOfflineFallbackMaxAge,
    );
    if (fallback == null) {
      return null;
    }
    return fallback.agents.map((item) => item.agentId).toSet();
  }

  Future<void> applySnapshotToCachedAgentDetail({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) async {
    final cachedDetail = await _localDataSource.readApprovedAgentDetail(
      userId: userId,
      agentId: agentId,
    );
    if (cachedDetail == null) {
      return;
    }
    await _localDataSource.saveApprovedAgentDetail(
      userId: userId,
      agentId: agentId,
      payload: ClientApprovedAgentDetailResponseDto(
        agent: applySnapshotToAccessibleAgent(cachedDetail.agent, snapshot),
      ),
    );
  }

  Future<void> applySnapshotToCachedApprovedAgents({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) async {
    final approvedSnapshot = await _localDataSource.readApprovedAgents(
      userId: userId,
      query: defaultRefreshQuery,
    );
    if (approvedSnapshot == null) {
      return;
    }
    var changed = false;
    final updatedAgents = approvedSnapshot.agents
        .map((agent) {
          if (agent.agentId != agentId) {
            return agent;
          }
          changed = true;
          return applySnapshotToAccessibleAgent(agent, snapshot);
        })
        .toList(growable: false);
    if (!changed) {
      return;
    }
    await _localDataSource.saveApprovedAgents(
      userId: userId,
      query: defaultRefreshQuery,
      payload: ClientApprovedAgentsResponseDto(
        agents: updatedAgents,
        agentIds: approvedSnapshot.agentIds,
        count: approvedSnapshot.count,
        total: approvedSnapshot.total,
        page: approvedSnapshot.page,
        pageSize: approvedSnapshot.pageSize,
      ),
    );
  }

  ClientAccessibleAgentDto applySnapshotToAccessibleAgent(
    ClientAccessibleAgentDto base,
    AgentProfileSnapshot snapshot,
  ) {
    final normalizedDocument = snapshot.document?.trim();
    return base.copyWith(
      name: snapshot.name,
      tradeName: snapshot.tradeName,
      document: normalizedDocument,
      cnpjCpf: normalizedDocument,
      documentType: snapshot.documentType,
      phone: snapshot.phone,
      mobile: snapshot.mobile,
      email: snapshot.email,
      notes: snapshot.notes,
      observation: snapshot.observation,
      profileUpdatedAt: snapshot.profileUpdatedAt,
      profileVersion: snapshot.profileVersion,
    );
  }
}
