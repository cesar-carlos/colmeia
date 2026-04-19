# Smoke Test Socket — Achados de 2026-04-19 e Ações para o Servidor

> **Quem deve ler**: equipe de servidor / DevOps responsável pelo
> `plug_server` (`https://plug-server.se7esistemassinop.com.br`)
> e pelo nginx upstream.
>
> **Contexto**: o cliente `colmeia` flipou
> `AGENT_BRIDGE_TRANSPORT=socket` em produção e rodou smoke test
> end-to-end com user real autenticado. O app **não quebrou**
> (fallback REST funcionou), mas três ajustes ficaram pendentes do
> lado do servidor.
>
> Este documento é **focado nos achados de hoje** — leitura rápida,
> 3 ações concretas, comando de verificação para cada uma.
> Self-contained: as 3 ações + verificações + mensagem de handoff
> estão todas aqui, sem necessidade de cross-reference.

---

## TL;DR — Tabela de ações

| # | Severidade | Ação | Onde | Tempo |
| - | ---------- | ---- | ---- | ----- |
| 1 | 🔴 Bloqueante | `SOCKET_CONSUMER_ROLES=user,admin,client` + restart | `.env` ativo do `plug_server` | 5 min |
| 2 | 🟡 Recomendada | Resposta para `agents:command` quando agente offline (503 vs JSON-RPC `-32000`) | `agents.routes.ts` / bridge | 30-60 min |
| 3 | 🟢 Verificação | Confirmar `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true` | `.env` ativo do `plug_server` | 2 min |

> **Quando os 3 estiverem ✅, avise a equipe Flutter.** Vamos rodar
> outro smoke test e validar o caminho feliz end-to-end (esperado:
> latência ≥ 30 % menor por consulta + push de catálogo em tempo
> real).

---

## Ação #1 — `SOCKET_CONSUMER_ROLES=user,admin,client` 🔴

### Sintoma observado no smoke test

Cada handshake `/consumers` recebeu, ainda hoje 19/04/2026:

```
ConsumerSocketConnection state changed → ConsumerSocketUnauthorized
Bad state: Consumer socket namespace forbidden:
  role=client namespace=/consumers
  message=Role 'client' is not allowed to connect to /consumers
```

O JWT enviado pelo app está válido (a mesma sessão funciona em
todos os endpoints REST autenticados — `/client-auth/me`,
`/client/me/agents`, etc.). O bloqueio é **exclusivamente** o
middleware `socket_namespace_auth` que valida a role contra
`SOCKET_CONSUMER_ROLES`.

### Verificar se a env está aplicada

A diferença comum é "editei o `.env` mas não restartei o
processo" — o Zod no `plug_server` re-parseia `process.env` apenas
no boot. Comandos para confirmar:

```bash
# No host do plug_server (NÃO no .env do disco — no processo rodando):
sudo printenv -p $(pgrep -f plug_server) | grep SOCKET_CONSUMER_ROLES

# OU, se rodando via pm2:
pm2 env <id> | grep SOCKET_CONSUMER_ROLES

# OU, se rodando via docker-compose:
docker exec <container> printenv | grep SOCKET_CONSUMER_ROLES
```

**Resultado esperado:**

```
SOCKET_CONSUMER_ROLES=user,admin,client
```

Se aparecer só `user,admin` (default antigo) ou nada, edite o
`.env` ativo e **restart**:

```bash
# Opção 1 — pm2:
pm2 restart plug_server --update-env

# Opção 2 — docker-compose:
docker-compose restart plug_server

# Opção 3 — systemd:
sudo systemctl restart plug_server
```

### Critério de aceitação

A próxima tentativa de handshake do app **não** deve aparecer no
log com `Role 'client' is not allowed`. Em vez disso, o cliente
deve receber `connection:ready` e o estado interno passa para
`ConsumerSocketConnected`.

---

## Ação #2 — `agents:command` para agente offline retorna 503 🟡

### Sintoma observado no smoke test

O app abriu o **detail page** do agente `3183a9f2-...` (que
estava offline no momento) e rodou as 2 chamadas de introspeção
do `agent_meta`:

```
HTTP request | method=POST, path=/api/v1/agents/commands  (rpc.discover)
HTTP request failed | statusCode=503

HTTP request | method=POST, path=/api/v1/agents/commands  (client_token.getPolicy)
HTTP request failed | statusCode=503
```

O comportamento atual `503 Service Unavailable` está **alinhado**
com a tabela na `docs/api_rest_bridge.md` linha 1309:

> *Falha rapida em disconnect do agente: pending requests REST do
> socket desconectado sao encerradas com 503 sem aguardar timeout*

Mas essa linha cobre o caso de **disconnect no meio** de uma
request pendente. Para uma request **nova** chegando para um
agente já-conhecido-como-offline, o esperado pelo protocolo
JSON-RPC é responder com:

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": "<rpcId>",
  "error": {
    "code": -32000,
    "message": "agent_offline",
    "data": {
      "reason": "agent_disconnected_at_dispatch",
      "agent_id": "3183a9f2-..."
    }
  }
}
```

### Por que importa

- O cliente já sabe distinguir `RpcFailure(rpcCode: -32000)` (erro
  semântico do agente) de `NetworkFailure(503)` (problema do hub).
  Hoje os 2 chegam como `NetworkFailure` indistinguível.
- A mensagem para o usuário fica genérica ("servidor indisponível")
  em vez de específica ("agente desconectado, tente reconectá-lo").
- Métricas e dashboards confundem indisponibilidade do hub
  (`SERVICE_UNAVAILABLE`, deve disparar alerta) com agent
  offline (estado normal, não é erro do hub).

### Como verificar / aplicar

No código do `plug_server`, o handler do `agents:command` provavelmente
tem algo como:

```typescript
// pseudo, em src/presentation/api/agents/agents.routes.ts:
const targetSocket = agentRegistry.findByAgentId(agentId);
if (!targetSocket) {
  return reply.code(503).send({ error: 'agent_unavailable' });
  //          ^^^^^^^ aqui é onde precisa virar JSON-RPC error
}
```

Substituir por uma resposta `200` com envelope JSON-RPC `error`,
documentado em `docs/api_rest_bridge.md` (seção *erros*):

```typescript
if (!targetSocket) {
  return reply.code(200).send({
    response: {
      type: 'rpc_error',
      item: {
        jsonrpc: '2.0',
        id: rpcId,
        error: {
          code: -32000,
          message: 'agent_offline',
          data: {
            reason: 'agent_not_connected',
            agent_id: agentId,
          },
        },
      },
    },
  });
}
```

### Critério de aceitação

Repetir o smoke do `rpc.discover` contra um agente offline e
confirmar `HTTP/200` com payload JSON-RPC `error.code = -32000`
em vez de `HTTP/503`.

> **Nota**: essa mudança é **idempotente do ponto de vista do
> cliente** — o app já trata ambas as respostas sem regredir
> (apenas a mensagem do user fica menos precisa hoje). É melhoria
> de qualidade do canal, não bloqueio.

---

## Ação #3 — `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true` 🟢

### Por que verificar

Sem essa env, o evento `client:agent.profile.updated` nunca é
emitido. O app cai em modo **polling** (chama `GET
/client/me/agents` repetidamente) para detectar:

- Mudança de status do agente (online ↔ offline)
- Revogação / rotação de token
- Mudança de nome / dados cadastrais

Funciona, mas:
- ↑ Latência percebida (até 30 s para refletir mudança).
- ↑ Carga REST desnecessária no hub.
- A UX de "token revogado" no detail page do agente (commit
  `24ea32f` no app) deixa de funcionar em tempo real.

### Verificar se está aplicada

```bash
sudo printenv -p $(pgrep -f plug_server) | grep SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED
```

Resultado esperado:

```
SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true
```

Se ausente ou `false`, edite o `.env` ativo + restart (mesmo
procedimento da Ação #1).

### Critério de aceitação

Após aplicar:

1. Cliente conectado em `/consumers` para um user `client` que
   tem acesso a um agente.
2. Admin altera o nome do agente via API admin (ou aciona
   `client_token.rotate`).
3. Cliente recebe um frame `client:agent.profile.updated` (visível
   no log do hub via `audit_events` ou métricas Prometheus).

---

## Verificações pré-handoff

Antes de avisar a equipe Flutter "tá pronto", confirme os 3:

```bash
# Tudo de uma vez no host do plug_server:
echo "=== Action 1: SOCKET_CONSUMER_ROLES ==="
sudo printenv -p $(pgrep -f plug_server) | grep SOCKET_CONSUMER_ROLES
echo "Esperado: user,admin,client"
echo

echo "=== Action 3: SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED ==="
sudo printenv -p $(pgrep -f plug_server) | grep SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED
echo "Esperado: true"
echo

echo "=== Sticky session (smoke rápido) ==="
echo "Faça 5 requests REST autenticadas em sequência e confirme"
echo "que X-Hub-Instance-Id retorna o MESMO valor em todas — caso"
echo "seja multi-réplica, sticky session está OK; caso valores"
echo "diferentes, configure ip_hash ou cookie no nginx upstream."
```

---

## Mensagem-modelo de handoff

Quando os 3 ✅, mande para a equipe Flutter algo como:

> **Servidor pronto para reflip do socket no Colmeia.**
>
> Ações 1–3 do `socket_smoke_2026_04_19_action_items.md` aplicadas:
>
> - `SOCKET_CONSUMER_ROLES=user,admin,client` ✅ (printenv confirma no PID rodando)
> - `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true` ✅
> - Ação #2 (503→JSON-RPC): **[Aplicada | Pulada por enquanto]**
> - Sticky session no upstream: **[ip_hash ativo | cookie ativo | N/A 1 réplica]**
> - `X-Hub-Instance-Id` em 5 requests consecutivas: estável (`<uuid>`)
>
> Pode flipar `AGENT_BRIDGE_TRANSPORT=socket` no `.env` do app
> e rodar smoke test.

A equipe Flutter então:

1. Edita `assets/env/default.env` (3 linhas — `transport=socket`,
   `relay=true`, `presence_listener=true`).
2. `flutter clean && flutter run` para rebuildar o asset bundle.
3. Confirma `Bootstrap: agent bridge transport resolved
   transport=socket` na primeira linha do log.
4. Confirma `ConsumerSocketConnected` em vez de
   `ConsumerSocketUnauthorized`.
5. Promove para builds de prod (release Beta / canary primeiro,
   depois geral).

Caminho de rollback se algo der errado: reverter as 3 linhas do
`.env` do app + redeploy. Drena no próximo app resume sem mexer
em nada do servidor.

---

## Estado do app (lado Flutter) — para sua tranquilidade

Independentemente das 3 ações acima, o cliente **não trava**.
Foram entregues nas últimas commits (`4caa5c9`, `05414c4`):

- **Detecção fina**: `Role 'X' not allowed` agora gera
  `SocketDispatchNamespaceForbidden` (não mais `Unauthorized`
  genérico) e a mensagem ao usuário diz "perfil não autorizado,
  contate o administrador" em vez de "sessão expirou".
- **Fallback REST automático**: ao detectar falha permanente do
  socket, o cliente faz **latch** para REST pelo resto da sessão.
  Tanto o `agents:command` legado quanto o `relay:rpc.request`
  são cobertos. Falhas transientes (timeout / disconnect / app:error)
  continuam respeitando o backoff + Retry-After do socket.

Ou seja: se você demorar para aplicar as 3 ações, o app continua
funcional via REST (com a perda de performance e push em tempo real,
mas sem UX quebrada).
