import 'package:checks/checks.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryCacheStore implements AppCacheStore {
  final Map<String, String> _values = <String, String>{};

  Iterable<String> get keys => _values.keys;

  @override
  Future<void> clearAll() async => _values.clear();

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    _values[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _values.remove(key);
  }
}

void main() {
  late ClientAgentsLocalDataSource datasource;

  setUp(() {
    datasource = ClientAgentsLocalDataSource(_InMemoryCacheStore());
  });

  test('should keep catalog cache isolated by query and search', () async {
    const firstQuery = PaginatedQuery();
    const secondQuery = PaginatedQuery(page: 2);

    const firstPayload = PaginatedAgentCatalogResponseDto(
      agents: [],
      count: 1,
      total: 10,
      page: 1,
      pageSize: 20,
    );
    const secondPayload = PaginatedAgentCatalogResponseDto(
      agents: [],
      count: 2,
      total: 10,
      page: 2,
      pageSize: 20,
    );

    await datasource.saveCatalog(
      userId: 'user-1',
      query: firstQuery,
      payload: firstPayload,
      search: 'north',
    );
    await datasource.saveCatalog(
      userId: 'user-1',
      query: secondQuery,
      payload: secondPayload,
      search: 'south',
    );

    final firstResult = await datasource.readCatalog(
      userId: 'user-1',
      query: firstQuery,
      search: 'north',
    );
    final secondResult = await datasource.readCatalog(
      userId: 'user-1',
      query: secondQuery,
      search: 'south',
    );
    final missingResult = await datasource.readCatalog(
      userId: 'user-1',
      query: firstQuery,
      search: 'south',
    );

    check(firstResult).isNotNull();
    check(firstResult!.count).equals(1);
    check(secondResult).isNotNull();
    check(secondResult!.count).equals(2);
    check(missingResult).isNull();
  });

  test('readCatalog returns null when stored value is invalid JSON', () async {
    final store = _InMemoryCacheStore();
    datasource = ClientAgentsLocalDataSource(store);
    const payload = PaginatedAgentCatalogResponseDto(
      agents: [],
      count: 0,
      total: 0,
      page: 1,
      pageSize: 20,
    );
    await datasource.saveCatalog(
      userId: 'user_x',
      query: const PaginatedQuery(),
      payload: payload,
    );
    final key = store.keys.single;
    await store.putString(key: key, value: '{not-json');

    final result = await datasource.readCatalog(
      userId: 'user_x',
      query: const PaginatedQuery(),
    );

    check(result).isNull();
  });
}
