# Dependency injection registration

File: [`lib/core/di/injector_agent_queries.dart`](../../lib/core/di/injector_agent_queries.dart)

## Shared infrastructure

Register once in `registerInjectorAgentQueries` (or `_registerSingleAgentQueryRepositories` prologue):

```dart
getIt.registerLazySingleton<AgentQueryFactsStore>(
  () => HiveAgentQueryFactsStore(getIt<AppCacheStore>()),
);

getIt.registerLazySingleton<ResumoTotalDiarioVendasCacheStrategy>(
  ResumoTotalDiarioVendasCacheStrategy.new,
);
```

## Pattern: no cache

Existing helper unchanged:

```dart
_registerSingle<CadastroFilialRepository, LoadCadastroFilialPageUseCase>(
  getIt,
  repo: () => CadastroFilialRepositoryImpl(getIt<AgentQueriesRepository>()),
  useCase: () => LoadCadastroFilialPageUseCase(getIt<CadastroFilialRepository>()),
);
```

Use for: options lists, catalog, high-churn reads, any query without catalog `persist` mode.

## Pattern: with cache

Replace only the `repo` factory for that type:

```dart
_registerSingle<
  ResumoTotalDiarioVendasRepository,
  LoadResumoTotalDiarioVendasUseCase
>(
  getIt,
  repo: () => CachingResumoTotalDiarioVendasRepositoryImpl(
    delegate: ResumoTotalDiarioVendasRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    factsStore: getIt<AgentQueryFactsStore>(),
    strategy: getIt<ResumoTotalDiarioVendasCacheStrategy>(),
  ),
  useCase: () => LoadResumoTotalDiarioVendasUseCase(
    getIt<ResumoTotalDiarioVendasRepository>(),
  ),
);
```

Across-agents registrations keep using `LoadResumoTotalDiarioVendasUseCase`; they automatically get the caching implementation.

## Strategy registration

One lazy singleton per strategy class. Do not register strategies for reports without cache.

## Testing

In unit tests, register:

- `AgentQueryFactsStore` → in-memory fake
- `ResumoXRepository` → plain impl or decorator with fake delegate

E2E uses production DI from `e2eSetupDependencies()`; cache should not break tests (closed buckets may be empty on first run).

## Session teardown

Ensure sign-out path calls `AppCacheStore.clearAll()` (existing). Facts keys use `agentQueryFacts` prefix and are cleared with the store.
