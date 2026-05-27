import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';

/// Contract for the short-lived branch catalog cache used by
/// `LoadSalesLiveMapUseCase`. Implementations decide where rows are stored
/// (disk, in-memory, etc.) and how TTL is enforced.
abstract class SalesLiveMapCatalogCache {
  /// Maximum age before a cached catalog entry is considered stale.
  static const Duration ttl = Duration(minutes: 4);

  /// Returns the cached catalog page when one exists for [userId] / [scope]
  /// and is still fresh relative to [now]. Returns null otherwise.
  CadastroFilialAcrossAgentsPageResult? readIfFresh({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
  });

  /// Writes [result] to the cache as the most recent snapshot for
  /// [userId] / [scope], anchored to [now].
  Future<void> write({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult result,
  });

  /// Removes any cached entries belonging to [userId].
  Future<void> invalidateUser(String userId);
}
