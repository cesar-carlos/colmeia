# Plano — Canal Socket (`/consumers`) para `agent_queries`

> Status: rascunho (planejamento). Sem código produzido ainda.
> Autor: planejamento orientado por análise da base atual + docs do `plug_server`.
> Documentos-fonte do hub:
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

| Tipo | Papel |
| ---- | ----- |
| `AppDioClient` | Cria `Dio` com `BaseOptions` (timeouts, base URL `apiBaseUrl`, content-type, logging). |
| `AuthInterceptor` | Injeta `Authorization: Bearer <accessToken>` lendo `AuthSessionAccessor`; em **401** chama `AuthRefreshCoordinator.refreshAccessToken()` e re-emite a request. |
| `AuthRefreshCoordinator` | Single-flight do `POST /client-auth/refresh`; em 400/401/403 limpa sessão e emite `AuthSessionEvents.notifyInvalidated()`. |
| `AuthSessionAccessor` | Read/save/clear da `AuthSessionModel` em `flutter_secure_storage`. |
| `AuthSessionEvents` | `Stream` broadcast de invalidação de sessão (consumida pelo router/auth controller). |
| `ApiRoutes` / `AgentCommandsApiRoutes` / `ClientAuthApiRoutes` | Constantes dos paths REST. |

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

| Opção | Nota |
| ----- | ---- |
| **`socket_io_client: ^3.1.4`** | Cliente Dart oficial para Socket.IO 4.7+. Suporta `setTransports(['websocket'])`, `setAuth({...})`, namespaces, reconexão automática, eventos. Ativo no pub.dev. **Escolhido.** |
| `web_socket_channel` | WS puro, não fala o protocolo Engine.IO/Socket.IO. Inadequado. |
| `socket_io_client_new` | Fork comunitário; sem maturidade. |

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
    PayloadFrame** (Fase 2 já validamos com `payload_frame.dart`; Fase 1
    aceitamos tanto `PayloadFrame` quanto `raw_json` durante a janela de
    compatibilidade `SOCKET_CONNECTION_READY_COMPAT_MODE`).
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

API alto-nível (Fase 1):

```dart
abstract interface class SocketCommandDispatcher {
  /// Envia evento `agents:command` e aguarda `agents:command_response`
  /// correlacionado pelo `id` JSON-RPC.
  Future<Map<String, dynamic>> sendAgentsCommand({
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  });
}
```

Implementação:

- Garante `connection.connect()` antes de emitir.
- Registra completer no `SocketRequestCorrelator`.
- `socket.emit('agents:command', body)`.
- Listener registrado uma vez por conexão para `agents:command_response`,
  `agents:command_stream_chunk` (na Fase 2), `agents:command_stream_complete`,
  e `app:error` — roteia por `id` ou `requestId`.
- Em desconexão durante request pendente: `Failure(NetworkFailure)`.

### 6.6 `core/socket/socket_failures.dart`

Mapeia:

- desconexão / `connect_error` → `NetworkFailure(isTransient: true)`.
- `unauthorized` / token inválido → `SessionFailure`.
- `app:error` com `AGENT_ACCESS_DENIED` → `AuthorizationFailure`.
- erros JSON-RPC vindos no body → reaproveita `AgentSqlBridgeResponse.parseSuccess`
  (que já lança `AgentSqlRpcException`), igual ao REST.

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

| Chave | Origem | Default | Uso |
| ----- | ------ | ------- | --- |
| `API_BASE_URL` | já existe | — | reutilizada (host/scheme) para Socket.IO. |
| `AGENT_BRIDGE_TRANSPORT` | nova | `rest` | `rest` \| `socket` (futuramente `auto`/`hybrid`). |
| `SOCKET_NAMESPACE` | nova (opcional) | `/consumers` | só sobrescreve em testes contra forks do hub. |
| `SOCKET_RECONNECT_ATTEMPTS` | nova (opcional) | `5` | teto de tentativas no backoff controlado. |
| `SOCKET_RECONNECT_INITIAL_DELAY_MS` | nova (opcional) | `1000` | delay inicial do backoff (com **jitter** — ver review §5.4). |
| `SOCKET_RECONNECT_MAX_DELAY_MS` | nova (opcional) | `30000` | teto do backoff exponencial. |
| `SOCKET_REQUEST_TIMEOUT_MS` | nova (opcional) | `15000` | timeout default por request quando não há histórico. |
| `SOCKET_HANDSHAKE_TIMEOUT_MS` | nova (opcional) | `10000` | espera por `connection:ready` antes de retry. |
| `SOCKET_MAX_INFLIGHT_PER_AGENT` | nova (opcional) | `8` | teto de requests paralelas por `agentId` (mirror conservador do `SOCKET_REST_AGENT_MAX_INFLIGHT=32` do hub — ver review §5.5). |
| `SOCKET_BATCH_WINDOW_MS` | nova (opcional, P2) | `8` | janela de coalescência para batch JSON-RPC (review §5.2). |
| `SOCKET_BATCH_MAX_SIZE` | nova (opcional, P2) | `32` | teto de RPCs por batch (limite oficial do hub). |
| `SOCKET_WARM_UP_AFTER_LOGIN` | nova (opcional) | `true` se `transport=socket` | dispara `connect()` em background ao final do login (review §5.7). |
| `SOCKET_TIMEOUT_ADAPTIVE_ENABLED` | nova (opcional, P2) | `false` | liga o `AgentLatencyOracle` para timeout por p95 (review §5.3). |
| `SOCKET_PAYLOAD_FRAME_ASYNC_GZIP_MIN_BYTES` | nova (opcional, Fase 2) | `65536` | usa `compute(...)` para gzip acima desse tamanho UTF-8 (review §5.9). |

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

| Evento | Ação esperada |
| ------ | ------------- |
| App inicia, sessão restaurada | **Não** conectar socket automaticamente. Conexão sob demanda no primeiro `executeSql` (lazy), reduz custo em telas que só usam REST/auth. |
| Login concluído | **Warm-up oportunista** quando `AGENT_BRIDGE_TRANSPORT=socket` e `SOCKET_WARM_UP_AFTER_LOGIN=true`: `unawaited(connection.connect())` ao final do `LoginUseCase` (ver review §5.7). |
| 401 em request socket | `AuthRefreshCoordinator.refreshAccessToken()` → reconectar com novo token; se falhar, `AuthSessionEvents.notifyInvalidated()`. |
| `AuthSessionEvents.invalidated` (logout, refresh fail) | `ConsumerSocketConnection.disconnect()`. |
| App em background (`AppLifecycleState.paused`/`detached`) | `connection.pause()` desconecta — decisão deliberada por **mobile economy** (bateria/dados). Detalhado em `consumer_socket_connection_design.md` §9. |
| App volta ao foreground (`resumed`) | `connection.resume()` reabre o socket; UI se atualiza pelo refresh normal e pelo stream de presença assim que reconectar. |
| Logout explícito | `disconnect(clearListeners: true)` antes de limpar a sessão. |

---

## 11. Roadmap por fases

### Fase 0 — Plano e dependência (este documento)

- [x] Plano consolidado em `docs/Features/socket_consumer_channel_plan.md`.
- [ ] Atualizar `project_platform_dependencies.mdc` para listar
  `socket_io_client` como dependência ativa.

### Fase 1 — Canal `agents:command` (paridade com REST)

Entrega: SQL executado via Socket usando o mesmo body do REST.

- [ ] `pubspec.yaml`: adicionar `socket_io_client: ^3.1.4`.
- [ ] `core/config/env_keys.dart` + `app_environment.dart`:
      `AGENT_BRIDGE_TRANSPORT` enum.
- [ ] `core/socket/`: `socket_io_client_factory`, `app_socket_url_resolver`,
      `socket_auth_token_provider`, `consumer_socket_connection` (sem
      PayloadFrame ainda — só decode JSON simples para `connection:ready` raw).
- [ ] `core/socket/socket_request_correlator` + `socket_command_dispatcher`.
- [ ] `core/di/injector_socket.dart` + integração em `injector.dart`.
- [ ] Extrair `agent_sql_execute_request_to_bridge_body.dart` (helper
      compartilhado entre REST e Socket).
- [ ] `socket_agent_queries_remote_datasource.dart`.
- [ ] Switch em `injector_agent_queries.dart`.
- [ ] Testes (§13) e logs estruturados em `AppLogger` com `transport: socket`.

### Fase 2 — `relay:*` + PayloadFrame

- [ ] `core/socket/payload_frame.dart` (encode/decode + gzip + validação:
      `enc==json`, `cmp ∈ {none,gzip}`, tamanho/inflação ≤ 10 MiB / 20×).
- [ ] Suporte a `connection:ready` em PayloadFrame na `ConsumerSocketConnection`.
- [ ] `RelayConversation` + `RelayCommandDispatcher` (start → request →
      stream pull → end). Conversa única reutilizável por agente, com isolamento.
- [ ] `relay`-aware datasource para queries grandes (`sql.execute` que devolva
      stream). Selecionável por flag por query (`useRelay`).
- [ ] Métricas: throughput, dedupe, timeouts; `AppLogger` com `requestId`.

### Fase 3 — Hybrid + push opcional

- [ ] `HybridAgentQueriesRemoteDataSource` (fallback Socket → REST).
- [ ] (Opcional) escutar `client:agent.profile.updated` para invalidar cache
      de catálogo de agentes em `client_agents`.

---

## 12. Impacto em outras features

| Feature | Impacto | Ação |
| ------- | ------- | ---- |
| `auth` | nenhum no fluxo HTTP. | manter; só fornece `AuthSessionEvents` para o socket. |
| `client_agents` | hoje usa REST `/client/me/agents` etc. | manter REST; em Fase 3 podemos invalidar cache via `client:agent.profile.updated`. |
| `overview`, `agent_queries` | só consomem `*Repository`. | nenhuma alteração de UI/use cases. |
| `user_context` | não toca SQL. | nenhum impacto. |

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

| Risco | Mitigação |
| ----- | --------- |
| Comportamento `connection:ready` migrar para PayloadFrame antes da Fase 2 | Implementar decode tolerante: tenta JSON puro, cai para PayloadFrame se `cmp/enc/payload` presentes. |
| Reconexão em loop após 401 | Single-flight via `AuthRefreshCoordinator` (igual REST); se refresh falha, parar reconexão e `notifyInvalidated`. |
| Multi-instância do hub (afinidade) | Para Fase 1 (`agents:command`) compartilha mesmo hub; Fase 2 (relay) — documentar dependência de sticky sessions (já citado em `scaling_and_roadmap.md`). |
| Web vs mobile (transports) | Forçar `websocket` em mobile; em web manter `websocket` apenas (produção do hub usa só WS). |
| Rate-limit compartilhado com REST | Métricas por feature; alternar para `relay:*` quando justificar. |
| Mudança de contrato do hub | Resposta do `agents:command_response` segue o mesmo envelope do REST; testes de contrato no datasource cobrem regressões. |

---

## 17. Critérios de aceite (Fase 1)

1. Ligar `AGENT_BRIDGE_TRANSPORT=socket` faz **toda** a feature `agent_queries`
   funcionar sem alteração de UI/use cases/repositórios de domínio.
2. Em `rest` (default), comportamento atual é byte-a-byte idêntico.
3. Logout/expiração derruba o socket e impede novas requests.
4. 401 em request socket aciona refresh e re-tenta uma vez.
5. Tempo médio de resposta ≤ REST em rede equivalente para a mesma query
   (medido em integração).
6. Cobertura: `≥ 90%` linhas em `core/socket/*` e no novo datasource.
7. `flutter analyze` limpo; sem novos lints `very_good_analysis`.

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

| Camada | Local |
| ------ | ----- |
| Domínio | `lib/features/client_agents/domain/entities/agent_connection_status.dart` (`online`/`offline`/`unknown`) |
| Resolução pura | `lib/features/client_agents/domain/services/agent_connection_status_resolver.dart` (`isHubConnected` ?? lookup em `onlineAgentIds`) |
| Repositório | `ClientAgentsRepository.loadOnlineAgentIds(...)`, `loadApprovedAgents(includeOnlineStatus: true, refresh: …)`, `loadApprovedAgentById(...)` |
| Datasource REST | `ClientAgentsRemoteDataSource.fetchOnlineAgents(...)` → `GET /api/v1/agents` (somente `user`); `fetchApprovedAgents(...)` → `GET /api/v1/client/me/agents` (com `isHubConnected` por linha) |
| Cache local | `ClientAgentsLocalDataSource.{read,save}OnlineAgents` (TTL **fresh = 1 min**, fallback **7 dias**) e `_persistHubPresenceCacheFromProfiles(...)` que sintetiza presença a partir do `isHubConnected` das respostas de catálogo |
| Refresh manual | `ClientAgentsController.refreshAll()` (botão `Refresh` no topo da tela) |
| Polling explícito | só durante o fluxo de aprovação: `_startApprovalPolling` (10 s × até 3 min) — **não** existe polling contínuo de presença |

Conclusão: hoje a **presença é amostral**, refrescada em interações do
usuário (load inicial / `Refresh` / depois de mutar acesso). Não há
notificação push.

### 19.2 O que o hub `plug_server` oferece hoje

Confirmado nos docs (`socket_client_sdk.md`, `client_agent_business_rules.md`,
`observability.md`):

| Evento Socket no `/consumers` | Significado | Útil para presença? |
| ----------------------------- | ----------- | ------------------- |
| `client:agent.profile.updated` (PayloadFrame) | Catálogo/perfil do agente mudou (HTTP / socket / pull sync). Payload típico: `agent_id`, `profile_version`, `profileUpdatedAt`, `changed_fields`, `source`. | **Indireto.** Disparado em mudanças de catálogo; reflete presença apenas quando a re-sincronização atualiza `isHubConnected`. |
| `connection:ready` | Confirmação do handshake do consumer. | **Não.** Apenas saúde do próprio socket do app. |
| `agents:command_response` / erros (`AGENT_OFFLINE`, `protocol_not_ready`, `AGENT_ACCESS_DENIED`) | Resposta do hub ao executar um RPC. | **Indireto.** Se a query falha por offline, sabemos que naquele instante estava offline. |

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

Encaixa no roadmap §11:

- **Fase 1** (`agents:command`): Camada 2 (hints implícitos) entra
  "de graça" porque o `SocketCommandDispatcher` já existe — só
  conectamos os erros/sucesso ao `AgentPresenceStream`.
- **Fase 2** (`relay:*` + `PayloadFrame`): habilita Camada 1
  (`client:agent.profile.updated` chega como `PayloadFrame`).
- **Fase 3** (push opcional): se o hub adicionar
  `client:agent.presence.changed`, é só um novo listener — UI/cache
  permanecem.

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

1. Aprovar este plano (escolher Opção A na §7 e confirmar default `rest`).
2. Atualizar `project_platform_dependencies.mdc` aprovando `socket_io_client`.
3. Abrir PR-1: pacote + `core/socket/*` + DI + flag (sem trocar default).
4. Abrir PR-2: `socket_agent_queries_remote_datasource` + helper de body
   compartilhado + testes unit + integração opt-in.
5. Rodar QA com flag `AGENT_BRIDGE_TRANSPORT=socket` em build interna.
6. Promover para default em ambiente staging; manter REST como fallback de
   build até decisão final.
