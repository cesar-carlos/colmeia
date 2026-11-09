# Product analysis and design history

These documents preserve the original product research, architectural alternatives,
and incremental plans. Their implementation-status lists describe the time of
writing; they are not the current feature inventory or platform contract.

For current implementation guidance, start with the [project overview](../../README.md),
[installation index](../install/readme.md), [cache architecture](../cache_repo/architecture.md),
and [hub integration index](../plug_server_docs_index_for_colmeia.md).
Coding policy belongs to the [rules index](../../.cursor/rules/rules_index.mdc).

## Historical documents

| Document | Purpose |
| --- | --- |
| [Original product analysis](analise.md) | Business context and initial requirements |
| [Technical analysis](analise_tecnica.md) | Initial architecture and technology alternatives |
| [Alignment review](alinhamento_levantamentos_iniciais.md) | Comparison of initial research with an earlier implementation |
| [Agents as data sources](agentes_como_fontes_de_dados.md) | Agent authorization and data-source design |
| [Multi-agent queries](consulta_multi_agente_para_relatorios_e_graficos.md) | Query orchestration, reports, and chart design |
| [Evolution plan](plano_evolucao_agentes_relatorios_dashboards.md) | Original incremental delivery sequence |

## Terminology

- **Agent:** authorized connection to a client's queryable data source.
- **Approved agent:** agent admitted to the client's allowed list.
- **Single-source query:** query executed against one agent.
- **Multi-source race:** parallel queries accepting the first valid result;
  this design term does not imply that every report uses this policy.
- **Query key:** logical query identifier used for routing, caching, and diagnostics.

SQLite/Drift proposals and native iOS assumptions in the initial research are
historical. Current storage uses the `AppCacheStore` abstraction; its platform
selection and limitations are documented in the cache architecture above.
