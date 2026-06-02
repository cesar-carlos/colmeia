# Per-repository consolidated facts cache

Design and rollout guide for optional business-layer caching on agent SQL report
repositories in Colmeia.

## Purpose

- Persist **closed** consolidated facts (by calendar day or month) so dashboards and
  reports can apply date/agent filters without repeating identical agent SQL.
- Keep caching **opt-in per repository** via GetIt (decorator registration).
- Use a **shared facts store** with one canonical key per bucket to avoid duplicate
  persistence across queries.

## Audience

Flutter/Dart contributors working on `lib/features/agent_queries/`, overview, and
sales surfaces that load multi-agent SQL reports.

## Document map

| Document | Contents |
| -------- | -------- |
| [architecture.md](architecture.md) | Layers, decorator pattern, facts store, replication control |
| [consolidation_rules.md](consolidation_rules.md) | When a bucket is "closed"; catalog per `AgentQueryKey` |
| [contracts.md](contracts.md) | Domain ports, load policies, invalidate scopes |
| [di_registration.md](di_registration.md) | GetIt: plain impl vs caching decorator |
| [implementation_phases.md](implementation_phases.md) | PR order, overview migration, prefetch |
| [testing.md](testing.md) | Unit tests, E2E requirements |

## Glossary

| Term | Meaning |
| ---- | ------- |
| **Bucket** | Smallest cache unit (e.g. one local calendar day, one calendar month) |
| **Closed bucket** | Bucket that ERP treats as consolidated; safe to persist (not today / not current month for monthly series) |
| **Open bucket** | Current day or current month; always fetched live, not written to durable store |
| **Fact kind** | Logical metric family (`dailySales`, `monthlyParcels`, …) used in storage keys |
| **Transport cache** | Short TTL SQL dedupe in `CachingAgentQueriesRepository` (~3s); separate from this design |
| **Decorator** | `Caching*RepositoryImpl` wrapping `*RepositoryImpl` (network-only) |

## Related code

| Area | Path |
| ---- | ---- |
| Report repository ports | `lib/features/agent_queries/domain/repositories/` |
| Network implementations | `lib/features/agent_queries/data/repositories/` |
| SQL transport chain | `lib/features/agent_queries/data/repositories/agent_queries_repository_chain_factory.dart` |
| Overview snapshot cache (legacy) | `lib/features/overview/data/datasources/overview_local_datasource.dart` |
| Reference: sales catalog cache port | `lib/features/sales/application/ports/sales_live_map_catalog_cache.dart` |
| KV prefixes | `lib/core/cache/app_kv_cache_key_prefixes.dart` |

## Project rules

- Architecture: `.cursor/rules/clean_architecture.mdc`
- Agent SQL and E2E: `.cursor/rules/project_agent_sql.mdc`
- Refactor vs feature separation: `.cursor/rules/general_rules.mdc`

## Related analysis

- `docs/analysis/consulta_multi_agente_para_relatorios_e_graficos.md`
- `docs/analysis/plano_evolucao_agentes_relatorios_dashboards.md`
