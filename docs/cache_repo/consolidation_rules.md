# Consolidation rules and catalog

## Business rules

### Calendar day

- A **calendar day** is closed when `day < startOfDay(now)` in the app's local timezone.
- **Today** is never written to the durable facts store. It may be held in memory for the current screen session only.
- Daily series (`ResumoTotalDiarioVendasRow.dataVenda`) align with this rule.

### Calendar month

- A **calendar month** is closed when it is strictly before the current local month (`year/month < now`).
- The **current month** is always loaded live for monthly aggregates (`ResumoParcelasMensalRow.ano/mes`, lucratividade mensal, etc.).

### Period aggregates (no date on row)

Queries that return one row set for the whole `[dataVendaInicio, dataVendaFim]` without per-day breakdown (e.g. `ResumoParcelaFormaPagamentoRowV2`) do not support arbitrary offline range slicing until either:

- daily payment facts are cached and summed in the client, or
- a full **closed calendar month** is cached as one blob when the UI filter equals that month.

Until then, catalog marks these as **hybrid / later**.

### Weekday and lucratividade period facts

**Weekday** (`resumoParcelasDiaSemana`) and **lucratividade period**
(`resumoProdutoVendaLucratividade`) use `persistClosedBuckets` in
[consolidation_catalog.dart](../../lib/features/agent_queries/domain/cache/consolidation_catalog.dart):
closed buckets are written by their canonical writer keys; open buckets stay
live SQL or in-memory for the session.

**Weekday-by-user** (`resumoParcelasDiaSemanaUsuario`) remains `derivedOnly` —
not persisted as canonical facts. Prefer computing from cached daily facts when
available, or live SQL when the filter includes open days.

## Catalog (initial)

| `AgentQueryKey` | `FactKind` | Bucket | Closed when | Persist | Phase |
| --------------- | ---------- | ------ | ----------- | ------- | ----- |
| `resumoTotalDiarioVendas` | `dailySales` | `yyyy-MM-dd` | day &lt; today | Yes | Pilot 1 |
| `resumoParcelasMensal` | `monthlyParcels` | `yyyy-MM` | month &lt; current | Yes | Pilot 2 |
| `resumoProdutoVendaLucratividadeMensal` | `lucratividadeMensal` | `yyyy-MM` | month &lt; current | Yes | Later |
| `resumoParcelaFormaPagamentoV2` | `paymentPeriod` | period | hybrid | Later | Derive or month blob |
| `resumoParcelaPorUsuario` | `userPeriod` | period | hybrid | Later | Same |
| `resumoParcelasDiaSemana` | `weekdayPeriod` | period | open if range includes today | Yes (closed buckets) | Active |
| `resumoParcelasDiaSemanaUsuario` | `weekdayUserPeriod` | — | derived | No | Derived |
| `resumoProdutoVendaLucratividade` | `lucratividadePeriod` | period | open if range includes today | Yes (closed buckets) | Active |
| Catalog / options | — | — | volatile | No | Never |

Canonical writers (enforced at store write):

| `FactKind` | Writer `AgentQueryKey` |
| ---------- | ---------------------- |
| `dailySales` | `resumoTotalDiarioVendas` |
| `monthlyParcels` | `resumoParcelasMensal` |
| `weekdayPeriod` | `resumoParcelasDiaSemana` |
| `lucratividadePeriod` | `resumoProdutoVendaLucratividade` |
| `lucratividadeMensal` | `resumoProdutoVendaLucratividadeMensal` |

## Filter → buckets

Example: dashboard `referenceRange` 2026-03-01 .. 2026-03-15 (local):

| Series | Buckets loaded |
| ------ | -------------- |
| Daily | Store: 01..14 if present; network: 15 (today) if in range |
| Monthly | If range spans March 2026 only: network for March (open month); store for Feb 2026 and earlier months if chart needs 12m window |

The strategy's `planBuckets(filter, clock)` returns `BucketPlan` with `storeHits`, `networkBuckets`, and `openBuckets` metadata for logging.

## Timezone

Bucket closure uses the **device local calendar** (`DateTime.now()` in the app process). If the ERP closes business days in another timezone, closed/open boundaries may disagree with server truth until filters are aligned or a dedicated business clock is introduced.

## Performance

Long ranges (for example 12 months of daily buckets for one agent) imply one store read per closed day. Prefetch backfills closed buckets in the background; avoid blocking the UI on full-range first paint when possible.

## Schema version

Each stored envelope includes `schemaVersion`. Bump when row JSON shape changes; old entries are treated as miss.

## ERP reopen

If a closed day is reopened in ERP, use `invalidateCache` with bucket scope or `forceRefresh` for that range. Document operational procedure for support; no automatic detection in v1.

## Cache scope in storage keys

Facts keys include a `cacheScopeId` derived from filter dimensions (not calendar buckets). Daily and monthly strategies use [AgentQueryCacheScope](../../lib/features/agent_queries/domain/cache/agent_query_cache_scope.dart): period flags for all reports; monthly also adds `e*`, `f*`, `v*` segments when company, branch, or seller filters are set.

Entries written before `cacheScopeId` was added remain in Hive until user-wide eviction (`removeMatching` with the user prefix), logout `clearAll`, or manual support action. They are not read after the key shape change.

Overview `forceRefresh` calls `AgentQueryFactsStore.removeMatching` for the user prefix before load, and skips background prefetch for that request so stale closed buckets are not repopulated from an in-flight prefetch.

Invalid JSON or empty payload on read evicts the key (same as stale schema version).

## Out of scope (v1)

- Unifying all overview sections (payment resumo, weekday-by-user) into the facts store — overview remains hybrid facts + SQL batch for sections without a catalog writer.
- Business-day clock aligned with ERP timezone — bucket closure uses device local calendar; see [Timezone](#timezone) above.
- Global mutex between prefetch and interactive load — mitigated by user invalidation on `forceRefresh` and no prefetch on that policy.
