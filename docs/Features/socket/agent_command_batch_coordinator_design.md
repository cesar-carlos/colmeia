# Design técnico — `AgentCommandBatchCoordinator`

> Companheiro técnico de:
>
> - `docs/Features/socket_consumer_channel_plan.md` §11.5 (matriz de transporte)
>   e Fase 1.2 / PR-I.
> - `docs/Features/socket_command_dispatcher_design.md` (camada abaixo).
> - `docs/Features/socket_channel_performance_review.md` §5.2 (origem da
>   melhoria, com estimativa de impacto **-30 a -60% no `p95(dispatch_ms)`**
>   em waves).
>
> Este documento detalha **arquitetura**, **API**, **lifecycle**, **parsing
> de batch**, **falhas parciais**, **interação com coalescing/gate**,
> **cancelamento**, **edge cases** e **plano de testes** para o coordenador
> de batch JSON-RPC nativo.
>
> Nenhum código de produção foi escrito ainda. Os blocos `dart` são
> **esqueletos normativos**.

---

## 1. Responsabilidade única (SRP)

`AgentCommandBatchCoordinator` é responsável por:

1. Aceitar submissions individuais de RPCs ao mesmo `agentId`.
2. **Agregar** submissions chegadas dentro de uma janela curta
   (`SOCKET_BATCH_WINDOW_MS`, default **8 ms**) em uma única chamada
   `agents:command` com `command: [...]` (máx **32**).
3. **Despachar** o batch via `SocketCommandDispatcher.sendAgentsCommand`.
4. **Distribuir** a resposta `response.type === "batch"` para os
   completers individuais, **sintetizando** payloads `single` por item
   (mantém `AgentSqlBridgeResponse.parseSuccess` funcionando sem mudanças).
5. **Tratar falhas parciais** (alguns `items[i].error`, outros `result`)
   sem afetar os bem-sucedidos.
6. **Falhar** todos os pendentes em erro de despacho (rede, timeout,
   `app:error` global, disconnect).

**Não responde por:**

- Conexão / handshake (é `ConsumerSocketConnection`).
- Correlação por `rpcId` na camada socket (é `SocketRequestCorrelator`
  dentro do dispatcher — o batch tem **um** `rpcId externo** mas o coordenador
conhece os `rpcId internos` dos itens).
- Decidir entre `agents:command` e `relay:*` (selecionado a montante).
- Construir o body interno de cada `command.params` (continua sendo do
  `AgentSqlExecuteRequestToBridgeBody`).

---

## 2. Quando batch é elegível (e quando não)

Tabela normativa para o caller decidir `batchEligible: true|false`:

| Caso                                                         | Elegível?                          | Motivo                                                                                    |
| ------------------------------------------------------------ | ---------------------------------- | ----------------------------------------------------------------------------------------- |
| `sql.execute` simples sem `multi_result`                     | **Sim**                            | Caso ideal para batch.                                                                    |
| `sql.execute` com `body.pagination`                          | **Não**                            | `pagination` no body só vale para `sql.execute` **único**, não para batch (regra do hub). |
| `sql.execute` com `multi_result: true`                       | **Não**                            | Já é multi-result em 1 RPC; não compor com batch.                                         |
| `sql.executeBatch`                                           | **Não**                            | Já é batch semântico no agente. Compor com JSON-RPC batch acrescenta confusão.            |
| `agent.getProfile`, `client_token.getPolicy`, `rpc.discover` | **Sim**                            | Pequenos, ideais para piggyback.                                                          |
| `sql.cancel`                                                 | **Não**                            | Tempo-crítico; envio imediato sem janela de espera.                                       |
| Caminho `relay:*` (Fase 2)                                   | **Não**                            | Relay aceita só **um** RPC por `relay:rpc.request`.                                       |
| Notification (`id: null`)                                    | **Não suportado pelo coordenador** | Sem correlação para distribuir resposta.                                                  |

**Regra dura**: o coordenador **rejeita** submissions com `id: null` ou
sem `rpcId` lançando `ArgumentError`.

**Atalho**: callers que não souberem a regra podem deixar `batchEligible: true`
(default); o coordenador detecta os casos não-elegíveis pela inspeção do
RPC e faz **bypass** automaticamente para o dispatcher.

---

## 3. API pública

`lib/core/socket/agent_command_batch_coordinator.dart`

```dart
import 'dart:async';

abstract interface class AgentCommandBatchCoordinator {
  /// Submete um único RPC. Pode ser agregado com outros RPCs do mesmo
  /// agentId que cheguem dentro da janela. Retorna o JSON normalizado
  /// como se fosse um envio unitário (`response.type === "single"`).
  ///
  /// `rpcCommand` deve ser o objeto JSON-RPC completo:
  /// `{ jsonrpc: "2.0", method: "...", id: "...", params: {...} }`.
  ///
  /// O `command.id` interno deve coincidir com `rpcId` (regra de
  /// correlação). Se o caller passar `id: null` (notification),
  /// lança `ArgumentError`.
  Future<Map<String, dynamic>> submit({
    required String agentId,
    required Map<String, Object?> rpcCommand,
    required String rpcId,
    Duration? timeout,
    bool batchEligible = true,
  });

  /// Forçar flush de todos os collectors (todos os agentes). Útil para
  /// dispose / logout. Não cancela: aguarda a resposta da emissão.
  Future<void> flushAll();

  /// Encerra timers e completa pendentes com `SocketDispatchDisconnected`.
  /// Idempotente.
  Future<void> dispose();
}
```

---

## 4. Modelo interno

```dart
class _PendingRpc {
  _PendingRpc({
    required this.rpcId,
    required this.command,
    required this.completer,
    required this.timeout,
    required this.enqueuedAt,
  });

  final String rpcId;
  final Map<String, Object?> command;
  final Completer<Map<String, dynamic>> completer;
  final Duration timeout;
  final DateTime enqueuedAt;
}

class _AgentBatchCollector {
  _AgentBatchCollector({required this.agentId});
  final String agentId;
  final List<_PendingRpc> queue = <_PendingRpc>[];
  Timer? flushTimer;
}
```

O coordenador mantém:

```dart
final Map<String, _AgentBatchCollector> _collectorsByAgent =
    <String, _AgentBatchCollector>{};
```

> **Sem state global**: cada agente tem seu coletor independente, com
> seu próprio timer. Garante isolamento — uma wave para o agente A não
> atrapalha o B.

---

## 5. Implementação default

`lib/core/socket/agent_command_batch_coordinator_impl.dart`

```dart
import 'dart:async';
import 'dart:math' show min;

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:uuid/uuid.dart';

class AgentCommandBatchCoordinatorImpl
    implements AgentCommandBatchCoordinator {
  AgentCommandBatchCoordinatorImpl({
    required SocketCommandDispatcher dispatcher,
    Duration windowDuration = const Duration(milliseconds: 8),
    int maxBatchSize = 32,
    int minBatchSize = 1,
    Duration defaultTimeout = const Duration(seconds: 20),
  })  : _dispatcher = dispatcher,
        _windowDuration = windowDuration,
        _maxBatchSize = maxBatchSize,
        _minBatchSize = minBatchSize,
        _defaultTimeout = defaultTimeout;

  final SocketCommandDispatcher _dispatcher;
  final Duration _windowDuration;
  final int _maxBatchSize;
  final int _minBatchSize;
  final Duration _defaultTimeout;
  static const Uuid _uuid = Uuid();

  final Map<String, _AgentBatchCollector> _collectorsByAgent =
      <String, _AgentBatchCollector>{};
  bool _isDisposed = false;

  @override
  Future<Map<String, dynamic>> submit({
    required String agentId,
    required Map<String, Object?> rpcCommand,
    required String rpcId,
    Duration? timeout,
    bool batchEligible = true,
  }) async {
    if (_isDisposed) {
      throw const SocketDispatchDisconnected(
        message: 'Coordinator disposed',
      );
    }
    _validateRpc(rpcCommand: rpcCommand, rpcId: rpcId);

    if (!batchEligible || !_isEligibleByMethod(rpcCommand)) {
      // Bypass: vai direto ao dispatcher como request unitário.
      return _dispatcher.sendAgentsCommand(
        agentId: agentId,
        body: _buildSingleBody(
          agentId: agentId,
          command: rpcCommand,
          timeout: timeout,
        ),
        rpcId: rpcId,
        timeout: timeout,
      );
    }

    final collector = _collectorsByAgent.putIfAbsent(
      agentId,
      () => _AgentBatchCollector(agentId: agentId),
    );

    final completer = Completer<Map<String, dynamic>>();
    collector.queue.add(_PendingRpc(
      rpcId: rpcId,
      command: rpcCommand,
      completer: completer,
      timeout: timeout ?? _defaultTimeout,
      enqueuedAt: DateTime.now(),
    ));

    if (collector.queue.length >= _maxBatchSize) {
      // Fila cheia: flush imediato (cancela timer pendente).
      collector.flushTimer?.cancel();
      collector.flushTimer = null;
      unawaited(_flushCollector(collector));
    } else {
      collector.flushTimer ??= Timer(_windowDuration, () {
        collector.flushTimer = null;
        unawaited(_flushCollector(collector));
      });
    }

    return completer.future;
  }

  @override
  Future<void> flushAll() async {
    final collectors = List<_AgentBatchCollector>.of(_collectorsByAgent.values);
    await Future.wait(collectors.map(_flushCollector));
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final collectors = List<_AgentBatchCollector>.of(_collectorsByAgent.values);
    _collectorsByAgent.clear();
    for (final collector in collectors) {
      collector.flushTimer?.cancel();
      for (final pending in collector.queue) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            const SocketDispatchDisconnected(
              message: 'BatchCoordinator disposed',
            ),
          );
        }
      }
      collector.queue.clear();
    }
  }

  // ----- Internals -----

  Future<void> _flushCollector(_AgentBatchCollector collector) async {
    if (collector.queue.isEmpty) {
      return;
    }

    // Drena até maxBatchSize itens (caso a fila tenha crescido após
    // o agendamento).
    final taken = collector.queue.take(_maxBatchSize).toList(growable: false);
    collector.queue.removeRange(0, taken.length);

    // Fast-path: se taken.length < minBatchSize, manda unitário.
    if (taken.length < _minBatchSize) {
      await _dispatchAsSingle(collector.agentId, taken.first);
      return;
    }

    // Constrói batch.
    final batchRpcId = 'batch-${_uuid.v4()}';
    final body = _buildBatchBody(
      agentId: collector.agentId,
      items: taken,
      timeout: _resolveBatchTimeout(taken),
    );

    AppLogger.debug(
      'Dispatching batch',
      context: <String, Object?>{
        'component': 'AgentCommandBatchCoordinatorImpl',
        'agentId': collector.agentId,
        'batchSize': taken.length,
        'batchRpcId': batchRpcId,
      },
    );

    Map<String, dynamic>? response;
    Object? failure;
    StackTrace? failureStack;
    try {
      response = await _dispatcher.sendAgentsCommand(
        agentId: collector.agentId,
        body: body,
        rpcId: batchRpcId,
        timeout: _resolveBatchTimeout(taken),
      );
    } on Object catch (e, s) {
      failure = e;
      failureStack = s;
    }

    if (failure != null) {
      // Falha total: todos os itens recebem o mesmo erro.
      for (final pending in taken) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(failure, failureStack);
        }
      }
      return;
    }

    _distributeBatchResponse(taken: taken, batchResponse: response!);
  }

  Future<void> _dispatchAsSingle(
    String agentId,
    _PendingRpc pending,
  ) async {
    try {
      final result = await _dispatcher.sendAgentsCommand(
        agentId: agentId,
        body: _buildSingleBody(
          agentId: agentId,
          command: pending.command,
          timeout: pending.timeout,
        ),
        rpcId: pending.rpcId,
        timeout: pending.timeout,
      );
      if (!pending.completer.isCompleted) {
        pending.completer.complete(result);
      }
    } on Object catch (e, s) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(e, s);
      }
    }
  }

  Map<String, Object?> _buildSingleBody({
    required String agentId,
    required Map<String, Object?> command,
    required Duration? timeout,
  }) {
    return <String, Object?>{
      'agentId': agentId,
      if (timeout != null) 'timeoutMs': timeout.inMilliseconds,
      'command': command,
    };
  }

  Map<String, Object?> _buildBatchBody({
    required String agentId,
    required List<_PendingRpc> items,
    required Duration timeout,
  }) {
    return <String, Object?>{
      'agentId': agentId,
      'timeoutMs': timeout.inMilliseconds,
      // Body-level pagination NÃO é permitido em batch.
      'command': items.map((p) => p.command).toList(growable: false),
    };
  }

  Duration _resolveBatchTimeout(List<_PendingRpc> items) {
    // Conservador: pega o MAIOR timeout entre os itens, com piso do default.
    var max = _defaultTimeout;
    for (final p in items) {
      if (p.timeout > max) {
        max = p.timeout;
      }
    }
    return max;
  }

  void _distributeBatchResponse({
    required List<_PendingRpc> taken,
    required Map<String, dynamic> batchResponse,
  }) {
    final byId = <String, _PendingRpc>{
      for (final p in taken) p.rpcId: p,
    };

    final response = batchResponse['response'];
    if (response is! Map<String, dynamic>) {
      _failAll(taken, _decodeFailure('response field missing/invalid'));
      return;
    }
    final type = response['type'];

    if (type == 'batch') {
      final items = response['items'];
      if (items is! List) {
        _failAll(taken, _decodeFailure('batch items missing'));
        return;
      }
      _distributeBatchItems(byId: byId, items: items, batchResponse: batchResponse);
      return;
    }

    if (type == 'single' && taken.length == 1) {
      // Fallback: hub respondeu como single (raro, mas defensivo).
      final only = taken.single;
      if (!only.completer.isCompleted) {
        only.completer.complete(batchResponse);
      }
      return;
    }

    _failAll(
      taken,
      _decodeFailure('unexpected response type: $type'),
    );
  }

  void _distributeBatchItems({
    required Map<String, _PendingRpc> byId,
    required List items,
    required Map<String, dynamic> batchResponse,
  }) {
    final unmatched = Map<String, _PendingRpc>.of(byId);
    final commonAgentId = batchResponse['agentId']?.toString();
    final commonRequestId = batchResponse['requestId']?.toString();

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final id = raw['id']?.toString();
      if (id == null) {
        continue;
      }
      final pending = unmatched.remove(id);
      if (pending == null) {
        AppLogger.warning(
          'Batch item id not in pending map (late or duplicate)',
          context: <String, Object?>{
            'component': 'AgentCommandBatchCoordinatorImpl',
            'rpcId': id,
          },
        );
        continue;
      }
      if (!pending.completer.isCompleted) {
        pending.completer.complete(_synthesizeSingleEnvelope(
          agentId: commonAgentId,
          requestId: commonRequestId,
          item: raw,
        ));
      }
    }

    // Itens que não vieram na resposta: hub omitiu? Falha defensiva.
    for (final pending in unmatched.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(_decodeFailure(
          'batch response did not include id=${pending.rpcId}',
        ));
      }
    }
  }

  /// Envelopa um item de batch como se fosse uma resposta `single`,
  /// para que `AgentSqlBridgeResponse.parseSuccess` continue funcionando
  /// no `AgentQueriesRepositoryImpl` sem mudança.
  Map<String, dynamic> _synthesizeSingleEnvelope({
    required String? agentId,
    required String? requestId,
    required Map<String, dynamic> item,
  }) {
    return <String, dynamic>{
      'mode': 'bridge',
      if (agentId != null) 'agentId': agentId,
      if (requestId != null) 'requestId': requestId,
      'response': <String, dynamic>{
        'type': 'single',
        'success': item['success'] ?? (item['error'] == null),
        'item': item,
      },
    };
  }

  void _failAll(List<_PendingRpc> pending, Object error) {
    for (final p in pending) {
      if (!p.completer.isCompleted) {
        p.completer.completeError(error);
      }
    }
  }

  Object _decodeFailure(String message) {
    return SocketDispatchDecodeFailure(message: 'batch decode: $message');
  }

  void _validateRpc({
    required Map<String, Object?> rpcCommand,
    required String rpcId,
  }) {
    if (!rpcCommand.containsKey('id') || rpcCommand['id'] == null) {
      throw ArgumentError(
        'BatchCoordinator does not accept JSON-RPC notifications (id == null)',
      );
    }
    if (rpcCommand['id'] != rpcId) {
      throw ArgumentError(
        'rpcCommand.id (${rpcCommand['id']}) must equal rpcId ($rpcId)',
      );
    }
  }

  bool _isEligibleByMethod(Map<String, Object?> rpcCommand) {
    final method = rpcCommand['method']?.toString();
    if (method == 'sql.executeBatch' || method == 'sql.cancel') {
      return false;
    }
    final params = rpcCommand['params'];
    if (params is Map<String, Object?>) {
      final options = params['options'];
      if (options is Map<String, Object?> &&
          options['multi_result'] == true) {
        return false;
      }
    }
    return true;
  }
}
```

---

## 6. Integração com o `SocketAgentQueriesRemoteDataSource`

`lib/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource.dart`
(versão **com batch**):

```dart
class SocketAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  SocketAgentQueriesRemoteDataSource({
    required AgentCommandBatchCoordinator coordinator,
    required AgentSqlExecuteRequestToBridgeBody bodyMapper,
  })  : _coordinator = coordinator,
        _bodyMapper = bodyMapper;

  final AgentCommandBatchCoordinator _coordinator;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  static const Uuid _uuid = Uuid();

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    final rpcId = _uuid.v4();
    final body = _bodyMapper.build(request: request, rpcId: rpcId);

    // Extrai apenas o objeto JSON-RPC (`command`) — o coordenador
    // monta o body envolvente (single ou batch) por agentId.
    final rpcCommand = body['command'] as Map<String, Object?>;

    return _coordinator.submit(
      agentId: request.trimmedAgentId,
      rpcCommand: rpcCommand,
      rpcId: rpcId,
      timeout: _resolveTimeout(request),
      // Body-level pagination (request.pagination != null) → bypass.
      batchEligible: request.pagination == null,
    );
  }

  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }
}
```

> **Importante**: `bodyMapper.build` ainda é a fonte da verdade do
> formato JSON-RPC; o coordenador apenas reusa o `command` interno.
> Garante paridade total com REST e com o caminho unitário.

---

## 7. Interação com outras melhorias

### 7.1 Coalescing (P1, dispatcher)

O coalescing vive **abaixo** do coordenador, no `SocketCommandDispatcher`.
Quando duas submissions com o **mesmo** `(agentId, method, params)` chegam:

- Cenário A — **mesma janela do batch**: as duas vão para o coletor.
  Bom seria detectar duplicidade aqui também (eficiência). **Decisão:**
  acrescentar dedupe **dentro** do coletor por chave estável; o segundo
  caller compartilha o completer do primeiro.

```dart
// dentro de submit() — antes de enfileirar:
final coalesceKey = _coalesceKey(agentId, rpcCommand);
final existing = collector.coalesceMap[coalesceKey];
if (existing != null && !existing.completer.isCompleted) {
  return existing.completer.future;
}
```

- Cenário B — submissions em janelas diferentes: o coalescing do
  dispatcher (próprio request inflight) pega — sem mudança.

### 7.2 `PerAgentConcurrencyGate` (P1)

O gate fica **no dispatcher** e protege **emissões**. Como 1 batch = 1
emissão, o gate naturalmente regula throughput correto:

- 32 RPCs em batch consomem **1 slot** do gate.
- Sem batch, 32 RPCs consumiriam 32 slots → enfileirados → mais latência.

**Conclusão**: batch + gate são **complementares**; batch reduz a pressão
no gate.

### 7.3 Timeout adaptativo (P2)

`AgentLatencyOracle` mede latência por `(agentId, method)`. Em batch, qual
método registrar?

- **Decisão**: registrar **um** outcome por item (depois do
  `_distributeBatchItems`), não por batch. Histograma reflete latência
  real percebida pelo caller (que tem `wait_window + dispatch`).
- O `Stream<AgentCommandOutcome>` do dispatcher precisa ganhar evento
  por item de batch — adicionar campo `batchSize` ao outcome ajuda
  na análise.

### 7.4 Cancelamento (P2)

`SocketCommandCancelToken.cancel()` precisa:

1. Se a submission **ainda não foi flush**: remover o `_PendingRpc` do
   coletor; completar com erro de cancelamento.
2. Se já foi flush: **manter** no `byId` (resposta ainda chega), mas
   ignorar o resultado quando completar (caller não está esperando mais).

Esqueleto da extensão:

```dart
// Em submit():
cancelToken?.onCancel(() {
  collector.queue.remove(pending);
  if (!pending.completer.isCompleted) {
    pending.completer.completeError(
      SocketDispatchCancelled(message: 'Cancelled before flush'),
    );
  }
});
```

### 7.5 Métricas (P0)

Acrescentar ao `SocketChannelMetrics`:

- `batch_emissions_total` (counter) — N emissões via coordenador.
- `batch_size_distribution` (histograma) — items por batch.
- `batch_window_flush_total` vs `batch_size_flush_total` — flush por
  timer vs por max size.
- `batch_partial_failure_total` (counter) — batches com pelo menos 1
  item com `error`.
- `batch_unmatched_id_total` (counter) — itens no `pending` que não
  vieram na resposta (sintoma de bug do hub).
- `batch_bypass_total` por motivo (`paginated`, `multi_result`,
  `executeBatch`, `cancel`, `caller_opt_out`).

---

## 8. Edge cases

| #   | Cenário                                                              | Comportamento esperado                                                                                                                                                                            |
| --- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Submit com `id: null`                                                | `ArgumentError` síncrono.                                                                                                                                                                         |
| 2   | Submit com `id != rpcId`                                             | `ArgumentError` síncrono.                                                                                                                                                                         |
| 3   | Fila cheia no momento do submit                                      | Cancela timer; flush imediato; agendamento de próximo timer só no próximo submit.                                                                                                                 |
| 4   | Timer dispara com fila vazia                                         | No-op (defensivo, embora o set do timer só aconteça com fila não-vazia).                                                                                                                          |
| 5   | `dispose()` durante batch in-flight                                  | Pendentes do coletor (ainda não flushados) recebem `SocketDispatchDisconnected`. Os já flushados continuam aguardando o dispatcher; quando ele falha (próximo `disconnect`), também recebem erro. |
| 6   | Resposta com `type: 'single'` para batch de 1 item                   | Aceito (defensivo): completa o único pendente com a resposta tal qual.                                                                                                                            |
| 7   | Resposta com `type: 'batch'` mas `items` vazio                       | Todos os pendentes falham com `SocketDispatchDecodeFailure`.                                                                                                                                      |
| 8   | `items[i].id` desconhecido (não bate com nenhum pendente)            | Log `warning`; descarta. Métricas registram `late_or_duplicate`.                                                                                                                                  |
| 9   | Pendente sem item correspondente na resposta                         | Falha aquele pendente com `decode failure`. Métrica `batch_unmatched_id_total`.                                                                                                                   |
| 10  | Erro de despacho (timeout / disconnect)                              | Todos os pendentes do batch recebem o **mesmo** erro.                                                                                                                                             |
| 11  | Falha parcial (`items[i].error`)                                     | Cada item falho recebe seu erro JSON-RPC; demais sucesso. **Sem fail-fast**.                                                                                                                      |
| 12  | Batch ultrapassa rate-limit do hub (`429`)                           | Hub responde com `app:error` global → `_failAll`. Próximas submissões respeitam backoff via dispatcher.                                                                                           |
| 13  | Coalescing dentro do batch (mesmo SQL+params duplicado em 2 submits) | Segundo submit compartilha o completer do primeiro; batch envia 1 só item. Métrica `coalesced_total`.                                                                                             |
| 14  | Submit com `batchEligible: true` mas `multi_result: true`            | Bypass automático: vai pelo dispatcher unitário.                                                                                                                                                  |
| 15  | Submit em **dois agentes diferentes** "ao mesmo tempo"               | Dois coletores independentes; duas emissões paralelas (respeitando o gate por agente).                                                                                                            |

---

## 9. Configuração

| Env                      | Default | Efeito                                                                                                                                                                                      |
| ------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SOCKET_BATCH_ENABLED`   | `true`  | Kill switch global. `false` força bypass de tudo.                                                                                                                                           |
| `SOCKET_BATCH_WINDOW_MS` | `8`     | Janela de coalescência. **0** = flush imediato a cada submit (efetivamente sem batch). Tuning: 4–16 ms é razoável para mobile.                                                              |
| `SOCKET_BATCH_MAX_SIZE`  | `32`    | Limite oficial do hub. **Não exceder.**                                                                                                                                                     |
| `SOCKET_BATCH_MIN_SIZE`  | `1`     | `1` = sempre batch (mesmo com 1 item; envia como `command: [x]`). `2` = se só houver 1 item ao flush, manda como `single` (mais legível em logs do hub). Recomendado: **1** (simplicidade). |

> **Tuning operacional**: medir `batch_size_distribution.p50/p95` em
> produção; se p50 < 2, considerar bumping `SOCKET_BATCH_WINDOW_MS`
> (mais espera, mais agregação). Se p95 = 32 sempre, bumping não ajuda
> (limite estourado é o gargalo).

---

## 10. DI

`lib/core/di/injector_socket.dart` (delta):

```dart
getIt
  ..registerLazySingleton<AgentCommandBatchCoordinator>(
    () => AgentCommandBatchCoordinatorImpl(
      dispatcher: getIt<SocketCommandDispatcher>(),
      windowDuration: Duration(
        milliseconds: AppEnvironment.socketBatchWindowMs,
      ),
      maxBatchSize: AppEnvironment.socketBatchMaxSize,
      minBatchSize: AppEnvironment.socketBatchMinSize,
    ),
    dispose: (c) => c.dispose(),
  );
```

`injector_agent_queries.dart` (substituir registro do datasource):

```dart
getIt.registerLazySingleton<AgentQueriesRemoteDataSource>(() {
  if (AppEnvironment.useFakeBackend) {
    return FakeAgentQueriesRemoteDataSource();
  }
  return switch (AppEnvironment.agentBridgeTransport) {
    AgentBridgeTransport.socket =>
      AppEnvironment.socketBatchEnabled
          ? SocketAgentQueriesRemoteDataSource(
              coordinator: getIt<AgentCommandBatchCoordinator>(),
              bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
            )
          : SocketAgentQueriesRemoteDataSourceWithoutBatch(
              dispatcher: getIt<SocketCommandDispatcher>(),
              bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
            ),
    AgentBridgeTransport.rest => ApiAgentQueriesRemoteDataSource(
        dio: getIt<Dio>(),
        bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
      ),
  };
});
```

> **Decisão**: o "datasource sem batch" (PR-B do plano executivo) **não
> some** quando `BATCH_ENABLED=true` — ele continua existindo como
> caminho de fallback rápido (sem precisar parar o app para diagnosticar).

---

## 11. Plano de testes

### 11.1 Unit — coordenador

`test/core/socket/agent_command_batch_coordinator_impl_test.dart`

Usa `fake_async` para controle determinístico do tempo + um
`FakeSocketCommandDispatcher` (registra emissões e devolve respostas
programadas).

Cobertura:

| Teste                                        | O que verifica                                                                                  |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `submit_alone_flushes_after_window`          | 1 submit + tick de `windowDuration` → 1 emissão batch com 1 item.                               |
| `submits_within_window_aggregate`            | 5 submits em < window → 1 emissão batch com 5 itens.                                            |
| `max_size_triggers_immediate_flush`          | 33 submits seguidos → 1 emissão de 32 + outra de 1 (agenda novo timer).                         |
| `mixed_agents_use_independent_collectors`    | 3 submits para A + 4 para B na mesma window → 2 emissões batch, isoladas.                       |
| `bypass_for_multi_result`                    | submit com `options.multi_result: true` → vai direto ao dispatcher unitário.                    |
| `bypass_for_pagination_in_body`              | submit com `batchEligible: false` → bypass.                                                     |
| `bypass_for_executeBatch`                    | submit com `method: 'sql.executeBatch'` → bypass.                                               |
| `bypass_for_cancel`                          | submit com `method: 'sql.cancel'` → bypass.                                                     |
| `rejects_notification`                       | `id: null` → `ArgumentError` síncrono.                                                          |
| `rejects_id_mismatch`                        | `command.id != rpcId` → `ArgumentError` síncrono.                                               |
| `partial_failure_distributes_individually`   | resposta com 3 itens (2 success, 1 error) → 2 completers OK, 1 com `AgentSqlRpcException`.      |
| `unmatched_id_in_response_logged_and_failed` | resposta omite 1 dos pendings → aquele falha com `decode_failure`.                              |
| `extra_id_in_response_logged_and_dropped`    | resposta tem 1 item extra → log warning; demais OK.                                             |
| `dispatcher_failure_fails_all_pending`       | dispatcher lança `Timeout` → todos os pendings recebem o **mesmo** erro.                        |
| `dispose_fails_pending`                      | submit + `dispose()` antes do flush → pending recebe `SocketDispatchDisconnected`.              |
| `coalesce_within_collector`                  | 2 submits idênticos antes do flush → 1 item no batch, 2 completers.                             |
| `single_response_for_batch_of_one_accepted`  | hub responde com `type: 'single'` para batch de 1 → completer recebe a resposta sem reformatar. |
| `synthetic_envelope_parsable`                | item de batch é envelopado para passar `AgentSqlBridgeResponse.parseSuccess` sem regressão.     |

### 11.2 Contract test — paridade com response single

`test/features/agent_queries/data/agent_sql_bridge_response_batch_envelope_test.dart`

- Para `N` payloads `items[i]` representativos (success com rows,
  success com pagination, error JSON-RPC), o envelope sintetizado por
  `_synthesizeSingleEnvelope` produz **o mesmo `AgentSqlExecutionResult`**
  que o caminho normal `single` produziria com o mesmo conteúdo.

### 11.3 Datasource

`test/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource_batch_test.dart`

- 5 chamadas `postSqlExecute` em paralelo → coordinator agrega; assert
  na captura de `dispatcher.sendAgentsCommand` que `body.command` é
  `List` com 5 entradas.
- Chamada com `pagination` → bypass; assert `body.command` é `Map`.

### 11.4 Integração e2e (opt-in)

`test/integration/e2e/agent_queries_socket_batch_e2e_test.dart`

- Login REST + socket conectado.
- Wave de 7 queries simultâneas ao **mesmo** agente real (representativo
  do `overview_controller`).
- Assert: `latency_total_ms` significativamente menor que o equivalente
  REST (rodar duas vezes, média/mediana).

### 11.5 Regression

- Manter todos os testes de `agent_queries_repository_impl_test.dart`
  passando sem mudança (porque o envelope sintético preserva o formato).

---

## 12. Métricas e logging

Logging estruturado (`AppLogger`):

| Evento                     | Nível     | Campos                                                                 |
| -------------------------- | --------- | ---------------------------------------------------------------------- |
| Batch dispatch             | `debug`   | `agentId`, `batchSize`, `batchRpcId`, `flushReason: 'timer'\|'size'`   |
| Batch response distribuído | `debug`   | `agentId`, `batchSize`, `successCount`, `errorCount`, `unmatchedCount` |
| Batch dispatcher failure   | `warning` | `agentId`, `batchSize`, `errorCode`                                    |
| Bypass                     | `debug`   | `agentId`, `method`, `bypassReason`                                    |
| Coalesced within batch     | `debug`   | `agentId`, `coalesceKey` (hashado)                                     |

> **Nunca** logar `command.params.sql` ou `client_token` no batch. Para
> diagnóstico, basta `agentId`, `method`, `rpcId`, `batchRpcId`.

---

## 13. Critérios de aceite

1. `flutter analyze` limpo.
2. Cobertura ≥ 90% em `agent_command_batch_coordinator_impl.dart`.
3. **Zero regressão** em `test/features/agent_queries/**` (envelope
   sintético preserva contratos).
4. Métrica em integração e2e: `p95(dispatch_ms)` em wave de 7 queries
   ≤ **40%** do equivalente unitário (alvo do review §5.2).
5. `SOCKET_BATCH_ENABLED=false` desativa completamente o coordenador
   sem precisar de redeploy/patch (kill switch funcional).
6. Bypass automático verificado para os 4 métodos não-elegíveis.
7. Coalescing dentro do coletor verificado em teste.

---

## 14. Pontos abertos (decidir antes da PR)

1. **Outcomes por item**: o `SocketCommandDispatcher.outcomes()` hoje
   emite **um** outcome por `sendAgentsCommand`. Em batch, isso significa
   1 outcome por **batch** (com `batchSize > 1`). Para a presença em
   tempo real (§4.2 do design de presença), faz sentido emitir
   **N outcomes** (um por item). Opções:
   - **(a)** Coordenador emite `outcomes` próprios por item (adicionar
     `Stream<AgentCommandOutcome> outcomesPerItem()` ao coordenador).
     — recomendado para preservar separação de responsabilidades.
   - **(b)** Dispatcher passa a aceitar uma lista de `agentId/rpcId` no
     contexto e emite N outcomes — mais acoplamento.
   - **(c)** Apresentação consome só `outcomes()` do coordenador, e o
     `dispatcher.outcomes()` é restrito ao caso unitário. — risco de
     gap.
     **Sugestão**: **(a)**.

2. **Coalescing dentro do coletor**: introduzir aqui ou esperar o
   coalescing global do dispatcher pegar?
   - Vantagem aqui: economiza slot de batch (32 → 32 únicos).
   - Custo: duplica lógica do dispatcher.
   - Sugestão: **introduzir aqui** (é coalescing **na fila de espera**,
     o do dispatcher é coalescing **inflight**; complementares).

3. **Timeout do batch**: usar `max(items.timeout)` é conservador. Se um
   item tem timeout 60 s e os outros 5 s, o batch espera 60 s para
   falhar — itens de 5 s ficam "presos". Alternativa:
   - Dividir em sub-batches por bucket de timeout. **Complexidade alta;
     descartar inicialmente.**
   - Documentar a regra: callers que precisam de timeout muito diferente
     devem usar `batchEligible: false`.

4. **Ordem dentro do batch**: o hub mantém ordem em `items[]` correspondente
   a `command[]`? Conferir contrato em `plug_server/docs/api_rest_bridge.md`
   (§ "Batch JSON-RPC nativo"). Se **não garantida**, o coordenador já
   trata: usa `id` para correlação, não índice.

5. **Web vs mobile**: `Timer` do `dart:async` em web tem resolução de
   ~4 ms (timer throttling em background). Em foreground é 1 ms. Para
   `windowMs = 8`, é OK. Documentar.

---

## 15. Referências cruzadas

- Plano executivo: `docs/Features/socket_consumer_channel_plan.md`
  (§11 Fase 1.2 PR-I, §11.5 matriz de transporte, §17.4 critérios de
  performance, §20.2 ordem de PRs).
- Designs companheiros:
  - `docs/Features/socket_command_dispatcher_design.md` (camada abaixo).
  - `docs/Features/agent_presence_realtime_design.md` (§4.2 — ponto
    aberto §14.1 deste doc).
  - `docs/Features/socket_channel_performance_review.md` §5.2 (origem).
- Hub:
  - `plug_server/docs/api_rest_bridge.md` (§ "Batch JSON-RPC nativo",
    `command` array até 32, `response.type === 'batch'`, semântica
    de `id` por item).
  - `plug_server/docs/socket_client_sdk.md` (§ "Bridge de comandos —
    `agents:command`").
- Local:
  - `docs/bridge_agent_sql_api_options.md` (matriz `batch` vs
    `multi_result` vs `executeBatch`).
- Código existente que **não muda** com este PR:
  - `lib/features/agent_queries/data/repositories/agent_queries_repository_impl.dart`
  - `lib/features/agent_queries/data/models/agent_sql_bridge_response.dart`
  - Use cases e controllers — todos seguem chamando o repository.
