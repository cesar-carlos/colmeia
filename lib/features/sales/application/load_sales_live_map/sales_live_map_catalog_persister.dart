import 'dart:async';

import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';

/// Writes branch catalog pages through the in-memory and disk caches.
class SalesLiveMapCatalogPersister {
  const SalesLiveMapCatalogPersister({
    required SalesLiveMapInMemoryCatalogCache memoryCache,
    required SalesLiveMapCatalogCache diskCache,
  }) : _memoryCache = memoryCache,
       _diskCache = diskCache;

  final SalesLiveMapInMemoryCatalogCache _memoryCache;
  final SalesLiveMapCatalogCache _diskCache;

  void persist({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult page,
  }) {
    _memoryCache.write(
      userId: userId,
      scope: scope,
      now: now,
      result: page,
    );
    unawaited(
      _diskCache.write(
        userId: userId,
        scope: scope,
        now: now,
        result: page,
      ),
    );
  }
}
