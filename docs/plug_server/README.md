# `plug_server` — handoffs para o hub

Pasta de pedidos **acionáveis** para o time do `plug_server`.

## Aberto

| Documento | Tema | Ação do hub |
| --- | --- | --- |
| [`socket_relay_timeout_deep_investigation_2026_07_22.md`](./socket_relay_timeout_deep_investigation_2026_07_22.md) | **RCA:** REST ok; socket/relay `RELAY_REQUEST_TIMEOUT` — agent nao responde | Logs por `conversation_id` + emit `rpc:request` |
| [`relay_request_timeout_socket_smoke_2026_07_22.md`](./relay_request_timeout_socket_smoke_2026_07_22.md) | Smoke socket repro + IDs | Correlacionar `relay_request_timeout` |
| [`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md) | Aceitar `timeoutMs` no envelope relay | Schema Zod + timer |
| [`relay_rpc_accepted_error_missing_ids.md`](./relay_rpc_accepted_error_missing_ids.md) | `accepted` de erro sem ids | Ecoar ids no `catch` |

## Já tratado no Colmeia

| Tema | Feito |
| --- | --- |
| Docs `socket/` sincronizadas com hub | Copia de `plug_server/docs/socket` (2026-07-22) |
| `fastPath` × streaming-capable | Guard no dispatcher (`BAD_REQUEST`) |
| Smoke unary | Sem `prefer_db_streaming` |
| `accepted` de erro | `RelayRequestRejected` imediato + fallback orphan |
| `timeoutMs` no envelope | Enviado (forward-compat); hub ainda stripa — ver handoff |
| `agents:command_response` PayloadFrame | `decodeAgentsWirePayload` (shim `raw_json` até 2026-09-30) |
| `app:error` terminal | Sem reconnect cego; `ACCOUNT_BLOCKED` invalida sessão |
| Idle keepalive | Touch valido `socket:event.subscribe` (env) |
| `requestId` conversa + `ended.reason` | Emitidos / parseados |
| `inFlight` + batch streaming | Flag + rejeição `BATCH_STREAMING_ITEM_REJECTED` no client |
| Stream `error_code` | Surfaced em `RelayStreamTerminated` |
| Gzip min-savings | Alinhado ao hub (64 bytes) |

## Convenção

- Sem segredos; handoffs com repro + IDs de correlação + critérios de aceite
- Fonte normativa socket: [`socket/`](./socket/) (espelho de `plug_server/docs/socket`)
- Remover da pasta quando resolvido
