# Plano: ResumoVendasDiariasPorVendedor

## Resumo

- Checklist de implementacao: secao [Tarefas em ordem de execucao](#tarefas-em-ordem-de-execucao).
- Adicionar a nova consulta SQL na feature `agent_queries`.
- Deixar a consulta pronta para consumo futuro por UI.
- Implementar cadeia completa single-agent e across-agents.
- Espelhar assinaturas, DI, `AgentSqlExecuteRequest` e orquestracao across-agents do fluxo existente `ResumoParcelaFormaPagamento` (com diferencas documentadas: filtros fixos na SQL desta consulta).
- Ja deixar o contrato preparado para filtros por vendedor, bairro e municipio.
- Ja deixar prevista a carga de sugestoes para autocomplete desses filtros, com **intervalo de datas** obrigatorio nas APIs de sugestao (coerente com as SQLs leves).
- Nao alterar `overview`, rotas, controllers ou widgets.
- Nao expor SQL bruto fora da camada `data`.

## Escopo Desta Rodada

### Inclui

- SQL da consulta em `data/queries`
- filtro tipado em `domain/entities`
- row entity em `domain/entities`
- row model em `data/models`
- suporte de filtro por vendedor, bairro e municipio
- consultas leves de sugestoes para autocomplete
- repositorio single-agent
- use case single-agent
- repositorio across-agents
- use case across-agents
- atualizacao de DI em `injector_agent_queries.dart`
- testes unitarios e de integracao leve da nova consulta (ver definicao abaixo)

### Nao inclui

- UI
- pages
- widgets
- controllers
- rotas
- integracao no `overview`
- cache novo

### Definicao de integracao leve

- Testes que exercitam `*RepositoryImpl` contra `AgentQueriesRepository` **falso** (mock/fake), verificando `AgentSqlExecuteRequest` (SQL constante, `namedParams`, `executionMode`, timeout) e o mapeamento de linhas.
- Nao inclui testes de bridge real, rede ou agente externo.

## Tarefas em ordem de execucao

Checklist operacional; marque `- [x]` ao concluir cada item. A ordem evita dependencias circulares (dominio antes de data; SQL antes de repos; repos antes de DI; DI antes de testes de integracao leve que resolvem tipos).

### Fase A — Dominio base

- [x] **A.1** Atualizar `agent_query_key.dart`: adicionar `resumoVendasDiariasPorVendedor`, `resumoVendasDiariasOptsVendedor`, `resumoVendasDiariasOptsBairro`, `resumoVendasDiariasOptsMunicipio`.
- [x] **A.2** Criar `resumo_vendas_diarias_por_vendedor_filter.dart` com `validationError()` alinhado a `ResumoParcelaFormaPagamentoFilter` (mensagens tecnicas em ingles).
- [x] **A.3** Criar `resumo_vendas_diarias_por_vendedor_row.dart` (entity).
- [x] **A.4** Criar `resumo_vendas_diarias_por_vendedor_vendedor_option.dart` e `resumo_vendas_diarias_por_vendedor_text_option.dart`.
- [x] **A.5** Criar interfaces `resumo_vendas_diarias_por_vendedor_repository.dart` e `resumo_vendas_diarias_por_vendedor_across_agents_repository.dart` (assinaturas fechadas no plano).
- [x] **A.6** Criar interfaces `resumo_vendas_diarias_por_vendedor_filter_options_repository.dart` e `resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart`.

### Fase B — SQL e modelos da consulta principal

- [x] **B.1** Criar `resumo_vendas_diarias_por_vendedor_sql.dart` com a query de referencia, parametros `:dataVendaInicio`, `:dataVendaFim`, `:codVendedor`, `:bairro`, `:municipio`; origem / financeiro / pre-venda fixos na string.
- [x] **B.2** Criar `resumo_vendas_diarias_por_vendedor_row_model.dart` (`fromMap`, regras de parse do plano) e conversao para entity.

### Fase C — Pipeline resumo (single-agent e across-agents)

- [x] **C.1** Implementar `resumo_vendas_diarias_por_vendedor_repository_impl.dart` (validacao, datas `yyyy-MM-dd`, `namedParams`, `preserve`, timeout `120000`, `operation` de logging).
- [x] **C.2** Criar `load_resumo_vendas_diarias_por_vendedor_use_case.dart` (pass-through).
- [x] **C.3** Implementar `resumo_vendas_diarias_por_vendedor_across_agents_repository_impl.dart` (resolver + plan builder + `AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>` + delegacao ao use case da fase C.2; `AgentQueryKey.resumoVendasDiariasPorVendedor`; `sourceAgentIds` em falhas).
- [x] **C.4** Criar `load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart` (pass-through).
- [x] **C.5** Testes: filter (incl. `validationError`); row model; repo single-agent resumo (integracao leve com `AgentQueriesRepository` fake); repo across resumo; use cases C.2 e C.4 delegando.

### Fase D — SQLs de sugestoes

- [x] **D.1** Criar `resumo_vendas_diarias_por_vendedor_vendedor_options_sql.dart` com `namedParams` fechados (`dataVendaInicio`, `dataVendaFim`, `searchPattern`, `limit`) e `LIKE` opcional em nome de vendedor.
- [x] **D.2** Criar `resumo_vendas_diarias_por_vendedor_bairro_options_sql.dart` (mesmo contrato de params; coluna `Bairro`).
- [x] **D.3** Criar `resumo_vendas_diarias_por_vendedor_municipio_options_sql.dart` (mesmo contrato de params; coluna `NomeMunicipio`).
- [x] **D.4** Garantir uma unica estrategia de limite (TOP ou OFFSET/FETCH) igual nas tres queries.

### Fase E — Modelos e repositorio single-agent de sugestoes

- [x] **E.1** Criar `resumo_vendas_diarias_por_vendedor_vendedor_option_model.dart` e `resumo_vendas_diarias_por_vendedor_text_option_model.dart`.
- [x] **E.2** Implementar `resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart` (tres metodos; validacao de periodo; montagem de `searchPattern` a partir de `searchTerm`; clamp de `limit`; logs com `operation` por tipo).
- [x] **E.3** Criar `load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart`, `..._bairro_options_use_case.dart`, `..._municipio_options_use_case.dart` (pass-through).
- [x] **E.4** Testes: option models; repo single-agent de sugestoes (integracao leve, `namedParams` exatos); tres use cases delegando.

### Fase F — Across-agents de sugestoes

- [x] **F.1** Implementar `resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository_impl.dart`: tres metodos; cada um com `AgentQueryKey` correspondente (`OptsVendedor` / `OptsBairro` / `OptsMunicipio`); `AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>` ou `...TextOption>`; deduplicacao deterministica + `limit` global apos merge; sucesso parcial alinhado ao resumo principal.
- [x] **F.2** Criar `load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart`, `..._bairro_...`, `..._municipio_...` (pass-through).
- [x] **F.3** Testes: repos across de sugestoes (chaves corretas, propagacao de datas e `selectedAgentIds`, deduplicacao, limite pos-merge); tres use cases delegando.

### Fase G — Injecao de dependencias

- [x] **G.1** Atualizar `injector_agent_queries.dart`: registrar resumo (repo, use case, `AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>`, across repo, across use case).
- [x] **G.2** Registrar sugestoes: `FilterOptionsRepository`, tres use cases single; `AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>`; `AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>`; `FilterOptionsAcrossAgentsRepository`, tres use cases across — com injecao do use case single correspondente em cada across (espelho de parcela).
- [x] **G.3** Rodar analyzer nos arquivos tocados; confirmar que nenhum import de `presentation` ou `overview` foi adicionado.

### Fase H — Encerramento e regressao

- [x] **H.1** Revisar criterios de aceite do plano (secao dedicada) e cobertura dos testes obrigatorios listados nas secoes "Testes Obrigatorios" e "Testes Adicionais".
- [x] **H.2** Rodar testes da feature `agent_queries` (ou suite minima acordada no time) e corrigir falhas.

### Dependencias resumidas

```text
A.* → B.* → C.* → (D.* paralelo a C.5 parcial) → E.* precisa D.* → F.* precisa E.* e executors registrados → G.* apos C.* e F.* → H.* por ultimo
```

Sugestao pratica: concluir **A → B → C → G parcial** (só resumo) e testes **C.5**, depois **D → E → F → G completo** e testes **E.4 / F.3**, fechando com **H**.

## SQL de Referencia

```sql
SELECT
  CodEmpresa,
  CodFilial,
  DataVenda,
  CodVendedor,
  NomeVendedor,
  SUM(QtdeItens) AS QtdeItens,
  SUM(ValorAcrescimo) AS ValorAcrescimo,
  SUM(ValorDesconto) AS ValorDesconto,
  SUM(ValorBruto) AS ValorBruto,
  SUM(ValorLiquido) AS ValorLiquido
FROM (
  SELECT
    pv.CodEmpresa,
    pv.CodFilial,
    pv.Origem,
    pv.CodOrigem,
    pv.CodTipoOperacaoSaida,
    pv.PreVenda,
    tos.GeraFinanceiro,
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    pv.CodVendedor,
    COALESCE(
      NULLIF(LTRIM(RTRIM(v.Nome)), ''),
      'Vendedor nao informado'
    ) AS NomeVendedor,
    pv.CodCliente,
    pv.NomeCliente,
    pv.CnpjCpf,
    pv.Bairro,
    m.Nome AS NomeMunicipio,
    m.UF AS UFMunicipio,
    pv.QtdeItens,
    pv.PercentualAcrescimo,
    pv.ValorAcrescimo,
    pv.PercentualDesconto,
    pv.ValorDesconto,
    pv.ValorBruto,
    pv.ValorLiquido
  FROM ProdutoVendido pv
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  LEFT JOIN Vendedor v ON
    v.CodVendedor = pv.CodVendedor
  LEFT JOIN Municipio m ON
    m.CodMunicipio = pv.CodMunicipio
) ResumoVendasDiario
WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
  AND Origem LIKE 'FrenteLoja'
  AND GeraFinanceiro = 'S'
  AND PreVenda = 'N'
  AND (:codVendedor IS NULL OR CodVendedor = :codVendedor)
  AND (:bairro IS NULL OR Bairro = :bairro)
  AND (:municipio IS NULL OR NomeMunicipio = :municipio)
GROUP BY
  CodEmpresa,
  CodFilial,
  DataVenda,
  CodVendedor,
  NomeVendedor
```

## Regras Fechadas

- A SQL permanece multiline no arquivo Dart.
- A normalizacao para linha unica continua sendo responsabilidade do datasource.
- Os filtros `Origem`, `GeraFinanceiro` e `PreVenda` ficam fixos na SQL nesta rodada.
- O contrato publico da consulta expoe intervalo de datas e filtros opcionais por vendedor, bairro e municipio.
- As sugestoes de autocomplete nao devem usar a query principal do resumo.
- Autocomplete deve ser alimentado por consultas leves separadas para vendedor, bairro e municipio.
- A consulta deve seguir as rules de:
  - `clean_architecture.mdc`
  - `project_architecture.mdc`
  - `project_agent_sql.mdc`
  - `testing.mdc`

### Alinhamento com `ResumoParcelaFormaPagamento`

- Repositório single-agent: mesma forma de `load` (`agentId`, `filter`, `clientToken`, `bridgeTimeoutMs`).
- Repositório across-agents: mesma forma de `load` (`userId`, `filter`, `selectedAgentIds`, `strategy`, `bridgeTimeoutMs`, `raceMaxSources`).
- Use cases: pass-through espelhando o repositório.
- Implementacao single-agent: validar filtro antes da chamada; `DateFormat('yyyy-MM-dd')`; timeout padrao `120000`; `AgentSqlExecutionMode.preserve`; `UnknownFailure` em `FormatException` ao mapear linhas.
- Implementacao across-agents: `AgentQueryTargetResolver` + `AgentQueryPlanBuilder` + `AgentQueryExecutor<Row>` + delegacao ao use case single-agent correspondente, repassando `target.clientToken` e `plan.bridgeTimeoutMs`.
- Contexto de falhas: enriquecer com `sourceAgentIds` como em `ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl`.
- Diferenca intencional: em parcela, `Origem` / `GeraFinanceiro` / `PreVenda` vêm do filter e dos `namedParams`; nesta consulta ficam **literais fixos na SQL** — nao enviar esses tres como `namedParams`.

## Politica de datas e fuso

- `ResumoVendasDiariasPorVendedorFilter.dataVendaInicio` e `dataVendaFim` sao interpretados como **datas de calendario no fuso local do dispositivo** (mesma convencao pratica ja usada ao formatar com `DateFormat('yyyy-MM-dd')` no repositório, alinhado a `ResumoParcelaFormaPagamentoRepositoryImpl`).
- O contrato SQL usa apenas a parte de data (`yyyy-MM-dd`), sem horario.
- A UI futura deve enviar o intervalo coerente com o que o usuario escolheu no seletor de datas local; se no futuro houver requisito de UTC explicito, isso sera uma mudanca de contrato separada.

## Tipos e Contratos Novos

### AgentQueryKey

Adicionar ao enum existente:

- `resumoVendasDiariasPorVendedor` — consulta principal agregada (mantem o prefixo `resumo`, alinhado a `resumoParcelaFormaPagamento`).
- `resumoVendasDiariasOptsVendedor` — sugestoes de vendedor (across-agents / observabilidade).
- `resumoVendasDiariasOptsBairro` — sugestoes de bairro.
- `resumoVendasDiariasOptsMunicipio` — sugestoes de municipio.

Os tres valores `...Opts...` omitem a repeticao `PorVendedor` no meio do identificador para manter o enum legivel; o escopo continua sendo a feature ResumoVendasDiariasPorVendedor.

Cada fluxo across-agents de sugestao deve usar sua propria chave no `AgentQueryPlan` / `AgentQueryExecutionReport` para observabilidade, sem reutilizar a chave da consulta principal.

### Filter

Criar `ResumoVendasDiariasPorVendedorFilter` com:

- `DateTime dataVendaInicio`
- `DateTime dataVendaFim`
- `int? codVendedor`
- `String? bairro`
- `String? municipio`

Validacao:

- Expor `String? validationError()` no filter, no **mesmo estilo** de `ResumoParcelaFormaPagamentoFilter` (mensagem tecnica em ingles no retorno; `userMessage` continua responsabilidade do repositorio ao montar `ValidationFailure`).
- `dataVendaFim` deve ser maior ou igual a `dataVendaInicio` (comparacao por data de calendario coerente com a politica de datas acima).
- `codVendedor`, quando informado, deve ser maior que zero.
- `bairro` e `municipio` devem ser normalizados com `trim`.
- `bairro` e `municipio` vazios devem ser tratados como `null` (ausencia de filtro).

### Row

Criar `ResumoVendasDiariasPorVendedorRow` com:

- `int codEmpresa`
- `int codFilial`
- `DateTime dataVenda`
- `int? codVendedor`
- `String nomeVendedor`
- `double qtdeItens`
- `double valorAcrescimo`
- `double valorDesconto`
- `double valorBruto`
- `double valorLiquido`

Defaults:

- `codVendedor` pode ser `null`
- `nomeVendedor` nunca sai vazio; fallback: `Vendedor nao informado`
- `qtdeItens` e `double` porque a SQL agrega com `SUM(QtdeItens)` — semanticamente e **total agregado de quantidade**, nao contagem inteira de linhas; a UI nao deve assumir inteiro sem arredondamento consciente.
- filtros de texto devem entrar no request ja normalizados

### Limitacao conhecida: municipio por nome

- O filtro principal e a sugestao de municipio usam `NomeMunicipio` (e LIKE nas sugestoes). Municipios homonimos em UFs diferentes podem colidir; a subconsulta expoe `UFMunicipio`, mas **esta rodada nao** filtra por UF no contrato publico.
- Evolucao futura possivel: expor `CodMunicipio` ou par `(NomeMunicipio, UF)` no filter e nas opcoes, sem quebrar esta entrega.

### Repositorio Single-Agent

Criar `ResumoVendasDiariasPorVendedorRepository` com:

```dart
Future<AppResult<List<ResumoVendasDiariasPorVendedorRow>>> load({
  required String agentId,
  required ResumoVendasDiariasPorVendedorFilter filter,
  String? clientToken,
  int? bridgeTimeoutMs,
});
```

### Use Case Single-Agent

Criar `LoadResumoVendasDiariasPorVendedorUseCase` como pass-through do repositorio.

### Repositorio Across-Agents

Criar `ResumoVendasDiariasPorVendedorAcrossAgentsRepository` com:

```dart
Future<AppResult<AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow>>> load({
  required String userId,
  required ResumoVendasDiariasPorVendedorFilter filter,
  Set<String>? selectedAgentIds,
  AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
  int? bridgeTimeoutMs,
  int? raceMaxSources,
});
```

### Use Case Across-Agents

Criar `LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase` como pass-through do repositorio multiagente.

### Contratos de Sugestoes para Autocomplete

Criar entidades e contratos especificos para opcoes de filtro:

- `ResumoVendasDiariasPorVendedorVendedorOption`
- `ResumoVendasDiariasPorVendedorTextOption`
- `ResumoVendasDiariasPorVendedorFilterOptionsRepository` (single-agent)
- `ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository` (multiagente)

Parametro de periodo obrigatorio em **todas** as cargas de sugestao (alinhado as SQLs que restringem por `DataVenda`):

- `required DateTime dataVendaInicio`
- `required DateTime dataVendaFim`

Validacao de periodo: mesmas regras do filter principal (`dataVendaFim` >= `dataVendaInicio`); pode reutilizar um helper compartilhado ou validar inline no repositorio antes de executar SQL.

#### Repositório single-agent (`ResumoVendasDiariasPorVendedorFilterOptionsRepository`)

Espelha o resumo principal: um agente, token opcional, timeout opcional.

```dart
Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>> loadVendedorOptions({
  required String agentId,
  required DateTime dataVendaInicio,
  required DateTime dataVendaFim,
  String? searchTerm,
  int limit = 20,
  String? clientToken,
  int? bridgeTimeoutMs,
});

Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>> loadBairroOptions({
  required String agentId,
  required DateTime dataVendaInicio,
  required DateTime dataVendaFim,
  String? searchTerm,
  int limit = 20,
  String? clientToken,
  int? bridgeTimeoutMs,
});

Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>> loadMunicipioOptions({
  required String agentId,
  required DateTime dataVendaInicio,
  required DateTime dataVendaFim,
  String? searchTerm,
  int limit = 20,
  String? clientToken,
  int? bridgeTimeoutMs,
});
```

#### Repositório across-agents (`ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository`)

Espelha o resumo across-agents: `userId`, selecao de agentes, estrategia e parametros de corrida. O retorno publico e **lista deduplicada e ordenada** pronta para UI (evita expor `AgentQueryExecutionReport.mergedRows` cru, que seria apenas concatenacao por agente).

```dart
Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>> loadVendedorOptions({
  required String userId,
  required DateTime dataVendaInicio,
  required DateTime dataVendaFim,
  Set<String>? selectedAgentIds,
  String? searchTerm,
  int limit = 20,
  AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
  int? bridgeTimeoutMs,
  int? raceMaxSources,
});

Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>> loadBairroOptions({
  required String userId,
  required DateTime dataVendaInicio,
  required DateTime dataVendaFim,
  Set<String>? selectedAgentIds,
  String? searchTerm,
  int limit = 20,
  AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
  int? bridgeTimeoutMs,
  int? raceMaxSources,
});

Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>> loadMunicipioOptions({
  required String userId,
  required DateTime dataVendaInicio,
  required DateTime dataVendaFim,
  Set<String>? selectedAgentIds,
  String? searchTerm,
  int limit = 20,
  AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
  int? bridgeTimeoutMs,
  int? raceMaxSources,
});
```

Implementacao: apos `AgentQueryExecutor` concluir com sucesso, obter linhas de cada participante bem-sucedido, **deduplicar e ordenar** conforme "Semantica Fechada das Sugestoes", aplicar `limit` ao resultado global se necessario, entao retornar `Success(list)`. Falhas parciais seguem a mesma filosofia do resumo principal (sucesso parcial quando ao menos um agente retorna dados; falha quando todos falham). Contexto de log deve incluir `queryKey` e `strategy` como no `ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl`.

#### Orquestracao across-agents das sugestoes

- Cada tipo de sugestao (vendedor, bairro, municipio) usa a **mesma composicao** da consulta principal: `AgentQueryTargetResolver`, `AgentQueryPlanBuilder`, `AgentQueryExecutor<T>` e delegacao ao **use case single-agent** correspondente daquele tipo.
- Registrar:
  - `AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>`
  - `AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>` — **compartilhado** entre sugestoes de bairro e municipio (mesmo tipo de linha).
- Passar `AgentQueryKey` adequada em `planBuilder.build` para cada fluxo (ver secao `AgentQueryKey`).
- Semantica de `selectedAgentIds`, skipped sem token e estrategias (`singleSource`, `mergeAll`, `race`): igual ao resumo principal.

#### Defaults fechados

- `searchTerm` vazio ou nulo na API significa "primeiras opcoes" (`searchPattern: null` na SQL; ver "Named params fechados").
- `limit` default sera `20`.
- Sugestoes existem em **dois** niveis de contrato (single-agent e across-agents), como a consulta principal.
- O merge de listas no `mergeAll` segue as regras da secao "Semantica Fechada das Sugestoes".

### Use Cases de Sugestoes (single-agent)

- `LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase` — pass-through para `ResumoVendasDiariasPorVendedorFilterOptionsRepository.loadVendedorOptions`
- `LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase` — idem `loadBairroOptions`
- `LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase` — idem `loadMunicipioOptions`

### Use Cases de Sugestoes (across-agents)

- `LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase` — pass-through para `ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository.loadVendedorOptions`
- `LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase` — idem `loadBairroOptions`
- `LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase` — idem `loadMunicipioOptions`

### Strings estaveis de `operation` (logging e contexto de falha)

Alinhar ao estilo de `ResumoParcelaFormaPagamentoRepositoryImpl` / `ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl`:

| Area | Valor sugerido para `operation` |
| --- | --- |
| Resumo single-agent | `loadResumoVendasDiariasPorVendedor` |
| Resumo across-agents | `loadResumoVendasDiariasPorVendedorAcrossAgents` |
| Sugestao vendedor single-agent | `loadResumoVendasDiariasPorVendedorVendedorOptions` |
| Sugestao bairro single-agent | `loadResumoVendasDiariasPorVendedorBairroOptions` |
| Sugestao municipio single-agent | `loadResumoVendasDiariasPorVendedorMunicipioOptions` |
| Sugestoes across-agents | `loadResumoVendasDiariasPorVendedorOptionsAcrossAgents`; incluir `queryKey` (`resumoVendasDiariasOptsVendedor` / `OptsBairro` / `OptsMunicipio`) no contexto para distinguir tipo |

Manter mensagens de `userMessage` em portugues no repositorio; mensagens tecnicas do `ValidationFailure.message` em ingles quando seguirem o padrao do filter existente.

## Arquivos a Adicionar

- `lib/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart`
- `lib/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart`
- `lib/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart`
- `lib/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart`
- `lib/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart`
- `lib/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository.dart`
- `lib/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart`
- `lib/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart`
- `lib/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart`
- `lib/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_sql.dart`
- `lib/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_vendedor_options_sql.dart`
- `lib/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_options_sql.dart`
- `lib/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_municipio_options_sql.dart`
- `lib/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_row_model.dart`
- `lib/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_vendedor_option_model.dart`
- `lib/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_text_option_model.dart`
- `lib/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart`
- `lib/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository_impl.dart`
- `lib/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart`
- `lib/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository_impl.dart`

## Arquivos a Atualizar

- `lib/features/agent_queries/domain/entities/agent_query_key.dart`
- `lib/core/di/injector_agent_queries.dart`

## Implementacao Detalhada

### 1. Query SQL

- Criar `ResumoVendasDiariasPorVendedorSql.query`.
- Usar `:dataVendaInicio` e `:dataVendaFim` como parametros nomeados.
- Preservar o agrupamento original.
- Manter `Origem`, `GeraFinanceiro` e `PreVenda` fixos na SQL.
- Adicionar filtros opcionais por `codVendedor`, `bairro` e `municipio`.
- Filtrar vendedor por codigo.
- Filtrar bairro e municipio por igualdade exata do valor escolhido na UI futura.

### 2. Row model

Criar `ResumoVendasDiariasPorVendedorRowModel.fromMap(Map<String, dynamic>)`.

Regras de parse:

- aceitar chaves PascalCase
- aceitar chaves camelCase
- aceitar chaves lowercase
- `dataVenda` deve aceitar `DateTime`, string ISO ou `yyyy-MM-dd`
- `codVendedor` deve aceitar `null`, `int`, `num` e string parseavel
- `nomeVendedor` deve fazer trim e aplicar fallback
- campos numericos devem aceitar `num` e string decimal com `.` ou `,`
- campos invalidos devem gerar `FormatException`

### 3. Repositorio single-agent

Implementar `ResumoVendasDiariasPorVendedorRepositoryImpl` no mesmo padrao de `ResumoParcelaFormaPagamentoRepositoryImpl`.

Comportamento:

- validar filtro antes da execucao via `filter.validationError()` (retorno nao nulo vira `ValidationFailure`, como em `ResumoParcelaFormaPagamentoRepositoryImpl`)
- usar `DateFormat('yyyy-MM-dd')`
- montar `AgentSqlExecuteRequest` com:
  - `agentId`
  - `clientToken`
  - `bridgeTimeoutMs ?? 120000`
  - `namedParams` com `dataVendaInicio`, `dataVendaFim`, `codVendedor`, `bairro` e `municipio`
  - `executeOptions: AgentSqlExecuteOptions(executionMode: preserve)`
- mapear as rows em `ResumoVendasDiariasPorVendedorRow`
- retornar `UnknownFailure` quando houver `FormatException`
- usar `operation: 'loadResumoVendasDiariasPorVendedor'` no contexto de falhas e logs de row inesperada

### 4. Use case single-agent

- Criar `LoadResumoVendasDiariasPorVendedorUseCase`
- Manter como pass-through sem regra extra nesta rodada

### 5. Repositorio across-agents

Implementar `ResumoVendasDiariasPorVendedorAcrossAgentsRepositoryImpl` reaproveitando:

- `AgentQueryTargetResolver`
- `AgentQueryPlanBuilder`
- `AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>`

Semantica fechada:

- `selectedAgentIds == null` significa todos os agentes aprovados
- `selectedAgentIds == {}` explicito significa nenhum agente
- agentes sem `clientToken` local entram como skipped
- `singleSource`, `mergeAll` e `race` ficam disponiveis
- falhas devem carregar `sourceAgentIds` no contexto
- usar `operation: 'loadResumoVendasDiariasPorVendedorAcrossAgents'` nos logs de resolucao / plano / execucao

### 6. Use case across-agents

- Criar `LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase`
- Manter como pass-through do contrato multiagente

### 7. DI

Atualizar `injector_agent_queries.dart` para registrar:

- `ResumoVendasDiariasPorVendedorRepository`
- `LoadResumoVendasDiariasPorVendedorUseCase`
- `AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>`
- `ResumoVendasDiariasPorVendedorAcrossAgentsRepository`
- `LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase`
- `ResumoVendasDiariasPorVendedorFilterOptionsRepository`
- `LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase`
- `LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase`
- `LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase`
- `AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>`
- `AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>`
- `ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository`
- `LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase`
- `LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase`
- `LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase`

Ordem sugerida (espelho de parcela): data source e `AgentQueriesRepository`; repositorio e use case do resumo; reutilizar os singletons existentes de `AgentQueryTargetResolver` e `AgentQueryPlanBuilder` (ja usados por parcela); registrar `AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>` e o across do resumo; em seguida executors e repos de sugestoes, sempre com o use case single-agent correspondente injetado no across de sugestoes.

Nao alterar:

- `injector_overview.dart`
- `overview`
- qualquer arquivo de `presentation`

### 8. Repositorio single-agent de sugestoes

- Implementar `ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl` chamando `AgentQueriesRepository.executeSql` com a SQL leve correspondente.
- Validar intervalo de datas antes da execucao (mesma regra do filter principal).
- `namedParams` fechados: `dataVendaInicio`, `dataVendaFim`, `searchPattern`, `limit` (ver secao "Named params fechados" em SQLs de Sugestoes); nao enviar `searchTerm` bruto como chave separada salvo alias interno nao usado no payload.
- Timeout padrao `120000`, `executionMode.preserve`, mesmo padrao do resumo principal.
- Mapear linhas via `ResumoVendasDiariasPorVendedorVendedorOptionModel` / `ResumoVendasDiariasPorVendedorTextOptionModel`; `FormatException` vira `UnknownFailure`.
- Contexto `operation` conforme tabela na secao "Strings estaveis de operation".

### 9. Repositorio across-agents de sugestoes

- Implementar `ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl` com `AgentQueryTargetResolver`, `AgentQueryPlanBuilder`, `AgentQueryExecutor<T>` e o use case single-agent de sugestao correspondente (vendedor ou texto), espelhando a estrutura de `ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl`.
- Usar `AgentQueryKey` especifica por tipo (vendedor / bairro / municipio).
- Apos executar o plano, reunir linhas dos participantes com sucesso, **deduplicar** conforme "Semantica Fechada das Sugestoes", **ordenar de forma deterministica**, aplicar `limit` ao resultado agregado e retornar `Success(list)`.
- Falhas: enriquecer contexto com `sourceAgentIds` quando aplicavel; semantica de sucesso parcial alinhada ao resumo principal.

### 10. Use cases de sugestoes

- Seis use cases (tres single-agent, tres across-agents), todos pass-through, espelhando `LoadResumoParcelaFormaPagamentoUseCase` / `LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase`.

## Estrategia de Autocomplete

- Autocomplete nao deve reutilizar a query principal do resumo.
- Cada filtro tera uma SQL propria e leve:
  - vendedores
  - bairros
  - municipios
- As consultas de sugestoes devem retornar listas pequenas, ordenadas e distintas.
- O uso esperado na UI futura sera:
  - debounce de `300ms`
  - minimo de `2` caracteres para iniciar busca remota
  - `limit = 20` por request
- Se `searchTerm` vier vazio, o repositorio envia `searchPattern: null` e a consulta retorna as primeiras opcoes em ordem alfabetica (ate `limit`).
- Em multiagente, as sugestoes devem ser agregadas e deduplicadas entre agentes.
- As sugestoes devem refletir o conjunto atual de agentes selecionados, nao todos os agentes da conta quando houver filtro de agentes ativo.

## SQLs de Sugestoes

### Named params fechados (Dart para todas as sugestoes)

Cada `ResumoVendasDiariasPorVendedor*OptionsSql.query` usa o **mesmo conjunto de chaves** em `AgentSqlExecuteRequest.namedParams`:

| Chave | Tipo em Dart | Regra |
| --- | --- | --- |
| `dataVendaInicio` | `String` | `DateFormat('yyyy-MM-dd').format(dataVendaInicio)` (calendario local, igual ao resumo principal). |
| `dataVendaFim` | `String` | Idem. |
| `searchPattern` | `String?` | Ver tabela abaixo; e a unica entrada usada no `LIKE` da SQL. |
| `limit` | `int` | Valor do parametro `limit` do metodo (default `20`). Deve ser `>= 1`; se a API receber `<= 0`, normalizar para `1` ou falhar em `validationError` — **fechar na implementacao com clamp para `1` no repositorio** para evitar SQL invalida. |

**Montagem de `searchPattern` no `*FilterOptionsRepositoryImpl`:**

| Entrada `searchTerm` (API) | Valor de `searchPattern` enviado ao agente |
| --- | --- |
| `null` ou `trim().isEmpty` | `null` — SQL trata como "sem filtro textual"; apenas periodo + filtros fixos + `ORDER BY` + limite. |
| Demais | Apos `trim`, escapar caracteres especiais do `LIKE` do motor (`%`, `_`; usar `ESCAPE` na SQL se necessario), depois envolver com `%` + literal + `%` para busca contem. |

**Padrao SQL para texto opcional (repetir nas tres queries, trocando apenas a coluna):**

```sql
AND (
  :searchPattern IS NULL
  OR <ColunaTexto> LIKE :searchPattern
)
```

Substituir `<ColunaTexto>` por `NomeVendedor` (com alias da subquery), `Bairro` ou `NomeMunicipio` conforme o arquivo.

**Limite de linhas:** usar parametro nomeado compativel com o dialeto suportado pelo bridge (ex. `SELECT TOP (:limit) ...` ou `OFFSET 0 ROWS FETCH NEXT :limit ROWS ONLY` em SQL Server). Escolher **uma** forma por arquivo e manter consistente entre vendedor / bairro / municipio.

### Vendedor

- Retornar `DISTINCT CodVendedor, NomeVendedor` (ou equivalente com subquery + `TOP`/`FETCH` conforme limite).
- Aplicar os mesmos filtros fixos de `Origem`, `GeraFinanceiro` e `PreVenda`.
- `DataVenda` (ou expressao de data alinhada a consulta principal) entre `:dataVendaInicio` e `:dataVendaFim`.
- Aplicar filtro textual opcional com `:searchPattern` em `NomeVendedor` (via clausula acima).
- Ignorar registros sem nome util (predicados `NULLIF` / `LTRIM` / `RTRIM` na subquery, alinhado a consulta principal).
- Ordenar por `NomeVendedor`, depois `CodVendedor`, antes de aplicar `limit` no servidor.

### Bairro

- Retornar `DISTINCT Bairro` com `namedParams` identicos (datas, `searchPattern`, `limit`).
- Aplicar os mesmos filtros fixos e intervalo de datas.
- Filtro textual opcional: `Bairro LIKE :searchPattern` quando `searchPattern` nao for `NULL`.
- Ignorar vazio, nulo e texto so com espacos na origem.
- Ordenar alfabeticamente por `Bairro` antes do limite no servidor.

### Municipio

- Retornar `DISTINCT NomeMunicipio` com os mesmos `namedParams`.
- Aplicar os mesmos filtros fixos e intervalo de datas.
- Filtro textual opcional: `NomeMunicipio LIKE :searchPattern` quando `searchPattern` nao for `NULL`.
- Ignorar vazio, nulo e texto so com espacos na origem.
- Ordenar alfabeticamente por `NomeMunicipio` antes do limite no servidor.

## Semantica Fechada das Sugestoes

- Vendedor sera filtrado e retornado por codigo + nome.
- Bairro e municipio serao retornados como texto normalizado.
- O merge multiagente das sugestoes deve deduplicar:
  - vendedor por `codVendedor`
  - bairro por texto normalizado em lowercase
  - municipio por texto normalizado em lowercase
- O label final preservado deve ser o primeiro valor nao vazio em **ordem alfabetica deterministica sobre os labels candidatos** — isto e: coletar todos os candidatos do mesmo grupo de deduplicacao, **ordenar estavelmente** (ex. por label normalizado, depois por label bruto), depois escolher o representante; **nao** depender da ordem de chegada das respostas dos agentes.
- O contrato de sugestoes deve ser leve o suficiente para ser chamado durante digitacao, desde que a UI futura use debounce.
- Nao adicionar cache persistente na camada `agent_queries` nesta rodada.
- Cache ou memoization curta, se vier a existir, deve ficar na camada consumidora futura.

## Testes Obrigatorios

### Option models (vendedor e texto)

- deve mapear chaves PascalCase / camelCase / lowercase
- deve lancar `FormatException` em payload invalido

### Row model

- deve mapear PascalCase
- deve mapear camelCase
- deve mapear lowercase
- deve aceitar `codVendedor` nulo
- deve aplicar fallback em `nomeVendedor`
- deve parsear `dataVenda` corretamente
- deve parsear campos numericos corretamente
- deve lancar `FormatException` em row invalida

### Repositorio single-agent

- deve retornar `ValidationFailure` quando o periodo for invalido
- deve montar corretamente o `AgentSqlExecuteRequest`
- deve usar `namedParams` de data
- deve usar timeout default `120000`
- deve usar `executionMode.preserve`
- deve mapear linhas validas
- deve retornar `UnknownFailure` para row invalida

### Use case single-agent

- deve delegar corretamente ao repositorio

### Repositorio across-agents

- deve usar `AgentQueryKey.resumoVendasDiariasPorVendedor`
- deve propagar `filter`, `clientToken` e `bridgeTimeoutMs`
- deve agregar sucesso parcial em `mergeAll`
- deve falhar quando todos os executados falharem
- deve retornar report vazio quando nao houver alvo elegivel
- deve enriquecer falhas com `sourceAgentIds`

### Use case across-agents

- deve delegar corretamente ao repositorio multiagente

### Repositorios de sugestoes (single-agent)

- devem usar queries leves separadas da query principal
- devem aplicar `limit`
- devem incluir nos `namedParams` exatamente `dataVendaInicio`, `dataVendaFim`, `searchPattern` e `limit`
- devem retornar `ValidationFailure` quando o periodo for invalido
- devem mapear `searchTerm` da API para `searchPattern` conforme tabela da secao "Named params fechados"
- devem retornar listas distintas e ordenadas por agente
- devem ignorar entradas vazias

### Repositorios de sugestoes (across-agents)

- devem usar `AgentQueryTargetResolver` / `AgentQueryPlanBuilder` / `AgentQueryExecutor<T>` como o resumo principal
- devem propagar `selectedAgentIds`, `strategy`, `bridgeTimeoutMs` e `raceMaxSources`
- devem deduplicar e ordenar de forma deterministica antes de retornar a lista agregada
- devem respeitar `limit` no resultado **apos** deduplicacao global
- devem aplicar semantica de sucesso parcial alinhada ao resumo principal

### Use cases de sugestoes

- os seis use cases (single e across) devem delegar corretamente aos respectivos repositorios

## Criterios de Aceite

- A consulta fica disponivel em `agent_queries` para consumo futuro por UI.
- Existe fluxo single-agent completo.
- Existe fluxo across-agents completo.
- Existem contratos e repositorios especificos para autocomplete de vendedor, bairro e municipio (single-agent e across-agents), com periodo obrigatorio nas cargas de sugestao.
- A DI resolve os contratos novos.
- O datasource continua sendo o unico ponto que normaliza a SQL.
- Nenhuma feature de UI e alterada.
- `overview` permanece inalterado.

## Assumptions e Defaults

- Esta rodada prepara apenas a camada de consulta.
- A UI futura consumira os contratos novos.
- O filtro publico incluira datas, vendedor, bairro e municipio.
- A UI futura podera usar autocomplete com contratos prontos de sugestoes; toda carga de sugestao recebe o **mesmo intervalo de datas** que o usuario aplicar ao resumo (coerencia com vendas no periodo).
- `Origem`, `GeraFinanceiro` e `PreVenda` permanecem fixos na SQL.
- `qtdeItens` sera tratado como `double` (agregado `SUM`, ver secao Row).
- `bridgeTimeoutMs` default sera `120000`.
- Politica de datas: calendario local + `yyyy-MM-dd` na SQL (ver secao dedicada).
- Municipio apenas por nome implica risco de homonimos entre UFs ate evolucao futura com `CodMunicipio` ou UF no contrato.

## Semantica Fechada dos Novos Filtros

- `codVendedor` sera o identificador usado no contrato para filtro de vendedor.
- `nomeVendedor` permanece como label de exibicao no resultado, nao como chave de filtro.
- `bairro` sera filtrado como texto opcional exato, ja normalizado com `trim`.
- `municipio` sera filtrado como texto opcional exato, ja normalizado com `trim`.
- Filtros textuais vazios nao devem gerar erro; devem ser tratados como ausencia de filtro.
- Nesta rodada, o plano ja preve consultas separadas de sugestoes para dropdown/autocomplete.

## Testes Adicionais Obrigatorios para os Novos Filtros

### Filter

- `validationError()` deve retornar erro quando `dataVendaFim` for anterior a `dataVendaInicio`
- deve aceitar ausencia de `codVendedor`, `bairro` e `municipio`
- deve invalidar `codVendedor` menor ou igual a zero quando informado
- deve normalizar `bairro` e `municipio`
- deve tratar texto vazio como ausencia de filtro

### Repositorio single-agent

- deve enviar `codVendedor` quando informado
- deve enviar `bairro` normalizado quando informado
- deve enviar `municipio` normalizado quando informado
- deve enviar `null` para filtros opcionais ausentes

### Repositorio across-agents

- deve propagar os novos filtros para cada target executado

## Testes Adicionais Obrigatorios para Autocomplete

### Vendedor

- deve retornar vendedores distintos por `codVendedor`
- com `searchTerm` nao vazio, deve enviar `searchPattern` adequado nos `namedParams`; com vazio/nulo, deve enviar `searchPattern: null`
- deve respeitar `limit` (e o valor em `namedParams`)
- deve ordenar por nome e codigo

### Bairro

- deve retornar bairros distintos
- deve ignorar bairro vazio ou nulo
- deve mapear `searchTerm` para `searchPattern` como na tabela fechada
- deve respeitar `limit` (e o valor em `namedParams`)

### Municipio

- deve retornar municipios distintos
- deve ignorar municipio vazio ou nulo
- deve mapear `searchTerm` para `searchPattern` como na tabela fechada
- deve respeitar `limit` (e o valor em `namedParams`)

### Across-agents

- deve usar `AgentQueryKey.resumoVendasDiariasOptsVendedor`, `resumoVendasDiariasOptsBairro` ou `resumoVendasDiariasOptsMunicipio` conforme o tipo de sugestao
- deve deduplicar sugestoes entre agentes com ordenacao deterministica (nao depender da ordem de resposta)
- deve continuar retornando sucesso parcial quando ao menos um agente responder
- deve falhar apenas quando todos os agentes executados falharem
- deve propagar intervalo de datas em cada target
