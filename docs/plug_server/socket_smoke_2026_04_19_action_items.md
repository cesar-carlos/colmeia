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

## Auditoria ao repo `plug_server` (docs + `env.ts`) — 2026

Leitura cruzada com `D:\Developer\plug_database\plug_server` (código e
`docs/`). Isto **não substitui** verificar o processo em produção, mas
esclarece o que é bug de deploy vs desvio do cliente Colmeia:

| Tópico | O que o upstream diz hoje | Implicação para produção |
| ------ | ------------------------- | ------------------------- |
| `SOCKET_CONSUMER_ROLES` | Em `src/shared/config/env.ts`, o default Zod é a string **`user,admin,client`** (parseada para lista). `docs/api_rest_bridge.md` repete o mesmo default. | Se o log ainda mostra `Role 'client' is not allowed`, o PID em produção quase de certeza tem **`SOCKET_CONSUMER_ROLES` definida explicitamente** sem `client` (override no `.env` / painel / compose), **ou** um artefacto antigo — **não** é o default do código atual. Remover a env (reiniciar) ou corrigir o valor + restart. |
| Agente offline + REST | Tabela *Erros HTTP* em `docs/api_rest_bridge.md`: **`200`** com envelope JSON-RPC `error.code: -32000` / `agent_offline` quando o `agentId` está **conhecido em memória** no processo, não há socket em `/agents`, e o pedido tem **`id` correlacionável**; `503` cobre overload, disconnect a meio de request pendente, notification-only (`id: null`), etc. | O smoke com `503` em `rpc.discover` pode ser **compatível com a spec** se o corpo omitir `id` ou o hub não tiver o agente “em memória” nesse PID; se o pedido cumprir os pré-requisitos da tabela e ainda vier `503`, trata-se de **desalinhamento deploy ↔ doc** (abrir issue no `plug_server`). |
| Handshake `connection:ready` | `docs/socket_relay_protocol.md`: contrato padrão é **`PayloadFrame`**; modo legado só via `SOCKET_CONNECTION_READY_COMPAT_MODE`. | Colmeia já decodifica `PayloadFrame` primeiro e tolera JSON legado — alinhado à doc. |
| Relay + legado | `docs/socket_client_sdk.md` + `socket_relay_protocol.md`: `/consumers` com `relay:*` e `agents:command`, paridade com `POST /api/v1/agents/commands`. | Colmeia usa o mesmo namespace e os mesmos eventos; não há “socket errado” no sentido de contrato. |

---

## TL;DR — Tabela de ações

| # | Severidade | Ação | Onde | Tempo |
| - | ---------- | ---- | ---- | ----- |
| 1 | 🔴 Bloqueante | Garantir `client` em `SOCKET_CONSUMER_ROLES` **ou** remover override errado (default do código = `user,admin,client`) + restart | `.env` / orquestrador + PID | 5 min |
| 2 | 🟡 Recomendada | Confirmar que REST / bridge em produção cumpre `docs/api_rest_bridge.md` para offline (`200` + `-32000` quando aplicável); corrigir só se o deploy divergir | `agents.routes.ts` / bridge + smoke `curl` | 30-60 min |
| 3 | 🟢 Verificação | Confirmar `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true` (ou ausente = default `true` no schema) | `.env` ativo do `plug_server` | 2 min |

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

### Causa raiz (confirmada no código — não é bug do app)

1. **Servidor (`plug_server`)** — `src/presentation/socket/auth/socket_namespace_auth.middleware.ts`:
   - O token vem de `socket.handshake.auth.token` ou do header `Authorization: Bearer …` (`getToken`).
   - `verifyAccessToken` corre **sem erro** (senão verias `Unauthorized`, não esta mensagem).
   - A role é `resolveRole(user)` → string do claim JWT `role` (para contas client, **`client`**).
   - A mensagem exacta `Role 'client' is not allowed to connect to /consumers` só é emitida quando
     **`!env.socketConsumerRoles.includes(role)`** (linhas 124–126), ou seja: o **array carregado no
     processo Node** não contém o literal **`client`**.
   - O ramo *anterior* (linhas 119–121) rejeitaria se a role estivesse em **`SOCKET_AGENT_ROLES`**
     (“cannot connect”) — não é o teu caso.

2. **Cliente (`colmeia`)** — `lib/core/socket/socket_io_client_factory.dart` envia o mesmo access
   token da sessão em `auth: { token: accessToken }`, alinhado com o que o middleware lê. O log
   `Bootstrap: … transport=socket` confirma intenção de usar socket; o log `namespace forbidden`
   confirma que o **hub** recusou a role, não que o token faltou ou era inválido.

**Conclusão para correcção:** o `plug_server` **em execução** no host público tem `socketConsumerRoles`
sem `client` — quase sempre por **`SOCKET_CONSUMER_ROLES` definida no ambiente** com valor antigo
(`user,admin` apenas), typo (`clients`), ou deploy que **não** aplica o default do `env.ts` porque a
variável está presente com valor incompleto. **Corrigir env + restart** (ou remover a variável para
herdar o default `user,admin,client` do schema). Não há alteração necessária no Flutter para este
erro específico.

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

**Resultado esperado (explícito no processo):**

```
SOCKET_CONSUMER_ROLES=user,admin,client
```

**Interpretação do `grep`:**

- Valor **sem** `client` (ex.: só `user,admin`) → corrigir para incluir
  `client` e **restart** (é a causa típica do erro visto no smoke).
- Variável **ausente** no `printenv` → o Node pode estar a usar só o
  **default do Zod** em `env.ts` (`user,admin,client`). Nesse caso o
  handshake **não** deveria rejeitar `client`; se ainda rejeita, há
  outro ramo (build antigo, segundo processo, middleware fork) —
  investigar versão deployada e **um único** PID do `plug_server`.

Após corrigir o `.env` (ou remover um override que exclua `client`),
**sempre** reiniciar o processo para o Zod voltar a ler `process.env`:

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

## Ação #2 — Offline: `503` vs `200` + JSON-RPC `-32000` 🟡

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

A documentação canónica atual (`plug_server/docs/api_rest_bridge.md`,
tabela *Erros HTTP*) já distingue:

- **`503`** — timeout, overload, disconnect **a meio** de request
  pendente, notification-only (`id: null` em todos os itens), etc.
- **`200`** com `response` JSON-RPC em erro — inclui **`agent_offline`**
  (`-32000`) quando o `agentId` está **conhecido em memória** neste
  processo (tipicamente após `agent:register`), não há socket ativo
  em `/agents`, e o pedido tem **`id` correlacionável**.

Ou seja: o `503` visto no smoke **pode** estar correto para alguns
ramos da tabela; para validar se o deploy está **desalinhado da doc**,
repetir o teste com um body que cumpra explicitamente os pré-requisitos
do caso `200` + `-32000` (ver critério abaixo). Se mesmo assim vier
`503`, aí sim é trabalho de código/deploy no `plug_server`.

Para uma request **nova** que caiba no caso “agente catalogado offline
com `id`”, o envelope esperado é:

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

1. Escolher um `agentId` que **já tenha feito** `agent:register` neste
   **mesmo** processo `plug_server` (e esteja offline agora).
2. `POST /api/v1/agents/commands` com Bearer do client, body alinhado ao
   OpenAPI, e o bloco `command` JSON-RPC com **`id` string não vazia**
   (não usar notification `id: null` neste teste).
3. Esperado pela doc: **`HTTP/200`** e `error.code = -32000` /
   `agent_offline` no envelope de resposta.

Se o passo 3 ainda devolver **`503`**, tratar como bug de implementação
ou de **afinidade multi-réplica** (o agente estava “vivo” noutro pod) —
correlacionar com `X-Hub-Instance-Id` e sticky session
(`docs/nginx_production.md`).

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
Foram entregues commits recentes na `main` (entre outros
`4caa5c9`, `05414c4`, `06332c8`):

- **Detecção fina**: `Role 'X' not allowed` agora gera
  `SocketDispatchNamespaceForbidden` (não mais `Unauthorized`
  genérico) e a mensagem ao usuário diz "perfil não autorizado,
  contate o administrador" em vez de "sessão expirou".
- **Fallback REST automático**: ao detectar falha permanente do
  socket, o cliente faz **latch** para REST pelo resto da sessão.
  Tanto o `agents:command` legado quanto o `relay:rpc.request`
  são cobertos. Falhas transientes (timeout / disconnect / app:error)
  continuam respeitando o backoff + Retry-After do socket.
- **Overview**: banner dedicado **"Agentes offline no momento"** quando
  o hub marca agentes com token como desconectados na fase de planeamento
  SQL — separado do banner "sem token no dispositivo".

Ou seja: se você demorar para aplicar as 3 ações, o app continua
funcional via REST (com a perda de performance e push em tempo real,
mas sem UX quebrada).
