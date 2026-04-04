# Consulta Multi-Agente Para Relatorios e Graficos

## Objetivo

Este documento detalha a proxima camada evolutiva do Colmeia: usar os agentes aprovados do cliente como fontes reais de consulta para alimentar dashboards, graficos e relatorios.

## Estado atual resumido

Hoje o projeto ja possui:

- autenticacao e sessao
- contexto de usuario
- dashboards consumindo API central
- widgets compartilhados para relatorios
- manutencao de agentes do cliente

### Status

- `implementado`: manutencao de agentes do cliente
- `implementado`: dashboards com integracao real inicial fora da camada de agentes
- `implementado`: componentes compartilhados de relatorio para reuso
- `planejado`: feature `agent_queries`
- `planejado`: consultas `single-source`
- `planejado`: consultas `multi-source race`

O passo seguinte e criar a camada de **execucao de consultas por agente**, mantendo a arquitetura atual do app e preparando suporte a consulta em uma unica fonte ou em varias fontes ao mesmo tempo.

## Papel da nova camada

Essa nova camada deve ficar entre a presentation de dashboards/relatorios e a infraestrutura de agentes.

Ela sera responsavel por:

- decidir quais agentes aprovados podem atender uma consulta
- montar o payload da consulta
- despachar a consulta para um ou mais agentes
- controlar timeout, erros e cancelamento
- consolidar respostas
- devolver um resultado normalizado para a UI

### Referencias de codigo relacionadas

- `lib/features/client_agents/`
- `lib/features/dashboards/`
- `lib/shared/widgets/reports/`
- `lib/core/network/app_dio_client.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/cache/app_cache_store.dart`

## Modelo conceitual

### Componentes principais

- `AgentQueryRequest`: representa a consulta que o app quer executar
- `AgentQueryTarget`: representa um agente elegivel para a consulta
- `AgentQueryPlan`: plano de execucao indicando se a consulta sera simples ou multi-agente
- `AgentQueryResult`: resultado normalizado de uma consulta
- `AgentQueryFailure`: falha tipada para erros de consulta

### Tipos de consulta

O desenho deve comecar com dois modos explicitos:

- `single-source query`: usa um agente especifico
- `multi-source race query`: envia a mesma consulta para varios agentes em paralelo

Isso evita ambiguidade no comportamento do sistema.

## Fluxo recomendado

### Fluxo macro

1. a UI pede dados para um dashboard ou relatorio
2. a camada de aplicacao monta uma `AgentQueryRequest`
3. o sistema resolve os agentes aprovados e elegiveis
4. um `planner` escolhe a estrategia de execucao
5. um executor dispara a consulta
6. os resultados retornam em formato bruto
7. um mapper normaliza o payload
8. a feature consumidora transforma o resultado em KPIs, series, linhas ou tabelas

## Onde isso encaixa na arquitetura atual

### Domain

Deve concentrar:

- entidades de consulta
- regras de elegibilidade
- contratos dos repositorios
- definicao de estrategias

### Application

Deve concentrar:

- casos de uso de consulta
- orquestracao entre resolver agentes, planejar e executar
- consolidacao final para a feature chamadora

### Data

Deve concentrar:

- datasource remoto para endpoint de query de agentes
- datasource local para snapshots e metadados de execucao quando fizer sentido
- DTOs de request e response
- mapeamento de payload tecnico para modelos internos

### Presentation

Deve continuar somente com:

- estado visual
- filtros
- carregamento
- renderizacao do resultado

## Estrutura sugerida de feature

Uma organizacao inicial coerente seria algo como:

```text
lib/features/agent_queries/
  presentation/
  application/
    usecases/
      execute_agent_query_use_case.dart
      preview_agent_query_plan_use_case.dart
  domain/
    entities/
      agent_query_request.dart
      agent_query_plan.dart
      agent_query_result.dart
      agent_query_target.dart
    repositories/
      agent_query_repository.dart
    services/
      agent_query_strategy.dart
  data/
    datasources/
      agent_query_remote_datasource.dart
    models/
      agent_query_request_dto.dart
      agent_query_response_dto.dart
    repositories/
      agent_query_repository_impl.dart
```

## Contrato de entrada recomendado

A consulta precisa ser desacoplada de uma tela especifica. O request deve representar a intencao analitica, nao o componente visual.

Exemplo conceitual:

```dart
class AgentQueryRequest {
  const AgentQueryRequest({
    required this.queryKey,
    required this.metricKeys,
    required this.filters,
    required this.allowedAgentIds,
    this.storeId,
    this.timeRange,
    this.maxSources,
    this.strategy = AgentQueryExecutionStrategy.single,
  });

  final String queryKey;
  final Set<String> metricKeys;
  final Map<String, Object?> filters;
  final Set<String> allowedAgentIds;
  final String? storeId;
  final DateTimeRange? timeRange;
  final int? maxSources;
  final AgentQueryExecutionStrategy strategy;
}
```

## Contrato de saida recomendado

O retorno nao deve nascer acoplado a um grafico especifico. Ele deve carregar um formato intermediario reutilizavel.

Exemplo conceitual:

```dart
class AgentQueryResult {
  const AgentQueryResult({
    required this.queryKey,
    required this.respondedAgentIds,
    required this.rows,
    required this.summary,
    required this.metadata,
    this.winnerAgentId,
    this.completedAt,
  });

  final String queryKey;
  final Set<String> respondedAgentIds;
  final List<Map<String, Object?>> rows;
  final Map<String, Object?> summary;
  final Map<String, Object?> metadata;
  final String? winnerAgentId;
  final DateTime? completedAt;
}
```

## Estrategia `RACE`

### Quando usar

A estrategia `RACE` faz sentido quando:

- a mesma consulta pode ser atendida por mais de um agente
- qualquer uma das respostas atende o objetivo do usuario
- a prioridade e reduzir tempo de resposta percebido

### Quando nao usar

Ela nao deve ser usada quando:

- a consulta precisa agregar dados de varias fontes obrigatoriamente
- cada agente responde apenas uma parte do resultado
- a origem precisa ser deterministicamente escolhida por regra de negocio

### Comportamento recomendado

Na primeira versao, a estrategia `RACE` deve ser simples:

- enviar a mesma consulta para todos os agentes elegiveis
- aceitar o primeiro resultado valido
- cancelar ou ignorar os demais requests
- registrar quem venceu a corrida
- registrar quais agentes falharam ou expiraram

### Evolucao futura

Depois, se necessario, pode haver outras estrategias:

- `fastest-success`
- `quorum`
- `merge-all`
- `best-quality`

Mas isso nao deve entrar antes da necessidade real.

## Decisoes abertas

Antes da implementacao, ainda e preciso definir:

- endpoint real da consulta por agente
- formato do payload da consulta
- como `queryKey` mapeia para um tipo de consulta
- criterio exato de vitoria no `RACE`
- quando cancelar requisicoes remanescentes
- se resultados parciais podem ser expostos para a UI
- quando `offline` impede elegibilidade e quando e apenas sinal informativo

## Resolver de agentes elegiveis

Antes de consultar, o sistema precisa resolver quais agentes podem participar da operacao.

Essa resolucao deve considerar:

- agente esta aprovado para a conta
- agente esta ativo no catalogo
- agente esta operacionalmente online quando isso for obrigatorio
- agente atende ao tipo de consulta solicitada
- agente esta dentro de qualquer escopo exigido pela consulta

## Politica de degradacao

Nem toda consulta precisa falhar integralmente quando um agente fica indisponivel.

A camada deve prever:

- falha total quando nenhum agente elegivel puder responder
- sucesso com degradacao quando ao menos um agente responder
- metadados de observabilidade para mostrar origem, timeout e fallback

## Tipos de erro recomendados

Convem tipar melhor as falhas para evitar mensagens genericas.

Exemplos:

- `NoEligibleAgentFailure`
- `AllAgentsTimedOutFailure`
- `AgentQueryUnauthorizedFailure`
- `AgentQueryBadPayloadFailure`
- `AgentQueryPartialFailure`
- `AgentQueryMappingFailure`

## Observabilidade

Como a camada multi-agente tera concorrencia e fallback, observabilidade sera essencial.

Cada execucao deveria registrar:

- `queryKey`
- quantidade de agentes elegiveis
- ids dos agentes consultados
- agente vencedor
- duracao total
- duracao por agente
- timeout por agente
- falhas por agente
- modo de execucao usado

Isso ajuda em tuning, suporte e diagnostico.

## Matriz de riscos e mitigacao

| Risco                                            | Impacto                     | Mitigacao sugerida                                                     |
| ------------------------------------------------ | --------------------------- | ---------------------------------------------------------------------- |
| Usar `RACE` onde a consulta exige agregacao real | resultado incorreto         | limitar `RACE` aos casos em que qualquer agente pode responder sozinho |
| Contrato muito acoplado ao grafico               | pouca reutilizacao          | manter resultado normalizado e intermediario                           |
| Timeout agressivo demais                         | erro artificial e baixa UX  | configurar timeout por agente e timeout global separadamente           |
| Falta de elegibilidade clara                     | consultas em fontes erradas | criar resolver de agentes elegiveis por `queryKey`                     |
| Falta de observabilidade por agente              | depuracao dificil           | registrar duracao, falha e vencedor por agente                         |

## Reuso da infraestrutura atual

Essa nova camada deve reaproveitar o que o projeto ja possui.

### HTTP

Usar o mesmo `Dio` ja configurado com:

- `AppDioClient`
- `AuthInterceptor`
- refresh automatico de token
- logging padrao

### Cache

Quando fizer sentido guardar resultados de leitura, reaproveitar:

- `AppCacheStore`
- `HiveAppCacheStore`
- padrao de cache por chave logica e TTL por recurso

### Erros

Manter o padrao atual:

- `AppResult<T>`
- `AppFailure`
- `mapToAppFailure`

### Injecao de dependencia

Registrar tudo no `GetIt`, seguindo o padrao dos outros modulos.

## Como conectar com dashboards

Hoje dashboards consomem `GET /dashboards/overview`.

Na evolucao orientada a agentes, o caminho mais seguro e nao quebrar isso de imediato. Em vez disso:

1. manter o dashboard overview atual
2. criar um dashboard ou widget piloto alimentado por consulta a agentes
3. validar contrato, latencia e consolidacao
4. expandir gradualmente para outros widgets

Isso reduz risco de regressao.

## Como conectar com relatorios

O projeto ja tem infraestrutura visual de relatorios em `lib/shared/widgets/reports/`, mesmo com o modulo de relatorios fora da navegacao principal.

A camada de consulta multi-agente deve ser pensada para abastecer:

- `rows`
- `summaryItems`
- `pageInfo`
- `filters`
- `query`

ou seja, o contrato de dados precisa conversar bem com o `AppReportViewer`.

## Paginacao e filtros

Se relatorios forem alimentados por agentes, a regra precisa ser clara:

- preferir paginacao e filtro no servidor/agente sempre que disponivel
- evitar trazer volume grande para paginar no app
- definir como filtros dinamicos sao traduzidos para o payload da consulta

## Contrato de traducao de filtros

Vale criar uma camada explicita para transformar filtros de UI em filtros de consulta.

Exemplo conceitual:

```dart
abstract interface class AgentQueryFilterMapper {
  Map<String, Object?> map({
    required String queryKey,
    required Map<String, Object?> uiFilters,
  });
}
```

Isso impede que widgets e controllers conhecam o formato do backend/agente.

## Timeout e cancelamento

Como ha concorrencia, a camada precisa ter regra clara de timeout.

Recomendacoes:

- timeout por agente
- timeout global da consulta
- cancelamento dos requests restantes ao obter sucesso em `RACE`
- registro do motivo do cancelamento

## Cache de resultados de consulta

Nao e necessario comecar com cache forte de resultados multi-agente. O ideal e um inicio controlado.

### O que pode valer a pena cachear

- ultimo resultado por `queryKey`
- metadados de ultima execucao bem-sucedida
- agente vencedor mais recente por contexto

### O que evitar no inicio

- merge complexo offline
- reconciliacao de respostas parciais
- snapshots pesados demais

## Interface de repositorio sugerida

Exemplo conceitual:

```dart
abstract interface class AgentQueryRepository {
  Future<AppResult<AgentQueryPlan>> previewPlan({
    required String userId,
    required AgentQueryRequest request,
  });

  Future<AppResult<AgentQueryResult>> execute({
    required String userId,
    required AgentQueryRequest request,
  });
}
```

## Sequencia recomendada de implementacao

### Fase 1

- criar entidades e contratos da feature `agent_queries`
- criar datasource remoto
- criar executor `single-source`
- retornar resultado normalizado simples

### Fase 2

- adicionar `multi-source race`
- incluir timeout por agente
- incluir observabilidade da corrida
- incluir cancelamento dos requests restantes

### Fase 3

- integrar com um dashboard piloto
- integrar com um relatorio piloto
- validar payloads e performance

### Fase 4

- adicionar cache seletivo
- evoluir estrategia para consolidacao quando necessario
- habilitar comparativos multi-fonte mais ricos

## Roadmap tecnico por entregavel

### Piloto 1

- primeiro KPI alimentado por consulta `single-source`

### Piloto 2

- primeiro grafico alimentado por consulta `single-source`

### Piloto 3

- primeiro relatorio alimentado por consulta `single-source`

### Piloto 4

- primeira consulta `multi-source race` com observabilidade completa

## Riscos

Os principais riscos dessa camada sao:

- acoplamento precoce a um tipo de grafico
- trazer dados demais para consolidar no app
- usar `RACE` em cenarios que exigem agregacao real
- falta de metadados para descobrir a origem vencedora
- timeouts mal configurados degradando experiencia
- regras pouco claras de elegibilidade de agente

## Recomendacao final

O melhor caminho e tratar consultas por agentes como uma feature propria, com contratos claros e evolucao incremental.

Primeiro:

- consulta simples
- payload normalizado
- observabilidade forte

Depois:

- concorrencia `RACE`
- integracao com relatorios e dashboards
- estrategias mais avancadas apenas se houver caso real

## Documentos relacionados

- `docs/analysis/agentes_como_fontes_de_dados.md`
- `docs/analysis/plano_evolucao_agentes_relatorios_dashboards.md`

## Conclusao

Os agentes ja resolveram a parte de manutencao e autorizacao operacional no app. A proxima etapa e transformar esse ativo em uma camada de consulta reutilizavel, capaz de atender dashboards e relatorios sem acoplar a presentation a detalhes de infraestrutura.

Com isso, o Colmeia passa a ter um caminho claro para analise multi-fonte, melhorando flexibilidade, desempenho e capacidade de crescimento do produto.
