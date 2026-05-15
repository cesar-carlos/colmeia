# Plano — Canal Socket (`/consumers`) para `agent_queries`

> Contrato atual de socket/relay para Colmeia:
> [`../../plug_server_docs_index_for_colmeia.md`](../../plug_server_docs_index_for_colmeia.md)
> e [`../../bridge_agent_sql_api_options.md`](../../bridge_agent_sql_api_options.md).

> Status: **em execução, código em estado de handoff**. Tudo da Fase 1
> (PR-A → PR-J: conexão, dispatcher, lifecycle, métricas, jitter,
> concurrency gate, coalescing, adaptive timeout, batch coordinator,
> cancel token) + Fase 2 (PR-K PayloadFrame, PR-L relay primitives,
> PR-L+ p1 selector, p2 streaming, p3 streaming datasource, p3.5
> collector + adapter, PR-M p1/p2/p3 presença em 3 camadas) +
> Fase 2.5 (smokes e2e com `SELECT 1` removidos — política do banco; ver §0.2.1) +
> auditoria de boot (B1 flash de login no cold start, B2 race do warm-up,
> S1 `connection` nullable quando `socketRelayEnabled` é falso, S2 sign-out
> só pausa socket quando `connection` não nula) +
> auditoria de error handling (#1 mapeamento de `RelayDispatchException`,
> #2 widening de auth-like codes em socket+relay, #2b cancelled benign,
> #3 race total timeout defensivo, #4 propagação de `RpcFailure.userMessage`
> pros gráficos opcionais do overview)
> entregues.
>
> **Pendências remanescentes** (todas operacionais ou esperando
> insumo externo):
>
> 1. **Servidor**: aplicar `SOCKET_CONSUMER_ROLES=user,admin,client`
>    no `plug_server` (descoberta do primeiro smoke — ver §0.2.1).
> 2. **Decisão de produto**: identificar a primeira query do
>    `overview` para PR-L+ p4 (swap de DI trivial usando o adapter
>    do PR-L+ p3.5).
> 3. **PR-N** (Hybrid REST↔Socket fallback) — Fase 3, só com baseline
>    P0 confirmando ganho.
> 4. **P3** (gzip async via `compute(...)`, dedup pós-reconexão,
>    OTel propagation) — Fase 3.
>    Autor: planejamento orientado por análise da base atual + docs do `plug_server`.
>    Documentos-fonte do hub:
>
> - `plug_server/docs/socket_relay_protocol.md`
> - `plug_server/docs/socket_client_sdk.md`
> - `plug_server/docs/api_rest_bridge.md`
> - `plug_server/docs/client_agent_business_rules.md`
> - `plug_server/docs/performance_hub_agent.md`
> - resumo local: `docs/plug_server_docs_index_for_colmeia.md`,
>   `docs/bridge_agent_sql_api_options.md`

> **Documentos companheiros (designs técnicos detalhados):**
>
> - `docs/Features/consumer_socket_connection_design.md` — conexão única,
>   handshake, refresh, reconexão com backoff e jitter.
> - `docs/Features/socket_command_dispatcher_design.md` — envio de comandos,
>   correlação por `rpcId`, `Stream<AgentCommandOutcome>`, mapeamento de erros.
> - `docs/Features/agent_presence_realtime_design.md` — presença de agente em
>   tempo real (push de catálogo + hints + polling adaptativo).
> - `docs/Features/socket_channel_performance_review.md` — review de
>   desempenho com 10 melhorias priorizadas, matriz de transporte e
>   estratégia de medição antes/depois.

---

## 0. Estado de implementação (snapshot atual)

> Atualizado após PR-J (cancel token) + auditoria completa de
> consistência doc↔código. Use como índice rápido — cada item aponta
> para a seção/PR onde o trabalho aconteceu.

### 0.1 Já em produção (Fase 1.0 + 1.1 + 1.2 + PR-K + PR-L + PR-L+ + PR-M)

| Pacote                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Caminho                                                                                                                                                                                                                                                                                                                                                                          | Origem              |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| Conexão única ao `/consumers` (single-flight + backoff jitter + auth refresh)                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `lib/core/socket/consumer_socket_connection.dart`, `socket_reconnect_backoff.dart`, `connection_ready_payload.dart`, `socket_io_client_factory.dart`, `app_socket_url_resolver.dart`, `socket_auth_token_provider.dart`                                                                                                                                                          | PR-A, PR-E (jitter) |
| Dispatcher `agents:command` + correlator + outcomes sealed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `lib/core/socket/socket_command_dispatcher.dart` (port), `socket_command_dispatcher_impl.dart`, `socket_request_correlator.dart`, `agent_command_outcome.dart`, `socket_dispatch_exception.dart`                                                                                                                                                                                 | PR-B                |
| Body mapper compartilhado REST↔Socket                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `lib/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart` + datasource `socket_agent_queries_remote_datasource.dart`                                                                                                                                                                                                                                       | PR-B                |
| App lifecycle hook (`pause`/`resume`) + warm-up no login                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `lib/app/bootstrap.dart` + `LoginUseCase` integration                                                                                                                                                                                                                                                                                                                            | PR-C                |
| Telemetria (handshake_ms, dispatch_ms, outcomes, inflight_peak, reconnects)                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `lib/core/observability/socket/socket_channel_metrics.dart`, `socket_metrics_listener.dart`, `socket_metrics_snapshot.dart`                                                                                                                                                                                                                                                      | PR-D                |
| Per-agent concurrency gate                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `lib/core/socket/per_agent_concurrency_gate.dart` (gated por `SOCKET_MAX_INFLIGHT_PER_AGENT`)                                                                                                                                                                                                                                                                                    | PR-F                |
| Request coalescing (key estável)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `lib/core/socket/socket_coalesce_key.dart` + integração no dispatcher impl (`SOCKET_COALESCING_ENABLED`)                                                                                                                                                                                                                                                                         | PR-G                |
| Adaptive timeout (EWMA por `(agentId, method)`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `lib/core/socket/agent_latency_oracle.dart` (gated por `SOCKET_TIMEOUT_ADAPTIVE_ENABLED`)                                                                                                                                                                                                                                                                                        | PR-H                |
| Batch coordinator (`command: [...]`, max 32)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `lib/core/socket/agent_command_batch_coordinator.dart` + `agent_command_sender.dart` (port) + `direct_agent_command_sender.dart` (gated por `SOCKET_BATCH_ENABLED`)                                                                                                                                                                                                              | PR-I                |
| Cancel token (cancela pendentes em `dispose()` de controllers) — `dispatcher.cancel(rpcId, reason)` + sealed `SocketDispatchCancelled` + helper `SocketCommandCancelToken` (register/unregister/cancelAll/dispose)                                                                                                                                                                                                                                                                                                                            | `lib/core/socket/socket_command_cancel_token.dart` + delta em `socket_command_dispatcher.dart` (port) / `socket_command_dispatcher_impl.dart` / `socket_dispatch_exception.dart`                                                                                                                                                                                                 | PR-J                |
| **PayloadFrame** envelope + codec (auto-gzip + limites 10 MiB / 10x)                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `lib/core/socket/payload_frame.dart`, `payload_frame_codec.dart`                                                                                                                                                                                                                                                                                                                 | PR-K                |
| **`connection:ready` em PayloadFrame** + compat decoder (gated por `SOCKET_CONNECTION_READY_COMPAT_MODE`)                                                                                                                                                                                                                                                                                                                                                                                                                                     | `lib/core/socket/connection_ready_payload.dart` (`PayloadFrameConnectionReadyDecoder`, `CompatConnectionReadyDecoder`), `lib/core/config/connection_ready_compat_mode.dart`                                                                                                                                                                                                      | PR-K                |
| **Relay primitives** (conversation, dispatcher unitário, exceptions sealed, outcomes)                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `lib/core/socket/relay/` (`relay_event_names.dart`, `relay_dispatch_exception.dart`, `relay_conversation_state.dart`, `relay_conversation.dart`, `relay_conversation_manager.dart`, `relay_command_dispatcher.dart`, `relay_command_dispatcher_impl.dart`, `relay_rpc_outcome.dart`)                                                                                             | PR-L                |
| **Relay datasource** (standalone) reusando o body REST                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `lib/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart`                                                                                                                                                                                                                                                                                         | PR-L                |
| **Per-query selector** `useRelay` em `AgentSqlExecuteRequest` (default `false`, **não** vai para o body)                                                                                                                                                                                                                                                                                                                                                                                                                                      | `lib/features/agent_queries/domain/entities/agent_sql_execute_request.dart`                                                                                                                                                                                                                                                                                                      | PR-L+ p1            |
| **Hybrid datasource** (`useRelay==true` ➜ relay; senão base REST/`agents:command`; loga `relay_bypass` quando relay não está disponível)                                                                                                                                                                                                                                                                                                                                                                                                      | `lib/features/agent_queries/data/datasources/hybrid_agent_queries_remote_datasource.dart` + auto-wrap no `injector_agent_queries.dart` quando `RelayCommandDispatcher` está registrado                                                                                                                                                                                           | PR-L+ p1            |
| **Streaming via `sendStreaming(...)`** com auto-pull rolante (`relay:rpc.stream.pull` granted on accept + refill on threshold) e tolerância a `relay:rpc.response` (single-chunk + close)                                                                                                                                                                                                                                                                                                                                                     | `lib/core/socket/relay/relay_command_dispatcher.dart` (port) + `relay_command_dispatcher_impl.dart` (refatorado em sealed `_PendingRelay` ↔ `_PendingUnary` / `_PendingStream`); envs `SOCKET_RELAY_STREAM_INITIAL_WINDOW` e `SOCKET_RELAY_STREAM_REFILL_THRESHOLD`                                                                                                              | PR-L+ p2            |
| **Streaming na camada de dados** — port `AgentQueriesStreamingRemoteDataSource` (separado do unary por ISP) + impl `RelayStreamingAgentQueriesRemoteDataSource` reusando `AgentSqlExecuteRequestToBridgeBody` (body byte-igual ao REST). Auto-wire no `injector_agent_queries.dart` apenas quando `RelayCommandDispatcher` está registrado. Pronto pra integrar no `AgentQueryExecutor` numa sub-PR seguinte assim que identificarmos a primeira query do `overview` que materializa muitos rows.                                             | `lib/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart` + `relay_streaming_agent_queries_remote_datasource.dart` + delta no `injector_agent_queries.dart`                                                                                                                                                                                   | PR-L+ p3            |
| **Collector + adapter** — `RelayCommandDispatcherImpl` agora forwarda o payload de `relay:rpc.complete` como item final do stream (sem isso o collector perderia `total_rows`/`execution_id`/`started_at`/`finished_at`). `BridgeShapedSqlExecuteCollector` agrega chunks em um `Map` no shape do `AgentSqlBridgeResponse.parseSuccess`. `CollectingRelayStreamingAgentQueriesRemoteDataSource` implementa o port unitário via streaming + collector — qualquer repository pode opt-in com 1 swap de DI, **sem** mexer no executor nem na UI. | `lib/features/agent_queries/data/streaming_sql_execute_collector.dart` + `lib/features/agent_queries/data/datasources/collecting_relay_streaming_agent_queries_remote_datasource.dart` + delta em `lib/core/socket/relay/relay_command_dispatcher_impl.dart`                                                                                                                     | PR-L+ p3.5          |
| **Presença em tempo real (Camadas 1+2)** — sealed `AgentPresenceEvent` (`CatalogUpdated`, `Hint`) + port `AgentPresenceStream` + `ObserveAgentPresenceUseCase` + adapters Socket (`ClientAgentProfileUpdatedListener` para `client:agent.profile.updated`, `AgentCommandPresenceHinter` para outcomes de `agents:command`) + composer `SocketAgentPresenceStream` (re-attach automático em reconnect)                                                                                                                                         | `lib/features/client_agents/{domain/events,domain/ports,application/usecases,data/socket}/` + auto-wire no `injector_client_agents.dart` (gated por `SOCKET_PRESENCE_LISTENER_ENABLED`)                                                                                                                                                                                          | PR-M p1             |
| **Wire-up no `ClientAgentsController`** — subscription opcional via `ObserveAgentPresenceUseCase?` (default `null` mantém UX legada); dedup por `observedAt`; `AgentPresenceCatalogUpdated` ➜ `LoadClientAgentDetailUseCase` + `_upsertApprovedAgentsInMemory`; `AgentPresenceHint` ➜ `copyWith(connectionStatus)` in-memory + Timer debounced (`hintConfirmDelay`, default 5 s) que confirma via REST; `dispose()` cancela sub + timers e é idempotente                                                                                      | `lib/features/client_agents/presentation/controllers/client_agents_controller.dart` + auto-wire no `injector_presentation.dart` (passa `null` quando o use case não está registrado)                                                                                                                                                                                             | PR-M p2             |
| **Camada 3 REST (`AgentPresencePoller`) + visibility gating** — `Timer.periodic` chama `loadOnlineAgentIds`, converte cada id em `AgentPresenceHint(online:true, source:'polling_rest')`. `ClientAgentsController.onScreenVisible/Hidden` (chamados pela page via `RouteAware`) + observação de `ConsumerSocketConnection.states()` reconciliam o gate: poller liga **só** quando tela visível **AND** socket NÃO conectado. Loop interno do poller re-tick caso `userId` mude mid-flight.                                                    | `lib/features/client_agents/application/services/agent_presence_poller.dart` + extensões em `client_agents_controller.dart` + `RouteAware.{didPush,didPopNext,didPushNext,didPop}` em `client_agents_page.dart` + auto-wire no `injector_client_agents.dart` (`AgentPresencePoller`) e `injector_presentation.dart` (passa `AgentPresencePoller?` + `ConsumerSocketConnection?`) | PR-M p3             |
| **E2E SQL real** (opt-in, `test/integration/e2e/`) — repositórios chamam `executeSql` com queries permitidas pelo banco (não usar `SELECT 1` sem tabela quando a política ODBC bloqueia).                                                                                                                                                 | `agent_sql_bridge_e2e_test.dart`, `resumo_*_repository_e2e_test.dart`, etc. + `support/e2e_dependency_bootstrap.dart`                                                                                                                                                                                                    | e2e agent_queries   |

### 0.2 Cobertura de testes (`flutter test`)

> 973 testes ✅ no momento desta atualização. Diff vs baseline (Phase 1
> completa em ~838): **+135 testes** (PR-K = +37, PR-L = +25, PR-L+ p1 = +6,
> PR-L+ p2 = +6, PR-L+ p3 = +6, PR-L+ p3.5 = +6, PR-M p1 = +20, PR-M p2 = +7,
> PR-M p3 = +13, PR-J = +9).
>
> Além disso: E2E opt-in em `test/integration/e2e/` (excluídos da pipeline
> padrão quando aplicável). Veja §0.2.1.

Suites principais novas/atualizadas:

- `test/core/socket/payload_frame_test.dart`,
  `payload_frame_codec_test.dart` (PR-K)
- `test/core/socket/connection_ready_payload_test.dart` (PR-K — agora cobre
  `JsonOnly` + `PayloadFrame` + `Compat`)
- `test/core/socket/relay/relay_event_names_test.dart`,
  `relay_conversation_test.dart`,
  `relay_command_dispatcher_impl_test.dart` (PR-L)
- `test/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource_test.dart`
  (PR-L)
- `test/features/agent_queries/data/datasources/hybrid_agent_queries_remote_datasource_test.dart`
  (PR-L+ p1) — cobre rotas `useRelay=false` ➜ base, `useRelay=true` ➜
  dispatcher, fallback gracioso quando o relay não está registrado.
- `test/features/agent_queries/data/agent_sql_execute_request_to_bridge_body_test.dart`
  ganhou um cenário garantindo que `useRelay` **não** vaza para o body.
- `test/core/socket/relay/relay_command_dispatcher_streaming_test.dart`
  (PR-L+ p2) — emit único de `relay:rpc.request`; pull inicial só
  depois de `accepted`; chunks chegam no `Stream<Map>`; refill rolante
  quando o crédito cai a/abaixo de `refillThreshold`; `terminal_status:
aborted` vira `RelayStreamTerminated`; `relay:rpc.response` (sem
  chunks) vira single-chunk-then-close; rejeição/timeout/dispose
  fecham com erro tipado.
- `test/features/client_agents/domain/events/agent_presence_event_test.dart`
  (PR-M p1) — campos preservados, `connectionStatusFromHint`, switch
  exaustivo no sealed.
- `test/features/client_agents/application/usecases/observe_agent_presence_use_case_test.dart`
  (PR-M p1) — port repassa o stream untouched.
- `test/features/client_agents/data/socket/agent_command_presence_hinter_test.dart`
  (PR-M p1) — Success ➜ hint online; FailedOffline ➜ hint offline;
  FailedAuth e FailedTransient ➜ NO hint; attach/dispose idempotentes.
- `test/features/client_agents/data/socket/client_agent_profile_updated_listener_test.dart`
  (PR-M p1) — PayloadFrame envelope decodifica para
  `AgentPresenceCatalogUpdated`; raw JSON map (legacy hub) aceito apenas com
  `SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED=true`; payloads sem `agent_id` ou com schema PayloadFrame inválido
  são logados e descartados sem matar o stream.
- `test/features/client_agents/data/socket/socket_agent_presence_stream_test.dart`
  (PR-M p1) — Camadas 1+2 num único stream; re-attach do listener no
  reconnect (disconnect ➜ reconnect ➜ novo handler ativo); dispose
  fecha tudo e descarta eventos tardios.
- `test/features/client_agents/presentation/controllers/client_agents_controller_presence_test.dart`
  (PR-M p2) — hint flips `connectionStatus` in-memory sem ir à rede;
  debounce confirm chama `LoadClientAgentDetailUseCase` após 30 ms
  (em produção 5 s); `AgentPresenceCatalogUpdated` faz upsert do
  agente refrescado; eventos com `observedAt` mais antigo/igual são
  dropados (dedup); hint para agente desconhecido é no-op silencioso;
  controller construído sem `ObserveAgentPresenceUseCase` ignora
  presença totalmente; `dispose()` cancela sub + timers (debounce
  past-window não dispara o REST).
- `test/features/client_agents/application/services/agent_presence_poller_test.dart`
  (PR-M p3) — `start` dispara tick imediato + emite hints `online`
  por id; idempotente para mesmo `userId`; trocar de `userId`
  re-tika imediatamente (loop interno); `null` da repo não emite
  hint; erro da repo é logado e o poller sobrevive; `stop`
  cancela e é idempotente.
- (mesmo arquivo de PR-M p2) novo grupo **`PR-M part 3 — visibility-gated REST poller`**
  no controller — liga poller quando `onScreenVisible` + socket
  desconectado; para quando o socket volta ao `Connected`; nunca
  liga com tela escondida; `dispose()` cancela sub do socket e
  para o poller (eventos pós-dispose não disparam start novo).
- `test/features/agent_queries/data/streaming_sql_execute_collector_test.dart`
  (PR-L+ p3.5) — collector funde row chunks + complete payload no
  envelope canônico (`response.item.{success,result.{rows,row_count,
execution_id,...}}`); fallback de `row_count` quando `total_rows`
  ausente; stream vazio gera envelope vazio bem-sucedido; erros do
  stream propagam.
- `test/features/agent_queries/data/datasources/collecting_relay_streaming_agent_queries_remote_datasource_test.dart`
  (PR-L+ p3.5) — adapter coleta chunks via streaming e devolve no
  shape do port unitário; erros viram `Future` errors.
- `test/features/agent_queries/data/datasources/relay_streaming_agent_queries_remote_datasource_test.dart`
  (PR-L+ p3) — chunks do dispatcher passam intactos pra
  `streamSqlExecute`; timeout vira `bridgeTimeoutMs + 5s` (default
  20 s quando ausente); hint de compressão é encaminhado;
  `command.method` é `sql.execute` no body emitido;
  `RelayDispatchException` propaga como erro no stream.
- `test/core/socket/socket_command_dispatcher_cancel_test.dart` (PR-J)
  — `dispatcher.cancel(rpcId, reason)` propaga `SocketDispatchCancelled`
  ao correlator com a `reason` no message + emite outcome
  `AgentCommandFailedTransient(reasonCode: 'cancelled')`. Cancelar
  rpcId desconhecido é no-op silencioso (não chama `failWith`).
- `test/core/socket/socket_command_cancel_token_test.dart` (PR-J)
  — `register/unregister/cancelAll/dispose` idempotentes; `cancelAll`
  itera todos os ids tracked com a `reason` configurada (ou
  `caller_cancelled` default); `dispose` usa `token_disposed` e
  bloqueia `register` subsequente.

### 0.2.1 E2E contra hub real

Os smokes que enviavam `agents:command` com **`SELECT 1`** foram
**removidos**: em produção a política do agente / ODBC costuma exigir SQL
contra tabelas reais; consultas “sem tabela” falham por autorização e não
validam o transporte de forma útil.

**O que usar:** E2E em `test/integration/e2e/` que executam SQL dos
repositórios (ex.: `agent_sql_bridge_e2e_test.dart`,
`resumo_*_repository_e2e_test.dart`), com os mesmos envs `E2E_*` em
`assets/env/local.env` (via `primeE2eEnvironment`). Handshake `/consumers`,
relay e presença seguem cobertos por testes unitários e por uso manual do
app com `AGENT_BRIDGE_TRANSPORT=socket` após `SOCKET_CONSUMER_ROLES` no hub.

#### Resultado do primeiro run contra `plug_server` produção (histórico)

**Achado real (a corrigir do lado do hub, não do app):** no primeiro smoke
(com `socket_consumer_smoke_e2e_test.dart`, arquivo desde então removido)
contra `https://plug-server.se7esistemassinop.com.br/api/v1` o login REST
funcionou, o handshake Socket.IO foi aceito, mas o middleware de
namespace rejeitou a conexão com:

```text
{message: Role 'client' is not allowed to connect to /consumers}
```

Origem confirmada no hub
(`plug_server/src/presentation/socket/auth/socket_namespace_auth.middleware.ts`
linha 122) — o gate é controlado por `SOCKET_CONSUMER_ROLES`. O
_default no código_ já inclui `client` (`user,admin,client`,
linha 88), e o `.env.example` do hub também — mas a instância de
produção atual está com `SOCKET_CONSUMER_ROLES=user,admin` (sem
`client`). Bate com a nota em `plug_server/docs/api_rest_bridge.md`
linha 77.

**Ação operacional do lado do servidor:**

```bash
# No deploy do plug_server, atualizar o env e reiniciar:
SOCKET_CONSUMER_ROLES=user,admin,client
```

Isso libera o app Colmeia (que loga com role `client`) a abrir o
namespace `/consumers`. **Sem mudança no Flutter.** Na época do smoke, a
fase REST + handshake passou e a conexão parou quando o gate fechou —
confirmação de que a pilha do app (PR-A → PR-M) chega até a borda do hub.

Com o env ajustado, validar `agents:command`, relay e presença via app ou
E2E com SQL real (§0.2.1), não via `SELECT 1`.

### 0.3 Em aberto (próximos PRs)

- **Operacional: ajustar `SOCKET_CONSUMER_ROLES` no hub para incluir
  `client`**. O primeiro run (histórico em §0.2.1) já validou login REST +
  handshake; em seguida usar app ou E2E com queries reais. Sem mudança de
  código obrigatória no Flutter.
- **PR-L+ parte 4** — registrar
  `CollectingRelayStreamingAgentQueriesRemoteDataSource` no
  `injector_agent_queries.dart` (gated por
  `useRelayStreaming` em `AgentSqlExecuteRequest` ou novo env)
  para uma query específica do `overview`. Com PR-L+ p3.5 entregue,
  isto vira um **swap de DI trivial** — qualquer repository passa a
  rodar via streaming wire sem mudar de comportamento. Falta apenas
  decisão de produto sobre qual query estrear.
- **PR-N** — Hybrid REST↔Socket fallback (Fase 3).
- **P3 / Fase 3** — gzip async via `compute(...)` para `> 64 KiB`,
  dedup pós-reconexão universal, OTel propagation.

### 0.4 Auditoria de boot (entregue) — bugs UX/lifecycle corrigidos

Auditoria do startup (`main.dart` → `bootstrap.dart` →
`SocketLifecycleObserver` → `AuthController.initialize` →
`AppRouter`) descobriu 2 bugs e 2 subótimos. Todos **corrigidos** com
testes nesta entrega:

| #      | Tipo     | Sintoma original                                                                                                                                                                                                                                                                                                    | Fix                                                                                                                                                                                                                                                                                                                            |
| ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **B1** | UX bug   | Cold start com sessão restaurada **flashava a tela de login** antes de redirecionar para o dashboard, porque `resolveAuthRedirect` decidia com `isAuthenticated == false` enquanto `isRestoringSession == true`.                                                                                                    | `resolveAuthRedirect` ganhou parâmetro `isRestoringSession` (default `false`); enquanto `isRestoringSession && !isAuthenticated`, o guard retorna `null` (segura a navegação). O `refreshListenable` re-avalia assim que o restore termina. `redirectWithAuthGuard` passa `authController.isRestoringSession` automaticamente. |
| **B2** | Race     | Em hot-reload (e em alguns cold-starts rápidos), o restore podia resolver **antes** de `SocketLifecycleObserver.initState` rodar; `_wasAuthenticated` virava `true` na entrada e a transição `false → true` nunca disparava ⇒ socket ficava cold até a primeira query, ignorando `SOCKET_WARM_UP_AFTER_LOGIN=true`. | `_SocketLifecycleObserverState.initState` chama `_safeResume(reason: 'mount_already_authenticated')` quando o gate já está autenticado, há `connection` materializado (ver S1), e `warmUpAfterLogin` é `true`.                                                                                                                |
| **S1** | Subótimo | `bootstrap.dart` chamava `getIt<ConsumerSocketConnection>()` **mesmo em builds REST-only**, materializando todo o stack socket sem necessidade.                                                                                                                                                                     | `SocketLifecycleObserver.connection` é `nullable`. `bootstrap.dart` resolve `ConsumerSocketConnection` quando `AppEnvironment.socketRelayEnabled` (`AGENT_BRIDGE_TRANSPORT=socket` **ou** `SOCKET_RELAY_ENABLED=true`). REST-only **sem** relay mantém `connection == null` ⇒ observer no-op.                                  |
| **S2** | Subótimo | `_onAuthChanged` chamava `_safePause(reason: 'signed_out')` no logout **independente do transport**, gerando log/método inútil em builds REST.                                                                                                                                                                      | Pause em sign-out só quando `_shouldManageSocket` (`connection != null`). Silencioso quando não há socket a gerir (REST-only sem relay).                                                                                                                                                                                         |

Arquivos tocados nesta entrega:

| Camada                   | Arquivo                                                                                                                                                                                                                            |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Auth (guard de rotas)    | `lib/features/auth/presentation/routes/auth_redirect.dart`                                                                                                                                                                         |
| App (lifecycle observer) | `lib/app/socket_lifecycle_observer.dart`                                                                                                                                                                                           |
| App (composição)         | `lib/app/bootstrap.dart`                                                                                                                                                                                                           |
| Tests (guard)            | `test/features/auth/presentation/routes/auth_redirect_test.dart` (+5 cenários: hold em rota protegida / guest-only / unmatched durante restore; resume normal pós-restore; redirect para login pós-restore sem sessão)             |
| Tests (observer)         | `test/app/socket_lifecycle_observer_test.dart` — warm-up no mount já autenticado; warm-up desligado; `connection == null` ⇒ no-op; REST com `connection` não nulo (relay) aplica pause/resume; sign-out sem socket não chama `pause` |

**Notas de impacto operacional:**

- **Relay opcional (`SOCKET_RELAY_ENABLED`) com bridge REST**: o mesmo
  `ConsumerSocketConnection` ao `/consumers` pode ser materializado para
  relay; `SocketLifecycleObserver` e `SocketMetricsListener` seguem
  `AppEnvironment.socketRelayEnabled`, não apenas `AGENT_BRIDGE_TRANSPORT ==
  socket`.

- B1 é o fix de maior impacto visível (UX): zero flicker de login no
  cold start com sessão válida. Sem mudança de contrato — o parâmetro
  novo tem default `false`, então qualquer chamada antiga continua
  válida.

### 0.5 Auditoria de error handling (entregue) — 4 bugs corrigidos

Auditoria da cadeia `socket → datasource → repo → executor → controller →
UI` em `agent_queries` e `overview` validou se: (a) erros não são
suprimidos silenciosamente, (b) telas não travam, (c) erros de
autorização chegam à UI, (d) erros de SQL chegam à UI. Encontrou e
**corrigiu** 4 bugs com testes:

| #       | Tipo                               | Sintoma original                                                                                                                                                                                                                                                                                                                     | Fix                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **#1**  | Suppression                        | Com `SOCKET_RELAY_ENABLED=true`, qualquer `RelayDispatchException` (`RelayRequestRejected`, `RelayRequestTimeout`, `RelayDecodeFailure`, `RelayStreamTerminated`, `RelayConversationLost`, etc.) caía em `on Object catch` no repositório → virava `UnknownFailure` genérico (mensagem vaga, código perdido nos logs).               | `agent_queries_repository_impl.dart` ganhou catches dedicados para **cada** variante sealed do relay (timeout, conversation lost/start failure, request rejected com classificação de auth-like, stream terminated, decode failure, duplicate request id, dispatcher disposed). Cada variante mapeia para o `AppFailure` correto com `userMessage` PT-BR específica.                                                                                                                                                                                                                                                                          |
| **#2**  | Suppression / classificação errada | Só `AGENT_ACCESS_DENIED` virava `AuthorizationFailure`; outros códigos auth-like do `app:error` (e da rejeição de relay) viravam `NetworkFailure` ("Falha de comunicação...") — mensagem **errada** para erro de **permissão**.                                                                                                      | Novo `agent_queries_failure_codes.dart` com 2 allowlists case-insensitive: `kSocketAuthorizationDeniedCodes` (`AGENT_ACCESS_DENIED`, `ACCESS_DENIED`, `PERMISSION_DENIED`, `FORBIDDEN`, `INSUFFICIENT_SCOPE`, `INSUFFICIENT_PRIVILEGES`, `NOT_AUTHORIZED`) e `kSocketAuthenticationFailedCodes` (`UNAUTHORIZED`, `UNAUTHENTICATED`, `INVALID_TOKEN`, `TOKEN_EXPIRED`, `TOKEN_INVALID`). O helper `_appErrorToFailure` no repo agora classifica server codes em `SessionFailure` (auth-failed) / `AuthorizationFailure` (auth-denied) / `NetworkFailure` (resto). Aplicado tanto em `SocketDispatchAppError` quanto em `RelayRequestRejected`. |
| **#2b** | UX errada para cancelamento        | `SocketDispatchCancelled` (controller dispose / navegação) caía em `SocketDispatchException` → `NetworkFailure` "Falha de comunicação...", surfacando erro pra usuário que já saiu da tela.                                                                                                                                          | Catch dedicado para `SocketDispatchCancelled` + `RelayDispatcherDisposed` retorna `UnknownFailure` com `userMessage: 'A consulta foi cancelada.'` e marca `context['cancelled'] = true`. Helper `isCancelledAgentQueryFailure(context)` permite controllers detectarem e **silenciarem** o banner de erro quando a tela já foi descartada.                                                                                                                                                                                                                                                                                                    |
| **#3**  | Tela travada (loading infinito)    | A estratégia `race` do `AgentQueryExecutor` esperava o `Completer` resolver. Se ao menos uma chamada nunca completasse E nem todas falhassem, o `await` ficava infinito → loading que não termina.                                                                                                                                   | Construtor ganhou `raceTotalTimeout` (default `Duration(minutes: 2)`). `_executeRace` aplica `completer.future.timeout(raceTotalTimeout, onTimeout: ...)` que sintetiza um decision `_RaceTimedOut`. Na timeout, retorna `Failure(NetworkFailure)` com `userMessage: 'A consulta multiagente demorou mais que o tempo permitido. Tente novamente.'` + log estruturado com `unresolvedAgentIds`. Em produção esse safety net **não deve** disparar (dispatchers Socket/REST já têm timeout per-request bem menor) — existe defensivamente para nunca confiar cegamente em timeouts upstream.                                                   |
| **#4**  | Mensagem perdida                   | Gráficos opcionais do `overview` (`monthly`, `weekday`, `weekday-by-user`) absorviam falhas de SQL em `loadFailed: true` + lista vazia, **descartando** a mensagem específica do `RpcFailure`/`AuthorizationFailure` (`userMessage: "Você não tem acesso a este agente."`). UI mostrava só "Não foi possível carregar este gráfico". | `_resolveOptionalChartData` no repositório agora retorna `(points, loadFailed, loadFailureMessage)` com `failure.userMessage`. Adicionados 3 campos `String? <chart>LoadFailureMessage` em `Overview` (entity), `OverviewModel` (data — runtime apenas, **não** persistido em JSON), e `OverviewMonthlyParcelsComboChart` / `OverviewWeekdaySalesTrendChart` / `OverviewWeekdayUserSalesTrendChart` (widgets). Charts mostram `loadFailureMessage ?? l10n.overviewXxxLoadFailed` quando `loadFailed` — mensagem específica quando disponível, fallback genérico quando não.                                                                   |

Arquivos tocados nesta entrega:

| Camada                           | Arquivo                                                                                                                                                                                                                                                                                                                                                    |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Códigos de erro (novo)           | `lib/features/agent_queries/data/repositories/agent_queries_failure_codes.dart` (allowlists `kSocketAuthorizationDeniedCodes` / `kSocketAuthenticationFailedCodes` + `AgentQueriesFailureContext` + `isCancelledAgentQueryFailure`)                                                                                                                        |
| Repositório (BUGS #1, #2, #2b)   | `lib/features/agent_queries/data/repositories/agent_queries_repository_impl.dart` (catches específicos para 8 variantes de relay + helper `_appErrorToFailure` compartilhado entre socket app:error e relay rejected)                                                                                                                                      |
| Executor (BUG #3)                | `lib/features/agent_queries/application/orchestration/agent_query_executor.dart` (parâmetro `raceTotalTimeout` + `_RaceTimedOut` + `Failure(NetworkFailure)` na timeout)                                                                                                                                                                                   |
| Overview entity / model (BUG #4) | `lib/features/overview/domain/entities/overview.dart`, `lib/features/overview/data/models/overview_model.dart` (3 novos `String? <chart>LoadFailureMessage` runtime, `copyWith` atualizado)                                                                                                                                                                |
| Overview repository (BUG #4)     | `lib/features/overview/data/repositories/overview_repository_impl.dart` (`_resolveOptionalChartData` propaga `loadFailureMessage`, `_buildOverview` aceita 3 novos opcionais, todas as 3 chamadas atualizadas)                                                                                                                                             |
| Overview widgets (BUG #4)        | `lib/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart`, `overview_weekday_sales_trend_chart.dart`, `overview_weekday_user_sales_trend_chart.dart` (param `loadFailureMessage` + lookup com fallback no l10n)                                                                                                               |
| Overview composição (BUG #4)     | `lib/features/overview/presentation/widgets/overview_home_staged_below_kpis.dart` (passa o novo campo do `Overview` pra cada chart, em ambos os branches do staged render)                                                                                                                                                                                 |
| Tests (BUGS #1, #2, #2b)         | `test/features/agent_queries/data/repositories/agent_queries_repository_impl_socket_failures_test.dart` (+15 cenários: relay timeout/conversation/rejected com auth allowlist, decode, duplicate, dispatcher disposed; widening de socket app:error com `FORBIDDEN`/`UNAUTHORIZED`/`TOKEN_EXPIRED`/lowercase; cancelled benign com `cancelled: true` flag) |
| Tests (BUG #3)                   | `test/features/agent_queries/data/orchestration/agent_query_executor_test.dart` (+3 cenários: timeout dispara quando nada settla, NÃO dispara quando alguém sucede, dispara quando alguns settlam mas restam pendentes)                                                                                                                                    |
| Tests (BUG #4)                   | `test/features/overview/presentation/widgets/overview_weekday_sales_trend_chart_test.dart` (+2 cenários: chart mostra `loadFailureMessage` específica quando setado, fallback pro l10n genérico quando null)                                                                                                                                               |

**Notas de impacto operacional:**

- BUG #1 desbloqueia ligar `SOCKET_RELAY_ENABLED=true` em produção sem
  perder qualidade de mensagens. Sem o fix, qualquer falha de relay
  chegava na UI como "Erro inesperado. Tente novamente." — agora chega
  como "A consulta demorou mais do que o esperado.", "Você não tem
  acesso a este agente.", "A conexão com o servidor caiu durante a
  consulta.", etc.
- BUG #2 corrige UX em produção mesmo no canal socket atual: erros de
  permissão (`FORBIDDEN`, `PERMISSION_DENIED`, etc.) que antes apareciam
  como "Falha de comunicação" agora aparecem como "Você não tem acesso
  a este agente." (`AuthorizationFailure`) ou "Sua sessão expirou"
  (`SessionFailure` para `UNAUTHORIZED`/`TOKEN_EXPIRED`).
- BUG #2b elimina banners "Falha de comunicação" que apareciam quando o
  usuário simplesmente saía da tela — controllers podem agora detectar
  via `isCancelledAgentQueryFailure(failure.context)` e ignorar.
- BUG #3 é safety net defensivo. Em produção o dispatcher Socket
  (`SOCKET_REQUEST_TIMEOUT_MS=15s` default) e o Dio (`receiveTimeout=15s`)
  já cobrem o cenário. O fix existe pra que nunca confiemos cegamente
  no upstream — o `raceTotalTimeout` de 2 min é deliberadamente folgado.
- BUG #4 melhora UX em telas que antes engoliam erros silenciosamente.
  Operador vendo "Você não tem acesso a este agente." pode pedir
  acesso; vendo "SQL inválido na coluna X" pode reportar pro time. O
  campo é runtime apenas — não persiste em cache JSON (mensagens auth
  ficam stale após app restart).

**Cobertura nesta entrega:**

- Repositório agent_queries (failures socket+relay): **20 testes ✅**
  (era 5 antes do fix; +15 novos cenários cobrindo relay e auth-like).
- Executor (race timeout): **11 testes ✅** (+3 novos para o timeout).
- Overview weekday chart (load failure UI): **6 testes ✅**
  (+2 novos para `loadFailureMessage`).
- `flutter analyze` limpo nos arquivos novos/tocados.
- 1022 unit/widget tests do projeto passam verde no `flutter test`
  (13 falhas no run total são **e2e tests** que requerem credenciais
  reais do `plug_server` — pre-existing, não regressão).
- B2 garante que o warm-up entrega o que `SOCKET_WARM_UP_AFTER_LOGIN`
  promete em **todos** os caminhos (cold start, hot reload, e a
  transição clássica `null → authenticated`). Sem isso, em prática o
  warm-up só funcionava de forma confiável em hot-restart com login
  manual.
- S1 evita materializar `ConsumerSocketConnection` e o stack Socket.IO no
  boot quando `AppEnvironment.socketRelayEnabled` é falso (REST-only **sem**
  relay). Com `SOCKET_RELAY_ENABLED=true` e bridge REST, o socket ainda é
  criado para relay — ver §0.4.
- S2 é cosmético mas elimina ruído de logging quando não há `connection`.

Cobertura: **31 testes ✅** nas 2 suites tocadas (16 em `auth_redirect_test`,
15 em `socket_lifecycle_observer_test`). Sweep `flutter analyze` limpo
para `lib/app`, `lib/features/auth/presentation/routes`, e ambas as
suites de teste.

---

## 1. Objetivo

Adicionar **canal Socket** (`Socket.IO` no namespace `/consumers` do hub
`plug_server`) como **alternativa** ao canal REST hoje usado por
`agent_queries`, mantendo:

- **Login via REST** (`/client-auth/login` + `/client-auth/refresh`) inalterado.
- A mesma sessão JWT (`AuthSessionAccessor`) compartilhada entre Dio e Socket.
- O contrato JSON-RPC (`sql.execute`, etc.) já consumido pelo `AgentQueriesRepository`.
- Capacidade de alternar (ou habilitar paralelamente) o transporte
  via configuração e DI, **sem** quebrar features existentes.
- Possibilidade futura de explorar streaming/relay sem mexer em `presentation/`.

Não-objetivos nesta fase:

- Não substituir o REST como canal primário (REST continua sendo o default).
- Não introduzir push-notifications nem `client:agent.profile.updated` na UI.
- Não implementar `relay:*` completo (chunks/`stream.pull`) na primeira entrega
  — começamos por `agents:command` (legado JSON), que reaproveita o **mesmo
  body** do REST. Relay vira fase 2 (ver §11).

---

## 2. Como a integração funciona hoje (REST)

### 2.1 Camada de rede compartilhada (`core/network`)

| Tipo                                                           | Papel                                                                                                                                                          |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AppDioClient`                                                 | Cria `Dio` com `BaseOptions` (timeouts, base URL `apiBaseUrl`, content-type, logging).                                                                         |
| `AuthInterceptor`                                              | Injeta `Authorization: Bearer <accessToken>` lendo `AuthSessionAccessor`; em **401** chama `AuthRefreshCoordinator.refreshAccessToken()` e re-emite a request. |
| `AuthRefreshCoordinator`                                       | Single-flight do `POST /client-auth/refresh`; em 400/401/403 limpa sessão e emite `AuthSessionEvents.notifyInvalidated()`.                                     |
| `AuthSessionAccessor`                                          | Read/save/clear da `AuthSessionModel` em `flutter_secure_storage`.                                                                                             |
| `AuthSessionEvents`                                            | `Stream` broadcast de invalidação de sessão (consumida pelo router/auth controller).                                                                           |
| `ApiRoutes` / `AgentCommandsApiRoutes` / `ClientAuthApiRoutes` | Constantes dos paths REST.                                                                                                                                     |

### 2.2 Feature `agent_queries` (alvo principal)

```text
features/agent_queries/
  domain/
    repositories/agent_queries_repository.dart        # interface única (executeSql)
    entities/agent_sql_execute_request.dart           # entrada semântica
    entities/agent_sql_execution_result.dart          # saída
  data/
    datasources/agent_queries_remote_datasource.dart  # interface + ApiAgentQueriesRemoteDataSource (REST) + Fake
    repositories/agent_queries_repository_impl.dart   # mapeia datasource -> AppResult/Failure
    repositories/gated_agent_queries_repository.dart  # decora com regras de eligibility (hub presence etc.)
    models/agent_sql_bridge_response.dart             # parser do JSON do bridge
  application/
    orchestration/agent_query_executor.dart           # merge-all / race / single-source
    orchestration/agent_query_plan_builder.dart
  data/orchestration/agent_query_target_resolver.dart
```

Hoje o `ApiAgentQueriesRemoteDataSource`:

1. Monta `body` JSON-RPC (mesmo formato exigido pelo socket).
2. Faz `Dio.post(AgentCommandsApiRoutes.commands, data: body)`.
3. Devolve `Map<String,dynamic>` para o repository normalizar.

### 2.3 DI (`core/di/injector_*.dart`)

- `injector_core.dart`: Dio (instância autenticada + `'refresh_dio'`),
  `AuthInterceptor`, `AuthRefreshCoordinator`, `AuthSessionAccessor`,
  `AuthSessionEvents`.
- `injector_agent_queries.dart`: troca entre `Api…` e `Fake…` datasource via
  `AppEnvironment.useFakeBackend`.

**Conclusão**: a fronteira ideal para introduzir Socket é o **datasource**
(`AgentQueriesRemoteDataSource`). O resto (`repository`, `executor`,
`use cases`, `presentation`) já depende só de interfaces.

---

## 3. Visão geral do canal Socket (do `plug_server`)

Resumo prático (detalhes em `socket_client_sdk.md` / `socket_relay_protocol.md`):

- **Transport**: Socket.IO 4.x (compatível com `socket_io_client` 3.x).
- **Namespace para consumers**: **`/consumers`** (o `/agents` é só do `plug_agente`;
  o namespace `/` é rejeitado com `NAMESPACE_DEPRECATED`).
- **Auth no handshake**: JWT do `client-auth/login` em `auth: { token: <jwt> }`.
- **Handshake confirmado** pelo evento `connection:ready` (vem como
  `PayloadFrame` — precisamos decodificar antes de usar).
- **Dois modos** dentro de `/consumers`:
  - **`agents:*` (legado, JSON puro)** — mesmo body do REST
    `POST /api/v1/agents/commands`, mas via socket. Resposta única em
    `agents:command_response`. **Vamos começar por aqui.**
  - **`relay:*`** — `PayloadFrame` binário/gzip, isolado por `conversationId`,
    suporta streaming (`relay:rpc.chunk`, `relay:rpc.stream.pull`). Útil para
    queries que viram stream grande. **Fase 2.**
- **Autorização por evento**: o servidor revalida `ClientAgentAccess`/conta
  ativa por evento. Em revogação, novas chamadas falham com `AGENT_ACCESS_DENIED`.
- **Rate limit**: `agents:command` compartilha quota com REST por `sub`; relay
  tem quotas próprias.

---

## 4. Pacote Dart recomendado

| Opção                          | Nota                                                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`socket_io_client: ^3.1.4`** | Cliente Dart oficial para Socket.IO 4.7+. Suporta `setTransports(['websocket'])`, `setAuth({...})`, namespaces, reconexão automática, eventos. Ativo no pub.dev. **Escolhido.** |
| `web_socket_channel`           | WS puro, não fala o protocolo Engine.IO/Socket.IO. Inadequado.                                                                                                                  |
| `socket_io_client_new`         | Fork comunitário; sem maturidade.                                                                                                                                               |

Adicionar em `pubspec.yaml`:

```yaml
dependencies:
  socket_io_client: ^3.1.4
```

> A regra `project_platform_dependencies.mdc` já permite `socket_io_client`
> "quando existir caso de uso concreto" — este plano é exatamente esse caso.
> Atualizar a rule depois para listar como dependência ativa.

Para a **Fase 2 (relay/PayloadFrame com gzip)** o Dart já fornece
`dart:io GZipCodec` / `dart:convert`, e `crypto` (já no projeto) cobre
`hmac-sha256` para `signature` opcional. Nenhum pacote adicional necessário.

---

## 5. Arquitetura proposta (limites SOLID + Clean Architecture)

### 5.1 Princípios aplicados

- **SRP**: HTTP, Socket e parsing de resposta são responsabilidades distintas.
  O `AgentQueriesRepository` continua **um único contrato**.
- **DIP**: presentation/application só conhecem o **port** (`AgentQueriesRepository`);
  detalhes de transporte ficam em `data/`.
- **OCP**: novo transporte entra como **nova implementação** de
  `AgentQueriesRemoteDataSource` sem alterar o repositório.
- **LSP**: ambas as implementações respeitam o mesmo contrato (mesmo
  `Map<String,dynamic>` no formato bridge). Falhas são mapeadas para os mesmos
  `AppFailure` (`NetworkFailure`, `RpcFailure`, `SessionFailure`, `UnknownFailure`).
- **ISP**: separamos `SocketTransport` (conexão/lifecycle), `SocketCommandSender`
  (envio request/response correlacionado) e o datasource específico de feature.
- **Stable Dependencies**: `core/socket/` é dependência estável, igual
  `core/network/`.

### 5.2 Mapa de pacotes novos

```text
lib/
  core/
    socket/
      socket_io_client_factory.dart            # produz io.Socket configurado (URL/transports/auth)
      app_socket_url_resolver.dart             # apiBaseUrl -> baseUrl Socket.IO + namespace
      consumer_socket_connection.dart          # ConsumerSocketConnection: ciclo de vida + estado
      consumer_socket_connection_state.dart    # enum/sealed: disconnected/connecting/connected/error
      socket_auth_token_provider.dart          # injeta token (lê AuthSessionAccessor, ouve AuthSessionEvents)
      socket_request_correlator.dart           # gera ids JSON-RPC, registra completers, timeout, idempotência
      socket_command_dispatcher.dart           # API alto-nível: send(method, body) -> Future<Map>
      payload_frame.dart                       # (Fase 2) decode/encode + gzip + validações
      socket_failures.dart                     # mapeamento socket-error -> AppFailure
  features/
    agent_queries/
      data/
        datasources/
          agent_queries_remote_datasource.dart           # interface (mantém)
          api_agent_queries_remote_datasource.dart       # rename do atual ApiAgentQueriesRemoteDataSource
          socket_agent_queries_remote_datasource.dart    # NOVO: usa SocketCommandDispatcher
          fake_agent_queries_remote_datasource.dart      # mantém
```

> Nota: a interface `AgentQueriesRemoteDataSource` continua exatamente igual.
> O “transporte” é detalhe de DI.

### 5.3 Diagrama lógico (texto)

```text
PresentationController
        │ (depende só de UseCase)
        ▼
LoadXxxUseCase ──► AgentQueriesRepository (port)
                          │
                          ▼
              GatedAgentQueriesRepository
                          │
                          ▼
              AgentQueriesRepositoryImpl
                          │ (depende só de AgentQueriesRemoteDataSource)
                          ▼
            ┌──────────────────────────┐
            │ ApiAgentQueriesRemoteDS  │  (Dio + AuthInterceptor) ── REST
            │ SocketAgentQueriesRemoteDS│ (SocketCommandDispatcher)── /consumers (NEW)
            │ FakeAgentQueriesRemoteDS │  (in-memory)
            └──────────────────────────┘
                          │
        ┌─────────────────┴──────────────┐
        ▼                                ▼
   Dio (core/network)             ConsumerSocketConnection (core/socket)
                                          │
                                          ▼
                                  SocketIoClientFactory ── socket_io_client.io(url, opts)
```

---

## 6. Componentes — responsabilidades detalhadas

### 6.1 `core/socket/socket_io_client_factory.dart`

- Função `IO.Socket createConsumerSocket({required String accessToken})`.
- Lê `AppEnvironment.apiBaseUrl` e converte para URL Socket.IO
  (mesma host/scheme; muda `http` → `ws` quando necessário; **não** acrescenta
  `/api/v1`; namespace é parte do `io()`).
- Opções:
  - `setTransports(['websocket'])` (alinhado a `SOCKET_IO_TRANSPORTS=websocket`
    em produção).
  - `setAuth({ 'token': accessToken })`.
  - `disableAutoConnect()` — quem chama controla `connect()`.
  - `disableReconnection()` ou config explícita; preferimos reconexão controlada.

### 6.2 `core/socket/consumer_socket_connection.dart`

- **Estado** observável (`ValueListenable<ConsumerSocketConnectionState>` ou
  `Stream`), com:
  - `disconnected` (default), `connecting`, `connected`, `error`, `unauthorized`.
- API:
  - `Future<void> connect()` (idempotente; single-flight).
  - `Future<void> disconnect({bool clearListeners})`.
  - `IO.Socket get raw` (uso restrito para `core/socket/*`).
- Comportamento:
  - Ao subir, requisita token via `SocketAuthTokenProvider`.
  - Espera evento `connection:ready` — quando recebido, **decodifica
    PayloadFrame** por padrão (`payload_frame_only`). `compat` e
    `raw_json_only` existem apenas como overrides explícitos para hubs antigos.
  - Em `connect_error` 401-like, chama `AuthRefreshCoordinator` e tenta
    reconectar uma vez; se falhar, emite `unauthorized` e `AuthSessionEvents.notifyInvalidated()`.
  - Escuta `AuthSessionEvents.invalidated` → `disconnect()`.

### 6.3 `core/socket/socket_auth_token_provider.dart`

```dart
abstract interface class SocketAuthTokenProvider {
  Future<String?> readAccessToken();
  Future<String?> refreshAccessToken();
}

class SessionSocketAuthTokenProvider implements SocketAuthTokenProvider { ... }
```

- Encapsula o `AuthSessionAccessor` + `AuthRefreshCoordinator` para o
  `core/socket` **não** depender direto de `features/auth`.
- Compatível com o padrão do `AuthInterceptor` (mesma fonte de verdade).

### 6.4 `core/socket/socket_request_correlator.dart`

- Gera `id` JSON-RPC (`Uuid().v4()`).
- Mapa `id -> Completer<Map<String,dynamic>>` com timeout configurável
  (`bridgeTimeoutMs + 5s`, alinhado ao `computeBridgeWaitTimeoutMs` do REST).
- `cancel(id)` para limpeza; sweep periódico de pendentes acima do limite.
- Não conhece `Socket.IO` — recebe o resultado já decodificado.

### 6.5 `core/socket/socket_command_dispatcher.dart`

API alto-nível (Fase 1) — **detalhamento completo em
`docs/Features/socket_command_dispatcher_design.md`**:

```dart
abstract interface class SocketCommandDispatcher {
  /// Envia evento `agents:command` e aguarda `agents:command_response`
  /// correlacionado pelo `rpcId` (JSON-RPC `command.id`).
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  });

  /// Stream broadcast de outcomes (Success / FailedOffline / FailedAuth /
  /// FailedTransient). Usado pela presença em tempo real (§19) e por
  /// métricas (review §5.8).
  Stream<AgentCommandOutcome> outcomes();

  Future<void> dispose();
}
```

Comportamento essencial:

- Garante `connection.connect()` antes de emitir (single-flight).
- Registra completer no `SocketRequestCorrelator` (timeout + sweep stale).
- `socket.emit('agents:command', body)`.
- Listeners únicos por conexão para `agents:command_response` e `app:error`.
- Em desconexão: falha pendentes com `SocketDispatchDisconnected` e emite
  `AgentCommandFailedTransient(reason: 'disconnected')`.
- Cataloga códigos do hub em **offline** (`AGENT_OFFLINE`,
  `protocol_not_ready`, `circuit_open`…) vs **auth** (`-32001`/`-32002`,
  `AGENT_ACCESS_DENIED`…) vs **transient** (timeout, decode_failed,
  `RATE_LIMITED`).

Melhorias planejadas (Fase 1.1+):

- **P1** — `coalesce` requests idênticas concorrentes.
- **P1** — `PerAgentConcurrencyGate` (`SOCKET_MAX_INFLIGHT_PER_AGENT`).
- **P2** — `cancelToken` opcional + integração com `sql.cancel`.
- **P2** — `AgentCommandBatchCoordinator` agregando até 32 RPCs.

### 6.6 `core/socket/socket_dispatch_exception.dart` + mapeamento

Exceptions sealed específicas do canal Socket (separadas dos erros JSON-RPC):

- `SocketDispatchTimeout` → `NetworkFailure(isTransient: true)`.
- `SocketDispatchDisconnected` → `NetworkFailure(isTransient: true)`.
- `SocketDispatchUnauthorized` → `SessionFailure`.
- `SocketDispatchDuplicateId` → `ValidationFailure` (bug do caller).
- `SocketDispatchDecodeFailure` → `UnknownFailure`.
- `app:error` com `AGENT_ACCESS_DENIED` → `AuthorizationFailure` (no
  `AgentQueriesRepositoryImpl`).
- Erros JSON-RPC `AgentSqlRpcException` continuam idênticos ao path REST
  (parser `parseSuccess` compartilhado — ver ponto aberto §13 do
  `socket_command_dispatcher_design.md`).

### 6.7 `features/agent_queries/data/datasources/socket_agent_queries_remote_datasource.dart`

- Implementa `AgentQueriesRemoteDataSource`.
- Reaproveita o **mesmo body** de
  `ApiAgentQueriesRemoteDataSource.postSqlExecute` (extrair helper compartilhado
  `agent_sql_execute_request_to_bridge_body.dart` em `data/` para evitar
  duplicação — ganho SRP).
- Chama `SocketCommandDispatcher.sendAgentsCommand(body, rpcId)`.
- Devolve o `Map<String,dynamic>` no mesmo formato.

> Resultado: `AgentQueriesRepositoryImpl` **não muda** — o parser
> `AgentSqlBridgeResponse.parseSuccess` continua válido (porque o socket usa
> o mesmo envelope `response.type`/`response.item`).

---

## 7. Estratégia para alternar transporte (Strategy + Decorator)

Duas opções, com trade-offs:

### Opção A — Single transport via flag de ambiente (escolhida para Fase 1)

- Nova chave `EnvKeys.agentBridgeTransport` (`rest` | `socket`), default `rest`.
- `AppEnvironment.agentBridgeTransport` lê via `--dart-define` / dotenv.
- `injector_agent_queries.dart` decide qual datasource registrar:

```dart
getIt.registerLazySingleton<AgentQueriesRemoteDataSource>(() {
  if (AppEnvironment.useFakeBackend) {
    return FakeAgentQueriesRemoteDataSource();
  }
  return switch (AppEnvironment.agentBridgeTransport) {
    AgentBridgeTransport.socket => SocketAgentQueriesRemoteDataSource(
      dispatcher: getIt<SocketCommandDispatcher>(),
      bodyMapper: getIt<AgentSqlExecuteBridgeBodyMapper>(),
    ),
    AgentBridgeTransport.rest => ApiAgentQueriesRemoteDataSource(getIt<Dio>()),
  };
});
```

- Vantagens: sem complexidade de roteamento dinâmico; muito fácil de rollout
  por build (canary `colmeia-staging` com Socket).

### Opção B — Hybrid datasource (preferido só após Fase 1 estabilizar)

- `HybridAgentQueriesRemoteDataSource` decora ambos:
  - tenta Socket se a conexão está saudável; em `NetworkFailure` transitória,
    cai para REST (fallback).
- Útil quando quisermos Socket para latência baixa mas REST como rede de
  segurança em redes ruins.
- Adicionar **só** depois que métricas mostrarem necessidade, evitando
  combinações duplicadas e cache invalidation entre canais.

---

## 8. Configuração e variáveis de ambiente

| Chave                                        | Origem                  | Default                      | Uso                                                                                                                                                                                                     |
| -------------------------------------------- | ----------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `API_BASE_URL`                               | já existe               | —                            | reutilizada (host/scheme) para Socket.IO.                                                                                                                                                               |
| `AGENT_BRIDGE_TRANSPORT`                     | nova                    | `rest`                       | `rest` \| `socket` (futuramente `auto`/`hybrid`).                                                                                                                                                       |
| `SOCKET_NAMESPACE`                           | nova (opcional)         | `/consumers`                 | só sobrescreve em testes contra forks do hub.                                                                                                                                                           |
| `SOCKET_RECONNECT_ATTEMPTS`                  | nova (opcional)         | `5`                          | teto de tentativas no backoff controlado.                                                                                                                                                               |
| `SOCKET_RECONNECT_INITIAL_DELAY_MS`          | nova (opcional)         | `1000`                       | delay inicial do backoff (com **jitter** — ver review §5.4).                                                                                                                                            |
| `SOCKET_RECONNECT_MAX_DELAY_MS`              | nova (opcional)         | `30000`                      | teto do backoff exponencial.                                                                                                                                                                            |
| `SOCKET_REQUEST_TIMEOUT_MS`                  | nova (opcional)         | `15000`                      | timeout default por request quando não há histórico.                                                                                                                                                    |
| `SOCKET_HANDSHAKE_TIMEOUT_MS`                | nova (opcional)         | `10000`                      | espera por `connection:ready` antes de retry.                                                                                                                                                           |
| `SOCKET_MAX_INFLIGHT_PER_AGENT`              | nova (opcional)         | `8`                          | teto de requests paralelas por `agentId` (mirror conservador do `SOCKET_REST_AGENT_MAX_INFLIGHT=32` do hub — ver review §5.5).                                                                          |
| `SOCKET_BATCH_WINDOW_MS`                     | nova (opcional, P2)     | `8`                          | janela de coalescência para batch JSON-RPC (review §5.2).                                                                                                                                               |
| `SOCKET_BATCH_MAX_SIZE`                      | nova (opcional, P2)     | `32`                         | teto de RPCs por batch (limite oficial do hub).                                                                                                                                                         |
| `SOCKET_WARM_UP_AFTER_LOGIN`                 | nova (opcional)         | `true` se `transport=socket` | dispara `connect()` em background ao final do login (review §5.7).                                                                                                                                      |
| `SOCKET_TIMEOUT_ADAPTIVE_ENABLED`            | nova (opcional, P2)     | `false`                      | liga o `AgentLatencyOracle` para timeout por p95 (review §5.3).                                                                                                                                         |
| `SOCKET_PAYLOAD_FRAME_ASYNC_GZIP_MIN_BYTES`  | nova (opcional, Fase 2) | `65536`                      | usa `compute(...)` para gzip acima desse tamanho UTF-8 (review §5.9).                                                                                                                                   |
| `SOCKET_CONNECTION_READY_COMPAT_MODE`        | nova (PR-K)             | `payload_frame_only`         | `payload_frame_only` (estrito, default atual) \| `compat` (PayloadFrame com fallback raw JSON; override de migracao) \| `raw_json_only` (legado). |
| `SOCKET_RELAY_ENABLED`                       | nova (PR-L)             | `false`                      | Master switch do relay. Quando `true`, registra `RelayConversationManager` + `RelayCommandDispatcher` no DI; `false` mantém apenas o canal `agents:command`.                                            |
| `SOCKET_RELAY_REQUEST_TIMEOUT_MS`            | nova (PR-L)             | `30000`                      | Timeout por `relay:rpc.request` (precisa ser maior que o `bridgeTimeoutMs` do bridge para o hub responder via `relay:rpc.complete`).                                                                    |
| `SOCKET_RELAY_CONVERSATION_START_TIMEOUT_MS` | nova (PR-L)             | `10000`                      | Espera por `relay:conversation.started` antes de falhar com `start_timeout`.                                                                                                                            |
| `SOCKET_RELAY_CONVERSATION_END_TIMEOUT_MS`   | nova (PR-L)             | `5000`                       | Espera por `relay:conversation.ended`; estourar é apenas warning (estado local muda assim mesmo).                                                                                                       |
| `SOCKET_RELAY_PAYLOAD_FRAME_COMPRESSION`     | nova (PR-L)             | `default`                    | `default` (auto: gzip se reduzir bytes) \| `none` \| `always`. Encaminhado em todo `relay:rpc.request` para o hub re-encodar o frame `hub→agente`.                                                      |
| `SOCKET_RELAY_STREAM_INITIAL_WINDOW`         | nova (PR-L+ p2)         | `32`                         | Janela inicial de chunks concedida no primeiro `relay:rpc.stream.pull` após `accepted`. O evento envia `{ conversationId, frame }`; o `frame` é `PayloadFrame` com `request_id`, `window_size` e `stream_id` quando existir. Mais alto = menos round-trips de pull, mais RAM em vôo. |
| `SOCKET_RELAY_STREAM_REFILL_THRESHOLD`       | nova (PR-L+ p2)         | `16`                         | Threshold (créditos restantes) para o dispatcher emitir um novo pull e voltar a janela ao initial, preservando `stream_id` quando o hub já o informou.                                                   |
| `SOCKET_PRESENCE_LISTENER_ENABLED`           | nova (PR-M p1)          | `false`                      | Master switch da pilha de presença em tempo real. Quando `true`, o `injector_client_agents` registra `SocketAgentPresenceStream` (Camadas 1+2 + Camada 3 do PR-M p3) e o `ObserveAgentPresenceUseCase`. |

Adicionar em:

- `lib/core/config/env_keys.dart` (constantes).
- `lib/core/config/app_environment.dart` (getters tipados; `agentBridgeTransport`
  como enum `AgentBridgeTransport`).
- `assets/env/default.env` e `assets/env/local.env` (defaults documentados).

---

## 9. DI — alterações concretas

### 9.1 Novo módulo `core/di/injector_socket.dart`

```dart
void registerInjectorSocket(GetIt getIt) {
  getIt
    ..registerLazySingleton<SocketAuthTokenProvider>(
      () => SessionSocketAuthTokenProvider(
        sessionAccessor: getIt<AuthSessionAccessor>(),
        refreshCoordinator: getIt<AuthRefreshCoordinator>(),
      ),
    )
    ..registerLazySingleton<AppSocketUrlResolver>(
      () => AppSocketUrlResolver(AppEnvironment.apiBaseUrl),
    )
    ..registerLazySingleton<ConsumerSocketConnection>(
      () => ConsumerSocketConnection(
        urlResolver: getIt<AppSocketUrlResolver>(),
        tokenProvider: getIt<SocketAuthTokenProvider>(),
        sessionEvents: getIt<AuthSessionEvents>(),
      ),
      dispose: (c) async => c.disconnect(clearListeners: true),
    )
    ..registerLazySingleton<SocketRequestCorrelator>(
      SocketRequestCorrelator.new,
    )
    ..registerLazySingleton<SocketCommandDispatcher>(
      () => SocketCommandDispatcherImpl(
        connection: getIt<ConsumerSocketConnection>(),
        correlator: getIt<SocketRequestCorrelator>(),
      ),
    );
}
```

Registrar **depois** de `injector_core` (precisa de `AuthSessionAccessor`,
`AuthRefreshCoordinator`, `AuthSessionEvents`) e **antes** de
`injector_agent_queries`:

```dart
// lib/core/di/injector.dart
await registerInjectorCore(getIt);
registerInjectorAuth(getIt);
registerInjectorUserContext(getIt);
registerInjectorSocket(getIt);          // ← novo
registerInjectorClientAgents(getIt);
registerInjectorAgentQueries(getIt);
registerInjectorOverview(getIt);
registerInjectorPresentation(getIt);
```

### 9.2 Alteração em `injector_agent_queries.dart`

- Trocar o registro de `AgentQueriesRemoteDataSource` pela switch da §7
  (Opção A).
- Adicionar registro de `AgentSqlExecuteBridgeBodyMapper` (helper extraído
  do método atual `postSqlExecute`).

---

## 10. Lifecycle e relação com a sessão

| Evento                                                    | Ação esperada                                                                                                                                                                                                                                                                                                               |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| App inicia, sessão restaurada                             | Sem `connection` materializado (`socketRelayEnabled` falso): nada. Com `connection` não nulo e `SOCKET_WARM_UP_AFTER_LOGIN=true`: warm-up oportunista no `SocketLifecycleObserver.initState` quando o gate já está autenticado (fix B2/§0.4 — antes a transição `null → authenticated` podia ser perdida no cold start). Sem warm-up, a conexão fica lazy até o primeiro uso. |
| Login concluído                                           | **Warm-up oportunista** quando há `connection`, `SOCKET_WARM_UP_AFTER_LOGIN=true`, e o `AuthenticationGate` faz `false → true`: o observer chama `connection.resume()` (single-flight + idempotente). Não depende só de `AGENT_BRIDGE_TRANSPORT=socket` — relay sobre REST também se qualifica.                                                                     |
| 401 em request socket                                     | `AuthRefreshCoordinator.refreshAccessToken()` → reconectar com novo token; se falhar, `AuthSessionEvents.notifyInvalidated()`.                                                                                                                                                                                              |
| `AuthSessionEvents.invalidated` (logout, refresh fail)    | `ConsumerSocketConnection.disconnect()`.                                                                                                                                                                                                                                                                                    |
| App em background (`AppLifecycleState.paused`/`detached`) | `connection.pause()` desconecta — decisão deliberada por **mobile economy** (bateria/dados). Detalhado em `consumer_socket_connection_design.md` §9.                                                                                                                                                                        |
| App volta ao foreground (`resumed`)                       | `connection.resume()` reabre o socket; UI se atualiza pelo refresh normal e pelo stream de presença assim que reconectar.                                                                                                                                                                                                   |
| Logout explícito                                          | `disconnect(clearListeners: true)` antes de limpar a sessão.                                                                                                                                                                                                                                                                |

---

## 11. Roadmap por fases (consolidado com melhorias de desempenho)

> Cada item marcado **P0/P1/P2/P3** vem do
> `socket_channel_performance_review.md` §5–§9 (priorização por
> custo-benefício). Itens sem marca são do plano base.

### Fase 0 — Plano e dependência (este documento)

- [x] Plano executivo (`socket_consumer_channel_plan.md`).
- [x] Designs companheiros (`consumer_socket_connection_design.md`,
      `socket_command_dispatcher_design.md`,
      `agent_presence_realtime_design.md`,
      `socket_channel_performance_review.md`).
- [x] Atualizar `project_platform_dependencies.mdc` para listar
      `socket_io_client` como dependência ativa
      (entrada em `.cursor/rules/project_platform_dependencies.mdc:53`).
- [x] **Resolvido ponto aberto §13 do `socket_command_dispatcher_design.md`**:
      `AgentSqlBridgeResponse.parseSuccess` permanece em
      `features/agent_queries/data/models/`. O dispatcher
      (`socket_command_dispatcher_impl.dart`) classifica outcomes
      inspecionando `response.item.error` no map cru, sem importar a
      feature — isso preserva a fronteira `core/socket/ → features/`
      sem precisar promover o parser para `core/network/jsonrpc/`.

### Fase 1.0 — Núcleo do canal `agents:command` (paridade com REST)

Entrega: SQL executado via Socket usando o mesmo body do REST.

- [x] `pubspec.yaml`: `socket_io_client: ^3.1.4`.
- [x] `core/config/env_keys.dart` + `app_environment.dart`:
      `AGENT_BRIDGE_TRANSPORT` enum + envs novas (§8).
- [x] `core/socket/`: factory, url resolver, token provider,
      `connection_ready_payload`, `consumer_socket_connection` com
      backoff exponencial + **single-flight**.
- [x] `core/socket/socket_request_correlator` + `socket_command_dispatcher_impl`
      com `Stream<AgentCommandOutcome>` (sealed) e mapeamento de erros.
- [x] `core/di/injector_socket.dart` + integração em `injector.dart`.
- [x] Extrair helper `agent_sql_execute_request_to_bridge_body.dart`
      compartilhado entre REST e Socket (paridade byte-a-byte).
- [x] `socket_agent_queries_remote_datasource.dart`.
- [x] Switch em `injector_agent_queries.dart`.
- [x] Testes unit (§13) + E2E opt-in com SQL real (§0.2.1).
- [x] **App lifecycle hook**: `pause()`/`resume()` via
      `lib/app/socket_lifecycle_observer.dart` (`WidgetsBindingObserver`).

### Fase 1.1 — Hardening de desempenho (P0 + P1)

Entrega: **mesma sprint** da 1.0 estabilizar; cada item é um sub-PR pequeno.

- [x] **P0** — `core/observability/socket_channel_metrics.dart` (review §5.8):
      `handshake_ms`, `dispatch_ms` por `(agentId, method)`, `outcomes_total`
      por `(kind, reasonCode)`, `inflight_peak_per_agent`, `reconnects_total`.
      Logging estruturado + breadcrumbs Sentry.
- [x] **P0** — Backoff de reconexão **com jitter** (review §5.4): trocar
      `_nextBackoff` por full jitter; `Random` injetado para teste
      determinístico.
- [x] **P1** — `PerAgentConcurrencyGate` (review §5.5): semáforo no
      dispatcher (`acquire`/`release`) com `SOCKET_MAX_INFLIGHT_PER_AGENT=8`.
- [x] **P1** — Request **coalescing** no dispatcher (review §5.1):
      `_inflightByKey` com hash estável de `(agentId, method, params, options)`.
- [x] **P1** — Warm-up no `LoginUseCase` (review §5.7) gated por
      `SOCKET_WARM_UP_AFTER_LOGIN`.

### Fase 1.2 — Otimizações dependentes de telemetria (P2)

Entregas só após 1 ciclo com dados das métricas P0.

- [x] **P2** — `AgentLatencyOracle` + timeout adaptativo (review §5.3) com
      EWMA por `(agentId, method)`; gated por `SOCKET_TIMEOUT_ADAPTIVE_ENABLED`.
- [x] **P2** — `AgentCommandBatchCoordinator` (review §5.2): coalesce N RPCs
      ao mesmo agente em janela de `SOCKET_BATCH_WINDOW_MS=8` e envia
      `command: [...]` (max 32). Doc detalhado em
      `docs/Features/agent_command_batch_coordinator_design.md`.
- [x] **P2** — `SocketCommandCancelToken` (review §5.6) — `dispatcher.cancel(rpcId)` + helper `SocketCommandCancelToken` (`register/cancelAll/dispose`).
      Integração explícita com `sql.cancel` para streams fica para um
      sub-PR futuro quando algum controller usar streaming.

### Fase 2 — `relay:*` + PayloadFrame

- [x] **PR-K** — `core/socket/payload_frame.dart` + `payload_frame_codec.dart`
      (encode auto-gzip + decode com validação estrutural:
      `enc==json`, `cmp ∈ {none,gzip}`, tamanho ≤ 10 MiB, inflação ≤ 10x,
      `compressedSize`/`originalSize` consistentes).
- [x] **PR-K** — Suporte a `connection:ready` em PayloadFrame na
      `ConsumerSocketConnection` via `PayloadFrameConnectionReadyDecoder`
      e `CompatConnectionReadyDecoder` (gated por
      `SOCKET_CONNECTION_READY_COMPAT_MODE`: `payload_frame_only` default,
      `compat` e `raw_json_only` como overrides explicitos).
- [x] **PR-L** — `RelayConversation` + `RelayConversationManager`
      (uma conversa por `agentId`, single-flight em `start()`,
      `forceEnd` em socket drop) em `lib/core/socket/relay/`.
- [x] **PR-L** — `RelayCommandDispatcher` (interface + impl) com
      `sendUnary({agentId, body, clientRequestId, timeout, compression})`
      ➜ encoda `PayloadFrame`, emite `relay:rpc.request`, correlaciona
      via `clientRequestId` ↔ `requestId` (do `relay:rpc.accepted`),
      finaliza em `relay:rpc.response` ou `relay:rpc.complete`
      (`terminal_status`). Erros mapeados para a sealed
      `RelayDispatchException`
      (`RelayConversationStartFailure`, `RelayConversationLost`,
      `RelayRequestRejected`, `RelayStreamTerminated`,
      `RelayRequestTimeout`, `RelayDecodeFailure`,
      `RelayDuplicateRequestId`, `RelayDispatcherDisposed`).
- [x] **PR-L** — `RelayAgentQueriesRemoteDataSource` (Standalone) —
      reusa `AgentSqlExecuteRequestToBridgeBody`, byte-igual ao
      REST/`agents:command`. Não está cabeada por padrão — em PR
      seguinte adicionamos seleção por query (`useRelay`).
- [x] **PR-L** — Envs: `SOCKET_RELAY_ENABLED`,
      `SOCKET_RELAY_REQUEST_TIMEOUT_MS`,
      `SOCKET_RELAY_CONVERSATION_START_TIMEOUT_MS`,
      `SOCKET_RELAY_CONVERSATION_END_TIMEOUT_MS`,
      `SOCKET_RELAY_PAYLOAD_FRAME_COMPRESSION` (`default` |
      `none` | `always`, mapeado para `RelayPayloadFrameCompression`).
- [x] **PR-L** — DI: `injector_socket` registra
      `RelayConversationManager` e `RelayCommandDispatcher` apenas
      quando `SOCKET_RELAY_ENABLED=true` (lazy, com `dispose`).
- [x] **PR-L+ parte 1** — Selector per-query (`useRelay` em
      `AgentSqlExecuteRequest`, default `false`, validado por teste
      garantindo que **não** vaza para o body) +
      `HybridAgentQueriesRemoteDataSource` que despacha
      `useRelay==true` para a relay datasource e o restante para a base
      (REST ou `agents:command`). Wrap automático no
      `injector_agent_queries.dart` quando `RelayCommandDispatcher`
      está registrado (`SOCKET_RELAY_ENABLED=true`); fallback logado
      como `relay_bypass` quando o relay não foi inicializado.
- [x] **PR-L+ parte 2** — Streaming via `relay:rpc.chunk` +
      `relay:rpc.stream.pull` no `RelayCommandDispatcher.sendStreaming`
      com auto-pull rolante. O pull segue o contrato atual do hub:
      envelope `{ conversationId, frame }` com `PayloadFrame` contendo
      `request_id`, `window_size` e `stream_id` quando conhecido. Refator interno em sealed
      `_PendingRelay` ↔ `_PendingUnary` / `_PendingStream` para o
      mesmo dispatcher cobrir ambos os modos. Envs novas
      `SOCKET_RELAY_STREAM_INITIAL_WINDOW` (default 32) e
      `SOCKET_RELAY_STREAM_REFILL_THRESHOLD` (default 16).
- [x] **PR-L+ parte 3** — Camada de dados streaming: port
      `AgentQueriesStreamingRemoteDataSource` (separado do unary por
      ISP) + impl `RelayStreamingAgentQueriesRemoteDataSource`. DI
      condicional em `RelayCommandDispatcher`.
- [x] **PR-L+ parte 3.5** — Dispatcher forwarda `relay:rpc.complete`
      payload como item final do stream + `BridgeShapedSqlExecuteCollector`
      agrega chunks no shape do `AgentSqlBridgeResponse.parseSuccess` + `CollectingRelayStreamingAgentQueriesRemoteDataSource`
      implementa o port unitário via streaming. Repository não muda;
      é só swap de DI.
- [x] **PR-M parte 1** — Listener de `client:agent.profile.updated`
      (entra com PayloadFrame) — `ClientAgentProfileUpdatedListener` + `AgentCommandPresenceHinter` + `SocketAgentPresenceStream` +
      `ObserveAgentPresenceUseCase` em
      `lib/features/client_agents/{domain,application,data/socket}/`.
      Integração com presença em tempo real (§19).
- [x] **PR-M parte 2** — Wire-up no `ClientAgentsController`:
      subscription opcional + dedup por `observedAt` + refresh
      debounced 5 s + `dispose()` idempotente.
- [x] **PR-M parte 3** — Camada 3 REST (`AgentPresencePoller`) +
      visibility gating no controller + `RouteAware` na page.
- [ ] **P3** — Compressão adaptativa (review §5.9): gzip síncrono < 64 KiB,
      `compute(...)` (Isolate) acima de
      `SOCKET_PAYLOAD_FRAME_ASYNC_GZIP_MIN_BYTES`.
- [ ] **P3** — Dedup pós-reconexão universal (review §5.10) reaproveitando
      `_lastObservedByAgentId` da presença.

### Fase 2.5 — Validação operacional (E2E)

- [x] E2E opt-in com SQL real em `test/integration/e2e/` (ver §0.2.1).
      Smokes com `SELECT 1` removidos (política do banco).
- [x] **Achado real do primeiro run**: hub produção precisa de
      `SOCKET_CONSUMER_ROLES=user,admin,client`. Documentado em
      §0.2.1 ("Resultado do primeiro run").
- [ ] **Operacional (servidor)**: aplicar
      `SOCKET_CONSUMER_ROLES=user,admin,client` no `plug_server` +
      validar cadeia socket no app ou E2E com queries reais.

### Fase 3 — Hybrid + observabilidade avançada

- [ ] `HybridAgentQueriesRemoteDataSource` (fallback Socket → REST).
      **Só ativar com métricas P0 mostrando necessidade.**
- [ ] OTel no cliente: propagar `traceparent` em `command.meta` (opcional).

---

## 11.5. Estratégia de transporte por carga (matriz de decisão)

Resumo da matriz completa em `socket_channel_performance_review.md` §4.
Esta tabela rege como o `AgentQueryExecutor` (ou um coordenador novo
introduzido em P2) deve escolher o canal por **wave** de queries:

| Situação                                          | Canal recomendado                                                              | Por quê                                                |
| ------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------ |
| 1 query, resposta pequena/média                   | `agents:command` unitário (Fase 1)                                             | Menor overhead, envelope único.                        |
| 1 query, resultado em stream grande               | `agents:command` com **paginação server-side** (`page`/`pageSize` ou `cursor`) | Evita materialização REST.                             |
| 1 query, resposta enorme (> 10 MiB)               | `relay:*` com `stream.pull` (Fase 2)                                           | Streaming progressivo + backpressure.                  |
| **N queries independentes ao mesmo agente**       | **Batch JSON-RPC** (`command: [...]`, máx **32**) (P2)                         | 1 emit, 1 correlação; reduz N RTT para 1 RTT.          |
| N queries com mesmo SQL e `params` variando       | `sql.executeBatch` (Fase 1)                                                    | Transação opcional no agente; resultados em `items[]`. |
| 1 SQL com vários `SELECT` agregados               | `multi_result: true` (Fase 1)                                                  | 1 round-trip ao banco, 1 RPC.                          |
| Queries em agentes diferentes simultaneamente     | Fan-out com **teto in-flight por agente** (P1)                                 | Reaproveita `AgentQueryExecutor.mergeAll`; evita 429.  |
| Push de catálogo (`client:agent.profile.updated`) | Listener passivo `/consumers` (Fase 2 / Presença §19)                          | Sem polling.                                           |

**Regras duras:**

- Relay (`relay:*`) **não aceita** batch JSON-RPC nem `id: null`
  (notifications). Batch é exclusivo de `agents:command`.
- Batch nativo limita a **32** RPCs por emissão (limite oficial do hub).
- Paginação no `body.pagination` só vale para `sql.execute` **único**, não
  para batch.

---

## 11.6. Anti-padrões (não fazer)

Lista normativa do `socket_channel_performance_review.md` §6.

| Anti-padrão                                                | Por quê                                                                                                  |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Múltiplos sockets paralelos por app                        | Socket.IO foi desenhado para um canal por cliente; piora rate-limit e auditoria. Singleton via `get_it`. |
| `autoConnect: true` no factory                             | Vai conectar antes de termos token; `connect_error` inútil no startup.                                   |
| Habilitar `perMessageDeflate` no cliente                   | Dupla compressão com PayloadFrame; CPU desperdiçada. O hub já desliga por default.                       |
| Retry infinito sem terminal                                | Loop em 401 persistente; o plano trata com `unauthorized` após 1 refresh.                                |
| Logar `command.params.sql`, `client_token` ou `auth.token` | Privacidade + tamanho. Logar só `agentId`, `method`, `rpcId`.                                            |
| Usar REST para streams grandes                             | Hub materializa tudo em RAM e pode gerar 503. Socket é o canal certo para > ~50k linhas.                 |
| Mudar `AGENT_BRIDGE_TRANSPORT` em runtime                  | Invalida correlator/cache; decisão é por build/env.                                                      |
| Paralelizar batches JSON-RPC                               | Batch já empacota até 32; paralelizar fura o rate-limit compartilhado.                                   |
| Reconectar sem refresh em 401                              | Loop garantido. Sempre passar pelo `AuthRefreshCoordinator`.                                             |
| Ler `connection.raw` de `presentation/` ou `application/`  | Quebra DIP; `raw` é restrito a adapters em `core/socket/*` e `data/socket/*`.                            |

---

## 12. Impacto em outras features

| Feature                     | Impacto                                | Ação                                                                               |
| --------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------- |
| `auth`                      | nenhum no fluxo HTTP.                  | manter; só fornece `AuthSessionEvents` para o socket.                              |
| `client_agents`             | hoje usa REST `/client/me/agents` etc. | manter REST; em Fase 3 podemos invalidar cache via `client:agent.profile.updated`. |
| `overview`, `agent_queries` | só consomem `*Repository`.             | nenhuma alteração de UI/use cases.                                                 |
| `user_context`              | não toca SQL.                          | nenhum impacto.                                                                    |

---

## 13. Estratégia de testes

Seguindo `testing_dart_flutter.mdc` e o padrão atual do repo:

### 13.1 Unit

- `core/socket/socket_request_correlator_test.dart`:
  - id único, completer resolvido, timeout dispara `TimeoutException`,
    `cancel` limpa estado.
- `core/socket/consumer_socket_connection_test.dart`:
  - mock `IO.Socket` (via `mocktail` + interface do factory):
    estado vai para `connecting → connected` em `connection:ready`;
    em `connect_error` 401, chama `refreshAccessToken` e reconecta.
- `core/socket/socket_command_dispatcher_test.dart`:
  - emite com body certo, recebe `agents:command_response` e completa o
    completer correto; `app:error` com `AGENT_ACCESS_DENIED` → `AuthorizationFailure`.
- `features/agent_queries/data/datasources/socket_agent_queries_remote_datasource_test.dart`:
  - body emitido bate com o esperado (mesmo `agentId`, `pagination`, etc.).
  - `Map` retornado é igual ao do `Api…` para o **mesmo** payload de resposta
    (assegura compatibilidade com `AgentSqlBridgeResponse`).

### 13.2 Integração (`test/integration`)

- Reaproveitar credenciais já presentes (`E2E_CLIENT_EMAIL`, `E2E_CLIENT_PASSWORD`,
  `E2E_AGENT_ID`, `E2E_CLIENT_TOKEN`).
- Novo `agent_queries_socket_e2e_test.dart` — só roda quando
  `AGENT_BRIDGE_TRANSPORT=socket` e credenciais e2e disponíveis.
- Cobre: login REST → conectar socket → `sql.execute` simples → comparação de
  contagem com mesma query via REST.

### 13.3 Mocks

- Padronizar uma fake `ConsumerSocketConnection` para testes de feature evitar
  abrir socket real.

---

## 14. Observabilidade e logging

- Reutilizar `AppLogger` com contexto:
  - `component: 'ConsumerSocketConnection'`, `state: <novo>`.
  - `component: 'SocketCommandDispatcher'`, `event`, `requestId`, `agentId`,
    `elapsedMs`.
- Sentry: `Sentry.addBreadcrumb` em mudanças de estado e em falhas mapeadas.
- Métricas internas (Fase 2): contadores em memória de timeout/dedupe/erro
  por agente.

---

## 15. Segurança

- Token nunca aparece em logs (`AppLogger` já sanitiza query para REST; no
  socket, **nunca** logar `auth.token`; logar apenas presença/ausência).
- Reuso de `flutter_secure_storage` via `AuthSessionAccessor` (não cachear
  token em memória global).
- Em build web, atenção a CORS/`websocket` — usar `setTransports(['websocket'])`
  e validar com nginx do hub (`docs/nginx_production.md`).

---

## 16. Riscos e mitigação

| Risco                                                                     | Mitigação                                                                                                                                                 |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hub antigo ainda emitir raw JSON em `connection:ready`                   | Usar `SOCKET_CONNECTION_READY_COMPAT_MODE=compat` ou `raw_json_only` temporariamente; o default atual é `payload_frame_only`.                              |
| Reconexão em loop após 401                                                | Single-flight via `AuthRefreshCoordinator` (igual REST); se refresh falha, parar reconexão e `notifyInvalidated`.                                         |
| Multi-instância do hub (afinidade)                                        | Para Fase 1 (`agents:command`) compartilha mesmo hub; Fase 2 (relay) — documentar dependência de sticky sessions (já citado em `scaling_and_roadmap.md`). |
| Web vs mobile (transports)                                                | Forçar `websocket` em mobile; em web manter `websocket` apenas (produção do hub usa só WS).                                                               |
| Rate-limit compartilhado com REST                                         | Métricas por feature; alternar para `relay:*` quando justificar.                                                                                          |
| Mudança de contrato do hub                                                | Resposta do `agents:command_response` segue o mesmo envelope do REST; testes de contrato no datasource cobrem regressões.                                 |

---

## 17. Critérios de aceite

### 17.1 Funcionais (Fase 1.0)

1. Ligar `AGENT_BRIDGE_TRANSPORT=socket` faz **toda** a feature `agent_queries`
   funcionar sem alteração de UI/use cases/repositórios de domínio.
2. Em `rest` (default), comportamento atual é byte-a-byte idêntico.
3. Logout/expiração derruba o socket e impede novas requests.
4. 401 em request socket aciona refresh e re-tenta **uma** vez; segundo 401
   leva a `unauthorized` (terminal).
5. Cobertura: `≥ 90%` linhas em `core/socket/*` e no novo datasource.
6. `flutter analyze` limpo; sem novos lints `very_good_analysis`.
7. Single-flight do `connect()` verificado em teste com 100 chamadas paralelas.
8. Body do Socket é **byte-igual** ao do REST (snapshot test
   `agent_sql_execute_request_to_bridge_body_test.dart`).

### 17.2 Arquiteturais

9. `core/socket/` não importa `features/auth/` direto (apenas via port
   `SocketAuthTokenProvider`).
10. `domain/` continua sem qualquer import de `socket_io_client`, `dio` ou
    `dart:io`.
11. `presentation/` e `application/` consomem só interfaces; nenhum acesso a
    `connection.raw` fora de `core/socket/*` e `data/socket/*`.

### 17.3 Performance (Fase 1.1, com baseline obrigatório)

> Comparar antes/depois usando o template em
> `socket_channel_performance_review.md` §7.3.

12. **`p95(dispatch_ms)` no Socket ≤ p95 do REST** em rede equivalente para
    a mesma query (medido em integração e2e).
13. **`handshake_ms` p95 < 500 ms** em rede 4G estável.
14. **`outcomes_total{kind='FailedTransient'}` ≤ 1%** do total em sessão de
    15+ min com tráfego normal.
15. **Zero** `inflight_peak_per_agent > SOCKET_MAX_INFLIGHT_PER_AGENT` (P1
    funcionando).
16. **Reconexões coordenadas** (hub restart) não geram thundering herd
    perceptível em logs (P0 jitter funcionando).

### 17.4 Performance (Fase 1.2, opcional mas recomendado)

17. **Batch JSON-RPC** (P2) reduz `p95(dispatch_ms)` em waves do `overview`
    em **≥ 30%** vs Fase 1.1.
18. **Coalescing** (P1) elimina **≥ 80%** dos emits duplicados detectados
    nas métricas (`coalesced_total / outcomes_total`).

---

## 18. Apêndice — exemplo de body `agents:command` (igual ao REST)

```json
{
  "agentId": "3183a9f2-429b-46d6-a339-3580e5e5cb31",
  "timeoutMs": 15000,
  "command": {
    "jsonrpc": "2.0",
    "method": "sql.execute",
    "id": "8c2d…-uuid-…",
    "params": {
      "sql": "SELECT 1",
      "client_token": "<token>",
      "options": { "execution_mode": "preserve" }
    }
  }
}
```

E o esqueleto de `connect`:

```dart
final socket = IO.io(
  urlResolver.consumersUrl,                         // ex.: https://hub.example.com/consumers
  IO.OptionBuilder()
      .setTransports(<String>['websocket'])
      .setAuth(<String, dynamic>{'token': accessToken})
      .disableAutoConnect()
      .build(),
);
socket
  ..onConnect((_) => _setState(connected))
  ..onConnectError((err) => _onConnectError(err))
  ..on('connection:ready', _onConnectionReady)
  ..on('agents:command_response', _onCommandResponse)
  ..on('app:error', _onAppError);
socket.connect();
```

---

## 19. Presença de agente em tempo real (feature `client_agents`)

### 19.1 O que existe hoje no Colmeia

Toda a UI de **Agent management** (telas vistas em `Approved agents`,
`Agent detail`) consome a presença online via:

| Camada            | Local                                                                                                                                                                                                                          |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Domínio           | `lib/features/client_agents/domain/entities/agent_connection_status.dart` (`online`/`offline`/`unknown`)                                                                                                                       |
| Resolução pura    | `lib/features/client_agents/domain/services/agent_connection_status_resolver.dart` (`isHubConnected` ?? lookup em `onlineAgentIds`)                                                                                            |
| Repositório       | `ClientAgentsRepository.loadOnlineAgentIds(...)`, `loadApprovedAgents(includeOnlineStatus: true, refresh: …)`, `loadApprovedAgentById(...)`                                                                                    |
| Datasource REST   | `ClientAgentsRemoteDataSource.fetchOnlineAgents(...)` → `GET /api/v1/agents` (somente `user`); `fetchApprovedAgents(...)` → `GET /api/v1/client/me/agents` (com `isHubConnected` por linha)                                    |
| Cache local       | `ClientAgentsLocalDataSource.{read,save}OnlineAgents` (TTL **fresh = 1 min**, fallback **7 dias**) e `_persistHubPresenceCacheFromProfiles(...)` que sintetiza presença a partir do `isHubConnected` das respostas de catálogo |
| Refresh manual    | `ClientAgentsController.refreshAll()` (botão `Refresh` no topo da tela)                                                                                                                                                        |
| Polling explícito | só durante o fluxo de aprovação: `_startApprovalPolling` (10 s × até 3 min) — **não** existe polling contínuo de presença                                                                                                      |

Conclusão: hoje a **presença é amostral**, refrescada em interações do
usuário (load inicial / `Refresh` / depois de mutar acesso). Não há
notificação push.

### 19.2 O que o hub `plug_server` oferece hoje

Confirmado nos docs (`socket_client_sdk.md`, `client_agent_business_rules.md`,
`observability.md`):

| Evento Socket no `/consumers`                                                                    | Significado                                                                                                                                                 | Útil para presença?                                                                                                           |
| ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `client:agent.profile.updated` (PayloadFrame)                                                    | Catálogo/perfil do agente mudou (HTTP / socket / pull sync). Payload típico: `agent_id`, `profile_version`, `profileUpdatedAt`, `changed_fields`, `source`. | **Indireto.** Disparado em mudanças de catálogo; reflete presença apenas quando a re-sincronização atualiza `isHubConnected`. |
| `connection:ready`                                                                               | Confirmação do handshake do consumer.                                                                                                                       | **Não.** Apenas saúde do próprio socket do app.                                                                               |
| `agents:command_response` / erros (`AGENT_OFFLINE`, `protocol_not_ready`, `AGENT_ACCESS_DENIED`) | Resposta do hub ao executar um RPC.                                                                                                                         | **Indireto.** Se a query falha por offline, sabemos que naquele instante estava offline.                                      |

> ⚠️ **Lacuna do hub:** atualmente **não existe** um evento dedicado
> `client:agent.presence.changed` (online/offline) emitido para consumers.
> A presença oficial em tempo real só é exposta para `user` via
> `GET /api/v1/agents` (REST) e como `isHubConnected` no catálogo aprovado.

### 19.3 Estratégia recomendada (em camadas)

Combinamos três fontes para subir a percepção de "tempo real" sem
depender de feature ainda não exposta pelo hub:

#### Camada 1 — Push de catálogo (Socket, **disponível hoje**)

- Subscrever **`client:agent.profile.updated`** assim que a
  `ConsumerSocketConnection` confirmar `connection:ready`.
- Para cada notificação de `agent_id`:
  1. Decodificar `PayloadFrame`.
  2. Verificar se o `Client` tem aprovação para esse agente
     (set local de `_approvedAgents`).
  3. Disparar `loadApprovedAgentById(refresh: true)` — atualiza o
     `isHubConnected` do agente e propaga via `notifyListeners` no
     `ClientAgentsController` (UI muda o badge `online`/`offline`).
  4. Atualizar o cache de presença sintético via
     `_persistHubPresenceCacheFromProfiles` (já existe).

#### Camada 2 — Sinal implícito do próprio canal de comandos (Socket)

- Quando `SocketCommandDispatcher.sendAgentsCommand(...)` (do plano §6.5)
  retornar erro `AGENT_OFFLINE` / `protocol_not_ready`, **emitir** um
  evento interno `AgentPresenceHint(agentId, online: false)`.
- Quando retornar sucesso, emitir `AgentPresenceHint(agentId, online: true)`.
- Esses hints alimentam o mesmo cache de presença usado por
  `loadOnlineAgentIds` (mantemos a regra do `agent_connection_status_resolver`).

#### Camada 3 — Refresh adaptativo (REST, fallback existente)

- Mantém o comportamento atual do `Refresh` manual.
- Acrescentar **polling adaptativo** **somente** quando:
  - a tela `client_agents` está visível (gate por route observer); **e**
  - o socket está em estado `disconnected` ou `error`.
- Intervalo sugerido: 30 s na tela ativa, sem polling em background.
  Reaproveita o mesmo `Timer.periodic` usado em `_startApprovalPolling`,
  centralizado em um `AgentPresencePoller` (novo serviço de application).

### 19.4 Estrutura proposta (Clean Architecture + DIP)

```text
lib/
  core/
    socket/
      consumer_socket_connection.dart           (do plano §6.2)
      socket_command_dispatcher.dart            (do plano §6.5)
      payload_frame.dart                        (Fase 2)
  features/
    client_agents/
      domain/
        services/
          agent_connection_status_resolver.dart # mantém
        events/
          agent_presence_event.dart             # NOVO (sealed: changed/hint)
        ports/
          agent_presence_stream.dart            # NOVO (interface: Stream<AgentPresenceEvent>)
      data/
        socket/
          client_agent_profile_updated_listener.dart  # NOVO: assina evento e mapeia para AgentPresenceEvent
          socket_agent_presence_stream.dart           # NOVO: implementa AgentPresenceStream usando o listener + hints do dispatcher
        repositories/
          client_agents_repository_impl.dart    # mantém; recebe um novo método `applyPresenceHint(...)` opcional ou consome via AgentPresenceCacheGateway
      application/
        usecases/
          observe_agent_presence_use_case.dart  # NOVO: expõe Stream<AgentPresenceEvent> à apresentação
        services/
          agent_presence_poller.dart            # NOVO: fallback REST com gate de visibilidade + estado do socket
      presentation/
        controllers/
          client_agents_controller.dart         # consome ObserveAgentPresenceUseCase + atualiza in-memory state
```

**Novas portas / interfaces:**

```dart
// domain/ports/agent_presence_stream.dart
abstract interface class AgentPresenceStream {
  Stream<AgentPresenceEvent> events();
  Future<void> dispose();
}

// domain/events/agent_presence_event.dart
sealed class AgentPresenceEvent {
  const AgentPresenceEvent(this.agentId, this.observedAt);
  final String agentId;
  final DateTime observedAt;
}

final class AgentPresenceCatalogUpdated extends AgentPresenceEvent {
  const AgentPresenceCatalogUpdated({
    required String agentId,
    required DateTime observedAt,
    required this.profileVersion,
    required this.changedFields,
  }) : super(agentId, observedAt);
  final int? profileVersion;
  final Set<String> changedFields;
}

final class AgentPresenceHint extends AgentPresenceEvent {
  const AgentPresenceHint({
    required String agentId,
    required DateTime observedAt,
    required this.online,
    required this.source, // 'agents:command_error' | 'agents:command_success'
  }) : super(agentId, observedAt);
  final bool online;
  final String source;
}
```

### 19.5 Como o `ClientAgentsController` integra

1. Em `initialize()` (já existente), além de `_refreshAll`, registra:

   ```dart
   _presenceSubscription = _observeAgentPresenceUseCase().listen(_onPresence);
   ```

2. `_onPresence` (novo método):
   - `AgentPresenceCatalogUpdated`: chama
     `_loadClientAgentDetailUseCase(agentId, refresh: true)`. Em sucesso,
     usa `_upsertApprovedAgentsInMemory([agent])` (já existe) para
     trocar **só** o agente afetado e `notifyListeners`.
   - `AgentPresenceHint(online: false)`: aplica `copyWith(connectionStatus: offline)`
     localmente sem ir à rede; agenda `loadApprovedAgentById` debounced
     (≥ 5 s) para confirmar.
   - `AgentPresenceHint(online: true)`: idem, mas com
     `AgentConnectionStatus.online`.

3. Em `dispose()`: cancela `_presenceSubscription` e o `AgentPresencePoller`.

> SOLID:
>
> - **SRP**: parsing do PayloadFrame fica em `client_agent_profile_updated_listener`,
>   tradução para evento de domínio em `socket_agent_presence_stream`,
>   reação à mudança em `_onPresence` do controller.
> - **DIP**: o controller depende só de `ObserveAgentPresenceUseCase`
>   (que devolve `Stream<AgentPresenceEvent>`); a fonte (Socket ou
>   `AgentPresencePoller` REST) é detalhe.
> - **OCP**: quando o hub passar a emitir `client:agent.presence.changed`,
>   adicionamos um novo `Listener` ao `socket_agent_presence_stream` sem
>   tocar na UI/usecase.

### 19.6 Multi-instância / `isHubConnected` (limitação herdada)

Conforme `client_agent_business_rules.md` (§3.4) e `scaling_and_roadmap.md`:

- `isHubConnected` é **por processo** do hub. Em deploy multi-réplica
  sem sticky session, pode aparecer `false` na réplica do REST mesmo
  com o agente ligado em outra.
- Mitigação que **já adotamos**: socket e REST devem usar a **mesma base
  URL** (a `apiBaseUrl` é a mesma origem). Em produção isso pressupõe
  load balancer com afinidade ou única réplica ativa do hub.
- Acrescentar (operacional, não código): documentar a flag
  `HUB_INSTANCE_ID` para correlacionar respostas REST com a réplica
  via header `X-Hub-Instance-Id`. Útil para diagnóstico.

### 19.7 Faseamento desta capacidade

> Status: as 3 camadas estão entregues. Mantido como histórico do
> faseamento original.

- **Fase 1** (`agents:command`): Camada 2 (hints implícitos) — **PR-M p1
  entregue** (`AgentCommandPresenceHinter`).
- **Fase 2** (`relay:*` + `PayloadFrame`): Camada 1
  (`client:agent.profile.updated` em `PayloadFrame`) — **PR-M p1
  entregue** (`ClientAgentProfileUpdatedListener` decodifica
  `PayloadFrame` por padrão; raw JSON só com
  `SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED=true`).
- **Fase 3 / Camada 3** (REST polling com visibility gating) — **PR-M p3
  entregue** (`AgentPresencePoller` + `RouteAware`).
- **Futuro** (push dedicado): se o hub adicionar
  `client:agent.presence.changed`, é só um novo listener no
  `SocketAgentPresenceStream` — UI/cache permanecem (§19.8).

### 19.8 Solicitação ao time do `plug_server`

Pedido formal a registrar (após este plano ser aprovado): adicionar
evento dedicado **`client:agent.presence.changed`** no namespace
`/consumers`, gated por `ClientAgentAccess`, com payload mínimo:

```json
{
  "agent_id": "...",
  "online": true,
  "observed_at": "2026-04-17T12:00:00Z",
  "hub_instance_id": "..."
}
```

Isso elimina a necessidade da Camada 3 (polling) para presença.

### 19.9 Critérios de aceite (presença)

1. Botão `Refresh` continua funcionando idêntico em offline/online de socket.
2. Com socket conectado, mudar o status no servidor (ex.: derrubar o agente)
   reflete na UI em **≤ 5 s** quando houver `client:agent.profile.updated`,
   ou em **≤ 30 s** via Camada 2 + polling adaptativo.
3. Sem socket (Fase 1 inativa), comportamento atual permanece intacto.
4. Sem regressão nos testes de `client_agents` existentes
   (`test/features/client_agents/...`).
5. Novo teste `socket_agent_presence_stream_test.dart` cobre:
   parsing do `client:agent.profile.updated`, geração de hints a partir
   do dispatcher, deduplicação por `agentId + observedAt`.

---

## 20. Próximos passos (acionáveis)

### 20.1 Decisões de aprovação

1. **Aprovar este plano** (escolher Opção A na §7, confirmar default `rest`).
2. **Aprovar designs companheiros** (4 docs em `docs/Features/`).
3. **Aprovar pacote** `socket_io_client: ^3.1.4`; atualizar
   `.cursor/rules/project_platform_dependencies.mdc`.
4. **Resolver ponto aberto** §13 do `socket_command_dispatcher_design.md`:
   mover `parseSuccess` para `core/network/jsonrpc/` (recomendado).

### 20.2 PRs sugeridos (em ordem)

| PR                        | Conteúdo                                                                                                                                                                                                                                                                                                                                                                   | Fase    |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| **PR-A (entregue)**       | Pacote + `core/socket/*` (factory, url resolver, token provider, connection com backoff/single-flight) + DI sem trocar default.                                                                                                                                                                                                                                            | 1.0     |
| **PR-B (entregue)**       | `SocketCommandDispatcher` + correlator + outcomes + helper de body compartilhado + datasource Socket + switch no `injector_agent_queries`.                                                                                                                                                                                                                                 | 1.0     |
| **PR-C (entregue)**       | `WidgetsBindingObserver` para `pause`/`resume` (`socket_lifecycle_observer.dart`) + warm-up no `LoginUseCase`.                                                                                                                                                                                                                                                             | 1.0/1.1 |
| **PR-D (P0, entregue)**   | `SocketChannelMetrics` (telemetria mínima) — **destrava** validação das próximas.                                                                                                                                                                                                                                                                                          | 1.1     |
| **PR-E (P0, entregue)**   | Jitter no backoff de reconexão (`socket_reconnect_backoff.dart`).                                                                                                                                                                                                                                                                                                          | 1.1     |
| **PR-F (P1, entregue)**   | `PerAgentConcurrencyGate` + `SOCKET_MAX_INFLIGHT_PER_AGENT`.                                                                                                                                                                                                                                                                                                               | 1.1     |
| **PR-G (P1, entregue)**   | Request coalescing no dispatcher (`socket_coalesce_key.dart`).                                                                                                                                                                                                                                                                                                             | 1.1     |
| **PR-H (P2, entregue)**   | `AgentLatencyOracle` + timeout adaptativo (gated).                                                                                                                                                                                                                                                                                                                         | 1.2     |
| **PR-I (P2, entregue)**   | `AgentCommandBatchCoordinator` (`agent_command_batch_coordinator_design.md`).                                                                                                                                                                                                                                                                                              | 1.2     |
| **PR-J (P2, entregue)**   | `SocketCommandCancelToken` + `dispatcher.cancel(rpcId, reason)` + `SocketDispatchCancelled`. Integração com `sql.cancel` para streams fica para um sub-PR futuro quando algum controller usar streaming.                                                                                                                                                                   | 1.2     |
| **PR-K (entregue)**       | `payload_frame.dart` + `payload_frame_codec.dart` (auto-gzip + limites 10 MiB / 10x) + `PayloadFrameConnectionReadyDecoder` + `CompatConnectionReadyDecoder` (gated por `SOCKET_CONNECTION_READY_COMPAT_MODE`).                                                                                                                                                            | 2       |
| **PR-L (entregue)**       | Relay primitives em `core/socket/relay/`: `RelayConversation`, `RelayConversationManager`, `RelayCommandDispatcher` (`sendUnary`), `RelayDispatchException` (sealed), `RelayPayloadFrameCompression`. `RelayAgentQueriesRemoteDataSource` standalone (não cabeado por padrão). Gated por `SOCKET_RELAY_ENABLED`.                                                           | 2       |
| **PR-L+ p1 (entregue)**   | `useRelay` em `AgentSqlExecuteRequest` + `HybridAgentQueriesRemoteDataSource` com auto-wrap no `injector_agent_queries` (gated por `RelayCommandDispatcher` registrado). Snapshot test garante body byte-igual.                                                                                                                                                            | 2       |
| **PR-L+ p2 (entregue)**   | `RelayCommandDispatcher.sendStreaming(...)` retornando `Stream<Map<String, dynamic>>`. Auto-pull rolante (`SOCKET_RELAY_STREAM_INITIAL_WINDOW` / `_REFILL_THRESHOLD`) via `relay:rpc.stream.pull` com `{ conversationId, frame }`, onde `frame` é `PayloadFrame` contendo `request_id`, `window_size` e `stream_id` quando conhecido. Refator em sealed `_PendingRelay`. Tolera `relay:rpc.response` (single-chunk + close) e mapeia `terminal_status != completed` para `RelayStreamTerminated` no stream. | 2       |
| **PR-L+ p3 (entregue)**   | Port `AgentQueriesStreamingRemoteDataSource` (separado do unary por ISP) + impl `RelayStreamingAgentQueriesRemoteDataSource` reusando `AgentSqlExecuteRequestToBridgeBody`. Auto-wire no `injector_agent_queries.dart` apenas quando o relay está disponível. Pronto pra consumir.                                                                                         | 2       |
| **PR-L+ p3.5 (entregue)** | Dispatcher forwarda `relay:rpc.complete` payload como item final do stream + `BridgeShapedSqlExecuteCollector` agrega chunks no shape do `AgentSqlBridgeResponse` + `CollectingRelayStreamingAgentQueriesRemoteDataSource` implementa o port unitário via streaming. Repository não muda; é só swap de DI.                                                                 | 2       |
| PR-L+ p4 (próximo)        | Registrar o `CollectingRelayStreamingAgentQueriesRemoteDataSource` para uma query específica do `overview`. Swap de DI trivial agora — falta decisão de produto.                                                                                                                                                                                                           | 2       |
| **PR-M p1 (entregue)**    | Pilha de presença em tempo real: sealed `AgentPresenceEvent`, port `AgentPresenceStream`, use case `ObserveAgentPresenceUseCase`, adapters Socket (`ClientAgentProfileUpdatedListener` + `AgentCommandPresenceHinter`), composer `SocketAgentPresenceStream` com re-attach automático. Auto-wire no `injector_client_agents` gated por `SOCKET_PRESENCE_LISTENER_ENABLED`. | 2       |
| **PR-M p2 (entregue)**    | `ClientAgentsController` consome `ObserveAgentPresenceUseCase?` (opcional para preservar a UX legada). Dedup por `observedAt`. `AgentPresenceCatalogUpdated` ➜ `LoadClientAgentDetailUseCase` + upsert. `AgentPresenceHint` ➜ `copyWith(connectionStatus)` in-memory + Timer debounced que confirma via REST. `dispose()` cancela tudo e é idempotente.                    | 2       |
| **PR-M p3 (entregue)**    | `AgentPresencePoller` (Camada 3 REST) + visibility gating no controller (`onScreenVisible/Hidden`) + observação de `ConsumerSocketConnection.states()` + `RouteAware` na page. Poller reagrupa hints `online` em loop interno, sobrevive a erros de rede e é idempotente.                                                                                                  | 2       |
| **E2E SQL (entregue)**    | Testes em `test/integration/e2e/` com consultas reais dos repositórios (`agent_sql_bridge`, `resumo_*`, etc.). Smokes `SELECT 1` removidos — ver §0.2.1.                                                                                                                                                                                                                | 2.5     |
| PR-N                      | Hybrid datasource (REST↔Socket fallback) — **só com métricas P0** confirmando ganho.                                                                                                                                                                                                                                                                                       | 3       |

### 20.3 QA / rollout

5. Rodar QA com `AGENT_BRIDGE_TRANSPORT=socket` em build interna após PR-B.
6. **Coletar baseline** (15–30 min, template em
   `socket_channel_performance_review.md` §7.3) **antes** de mergear PR-D em diante.
7. Promover para default em staging após PR-G; manter `rest` como fallback de
   build até PR-I estabilizar em produção.
8. **Regra de ouro**: alterar **um bloco por vez** e medir. Ganhos somam de
   forma não-linear em sistemas com rate-limit e compressão.

### 20.4 Apresentar ao time `plug_server` (paralelo)

9. Pedir avaliação de **`client:agent.presence.changed`** (presença §19.8) —
   eliminaria a Camada 3 (polling) da presença em tempo real.
