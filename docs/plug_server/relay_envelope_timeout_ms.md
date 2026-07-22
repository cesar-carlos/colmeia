# Hub: aceitar `timeoutMs` no envelope `relay:rpc.request`

> **Audience:** `plug_server`  
> **Status:** aberto — Colmeia ja envia; schema Zod stripa o campo  
> **Priority:** medium (paridade REST; desbloqueia SQL longo no smoke)

## Problema

No REST / `agents:command`, o body aceita `timeoutMs` e o hub calcula a
espera com `computeBridgeWaitTimeoutMs`.

No relay, `relayRpcEnvelopeSchema` **nao** declara `timeoutMs`. O timer e
sempre `SOCKET_RELAY_REQUEST_TIMEOUT_MS` (`rpc_bridge_dispatch_relay.ts`).

Resultado: o consumer nao consegue pedir espera por-request no canal
preferido (Socket/relay). SQL > default do env falha com
`RELAY_REQUEST_TIMEOUT` mesmo com `bridgeTimeoutMs` alto no client.

## Pedido

1. Adicionar ao envelope de `relay:rpc.request` e `relay:rpc.request.batch`:

```ts
timeoutMs: z.number().int().positive().max(360_000).optional()
```

(teto alinhado a REST: `AGENT_TIMEOUT_MS_LIMIT + 60000`).

2. Propagar ate o timer do route:

```text
effective = computeBridgeWaitTimeoutMs(command, timeoutMs ?? SOCKET_RELAY_REQUEST_TIMEOUT_MS)
```

3. No batch, o mesmo `timeoutMs` do envelope aplica a cada item (ou
   documentar max por item se preferirem).

4. Documentar em `docs/socket/socket_relay_protocol.md` e
   `docs/socket/socket_client_sdk.md` (secao opt-in do envelope).

5. Em timeout: manter `error.data.code = RELAY_REQUEST_TIMEOUT` + log
   `relay_request_timeout` com `conversationId` / `requestId` /
   `clientRequestId`.

## Colmeia (ja pronto)

- Envia `timeoutMs` = `bridgeTimeoutMs` em unary / streaming / batch.
- Timer local do consumer permanece independente (`timeout` do dispatcher).

## Criterios de aceite

1. Envelope com `timeoutMs: 60000` faz o hub esperar ~60s (nao o default
   de env) antes de `RELAY_REQUEST_TIMEOUT`.
2. Sem `timeoutMs`, comportamento atual (env default) permanece.
3. Docs socket atualizadas; schema Zod rejeita valores invalidos com
   `VALIDATION_ERROR` / `BAD_REQUEST` em `relay:rpc.accepted`.

## Referencias

- Schema atual: `src/presentation/socket/consumers/relay_rpc_request.handler.ts`
- Batch: `src/presentation/socket/consumers/relay_rpc_request_batch.handler.ts`
- Timer: `src/presentation/socket/hub/relay/rpc_bridge_dispatch_relay.ts`
- Paridade REST: `computeBridgeWaitTimeoutMs` em `command_transformers.ts`
- Smoke relacionado: [`relay_request_timeout_socket_smoke_2026_07_22.md`](./relay_request_timeout_socket_smoke_2026_07_22.md)
