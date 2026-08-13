# Review de desempenho — canal Socket `/consumers`

> Current socket/relay contract for Colmeia:
> [`../../plug_server_docs_index_for_colmeia.md`](../../plug_server_docs_index_for_colmeia.md)
> and [`../../bridge_agent_sql_api_options.md`](../../bridge_agent_sql_api_options.md).
> Use these summaries for current PayloadFrame/relay defaults.

> Análise crítica do plano em `docs/Features/socket_consumer_channel_plan.md`
> e designs companheiros (`consumer_socket_connection_design.md`,
> `socket_command_dispatcher_design.md`, `agent_presence_realtime_design.md`)
> sob a ótica de **desempenho** e **estratégia de transporte**.
>
> Fonte normativa do lado do hub:
>
> - `plug_server/docs/performance_hub_agent.md`
> - `plug_server/docs/socket_relay_protocol.md`
> - `plug_server/docs/relay_fastpath_study.md`
> - `plug_server/docs/api_rest_bridge.md`
>
> **TL;DR** — O plano atual já captura 80% das boas práticas (websocket-only,
> single socket, auto-gzip alinhado ao hub, dispatcher correlacionado,
> auto-refresh de token). Para extrair os 20% restantes precisamos de:
>
> 1. **coalescing de requests idênticas** (cliente),
> 2. **batch JSON-RPC nativo** (até 32 RPCs por emissão) para as ondas do
>    `agent_query_executor` em `mergeAll`,
> 3. **timeout adaptativo** baseado em p95 por agente,
> 4. **backoff de reconexão com jitter**,
> 5. **backpressure na emissão** (teto in-flight por agente, mirror do
>    `SOCKET_REST_AGENT_MAX_INFLIGHT` do hub),
> 6. **telemetria mínima no cliente** para validar qualquer mudança por
>    comparação antes/depois.

---

## Fronteiras de timeout (transporte vs repositório)

- **`AgentLatencyOracle`** (`lib/core/socket/agent_latency_oracle.dart`): alimenta timers de pendência **no transporte** (ex.: `RelayCommandDispatcherImpl`) quando o RPC **não** traz `Duration` explícita — EWMA por `(agentId, método)`.
- **`AdaptiveTimeoutAgentQueriesRepository`**: atua **só** em chamadas Agent SQL que já declaram `bridgeTimeoutMs`, ajustando esse teto com base em histórico de latência no decorator da cadeia do repositório.
- **Convivência:** overview batch com `bridgeTimeoutMs` longo (300s) continua passando pelo decorator quando habilitado; o oracle cobre o caminho relay default sem timeout por request. Não misturar as duas camadas na mesma responsabilidade.

---

## 1. Matriz de responsabilidades (quem controla o quê)

| Camada                | Cliente (Colmeia)                                    | Hub (`plug_server`)                                                                                      | Agente (`plug_agente`)                           |
| --------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| Transport             | `websocket`, single socket, auth header              | `SOCKET_IO_TRANSPORTS`, `PER_MESSAGE_DEFLATE`, `HTTP_COMPRESSION`, `MAX_HTTP_BUFFER_BYTES`               | WebSocket no `/agents`                           |
| Compressão            | gzip do PayloadFrame (Fase 2, modo auto)             | `PAYLOAD_FRAME_*` (gzip auto, async acima de 128 KiB, level 3 em prod)                                   | `compressions` anunciado no handshake            |
| Correlation / timeout | `rpcId` + `SocketRequestCorrelator` + timeout client | correlação por processo (em memória); `SOCKET_RELAY_REQUEST_TIMEOUT_MS`                                  | responde `rpc:response` / chunks                 |
| Rate limit            | nenhum (respeita o do hub)                           | `REST_AGENTS_COMMANDS_RATE_LIMIT_*` (compartilhado REST + `agents:command`); `SOCKET_RELAY_RATE_LIMIT_*` | —                                                |
| Backpressure          | **ausente hoje no plano** (melhoria §5.5)            | fila relay outbound, `SOCKET_RELAY_MAX_BUFFERED_CHUNKS_*`, overload gate O(1)                            | capabilities (`recommendedStreamPullWindowSize`) |
| Parallelism           | `AgentQueryExecutor.mergeAllConcurrency = 16`        | `SOCKET_REST_AGENT_MAX_INFLIGHT = 32` (REST); relay sem teto global explícito                            | `max_concurrent_streams` no handshake            |
| Auditoria             | —                                                    | `SOCKET_AUDIT_HIGH_VOLUME_SAMPLE_PERCENT`, batch DB                                                      | —                                                |

Conclusão: o **hub** já tem a maioria das válvulas. Do lado do **cliente**,
as melhorias práticas vivem em: **coalescing**, **batch**, **timeout
adaptativo**, **backoff com jitter**, **teto in-flight por agente**,
**telemetria**.

---

## 2. Análise do plano atual (onde já acertamos)

| Item                                            | Status no plano                              | Justificativa                                                                                                                                        |
| ----------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Transport `websocket` apenas                    | ✅ `consumer_socket_connection_design.md` §5 | Alinha com `SOCKET_IO_TRANSPORTS=websocket` default em produção do hub.                                                                              |
| **Sem** `perMessageDeflate` no cliente          | ✅ implícito (não setamos)                   | Hub desliga `SOCKET_IO_PER_MESSAGE_DEFLATE` para evitar dupla compressão. `socket_io_client` Dart não habilita deflate por padrão, então estamos OK. |
| Single socket compartilhado                     | ✅ singleton via `get_it`                    | Evita handshake redundante; reusa auditoria/correlação.                                                                                              |
| Reconexão controlada (não nativa)               | ✅ `disableReconnection()` + backoff         | Reconexão nativa do socket.io não refresca token.                                                                                                    |
| Single-flight de `connect()`                    | ✅ §7 do design                              | Evita sockets paralelos.                                                                                                                             |
| Refresh de token automático em 401              | ✅                                           | Reaproveita `AuthRefreshCoordinator` (single-flight no HTTP).                                                                                        |
| Body idêntico REST ↔ Socket                     | ✅ helper compartilhado                      | Garante paridade (mesmos tetos UTF-8 que o REST).                                                                                                    |
| Gzip **do cliente** alinhado ao hub (modo auto) | ✅ Fase 2, threshold 4096 B                  | Evita que o hub desperdice CPU gunzipando algo que não compensou.                                                                                    |
| Listener único por evento                       | ✅ `_ensureListenersAttached`                | Evita memory leak por re-anexar em cada emit.                                                                                                        |

---

## 3. Gargalos esperados e onde eles se manifestam

| Fonte                                                                        | Impacto visível                                         | Instrumentação recomendada                                                                                     |
| ---------------------------------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **TTFB do handshake** (`connect` + `connection:ready`)                       | latência só na **primeira** query após login/background | log `handshake_at - connect_at` em `info`, enviar como breadcrumb Sentry                                       |
| **CPU de gzip/gunzip** no cliente (Fase 2)                                   | travamentos ocasionais na UI thread                     | medir via `Stopwatch` em `encodePayloadFrame` / `decodePayloadFrame`; considerar `compute(...)` para > 128 KiB |
| **Wave de requests paralelas** do `AgentQueryExecutor` (16 em paralelo)      | spikes de CPU no hub + rate-limit do `agents:command`   | teto in-flight **por agente** no cliente (melhoria §5.5)                                                       |
| **Queries idênticas simultâneas** (mesmo SQL, mesmo agente, paginação igual) | bytes desperdiçados, CPU duplicada                      | **coalescing** no dispatcher (melhoria §5.1)                                                                   |
| **Overhead por request do JSON-RPC**                                         | muitas queries pequenas = muitos emits                  | **batch** via `command: [...]` (melhoria §5.2)                                                                 |
| **Reconexões em rede instável (4G)**                                         | UX engasga; pendentes falham com `disconnected`         | **jitter no backoff** (melhoria §5.4); retry transparente no dispatcher (melhoria §5.3)                        |
| **Requests "zumbis"** (UI saiu da tela mas o Future continua)                | bytes consumidos à toa + pressão no rate limit          | cancelamento com `sql.cancel` (melhoria §5.6)                                                                  |

---

## 4. Estratégias de transporte — qual modo usar e quando

Matriz de decisão que o `AgentQueryExecutor` (ou um coordenador novo) deve
aplicar **por wave** de queries:

| Situação                                                        | Estratégia recomendada                            | Canal                                              | Porquê                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------- |
| 1 query, resposta pequena/média                                 | `sql.execute` unitário                            | `agents:command` (Fase 1)                          | menor overhead, envelope único                                                      |
| 1 query, resultado stream grande                                | `sql.execute` + paginação server-side             | `agents:command` com `page`/`pageSize` ou `cursor` | evita materialização no hub (REST materializaria tudo em 1 JSON)                    |
| 1 query, resposta enorme (> 10 MiB decodificado)                | relay com `stream.pull`                           | `relay:*` (Fase 2)                                 | streaming progressivo com backpressure                                              |
| N queries **independentes** ao **mesmo agente**                 | **batch JSON-RPC** (`command: [...]`, máx **32**) | `agents:command` (Fase 1)                          | 1 emit, 1 correlação, reduz overhead por query                                      |
| N queries ao **mesmo agente** com mesmo SQL mudando só `params` | `sql.executeBatch`                                | `agents:command` (Fase 1)                          | **uma** transação opcional no agente, resultados em `items[]`                       |
| 1 SQL com vários `SELECT` agregados                             | `multi_result: true`                              | `agents:command` (Fase 1)                          | 1 round-trip ao banco, 1 RPC                                                        |
| Queries em **agentes diferentes** simultaneamente               | fan-out com teto por agente                       | `agents:command` em paralelo                       | `AgentQueryExecutor.mergeAll` **já existe**; só adicionar teto in-flight por agente |
| Push de catálogo (`client:agent.profile.updated`)               | listener passivo                                  | `/consumers` Socket                                | nenhum polling; já é o desenho da presença                                          |

> **Importante**: o relay (`relay:*`) **não aceita batch JSON-RPC** e
> **não aceita notifications (`id: null`)**. Para batch, o canal é
> `agents:command`. Confirmar sempre antes de mudar estratégia.

---

## 5. Melhorias sugeridas (com justificativa e esforço)

> **Status (Colmeia client, 2026-07):** delivered on the client —
> **5.1** coalescing (`SocketCommandCoalescer`), **5.2** batch coordinators
> (agents:command + relay batch), **5.4** reconnect jitter,
> **5.5** per-agent inflight gate, adaptive timeout oracle (opt-in),
> **temporary REST latch** after consecutive socket/relay transport timeouts
> (`SocketWithRestFallbackAgentQueriesRemoteDataSource`), and
> **single-flight `RelayConversationManager.obtain`**. Connection pool stays
> `poolSize == 1` (not wired for multi-socket). PayloadFrame worker isolates
> default **on** (`SOCKET_PAYLOAD_WORKER_ISOLATES_ENABLED`, gzip/json thresholds
> 16 KiB class). Hub `fastPath` JSON-RPC `id` echo remains a hub concern
> (see § fast-path caveat below and
> [`docs/server_adjustments/relay_unary_fast_path.md`](../../server_adjustments/relay_unary_fast_path.md)).

Cada melhoria mapeada como item acionável, com impacto esperado. **Todas
opcionais ao plano base** — prioridade por ordem.

### 5.1 Request coalescing no `SocketCommandDispatcher`

**Status:** delivered — maps live in `lib/core/socket/socket_command_coalescer.dart`.

**Problema**: se `ClientAgentsController` e `OverviewController` dispararem
a mesma query `agent.getProfile` para o mesmo agente em < 100 ms (caso real
ao carregar 2 telas em sequência), enviamos dois emits idênticos.

**Proposta**:

```dart
// core/socket/socket_command_dispatcher_impl.dart (interno)

String _coalesceKey({
  required String agentId,
  required String method,
  required Map<String, Object?> params,
}) {
  // Hash estável de params normalizados (SQL já trimmado, keys em ordem).
  return '$agentId|$method|${_stableHash(params)}';
}

final Map<String, Future<Map<String, dynamic>>> _inflightByKey =
    <String, Future<Map<String, dynamic>>>{};

// Em sendAgentsCommand:
final key = _coalesceKey(agentId: agentId, method: ..., params: ...);
final existing = _inflightByKey[key];
if (existing != null) {
  return existing; // mesma resposta, sem novo emit
}
_inflightByKey[key] = pending.whenComplete(() => _inflightByKey.remove(key));
```

**Impacto**: dedupe de 100% das chamadas idempotentes concorrentes.
**Esforço**: baixo (~80 linhas + testes).
**Risco**: chamadas com `max_rows` diferente por contexto — a chave deve
incluir `options` completas, não só `sql+params`.

### 5.2 Batch JSON-RPC nativo na camada de orquestração

**Problema**: `agent_query_executor.dart` em `mergeAll` dispara N queries
paralelas para N agentes. Quando **dois ou mais** alvos são o **mesmo agente**
(raro, mas possível em `agent_queries_across_agents`), podemos agrupar.
Mais relevante: o `overview_controller` hoje dispara 7+ queries seguidas
ao mesmo agente (resumos). Isso **são** 7 round-trips em vez de 1.

**Proposta** — novo serviço de aplicação `AgentCommandBatchCoordinator`:

```dart
// application/orchestration/agent_command_batch_coordinator.dart

/// Agrega requests ao mesmo agentId dentro de uma janela curta
/// (ex.: 8 ms) e envia como `command: [...]` (max 32 itens).
class AgentCommandBatchCoordinator {
  Future<Map<String, dynamic>> submit({
    required String agentId,
    required Map<String, Object?> rpcCommand,  // objeto JSON-RPC único
  }) async {
    // ... collector por agentId, timer de 8 ms, flush em batch ...
  }
}
```

**Impacto medido** (estimativa): em dashboards com 5+ queries ao mesmo
agente, 1 batch reduz latência total de `5 * RTT` para `1 * RTT`
(+ tempo no agente).
**Esforço**: médio (~250 linhas + testes de ordenação e erros parciais).
**Cuidados**:

- Batch JSON-RPC **não** aceita `pagination` no nível do body — apenas
  por comando. Manter paginação em `params.options`.
- Se um item do batch falhar, os demais continuam; precisamos mapear
  `response.items[i].error` → `AppFailure` por request original.
- **Opt-in** por use case; `sql.execute` com `multi_result` ou
  `sql.executeBatch` podem ser preferíveis em cenários específicos.

### 5.3 Timeout adaptativo por agente

**Problema**: `bridgeTimeoutMs = 15000` é fixo. Agentes rápidos pagam
o teto; agentes lentos falham cedo em picos.

**Proposta** — histograma EWMA de latência por `(agentId, method)`:

```dart
// core/socket/agent_latency_oracle.dart

class AgentLatencyOracle {
  void record({required String agentId, required String method, required Duration elapsed}) { … }

  /// p95 estimado pelo EWMA; fallback para default se histórico < 5.
  Duration suggestTimeout({
    required String agentId,
    required String method,
    Duration fallback = const Duration(seconds: 15),
    Duration floor = const Duration(seconds: 3),
    Duration ceiling = const Duration(seconds: 60),
  }) { … }
}
```

Dispatcher usa `suggestTimeout` quando o caller não passa timeout
explícito.

**Impacto**: reduz 429/timeout em redes instáveis; libera mais cedo a UI
quando o agente responde rápido.
**Esforço**: baixo-médio (~150 linhas + testes com fake clock).

### 5.4 Backoff com jitter na reconexão

**Problema**: com backoff puramente exponencial (1→2→4→…) e **muitos
clientes Colmeia** caindo ao mesmo tempo (ex.: hub restart), temos
**thundering herd** — todos reconectam no mesmo segundo.

**Proposta** — adicionar jitter aleatório:

```dart
// core/socket/consumer_socket_connection.dart (_nextBackoff)

Duration _nextBackoff(Duration current, {required Random rng}) {
  final doubled = current * 2;
  final capped = doubled > _reconnectMaxDelay ? _reconnectMaxDelay : doubled;
  // Full jitter: [0, capped). Suaviza picos coordenados.
  final jittered = Duration(
    milliseconds: rng.nextInt(capped.inMilliseconds + 1),
  );
  return jittered;
}
```

**Impacto**: espalhamento temporal das reconexões.
**Esforço**: trivial (1 função + 1 teste determinístico com `Random.seeded`).

### 5.5 Backpressure por agente no cliente

**Problema**: se o `AgentQueryExecutor` disparar 16 queries paralelas e
todas forem para o mesmo agente, o hub pode bater em `rate-limited`
(`REST_AGENTS_COMMANDS_RATE_LIMIT_*` é compartilhado entre REST e
`agents:command`) e o agente pode congestionar (ver
`SOCKET_REST_AGENT_MAX_INFLIGHT=32` no hub).

**Proposta** — fila semafórica por `agentId` no dispatcher:

```dart
// core/socket/per_agent_concurrency_gate.dart

class PerAgentConcurrencyGate {
  PerAgentConcurrencyGate({this.maxInflightPerAgent = 8});
  final int maxInflightPerAgent;

  final Map<String, int> _inflight = <String, int>{};
  final Map<String, Queue<Completer<void>>> _waiters =
      <String, Queue<Completer<void>>>{};

  Future<void> acquire(String agentId) async { … }
  void release(String agentId) { … }
}
```

Dispatcher usa `acquire(agentId)` antes de `emit` e `release(agentId)`
no `finally`.

**Impacto**: elimina picos de rate-limit; mantém UX responsivo.
**Esforço**: baixo (~120 linhas + testes).
**Tuning**: `maxInflightPerAgent = 8` é um teto conservador (< metade do
teto default do hub); monitorar e ajustar via env
(`SOCKET_MAX_INFLIGHT_PER_AGENT`).

### 5.6 Cancelamento de requests "zumbis"

**Problema**: usuário sai do dashboard enquanto queries pendentes; a UI
descarta o Future mas o emit já foi enviado e o agente vai gastar CPU.

**Proposta** — mapa `rpcId → cancel token` no dispatcher + chamada ao
`sql.cancel` (método suportado pelo hub) quando `CancelToken` é sinalizado:

```dart
abstract class SocketCommandDispatcher {
  // delta na interface:
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
    SocketCommandCancelToken? cancelToken,   // NEW
  });
}

class SocketCommandCancelToken {
  void cancel() { … }
  bool get isCancelled => …;
}
```

Use case em `ClientAgentsController` / `OverviewController` passa o
token para cada request; no `dispose()` do controller, chama
`token.cancel()` em todas as pendentes.

**Impacto**: reduz pressão no agente quando o usuário navega rápido.
**Esforço**: médio (~180 linhas + testes de corrida).
**Cuidado**: o hub só suporta `sql.cancel` para SQL em streaming; para
request unitário simples o `cancel` apenas **remove o completer** do
correlator (o agente ainda vai responder, mas o cliente ignora).

### 5.7 Warm-up oportunista do socket

**Problema**: primeira query após login paga o handshake inteiro.

**Proposta**: ao final do login (`LoginUseCase` retornar sucesso e a
sessão estar salva), disparar `unawaited(getIt<ConsumerSocketConnection>().connect())`.
Se a flag `AGENT_BRIDGE_TRANSPORT=socket` está ligada, o socket já
estará `connected` quando a home renderizar.

**Impacto**: elimina latência de handshake da UX (~100–300 ms em 4G).
**Esforço**: trivial (1 linha no fluxo de login).
**Cuidado**: não warm-up em `AGENT_BRIDGE_TRANSPORT=rest` para não
manter socket aberto à toa.

### 5.8 Métricas no cliente (tabela de KPIs)

**Problema**: não temos como comparar antes/depois das mudanças.

**Proposta** — `SocketChannelMetrics` como serviço em `core/observability/`:

| Métrica                   | Tipo       | Agregação                             |
| ------------------------- | ---------- | ------------------------------------- |
| `handshake_ms`            | histograma | p50, p95 por sessão                   |
| `dispatch_ms` (Success)   | histograma | p50, p95, p99 por `(agentId, method)` |
| `outcomes_total`          | counter    | por `(kind, reasonCode)`              |
| `inflight_peak_per_agent` | gauge      | max por sessão                        |
| `reconnects_total`        | counter    | por `reason`                          |
| `coalesced_total`         | counter    | (Melhoria §5.1)                       |
| `batch_size_distribution` | histograma | (Melhoria §5.2)                       |

Emitir para `AppLogger` (info) + Sentry breadcrumb. Em ambiente de
diagnóstico, pode rodar um `sink` HTTP para painel interno.

**Impacto**: destrava qualquer decisão de tuning futuro.
**Esforço**: médio (~200 linhas + testes).

### 5.9 Compressão adaptativa (Fase 2)

**Problema**: gzip na thread UI pode causar jank em payloads grandes.

**Proposta** — mirror do comportamento do hub:

- **síncrono** para JSON < **64 KiB** UTF-8 (evita `Isolate` setup overhead);
- **assíncrono via `compute(...)`** acima disso, alinhado ao
  `PAYLOAD_FRAME_ASYNC_GZIP_MIN_UTF8_BYTES=131072` do hub (usamos teto
  mais baixo no cliente porque o device é mais fraco).

```dart
// core/socket/payload_frame.dart (Fase 2)

Future<PayloadFrame> encodeAuto(Object data) async {
  final encoded = utf8.encode(jsonEncode(data));
  if (encoded.length < 4096) {
    return PayloadFrame.raw(encoded);
  }
  if (encoded.length < _asyncGzipThreshold) {
    return _syncGzipAttempt(encoded);
  }
  return compute(_asyncGzipAttempt, encoded); // offload Isolate
}
```

**Impacto**: UI suave mesmo em payloads de 1–10 MiB.
**Esforço**: médio (Isolate communication, testes de concorrência).

### 5.10 Debouncing de subscribe pós-reconexão

**Problema**: em redes voláteis (transport twin flipping), a cada
reconexão re-anexamos listeners e pode chover eventos duplicados se
o app já tinha recebido.

**Proposta**: manter `_lastObservedByAgentId` (já no design de presença
§6.4) como **idempotência universal** para push events (não só
presence). Qualquer listener que resuba após reconexão descarta
eventos com `observedAt` anterior.

**Impacto**: robustez em WiFi ruim / handoff 4G↔WiFi.
**Esforço**: baixo (já previsto em presença; estender para todos
listeners futuros).

---

## 6. Anti-padrões a evitar (riscos do caminho errado)

| Anti-padrão                                  | Por quê                                                                                     |
| -------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Pool de múltiplos sockets                    | Socket.IO foi desenhado para um canal por cliente; múltiplos pioram rate-limit e auditoria. |
| `autoConnect: true`                          | Vai conectar antes de termos token; `connect_error` inútil no startup.                      |
| Habilitar `perMessageDeflate` no cliente     | Dupla compressão com PayloadFrame; CPU desperdiçada.                                        |
| Retry infinito sem backoff terminal          | Loop de refresh em 401 persistente; o plano já trata com `unauthorized` após 1 tentativa.   |
| Logar `command.params.sql` ou `client_token` | Privacidade + tamanho. Logar só `agentId`, `method`, `rpcId`.                               |
| Usar REST para streams grandes               | Hub materializa tudo em RAM; pode gerar 503. Socket é o canal certo para > ~50 k linhas.    |
| Mudar `AGENT_BRIDGE_TRANSPORT` em runtime    | Invalidaria caches/correlator; decisão é por build/env.                                     |
| Paralelizar batch JSON-RPC sem necessidade   | Batch já empacota 32; paralelizar N batches fura o rate-limit.                              |

---

## 7. Estratégia de medição (antes/depois)

Segue o mesmo padrão do `plug_server/docs/performance_hub_agent.md`
§ "Baseline antes/depois". Adaptado ao cliente:

### 7.1 Janela mínima

15–30 min de uso real (ou sessão e2e scripted com carga representativa
das telas `agent_queries` + `overview`).

### 7.2 KPIs obrigatórios

| KPI                                            | Descrição                        |
| ---------------------------------------------- | -------------------------------- |
| `p95(dispatch_ms)` por `(agentId, method)`     | principal indicador de regressão |
| `rate(outcomes_total{kind='Success'})`         | volume útil                      |
| `rate(outcomes_total{kind='FailedOffline'})`   | presença vs rede                 |
| `rate(outcomes_total{kind='FailedTransient'})` | qualidade do canal               |
| `reconnects_total`                             | estabilidade                     |
| `p95(handshake_ms)`                            | TTFB do canal                    |
| `inflight_peak_per_agent`                      | pressão sobre o hub              |
| `dropped_frames_total` (presença)              | perda de push                    |

### 7.3 Template

| Indicador                         | Baseline | Pós-mudança | Δ   | Observação |
| --------------------------------- | -------- | ----------- | --- | ---------- |
| `p95(dispatch_ms)`                |          |             |     |            |
| `handshake_ms`                    |          |             |     |            |
| `outcomes_total{FailedTransient}` |          |             |     |            |
| `reconnects_total`                |          |             |     |            |

### 7.4 Regra de rollout

1. Medir baseline com a mesma build (só o transporte muda).
2. Alterar **um** bloco por vez (§5.1 → §5.2 → …).
3. Manter mudança apenas se `p95(dispatch_ms)` não subiu e
   `FailedTransient` não subiu.
4. Se regressão, reverter antes de avançar.

---

## 8. Impacto esperado de cada melhoria (estimativas)

Valores **estimados** com base na arquitetura; confirmar com §7.

| Melhoria                     | Latência p50              | Latência p95                             | CPU cliente | Bandwidth                              |
| ---------------------------- | ------------------------- | ---------------------------------------- | ----------- | -------------------------------------- |
| §5.1 coalescing              | ≈                         | ≈                                        | ≈           | **-10 a -30%** em telas abertas rápido |
| §5.2 batch JSON-RPC          | **-30 a -60%** em waves   | **-30 a -50%**                           | ≈           | **-20 a -40%**                         |
| §5.3 timeout adaptativo      | ≈                         | **-10 a -20%** (menos falsos timeouts)   | ≈           | ≈                                      |
| §5.4 jitter                  | ≈                         | ≈ (ocasiões de thundering herd somem)    | ≈           | ≈                                      |
| §5.5 backpressure por agente | +≈5% em picos (enfileira) | **-20 a -40%** (evita 429)               | ≈           | ≈                                      |
| §5.6 cancelamento            | ≈                         | ≈                                        | ≈           | **-5 a -15%** em navegação rápida      |
| §5.7 warm-up                 | —                         | —                                        | ≈           | ≈ (**-100 a -300 ms** percebido)       |
| §5.8 métricas                | ≈                         | ≈                                        | +negligível | ≈                                      |
| §5.9 compressão adaptativa   | ≈                         | **-100 a -500 ms** em payloads > 256 KiB | -variável   | ≈                                      |
| §5.10 dedup pós-reconexão    | ≈                         | ≈                                        | ≈           | ≈                                      |

> Nenhuma melhoria piora caso base; todas são **orthogonais**.

---

## 9. Roadmap sugerido (priorização)

Faseamento otimizado por **custo-benefício**, assumindo que o plano
executivo §11 já deu Fase 1 (`agents:command`):

| Prio | Melhoria                     | Depende de            | Entrega                             |
| ---- | ---------------------------- | --------------------- | ----------------------------------- |
| P0   | §5.8 métricas cliente        | Fase 1                | Destrava comparação                 |
| P0   | §5.4 jitter                  | Fase 1                | Trivial; evita regressão coordenada |
| P1   | §5.1 coalescing              | Fase 1                | Grande ganho / baixo esforço        |
| P1   | §5.5 backpressure por agente | Fase 1                | Evita 429 em produção               |
| P1   | §5.7 warm-up                 | Fase 1                | UX percebida                        |
| P2   | §5.3 timeout adaptativo      | Métricas (P0)         | Só faz sentido com histórico        |
| P2   | §5.2 batch JSON-RPC          | Fase 1                | Grande ganho; esforço médio         |
| P2   | §5.6 cancelamento            | Fase 1                | Bom cidadão com o hub               |
| P3   | §5.9 compressão adaptativa   | Fase 2 (PayloadFrame) | Entra junto com relay               |
| P3   | §5.10 dedup pós-reconexão    | Presença              | Entra junto com realtime            |

**Meta razoável para MVP do canal Socket**: P0 + P1 no mesmo cycle;
P2 em cycle seguinte; P3 com Fase 2.

---

## 10. Riscos residuais e limites do desenho

1. **`isHubConnected` por processo** (multi-réplica do hub sem sticky
   session) — fora do controle do cliente; mitigação é operacional
   (single replica / sticky / mesma base URL). Documentado.
2. **Rate limit compartilhado REST + `agents:command`** — se o Colmeia
   em _hybrid_ futuro (§7-B do plano principal) dobra a carga sobre o
   mesmo `sub`. Só ativar hybrid com telemetria.
3. **Backpressure explícito só com relay** (Fase 2) — em `agents:command`
   legado, o cliente não tem créditos por stream. Para streams muito
   grandes, obrigatório migrar para relay.
4. **Sem OTel no cliente** ainda — traces correlacionados hub↔app vão
   precisar de `traceparent` em `command.meta` (o hub já aceita — ver
   `api_rest_bridge.md`). Fase 3 opcional.
5. **Mobile economy** — decisão de desconectar em background **maximiza**
   bateria e minimiza dados móveis, mas **zera** push de presença em
   background. Alternativa (fora de escopo): usar Firebase Cloud Messaging
   para wake-up + reconect; abre frente nova.

---

## 11. Conclusão

O plano atual é **sólido como baseline**: nada nele precisa ser
refeito. As melhorias listadas são **incrementais** e cabem em PRs
pequenos depois que a Fase 1 estiver estável. Sem medição prévia
(§7 e §5.8), evitar mudar mais de um bloco por vez — ganhos e
regressões somam-se de forma não-linear em sistemas com rate-limit e
compressão.

**Três prioridades imediatas** para extrair o máximo do canal Socket:

1. **Instrumentar o cliente** (§5.8) antes de qualquer tuning.
2. **Jitter** (§5.4) e **backpressure por agente** (§5.5) — ambos
   trivialmente pequenos e salvam o canal de anti-patterns coordenados.
3. **Batch JSON-RPC** (§5.2) onde o `overview` consome 5+ queries no
   mesmo agente — maior ganho de latência por linha de código.

---

## 12. Colmeia implementation status (roadmap 2026-05)

Audit against PR2 baseline and roadmap phases. **Do not duplicate policy from
`.cursor/rules`** — this section is a checklist only.

| Review § | Item | Status | Colmeia location |
| --- | --- | --- | --- |
| 5.1 | Request coalescing | Done | `SocketCommandDispatcher` + `CoalescingAgentQueriesRepository` |
| 5.2 | Batch `agents:command` | Done | `AgentCommandBatchCoordinator` (`SOCKET_BATCH_ENABLED`) |
| 5.4 | Reconnect jitter | Done | `SocketReconnectBackoff`, `consumer_socket_connection.dart` |
| 5.5 | Per-agent concurrency gate | Done | `PerAgentConcurrencyGate` |
| 5.6 | Cancel / `sql.cancel` | Done (client) | `AgentQueriesCancelScope`, `wireAgentQueriesCancelScopeHandlers`, `AgentSqlCancelEmitter`; map: `sql_cancel_contract_colmeia_map.md` |
| 5.7 | Socket warm-up after login | Done | `SOCKET_WARM_UP_AFTER_LOGIN`, `bootstrap.dart` |
| 5.8 | Client metrics | Done | `SocketChannelMetrics`, `SocketMetricsListener` |
| 5.9 | Async gzip encode/decode | Done | `PayloadFrameCodec` isolate thresholds |
| PR2 | Relay cancel fail-fast | Done | `RelayCommandDispatcher.cancel` |
| Phase 3 | Shared latency budget | Done | `AgentLatencyBudget` → oracle + adaptive timeout repo |
| Phase 4 | Relay batch | Guard only | `RelayBatchProtocolGuard`, `relay_batch_future_spec.md`; hub TBD |
| Phase 5 | Socket pool spike | Done (minimal) | `ConsumerSocketConnectionPool`, `SOCKET_CONNECTION_POOL_SIZE` |
| Phase 6 | Transport policy matrix | Done (env) | `AgentQueryTransportPolicy`, `AGENT_QUERY_TRANSPORT_POLICY` |

**Gaps / hub-dependent**: relay JSON-RPC batch on plug_server; optional second
socket connection factory when `SOCKET_CONNECTION_POOL_SIZE > 1` (**not wired** —
production stays on a single `ConsumerSocketConnection`); unary
`sql.cancel` semantics on the agent. Hub `fastPath` must echo the client
JSON-RPC `id` (see `docs/server_adjustments/relay_unary_fast_path.md`).

**Client reliability (2026-07):** temporary REST latch after 3 consecutive
socket/relay transport timeouts; `RelayConversationManager.obtain` is
single-flight per `agentId`.

### Performance follow-up (Colmeia-only plan)

| PR | Item | Status | Location |
| --- | --- | --- | --- |
| PR1 | SQL cache/coalesce in socket session export | Done | `wireAgentQueriesSocketMetricsExport`, `MetricsAgentQueriesRepository.repositoryLayerAppendix` |
| PR2 | Coalescing with `cancelScope` + split pending ids | Done | `CoalescingAgentQueriesRepository`, `AgentQueriesCancelScope` |
| PR3 | Transport policy effective on overview | Done | `OverviewBatchLoader`, `AgentQueryTransportPolicy` |
| PR4 | Parse rows off main thread | Done | `AgentSqlBridgeResponse`, `agent_sql_bridge_response_isolate.dart` |
| PR5 | Sales map batch + wave limit | Done | `LoadSalesLiveMapUseCase`, `AgentQueryTargetOrdering` |
| PR6 | Push dedup §5.10 | Done | `PushEventDeduper`, profile listener, `ClientAgentsController` |
| PR7 | mergeAll default, catalog cache TTL, same-agent grouping | Done | `AgentQueryExecutor`, `CachingAgentQueriesRepository`, coordinator |
| A | Handshake timer cancel, FNV coalesce key, pre-warm stagger | Done | `consumer_socket_connection.dart`, `socket_coalesce_key.dart`, `relay_conversation_pre_warmer.dart` |
| B | Async `agents:command` / presence decode + wall-clock | Done | `socket_command_dispatcher_impl.dart`, `ClientAgentProfileUpdatedListener`, `SocketChannelMetrics` |
| C | Relay fast-path one decode per frame | Done | `relay_command_dispatcher_impl.dart` (`preDecodedBody`) |
| D | Lazy PayloadFrame headers (no `base64Decode` on route) | Done | `payload_frame.dart` (`parseHeaders` / `materialize`) |
| E | Persistent codec isolate worker | Done | `payload_frame_codec_worker.dart`, `PayloadFrameCodec`, `injector_socket.dart` |

**Baseline before transport rollout (§7):** capture `SocketMetricsListener` log
`Socket session metrics export` after a 15–30 min session; compare
`coalescedTotal`, `sqlCacheHits`, `sqlCacheHitRate`,
`coalescingRepositoryCoalescedTotal`, `p95(dispatch_ms)` and
`relayAcceptToFirstChunkMs` before changing `AGENT_QUERY_TRANSPORT_POLICY`.

---

## 13. Referências cruzadas

- Plano executivo: `docs/Features/socket_consumer_channel_plan.md`
- Conexão: `docs/Features/consumer_socket_connection_design.md`
- Dispatcher: `docs/Features/socket_command_dispatcher_design.md`
- Presença: `docs/Features/agent_presence_realtime_design.md`
- Hub:
  - `plug_server/docs/performance_hub_agent.md`
  - `plug_server/docs/socket_relay_protocol.md`
  - `plug_server/docs/relay_fastpath_study.md`
  - `plug_server/docs/api_rest_bridge.md`
- Colmeia docs locais:
  - `docs/bridge_agent_sql_api_options.md` (batch, multi_result, executeBatch)
  - `docs/plug_server_docs_index_for_colmeia.md`
