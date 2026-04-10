# Plano Detalhado: Consulta por Agentes

## Objetivo

Este documento detalha a evolucao da feature de consultas por agentes no
Colmeia, alinhada com as rules do projeto em `./.cursor/rules`.

O foco desta rodada e:

- extrair a orquestracao multiagente hoje embutida no `overview`
- consolidar uma camada propria em `features/agent_queries`
- manter o bridge SQL atual como primitive single-agent
- refatorar o `overview` para depender de um contrato estavel de
  `agent_queries`

## Status de execucao

- `concluido`: Commit 1 - base de contratos e funcao compartilhada
- `concluido`: Commit 2 - use case publico e wiring de DI em `agent_queries`
- `concluido`: Commit 3 - resolver de agentes aprovados e tokens locais
- `concluido`: Commit 4 - planner de estrategia
- `concluido`: Commit 5 - executor multiagente
- `concluido`: Commit 6 - repositorio multiagente tipado de resumo
- `concluido`: Commit 7 - troca do consumidor no overview
- `concluido`: Commit 8 - limpeza, logs e consolidacao

### Atualizacao da etapa atual

- `overview` agora depende de
  `ResumoParcelaFormaPagamentoAcrossAgentsRepository`
- `OverviewRepositoryImpl` nao carrega mais agentes aprovados, tokens locais ou
  fan-out por conta propria
- `injector_overview.dart` foi trocado para o contrato novo
- `injector.dart` passou a registrar `agent_queries` antes de `overview`
- os testes do `overview` foram reescritos para validar o report multiagente
- a camada multiagente agora loga resolucao, planejamento e execucao com
  contexto estruturado
- o `overview` deixou de registrar como erro o caso esperado de negocio
  `noApprovedAgents`
- o executor multiagente passou a tratar excecoes lancadas por loaders como
  `AppFailure`
- falhas multiagente agora carregam `sourceAgentIds` para preservar a validacao
  da assinatura de cache no `overview`
- a selecao explicita vazia deixou de ser interpretada como "todos os agentes"
- `agent_queries` deixou de depender diretamente do storage concreto de token e
  passou a usar contrato estavel
- `AgentQueryPlanBuilder` e `AgentQueryExecutor` foram movidos para
  `application/orchestration`
- a validacao executada nesta etapa ficou verde para `overview`,
  `agent_queries` e `client_agent_display_name`

## Escopo desta rodada

### Inclui

- nova camada de consulta multiagente em `agent_queries`
- suporte a estrategias `singleSource`, `mergeAll` e `race`
- refatoracao do `overview` para usar a camada nova
- correcao da fronteira entre `overview` e `agent_queries`
- testes unitarios e de integracao leve da nova camada
- documentacao do plano detalhado nesta pasta

### Nao inclui

- religar o modulo de `reports` na navegacao
- UI incremental por agente
- cancelamento real de request HTTP no `race`
- cache generico dentro de `agent_queries`
- bloqueio por `offline`
- widget tests
- SQL bruto exposto para outras features

## Melhorias incorporadas ao plano

As melhorias abaixo passam a fazer parte do desenho oficial desta rodada, e nao
apenas como recomendacoes futuras.

### Melhorias arquiteturais

- corrigir a fronteira entre `overview` e `agent_queries`
- mover timeout, fan-out, merge e degradacao parcial para `agent_queries`
- expor apenas contrato query-specific entre features
- manter o bridge SQL como primitive de baixo nivel e nao como API publica para
  outras features
- extrair a regra de `displayName` do agente para funcao compartilhada

### Melhorias de robustez

- centralizar limite de concorrencia e timeout na camada de orquestracao
- devolver um report tipado de execucao, em vez de listas paralelas soltas
- garantir ordenacao deterministica por `agentId` em resolucao, execucao e
  merge
- manter cache apenas na feature consumidora
- preservar comportamento de falha parcial sem derrubar a carga completa quando
  houver sucesso parcial em `mergeAll`

### Melhorias de testes

- separar testes de resolver, planner e executor
- manter os testes do bridge SQL como contrato estavel
- validar equivalencia funcional do `overview` apos a refatoracao
- reforcar cenarios de token ausente, falha parcial, timeout e ordenacao

## Rules aplicadas

### Arquitetura

- `clean_architecture.mdc`
- `project_architecture.mdc`

Decisoes derivadas:

- `presentation` nao pode falar com datasource, storage ou HTTP
- `overview` deve depender de contratos estaveis, nao de detalhes internos
- `agent_queries` continua sendo a feature dona da integracao com o bridge SQL

### Dados e dominio

- `project_data_domain.mdc`
- `project_conventions.mdc`
- `project_agent_sql.mdc`

Decisoes derivadas:

- `AppResult<T>` e `AppFailure` seguem como contrato de falha
- cache continua leve e no consumidor, nao na camada nova
- SQL multiline continua nos arquivos de query e e normalizada apenas no envio
- filtros e paginacao continuam preferencialmente no servidor/agente

### Testes

- `testing.mdc`

Decisoes derivadas:

- foco em unit tests e integracao leve
- sem `testWidgets` nesta rodada
- cobertura explicita de falhas, timeout, parse e degradacao parcial

## Problema atual

Hoje o projeto ja possui:

- primitive single-agent via `POST /agents/commands`
- `AgentSqlExecuteRequest`
- `AgentQueriesRepository.executeSql(...)`
- consulta SQL tipada para `ResumoParcelaFormaPagamento`
- agregacao multiagente implementada diretamente dentro de
  `OverviewRepositoryImpl`

O problema e que a orquestracao atual esta no lugar errado:

- `overview` carrega agentes aprovados por conta propria
- `overview` le tokens locais por conta propria
- `overview` controla o fan-out paralelo por conta propria
- `overview` conhece detalhes de resiliencia que deveriam viver em
  `agent_queries`
- `overview` depende diretamente de um use case de outra feature

Isso cria acoplamento entre features e dificulta reuso futuro em dashboards e
relatorios.

## Visao alvo

### Principio central

Cada consulta orientada a agentes deve passar por uma camada propria da feature
`agent_queries`, com contratos tipados por `queryKey`, sem expor SQL bruto para
outras features.

### Resultado esperado

- `agent_queries` resolve agentes aprovados e tokens locais
- `agent_queries` planeja a estrategia de execucao
- `agent_queries` executa a consulta por um ou varios agentes
- `agent_queries` devolve um report consolidado e observavel
- `overview` apenas transforma as linhas recebidas em KPIs, rankings e avisos

### Beneficios esperados

- menor acoplamento entre features
- maior reuso para dashboards e relatorios futuros
- menos risco de regressao ao evoluir regras de consulta
- testes mais localizados e mais baratos
- melhor observabilidade por agente participante

## Estrategia de produto fechada

- primeira rodada: `camada + overview`
- estrategias alvo: `singleSource`, `mergeAll`, `race`
- entrega para UI: somente consolidada ao final
- contrato publico: query-specific e tipado
- status operacional: apenas observabilidade nesta rodada

## Contratos novos

## 1. Enumeracoes

### `AgentQueryKey`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_key.dart`

Conteudo inicial:

```dart
enum AgentQueryKey {
  resumoParcelaFormaPagamento,
}
```

### `AgentQueryExecutionStrategy`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_execution_strategy.dart`

Conteudo:

```dart
enum AgentQueryExecutionStrategy {
  singleSource,
  mergeAll,
  race,
}
```

## 2. Target de agente

### `AgentQueryTarget`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_target.dart`

Campos:

- `agentId`
- `displayName`
- `connectionStatus`
- `clientToken`

Regras:

- `clientToken` pode ser nulo apenas para representar agente considerado sem
  token local
- `displayName` deve vir de funcao compartilhada com `client_agents`

## 3. Resolucao de alvos

### `AgentQueryTargetResolution`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_target_resolution.dart`

Campos:

- `consideredApprovedTargets`
- `missingClientTokenTargets`
- `consideredApprovedAgentCount`
- `selectedAgentIds`

Regras:

- `consideredApprovedTargets` inclui apenas agentes aprovados filtrados
- `missingClientTokenTargets` e subconjunto dos considerados
- a ordem deve ser deterministica por `agentId`

## 4. Plano de execucao

### `AgentQueryPlan`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_plan.dart`

Campos:

- `queryKey`
- `strategy`
- `consideredApprovedAgentCount`
- `plannedTargets`
- `missingClientTokenTargets`
- `bridgeTimeoutMs`
- `raceMaxSources`

Regras:

- `plannedTargets` sempre ordenados por `agentId`
- `raceMaxSources` so faz sentido em `race`

## 5. Resultado por participante

### `AgentQueryExecutionParticipant<Row>`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_execution_participant.dart`

Campos:

- `agentId`
- `displayName`
- `rows`
- `failure`
- `elapsedMs`
- `wasDiscardedByRace`

Regras:

- sucesso: `rows` preenchido, `failure == null`
- falha: `failure != null`
- descarte logico em `race`: `wasDiscardedByRace == true`

## 6. Report final de execucao

### `AgentQueryExecutionReport<Row>`

Arquivo:

- `lib/features/agent_queries/domain/entities/agent_query_execution_report.dart`

Campos:

- `queryKey`
- `strategy`
- `consideredApprovedAgentCount`
- `plannedTargets`
- `missingClientTokenTargets`
- `participants`
- `winnerAgentId`
- `totalElapsedMs`

Getters derivados:

- `mergedRows`
- `rowsByAgentId`
- `failedAgentIds`
- `failedAgentNames`
- `missingClientTokenAgentIds`
- `missingClientTokenAgentNames`
- `requiresClientTokenSetup`
- `hasPartialFailure`
- `hasRows`

## Contrato cross-feature novo

### `ResumoParcelaFormaPagamentoAcrossAgentsRepository`

Arquivo:

- `lib/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart`

Assinatura:

```dart
abstract interface class ResumoParcelaFormaPagamentoAcrossAgentsRepository {
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>>>
  load({
    required String userId,
    required ResumoParcelaFormaPagamentoFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy =
        AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}
```

### Motivo dessa escolha

- `overview` deixa de depender de detalhes de `agent_queries` application/data
- o contrato fica estavel, tipado e claro
- evitamos expor SQL bruto para as features consumidoras

## Use case publico novo

### `LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase`

Arquivo:

- `lib/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart`

Papel:

- encapsular a chamada ao repositorio multiagente
- manter o mesmo estilo do repo para use cases simples

## Colaboradores internos novos

## 1. `AgentQueryTargetResolver`

Arquivo:

- `lib/features/agent_queries/data/orchestration/agent_query_target_resolver.dart`

Dependencias:

- `ClientAgentsRepository`
- `LocalAgentClientTokenStore`

Responsabilidades:

- paginar todos os agentes aprovados
- aplicar filtro por `selectedAgentIds`
- ler tokens locais em lote
- separar agentes considerados e agentes sem token
- devolver `AgentQueryTargetResolution`

Regras:

- usar `includeOnlineStatus: false`, igual ao `overview` atual
- pagina em lotes como hoje, com comportamento deterministico
- se nenhum agente aprovado existir na conta: `ValidationFailure`
- se houver aprovados, mas nenhum casar com `selectedAgentIds`: sucesso vazio

## 2. `AgentQueryPlanBuilder`

Arquivo:

- `lib/features/agent_queries/data/orchestration/agent_query_plan_builder.dart`

Responsabilidades:

- validar a estrategia pedida
- converter `TargetResolution` em `AgentQueryPlan`
- aplicar defaults

Defaults:

- `bridgeTimeoutMs = 120000`
- `raceMaxSources = 4`

Validacoes:

- `singleSource` exige exatamente 1 agente considerado
- `raceMaxSources >= 1`
- `mergeAll` ignora `raceMaxSources`

## 3. `AgentQueryExecutor<Row>`

Arquivo:

- `lib/features/agent_queries/data/orchestration/agent_query_executor.dart`

Responsabilidades:

- executar o plano
- controlar concorrencia
- montar `AgentQueryExecutionReport<Row>`
- preservar falhas e tempos por agente
- ser o unico dono do timeout por estrategia e do limite de concorrencia

API interna sugerida:

```dart
typedef AgentQueryTargetLoader<Row> =
    Future<AppResult<List<Row>>> Function(AgentQueryTarget target);
```

Metodos internos:

- `executeSingleSource`
- `executeMergeAll`
- `executeRace`

## Estrategias detalhadas

## `singleSource`

Comportamento:

- executa exatamente um agente
- se houver token local, usa o loader single-agent
- se nao houver token, retorna `Success` vazio guiado para setup
- se falhar, retorna `Failure`

## `mergeAll`

Comportamento:

- executa todos os agentes planejados com concorrencia maxima `4`
- espera o lote terminar
- concatena apenas os sucessos em `mergedRows`
- preserva falhas parciais no report

Regras de sucesso:

- se ao menos um agente tiver sucesso: `Success`
- se todos os executados falharem: `Failure`
- se todos os considerados estiverem sem token: `Success` vazio

Ordenacao:

- `mergedRows` e `rowsByAgentId` seguem ordem deterministica por `agentId`
- nunca por ordem de chegada

Politica de degradacao:

- quando houver sucesso parcial, o resultado final deve ser `Success`
- participantes com falha continuam visiveis no report
- `overview` usa esse report para popular avisos e metadados de exclusao

## `race`

Comportamento:

- dispara em paralelo os agentes planejados
- o primeiro sucesso vence
- falhas iniciais nao encerram o fluxo enquanto houver candidatos em voo

Regras:

- se algum agente tiver sucesso: `Success`
- se todos falharem: `Failure`
- respostas tardias apos o vencedor sao descartadas logicamente
- nao ha cancelamento real de transporte nesta v1

Observabilidade:

- preencher `winnerAgentId`
- marcar descartes com `wasDiscardedByRace`

## Reuso do fluxo single-agent atual

### Mantido

- `AgentQueriesRemoteDataSource`
- `AgentQueriesRepository`
- `LoadResumoParcelaFormaPagamentoUseCase`
- `ResumoParcelaFormaPagamentoRepositoryImpl`
- `ResumoParcelaFormaPagamentoSql`

### Nova composicao

O multiagente nao substitui o single-agent. Ele o reutiliza por alvo.

Fluxo:

1. repositorio multiagente resolve agentes
2. planner monta a estrategia
3. executor chama o loader por agente
4. o loader reutiliza `LoadResumoParcelaFormaPagamentoUseCase`
5. esse use case continua delegando para o repositorio single-agent
6. o repositorio single-agent continua usando o bridge atual

### Regra de encapsulamento

- SQL, `namedParams` e `AgentSqlExecuteRequest` ficam encapsulados dentro da
  data layer de `agent_queries`
- nenhuma outra feature deve importar `ResumoParcelaFormaPagamentoSql`
- nenhuma outra feature deve montar payload RPC diretamente

## Correcao de fronteira entre features

## Problema atual

`OverviewRepositoryImpl` depende diretamente de:

- `LoadResumoParcelaFormaPagamentoUseCase`
- `ClientAgentsRepository`
- `LocalAgentClientTokenStore`

Isso faz o `overview` conhecer demais a estrategia de consulta por agente.

## Solucao

`OverviewRepositoryImpl` passara a depender apenas de:

- `OverviewLocalDataSource`
- `ResumoParcelaFormaPagamentoAcrossAgentsRepository`

Com isso:

- a regra de consulta multiagente sai do `overview`
- a feature `overview` volta a ser consumidora
- `agent_queries` vira a feature dona da orquestracao

## Logica compartilhada de nome de agente

### Problema

A regra de `displayName` do agente hoje esta privada em
`OverviewRepositoryImpl`.

### Solucao

Extrair funcao pura para:

- `lib/features/client_agents/domain/client_agent_display_name.dart`

Assinatura sugerida:

```dart
String resolveClientAgentDisplayName(ClientAgent? agent, String fallbackAgentId)
```

Regra:

1. `name`
2. `tradeName`
3. `agentId`

Consumidores:

- `overview`
- `agent_queries`

## Refatoracao do `overview`

## O que sai de `OverviewRepositoryImpl`

- `_loadAllApprovedAgents`
- `_loadResumoQueryResults`
- dependencia direta em `ClientAgentsRepository`
- dependencia direta em `LocalAgentClientTokenStore`
- dependencia direta em `LoadResumoParcelaFormaPagamentoUseCase`
- resolucao interna de sucesso parcial por agente

## O que permanece no `overview`

- agregacao final para KPIs
- ranking por agente
- ranking por usuario
- cache local do overview
- fallback para cache
- copy e comportamento de `OverviewFailureUiKey`
- agregacao final somente de dominio de apresentacao do overview

## Escolha da estrategia pelo `overview`

- 1 agente selecionado: `singleSource`
- nenhum ou varios agentes selecionados: `mergeAll`

### Observacao importante

`race` sera implementado e testado na camada nova, mas nao sera usado pelo
`overview`, porque o `overview` exige agregacao real entre fontes.

## Arquivos que devem ser alterados

## `agent_queries`

- `lib/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart`
- `lib/features/agent_queries/domain/entities/agent_query_key.dart`
- `lib/features/agent_queries/domain/entities/agent_query_execution_strategy.dart`
- `lib/features/agent_queries/domain/entities/agent_query_target.dart`
- `lib/features/agent_queries/domain/entities/agent_query_target_resolution.dart`
- `lib/features/agent_queries/domain/entities/agent_query_plan.dart`
- `lib/features/agent_queries/domain/entities/agent_query_execution_participant.dart`
- `lib/features/agent_queries/domain/entities/agent_query_execution_report.dart`
- `lib/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart`
- `lib/features/agent_queries/data/orchestration/agent_query_target_resolver.dart`
- `lib/features/agent_queries/data/orchestration/agent_query_plan_builder.dart`
- `lib/features/agent_queries/data/orchestration/agent_query_executor.dart`
- `lib/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart`

## `client_agents`

- `lib/features/client_agents/domain/client_agent_display_name.dart`

## `overview`

- `lib/features/overview/data/repositories/overview_repository_impl.dart`
- `lib/core/di/injector_overview.dart`

## `di`

- `lib/core/di/injector_agent_queries.dart`

## `docs`

- este arquivo em `docs/features/`

## Sequencia recomendada de implementacao

## Fase 1: Preparacao de contratos

1. extrair `resolveClientAgentDisplayName`
2. criar enums e entidades do fluxo multiagente
3. criar o contrato `ResumoParcelaFormaPagamentoAcrossAgentsRepository`
4. criar o novo use case multiagente

## Fase 2: Orquestracao

1. implementar `AgentQueryTargetResolver`
2. implementar `AgentQueryPlanBuilder`
3. implementar `AgentQueryExecutor<Row>`
4. implementar o repositorio multiagente de `ResumoParcelaFormaPagamento`

## Fase 3: Integracao com overview

1. trocar dependencias em `injector_overview.dart`
2. refatorar `OverviewRepositoryImpl`
3. remover a logica de consulta multiagente interna ao `overview`
4. manter a agregacao e o cache do `overview`

## Fase 4: Fechamento

1. ajustar logs
2. atualizar testes do `overview`
3. revisar docs de analise em rodada posterior, se desejado

## Estrategia de migracao sem regressao

### Etapa 1: preparar contratos antes da troca do consumidor

- criar contratos novos mantendo o fluxo atual do `overview` intacto
- adicionar testes da camada nova antes de plugar no `overview`

### Etapa 2: conectar `overview` ao contrato novo

- trocar DI primeiro
- adaptar `OverviewRepositoryImpl` para ler do report novo
- manter os asserts funcionais do teste atual do `overview`

### Etapa 3: remover codigo antigo

- apagar apenas depois que os testes equivalentes estiverem verdes
- remover helpers privados do `overview` que virarem duplicacao

### Etapa 4: validar estabilidade

- garantir que os testes do bridge permaneçam verdes
- garantir que o `overview` preserve cache, sucesso parcial e estados de token

## Testes obrigatorios

## Novos testes

- `test/features/client_agents/domain/client_agent_display_name_test.dart`
- `test/features/agent_queries/data/orchestration/agent_query_target_resolver_test.dart`
- `test/features/agent_queries/data/orchestration/agent_query_plan_builder_test.dart`
- `test/features/agent_queries/data/orchestration/agent_query_executor_test.dart`
- `test/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl_test.dart`
- `test/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case_test.dart`

## Testes a atualizar

- `test/features/overview/data/repositories/overview_repository_impl_test.dart`

## Testes que devem continuar verdes

- `test/features/agent_queries/data/datasources/agent_queries_remote_datasource_test.dart`
- `test/features/agent_queries/data/repositories/agent_queries_repository_impl_test.dart`
- `test/integration/e2e/agent_sql_bridge_e2e_test.dart`

## Cenarios de teste

### Resolver

- deve carregar todos os aprovados da conta
- deve respeitar `selectedAgentIds`
- deve marcar agentes sem token local
- deve retornar sucesso vazio quando o filtro nao casar com nenhum aprovado
- deve falhar quando nao houver agentes aprovados

### Planner

- deve validar `singleSource`
- deve aplicar defaults de timeout e `raceMaxSources`
- deve montar o plano certo para `mergeAll`
- deve montar o plano certo para `race`

### Executor

- deve agregar sucessos em `mergeAll`
- deve falhar quando todos falham em `mergeAll`
- deve retornar sucesso vazio quando todos estao sem token
- deve escolher o primeiro sucesso em `race`
- deve ignorar respostas tardias no `race`
- deve preservar ordenacao por `agentId` independentemente da ordem de retorno
- deve manter `rowsByAgentId` completo para todos os agentes considerados

### Repositorio multiagente

- deve reutilizar o fluxo single-agent por alvo
- deve preencher `rowsByAgentId`
- deve preservar nomes e ids de falha parcial
- deve devolver `requiresClientTokenSetup` quando apropriado

### Overview

- deve manter os KPIs agregados
- deve manter `agentIdsExcludedFromQueryFailure`
- deve manter `agentIdsMissingClientToken`
- deve manter fallback em cache para falhas transientes
- deve nao usar cache em `forceRefresh`
- deve continuar exibindo dados consolidados com o mesmo comportamento atual
- deve permanecer sem conhecer timeout, token store e fan-out

## Checklist de robustez da implementacao

- timeout e concorrencia vivem apenas em `agent_queries`
- merge e ordenacao sao deterministas
- `rowsByAgentId` existe mesmo para agentes sem sucesso
- `race` nao e conectado ao `overview`
- `overview` continua dono apenas de cache e agregacao final
- nenhuma feature fora de `agent_queries/data` conhece SQL do agente
- falhas preservam `cause`, `stackTrace` e contexto tecnico
- logs nao expõem `clientToken`

## Logging e observabilidade

Campos minimos por execucao:

- `queryKey`
- `strategy`
- `consideredApprovedAgentCount`
- `plannedTargetCount`
- `winnerAgentId`
- `totalElapsedMs`
- `failedAgentIds`
- `missingClientTokenAgentIds`

Regras:

- nunca logar `clientToken`
- nunca logar PII desnecessaria
- preservar contexto tecnico util

## Criterios de aceite

- `overview` nao depende mais de `ClientAgentsRepository`
- `overview` nao depende mais de `LocalAgentClientTokenStore`
- `overview` nao depende mais de `LoadResumoParcelaFormaPagamentoUseCase`
- `agent_queries` vira a feature dona da orquestracao multiagente
- `singleSource`, `mergeAll` e `race` ficam implementados e testados
- `overview` usa apenas `singleSource` e `mergeAll`
- nenhum consumidor fora de `agent_queries/data` monta SQL bruto
- o comportamento funcional atual do `overview` continua equivalente
- a ordenacao dos resultados fica deterministica
- os testes do bridge SQL continuam verdes
- a camada nova devolve report tipado com metadados completos por participante

## Defaults e assumptions fechados

- `bridgeTimeoutMs` default: `120000`
- concorrencia em `mergeAll`: `4`
- `raceMaxSources` default: `4`
- criterio de vitoria em `race`: primeiro sucesso
- `offline` e `unknown` sao apenas observabilidade nesta rodada
- filtro sem agente aprovado correspondente retorna sucesso vazio
- `reports` continua fora do escopo desta rodada

## Observacao final

Este plano foi fechado para permitir implementacao direta, sem deixar decisoes
em aberto para o executor. Se a proxima etapa for implementacao, a ordem mais
segura e iniciar pelos contratos novos, depois pela orquestracao, e por fim
pela refatoracao do `overview`.

## Roteiro executavel

Esta secao transforma o plano em uma sequencia pratica de implementacao.

## Sequencia sugerida por commit

## Commit 1: base de contratos e funcao compartilhada

Objetivo:

- preparar tipos estaveis antes de tocar no `overview`

Arquivos novos:

- `lib/features/client_agents/domain/client_agent_display_name.dart`
- `lib/features/agent_queries/domain/entities/agent_query_key.dart`
- `lib/features/agent_queries/domain/entities/agent_query_execution_strategy.dart`
- `lib/features/agent_queries/domain/entities/agent_query_target.dart`
- `lib/features/agent_queries/domain/entities/agent_query_target_resolution.dart`
- `lib/features/agent_queries/domain/entities/agent_query_plan.dart`
- `lib/features/agent_queries/domain/entities/agent_query_execution_participant.dart`
- `lib/features/agent_queries/domain/entities/agent_query_execution_report.dart`
- `lib/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart`

Arquivos de teste:

- `test/features/client_agents/domain/client_agent_display_name_test.dart`

Definition of done:

- todos os tipos novos compilam
- a funcao de `displayName` cobre `name`, `tradeName` e fallback para `agentId`
- nenhum arquivo do `overview` foi alterado ainda

## Commit 2: use case publico e wiring inicial de DI

Objetivo:

- expor o contrato novo para uso futuro sem ainda trocar o consumidor

Arquivos novos:

- `lib/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart`

Arquivos alterados:

- `lib/core/di/injector_agent_queries.dart`

Arquivos de teste:

- `test/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case_test.dart`

Observacao:

- o wiring final de DI desta etapa depende do repositorio concreto do commit 6

Definition of done:

- o use case novo existe e esta testado
- o wiring final no DI sera concluido junto com o repositorio concreto
- ainda nao existe efeito funcional no `overview`

## Commit 3: resolver de agentes aprovados e tokens locais

Objetivo:

- mover a resolucao de agentes para `agent_queries`

Arquivos novos:

- `lib/features/agent_queries/data/orchestration/agent_query_target_resolver.dart`

Arquivos de teste:

- `test/features/agent_queries/data/orchestration/agent_query_target_resolver_test.dart`

Responsabilidades implementadas:

- paginacao de agentes aprovados
- filtro por `selectedAgentIds`
- leitura de tokens locais em lote
- ordenacao deterministica por `agentId`
- mapeamento de `displayName`

Definition of done:

- o resolver retorna `ValidationFailure` quando nao ha agentes aprovados
- o resolver retorna sucesso vazio quando o filtro nao encontra aprovados
- agentes sem token ficam separados corretamente

## Commit 4: planner de estrategia

Objetivo:

- centralizar validacao de `singleSource`, `mergeAll` e `race`

Arquivos novos:

- `lib/features/agent_queries/data/orchestration/agent_query_plan_builder.dart`

Arquivos de teste:

- `test/features/agent_queries/data/orchestration/agent_query_plan_builder_test.dart`

Definition of done:

- defaults de timeout e `raceMaxSources` estao aplicados
- `singleSource` exige exatamente um agente considerado
- `mergeAll` e `race` ficam validados em unidade propria

## Commit 5: executor multiagente

Objetivo:

- centralizar fan-out, merge, `race`, tempos e degradacao parcial

Arquivos novos:

- `lib/features/agent_queries/data/orchestration/agent_query_executor.dart`

Arquivos de teste:

- `test/features/agent_queries/data/orchestration/agent_query_executor_test.dart`

Responsabilidades implementadas:

- `executeSingleSource`
- `executeMergeAll`
- `executeRace`
- ordenacao deterministica
- report final por participante

Definition of done:

- `mergeAll` agrega sucessos e preserva falhas
- `mergeAll` falha quando todos falham
- `race` escolhe o primeiro sucesso
- respostas tardias em `race` sao descartadas logicamente

## Commit 6: repositorio multiagente tipado de resumo

Objetivo:

- ligar resolver, planner e executor ao fluxo ja existente de `Resumo`

Arquivos novos:

- `lib/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart`

Arquivos alterados:

- `lib/core/di/injector_agent_queries.dart`

Arquivos de teste:

- `test/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl_test.dart`

Responsabilidades implementadas:

- reutilizar `LoadResumoParcelaFormaPagamentoUseCase` por agente
- preencher `rowsByAgentId`
- preencher falhas parciais
- preencher estados de token ausente

Definition of done:

- o repositorio novo funciona isoladamente
- o bridge single-agent nao foi alterado
- os testes antigos de `agent_queries` continuam verdes

## Commit 7: troca do consumidor no overview

Objetivo:

- remover do `overview` a responsabilidade de consulta multiagente

Arquivos alterados:

- `lib/features/overview/data/repositories/overview_repository_impl.dart`
- `lib/core/di/injector_overview.dart`

Arquivos de teste:

- `test/features/overview/data/repositories/overview_repository_impl_test.dart`

Mudancas esperadas:

- remover dependencia direta em `ClientAgentsRepository`
- remover dependencia direta em `LocalAgentClientTokenStore`
- remover dependencia direta em `LoadResumoParcelaFormaPagamentoUseCase`
- usar `ResumoParcelaFormaPagamentoAcrossAgentsRepository`
- manter cache, fallback e agregacao final

Definition of done:

- comportamento do `overview` permanece equivalente
- os testes do `overview` validam a nova integracao

## Commit 8: limpeza, logs e consolidacao

Objetivo:

- remover codigo morto e fechar observabilidade

Arquivos alterados:

- `lib/features/overview/data/repositories/overview_repository_impl.dart`
- arquivos de orquestracao em `agent_queries`
- docs relacionadas, se a rodada incluir atualizacao analitica

Itens:

- remover helpers privados obsoletos do `overview`
- revisar logs para nao expor `clientToken`
- revisar nomes e comentarios
- validar consistencia final da camada

Definition of done:

- nao sobra logica de consulta multiagente no `overview`
- logs estao consistentes
- a feature nova esta coesa e sem duplicacao

## Mapa de implementacao por arquivo

## Novos arquivos obrigatorios

### `lib/features/client_agents/domain/client_agent_display_name.dart`

Implementar:

- funcao pura para resolver o nome de exibicao do agente

### `lib/features/agent_queries/domain/entities/agent_query_key.dart`

Implementar:

- enum de chaves tipadas de consulta

### `lib/features/agent_queries/domain/entities/agent_query_execution_strategy.dart`

Implementar:

- enum de estrategia de execucao

### `lib/features/agent_queries/domain/entities/agent_query_target.dart`

Implementar:

- alvo de execucao por agente

### `lib/features/agent_queries/domain/entities/agent_query_target_resolution.dart`

Implementar:

- resultado da resolucao de agentes aprovados e tokens

### `lib/features/agent_queries/domain/entities/agent_query_plan.dart`

Implementar:

- plano final de execucao multiagente

### `lib/features/agent_queries/domain/entities/agent_query_execution_participant.dart`

Implementar:

- resultado individual por agente participante

### `lib/features/agent_queries/domain/entities/agent_query_execution_report.dart`

Implementar:

- report consolidado da execucao

### `lib/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart`

Implementar:

- contrato cross-feature para consumo por `overview`

### `lib/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart`

Implementar:

- use case fino sobre o repositorio multiagente

### `lib/features/agent_queries/data/orchestration/agent_query_target_resolver.dart`

Implementar:

- carregamento de agentes aprovados
- filtro por selecao
- leitura de token local

### `lib/features/agent_queries/data/orchestration/agent_query_plan_builder.dart`

Implementar:

- validacao e montagem do plano por estrategia

### `lib/features/agent_queries/data/orchestration/agent_query_executor.dart`

Implementar:

- execucao `singleSource`
- execucao `mergeAll`
- execucao `race`

### `lib/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart`

Implementar:

- composicao entre resolver, planner, executor e fluxo single-agent

## Arquivos existentes a alterar

### `lib/core/di/injector_agent_queries.dart`

Alterar para:

- registrar colaboradores de orquestracao
- registrar o repositorio multiagente
- registrar o novo use case

### `lib/core/di/injector_overview.dart`

Alterar para:

- remover injeção de `ClientAgentsRepository`
- remover injeção de `LocalAgentClientTokenStore`
- remover injeção de `LoadResumoParcelaFormaPagamentoUseCase`
- injetar `ResumoParcelaFormaPagamentoAcrossAgentsRepository`

### `lib/features/overview/data/repositories/overview_repository_impl.dart`

Alterar para:

- consumir o report multiagente
- manter cache e agregacao final
- remover logica de resolucao e fan-out

## Ordem de execucao recomendada para o implementador

1. implementar os contratos e a funcao compartilhada
2. implementar testes da base nova
3. implementar resolver
4. implementar planner
5. implementar executor
6. implementar repositorio multiagente
7. registrar DI novo
8. refatorar `overview`
9. remover codigo antigo
10. rodar a bateria de testes relevante

## Bateria minima de verificacao

- `test/features/client_agents/domain/client_agent_display_name_test.dart`
- `test/features/agent_queries/data/orchestration/agent_query_target_resolver_test.dart`
- `test/features/agent_queries/data/orchestration/agent_query_plan_builder_test.dart`
- `test/features/agent_queries/data/orchestration/agent_query_executor_test.dart`
- `test/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl_test.dart`
- `test/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case_test.dart`
- `test/features/overview/data/repositories/overview_repository_impl_test.dart`
- `test/features/agent_queries/data/repositories/agent_queries_repository_impl_test.dart`
- `test/features/agent_queries/data/datasources/agent_queries_remote_datasource_test.dart`
- `test/integration/e2e/agent_sql_bridge_e2e_test.dart` quando houver ambiente

## Riscos de implementacao e mitigacao

### Risco: quebrar o comportamento do overview

Mitigacao:

- manter testes atuais do `overview`
- trocar o consumidor apenas depois do repositorio multiagente estar coberto

### Risco: duplicar regra de nome de agente

Mitigacao:

- extrair a funcao compartilhada antes de criar o resolver

### Risco: misturar responsabilidades entre feature e consumer

Mitigacao:

- fan-out, timeout e merge ficam em `agent_queries`
- cache e apresentacao final continuam no `overview`

### Risco: race contaminar cenarios de agregacao

Mitigacao:

- implementar `race`, mas nao conectar ao `overview`

### Risco: regressao no bridge SQL

Mitigacao:

- nao tocar nos contratos do bridge alem do necessario
- preservar os testes de payload e normalizacao
