# Hub: `relay:rpc.accepted` de erro sem `clientRequestId` / `conversationId`

> **Audience:** `plug_server`  
> **Status:** aberto — catch de `handleRelayRpcRequest` ainda omite os ids  
> **Priority:** medium (evita hang ate timer local no consumer)

## Problema

No sucesso, `relay:rpc.accepted` carrega `conversationId`, `requestId` e
opcionalmente `clientRequestId`.

No caminho de erro (`catch` de `handleRelayRpcRequest`), o emit e so:

```ts
emitRelayRpcAccepted(socket, {
  success: false,
  error: { code, message, statusCode?, retryAfterMs? },
});
```

Sem `conversationId` / `clientRequestId`, consumers que indexam pendings
por esses ids podem ignorar o evento e esperar o timer local.

O tipo TypeScript `RelayRpcAcceptedPayload` (ramo `success: false`) tambem
nao declara esses campos — o contrato de erro fica incompleto.

## Pedido

1. No `success: false`, **sempre** ecoar `conversationId` do envelope
   quando o parse ja ocorreu.
2. **SHOULD** ecoar `clientRequestId` quando o frame ja foi decodificado o
   bastante para ler o JSON-RPC `id` (incluindo rejeicao
   `fastPath` + metodo streaming-capable).
3. Atualizar o tipo `RelayRpcAcceptedPayload` e a doc em
   `docs/socket/socket_relay_protocol.md`.

## Mitigacao no Colmeia (nao substitui o hub)

- Rejeicao imediata quando `clientRequestId` vem no `accepted` de erro.
- Fallback orphan: se veio sem id e ha exatamente 1 pending na conversa,
  falha esse pending.

## Criterios de aceite

1. `accepted { success: false }` em rejeicao de `fastPath` + streaming
   inclui `conversationId` + `clientRequestId` quando disponiveis.
2. Teste de integracao no hub cobre o eco nos erros de dispatch.

## Referencias

- `src/presentation/socket/consumers/relay_rpc_request.handler.ts`
  (`emitRelayRpcAccepted` no `catch`)
- Colmeia: `lib/core/socket/relay/relay_command_dispatcher_impl.dart`
  (`_onAccepted`, `_failOrphanAcceptedRejection`)
