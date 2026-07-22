# Hub: `RELAY_REQUEST_TIMEOUT` no smoke socket

> **Audience:** Colmeia + `plug_server` hub / ops  
> **Status:** **ainda falha** — agent nao responde a tempo; `timeoutMs` no envelope relay **nao** e contrato do hub hoje  
> **Priority:** high (presenca / dispatch do agent + gap de contrato)

## Correcao de entendimento (2026-07-22)

O envelope `relay:rpc.request` **nao** aceita `timeoutMs` no schema Zod
(`relayRpcEnvelopeSchema` em `relay_rpc_request.handler.ts`). Campos
desconhecidos sao stripados. A espera do hub no relay e **fixa**:

```text
env.socketRelayRequestTimeoutMs  // SOCKET_RELAY_REQUEST_TIMEOUT_MS
```

(ver `rpc_bridge_dispatch_relay.ts` — timer com `relayRequestTimeoutMs`).

Paridade REST (`timeoutMs` no body / `computeBridgeWaitTimeoutMs`) **nao**
existe no caminho relay. O Colmeia continua a enviar `timeoutMs` no envelope
como forward-compat; ate o hub aceitar o campo, isso **nao** estende a espera.

A correlacao wall-clock 15s/30s/60s observada no smoke combina com o
**timer local** do consumer (`bridgeTimeoutMs` / `agentSqlTransportDispatchTimeout`)
e/ou com mudancas de `SOCKET_RELAY_REQUEST_TIMEOUT_MS` no hub — nao prova
honra de `timeoutMs` no envelope.

Pedido de contrato: [`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md).

## Orientacao ao Colmeia — status

| Pedido | Status Colmeia |
| --- | --- |
| Smoke unary sem `prefer_db_streaming` / sem `fastPath` streaming | Feito |
| `accepted { success: false }` → rejeicao imediata | Feito |
| Enviar `timeoutMs` no envelope | Feito (forward-compat; hub ainda stripa) |
| Correlacionar `relay_request_timeout` + `conversationId` | IDs abaixo |

## Repro

```powershell
flutter test test/integration/e2e/agent_queries_socket_relay_smoke_e2e_test.dart `
  --concurrency=1 `
  --dart-define=AGENT_BRIDGE_TRANSPORT=socket `
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=false `
  --dart-define=E2E_LOG_TRANSIENT=1
```

Smoke: unary, `prefer_db_streaming: false`, `bridgeTimeoutMs: 60000`, SQL:

```sql
SELECT CodCliente, Nome FROM Cliente ORDER BY CodCliente
```

## Correlacao para o hub (usar estes)

1. Log / metrica: `relay_request_timeout` / `RELAY_REQUEST_TIMEOUT`
2. IDs recentes:
   - `conversation_id=130793fb-b2d4-41f6-aed9-0c634fe433e5` + `client_request_id=ff10fcc8-cad0-4c73-8151-1768b81c7612`
   - `conversation_id=ff788799-19c0-4b5c-9b34-47238d1e64d3`
3. A/B: `agents:command` no mesmo agent devolve `NOT_FOUND` em ~0.6s — agent
   visivel no registry do relay start mas nao no dispatch legado?
4. Confirmar valor runtime de `SOCKET_RELAY_REQUEST_TIMEOUT_MS`
5. Confirmar: emit `rpc:request` ao agent socket? Agent online no mesmo PID
   (`X-Hub-Instance-Id: plug-4000`)?

RCA completo: [`socket_relay_timeout_deep_investigation_2026_07_22.md`](./socket_relay_timeout_deep_investigation_2026_07_22.md).

## Criterios de aceite

1. Smoke socket passa (rows nao vazias), **ou**
2. Hub logs para `19fec777-…` (ou novo id) mostram causa clara no agent /
   sticky — nao drop silencioso.
3. (Contrato) `timeoutMs` no envelope relay honrado — ver
   [`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md).

## Referencias

- Colmeia wire: `lib/core/socket/relay/relay_command_dispatcher_impl.dart`
- Smoke: `test/integration/e2e/agent_queries_socket_relay_smoke_e2e_test.dart`
- Hub schema: `src/presentation/socket/consumers/relay_rpc_request.handler.ts`
- Hub timer: `src/presentation/socket/hub/relay/rpc_bridge_dispatch_relay.ts`
- Docs oficiais: `docs/plug_server/socket/socket_relay_protocol.md`
