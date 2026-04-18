# Canal Socket `/consumers` — ajustes obrigatórios e recomendados no `plug_server`

> **Quando aplicar**: antes de ligar `AGENT_BRIDGE_TRANSPORT=socket` em qualquer
> build do `colmeia` (interna, homolog ou prod).
>
> **Estado atual do código de servidor**: 100% pronto. Todos os handlers
> (`agents:command`, `relay:rpc.request`, `relay:rpc.stream.pull`,
> `relay:conversation.start`, `client:agent.profile.updated`, etc.) já estão
> implantados em `plug_server`. **Não** existe mudança de código pendente —
> apenas configuração de ambiente.
>
> **Estado atual do código de cliente** (`colmeia`): 100% pronto. Todo o stack
> Socket + Relay + Presença + boot audit foi entregue (PR-A → PR-M, ver
> `docs/Features/socket/socket_consumer_channel_plan.md`). Por padrão o app
> usa REST (`AGENT_BRIDGE_TRANSPORT=rest`); ligar é uma mudança trivial de
> dart-define ou env do client.

---

## 0. TL;DR — o que precisa ser feito

| # | Tipo | Ajuste | Onde |
| - | ---- | ------ | ---- |
| 1 | **Obrigatório** | Garantir que `SOCKET_CONSUMER_ROLES` inclui `client` (default do código já inclui; só precisa intervir se houver override no deploy). | `.env` do deploy do `plug_server` |
| 2 | **Operacional** | Reiniciar o `plug_server` para o Zod re-parsear `process.env`. | Host do deploy |
| 3 | **Validação** | Rodar os 3 smokes e2e do `colmeia` e confirmar verde. | Workstation / CI |
| 4 | Recomendado | Conferir os defaults dos itens da §3 (já estão corretos no código; intervir só se o deploy tiver override). | `.env` do deploy |

> O smoke e2e do `colmeia` rodando contra
> `https://plug-server.se7esistemassinop.com.br` recebeu
> `Role 'client' is not allowed to connect to /consumers` — ou seja, o deploy
> de produção tem um override que **não inclui** `client`. Esse é o único
> bloqueador conhecido. Resolvendo o item 1 + 2, todo o resto do canal já
> funciona com os defaults atuais.

---

## 1. Por que isso é necessário

O `colmeia` autentica via REST (`/client-auth/login`) e recebe um JWT cuja
claim `role` é `"client"` (regra de negócio do
`docs/client_agent_business_rules.md`). Esse mesmo JWT é apresentado no
handshake do Socket.IO para o namespace `/consumers`.

O middleware do servidor:

```typescript
// src/presentation/socket/auth/socket_namespace_auth.middleware.ts
if (env.socketAgentRoles.includes(role)) {
  next(forbidden(`Role '${role}' cannot connect to /consumers`));
  return;
}

if (!env.socketConsumerRoles.includes(role)) {
  next(forbidden(`Role '${role}' is not allowed to connect to /consumers`));
  return;
}
```

E o schema Zod em `src/shared/config/env.ts`:

```typescript
SOCKET_CONSUMER_ROLES: z
  .string()
  .default("user,admin,client")
  .transform(v => v.split(",").map(s => s.trim()).filter(Boolean)),
```

⇒ **Default do código já inclui `client`**. O problema só aparece quando o
deploy define um valor que **não** inclui `client` (ex.: legado
`SOCKET_CONSUMER_ROLES=user,admin`).

---

## 2. Ajuste obrigatório — `SOCKET_CONSUMER_ROLES`

### 2.1 Antes / depois

| Antes (deploy atual) | Depois |
| -------------------- | ------ |
| Env não definida **ou** valor que inclua `client`. | Sem mudança. |
| `SOCKET_CONSUMER_ROLES=user,admin` (ou similar sem `client`). | `SOCKET_CONSUMER_ROLES=user,admin,client` |

### 2.2 Como aplicar

Há 3 caminhos válidos — escolher **um**:

1. **Setar explicitamente** (recomendado para ambientes que já têm a env):

   ```bash
   SOCKET_CONSUMER_ROLES=user,admin,client
   ```

2. **Remover a env** (deixa o default do schema entrar):

   ```bash
   # remover a linha SOCKET_CONSUMER_ROLES=... do .env do deploy
   ```

3. **Adicionar role específica do tenant** (se um cliente legado usar role
   diferente, p. ex. `consumer`):

   ```bash
   SOCKET_CONSUMER_ROLES=user,admin,client,consumer
   ```

### 2.3 Procedimento

1. Editar `.env` no host do `plug_server` (ou dashboard de env do orquestrador
   — Docker Compose, Kubernetes ConfigMap/Secret, Render, Railway, etc.).
2. **Reiniciar o processo** do `plug_server`. Zod só re-parseia `process.env`
   na inicialização — não há hot-reload de env.
   - Docker Compose: `docker compose restart plug_server`
   - PM2: `pm2 restart plug_server`
   - Systemd: `systemctl restart plug_server`
   - Kubernetes: `kubectl rollout restart deployment/plug-server`
3. Conferir nos logs de boot que a env foi parseada sem erro Zod.

### 2.4 Critério de aceitação

- Cliente com role `client` consegue **conectar** a `/consumers` (não recebe
  mais `forbidden(403)` com `Role 'client' is not allowed to connect to /consumers`).
- Smoke e2e `socket_consumer_smoke_e2e_test.dart` (descrito na §6) passa
  verde.

### 2.5 Riscos / efeitos colaterais

- **Negativo**: nenhum conhecido. Adicionar `client` ao allowlist não afrouxa
  segurança porque o JWT continua sendo validado (assinatura, expiração,
  conta ativa via `ensureJwtUserAccountActive`).
- **Positivo**: builds antigas do `colmeia` (REST-only) continuam funcionando
  inalteradas — REST e Socket coexistem no mesmo deploy.

---

## 3. Ajustes recomendados — conferir / manter defaults

Estes são os defaults do código que o cliente `colmeia` **assume** estarem
ativos. Se o deploy atual tem override divergente, ajustar conforme a tabela.

### 3.1 Autenticação e roles

| Env | Valor esperado pelo `colmeia` | Default do código | Notas |
| --- | ----------------------------- | ----------------- | ----- |
| `SOCKET_AUTH_REQUIRED` | `true` | `true` | Sem isso, qualquer socket sem token consegue conectar (apenas para dev local). |
| `SOCKET_CONSUMER_ROLES` | `user,admin,client` (mínimo: contém `client`) | `user,admin,client` | **Item §2 — obrigatório**. |
| `SOCKET_AGENT_ROLES` | `agent` (default) | `agent` | Não pode colidir com `SOCKET_CONSUMER_ROLES`. |

### 3.2 Engine.IO / Socket.IO transport

| Env | Valor esperado | Default do código | Notas |
| --- | -------------- | ----------------- | ----- |
| `SOCKET_IO_TRANSPORTS` | `websocket,polling` (ou `websocket` em prod) | Em prod: `websocket`; senão: `websocket,polling`. | Cliente Flutter usa Socket.IO 3.x (`socket_io_client: ^3.1.4`); ambos transports são suportados. Se o deploy estiver atrás de proxy/CDN que **bloqueia** WebSocket, manter `websocket,polling` para fallback. |
| `SOCKET_IO_MAX_HTTP_BUFFER_BYTES` | `10485760` (10 MiB) | `10485760` | Espelha o teto do `PayloadFrame` no cliente (ver `lib/core/socket/payload_frame.dart`). Reduzir abaixo disso pode rejeitar respostas grandes do bridge. |
| `SOCKET_IO_PER_MESSAGE_DEFLATE` | `false` | `false` | `PayloadFrame` já comprime via gzip na camada de aplicação — ligar `permessage-deflate` redundantemente custa CPU sem ganho. |
| `SOCKET_IO_HTTP_COMPRESSION` | (default) | Em prod: `false`; senão: `true`. | Aplica-se ao polling. Manter o default por ambiente. |
| `SOCKET_IO_PING_INTERVAL_MS` | (default `25000`) | `25000` (Engine.IO default) | Se setar custom, manter compatível com `pingTimeout`. Cliente não tem expectativa rígida — só precisa que o server-side ping mantenha a conexão viva. |
| `SOCKET_IO_PING_TIMEOUT_MS` | (default `20000`) | `20000` | Idem. |
| `SOCKET_IO_SERVE_CLIENT` | `false` | `false` | Cliente Flutter **não** consome o JS embarcado do servidor. Manter `false` para reduzir superfície. |

### 3.3 PayloadFrame

| Env | Valor esperado | Default do código | Notas |
| --- | -------------- | ----------------- | ----- |
| `SOCKET_CONNECTION_READY_COMPAT_MODE` | `payload_frame` | `payload_frame` | Cliente suporta `compat` (PR-K do plano), aceita JSON puro **ou** PayloadFrame em `connection:ready`. Não há ação necessária aqui. |
| `PAYLOAD_FRAME_AUTO_GZIP_MIN_SAVINGS_BYTES` | `64` | `64` | Mínimo de bytes economizados para o servidor escolher gzip no envio. |
| `PAYLOAD_FRAME_ASYNC_GZIP_MIN_UTF8_BYTES` | `131072` (128 KiB) | `131072` | Acima disso o servidor faz gzip async (worker). |
| `PAYLOAD_FRAME_ASYNC_GUNZIP_MIN_COMPRESSED_BYTES` | `65536` (64 KiB) | `65536` | Idem para descompressão. |
| `PAYLOAD_FRAME_MAX_GZIP_INPUT_BYTES` | `524288` (512 KiB) ou maior | `524288` | Teto do tamanho da entrada gzip antes de o servidor recusar. Cliente respeita o mesmo limite (ver `payload_frame_codec.dart`). |

### 3.4 Relay (`relay:*`) — opt-in no cliente, **sempre disponível** no server

> O cliente liga relay com `--dart-define=SOCKET_RELAY_ENABLED=true`. Os defaults
> do servidor abaixo são generosos para a maioria dos cenários; ajustar só se
> houver pressão de carga conhecida.

| Env | Default do código | Quando aumentar / reduzir |
| --- | ----------------- | ------------------------- |
| `SOCKET_RELAY_REQUEST_TIMEOUT_MS` | `15000` | Se queries longas forem rotina, alinhar com o `SOCKET_RELAY_REQUEST_TIMEOUT_MS` do client (default lá é `30000`). |
| `SOCKET_RELAY_CONVERSATION_IDLE_TIMEOUT_MS` | `300000` (5 min) | Cliente fecha conversation rapidamente (`relay_conversation_end_timeout_ms` default `5000`). Manter. |
| `SOCKET_RELAY_CONVERSATION_SWEEP_INTERVAL_MS` | `60000` | Período do GC. Manter. |
| `SOCKET_RELAY_MAX_CONVERSATIONS` | `5000` | Capacidade total. Aumentar só com observação de saturação. |
| `SOCKET_RELAY_MAX_CONVERSATIONS_PER_CONSUMER` | `20` | **Importante**: cliente abre 1 conversation por agente — se houver tenants com >20 agentes simultâneos, aumentar. |
| `SOCKET_RELAY_MAX_PENDING_REQUESTS_PER_CONVERSATION` | `32` | Cliente respeita `SOCKET_MAX_INFLIGHT_PER_AGENT=8` (PR-F), bem abaixo do limite. Manter. |
| `SOCKET_RELAY_MAX_PENDING_REQUESTS_PER_CONSUMER` | `128` | Idem. |
| `SOCKET_RELAY_MAX_BUFFERED_CHUNKS_PER_REQUEST` | `256` | Streaming PR-L+ p2 do cliente: `SOCKET_RELAY_STREAM_INITIAL_WINDOW=32` + `SOCKET_RELAY_STREAM_REFILL_THRESHOLD=16`. Buffer do servidor cobre folga. Manter. |
| `SOCKET_RELAY_IDEMPOTENCY_TTL_MS` | `300000` | Janela de dedup do servidor. Cliente ainda **não** explora idempotência via `meta` (P3 / Fase 3 do plano). Manter. |
| `SOCKET_RELAY_RATE_LIMIT_MAX_REQUESTS` | `64` por janela de `10s` | Cliente respeita o gate de inflight (8/agente) + coalescing. Default folgado. |
| `SOCKET_RELAY_RATE_LIMIT_MAX_CONVERSATION_STARTS` | `8` por janela de `10s` | Cliente abre 1 conversation por agente, sob demanda. Default folgado. |
| `SOCKET_RELAY_OUTBOUND_OVERLOAD_BACKLOG` | `200` | Shedding por backlog. `0` desativa. Manter para proteção. |
| `SOCKET_RELAY_OUTBOUND_OVERLOAD_P95_MS` | `250` | Shedding por latência da fila. Manter. |
| `SOCKET_RELAY_CIRCUIT_FAILURE_THRESHOLD` | `5` | Abre o circuito após 5 falhas seguidas. Cliente detecta como `RelayDispatchException` e propaga normalmente. Manter. |
| `SOCKET_RELAY_CIRCUIT_OPEN_MS` | `30000` | Tempo aberto. Manter. |

### 3.5 REST bridge (cobertura paralela ao Socket)

> Mesmo com Socket ligado, o cliente continua usando REST para login (`/client-auth/*`)
> e pode roteado consultas por REST quando `AGENT_BRIDGE_TRANSPORT=rest` ou
> `useRelay==false`. O REST bridge **não muda** com a ativação do canal Socket.

| Env | Default | Notas |
| --- | ------- | ----- |
| `SOCKET_REST_AGENT_MAX_INFLIGHT` | `32` | Limite REST↔agent. Independente do Socket. |
| `SOCKET_REST_STREAM_PULL_WINDOW_SIZE` | `256` | Janela do REST quando o agente faz streaming. Independente do Socket. |
| `SOCKET_REST_SQL_STREAM_MATERIALIZE_MAX_ROWS` | `1000000` | Teto de linhas materializadas em REST. Cliente respeita `max_rows` por request. |

---

## 4. O que **não** precisa mudar

- **Schemas REST de auth** (`/client-auth/login`, `/client-auth/refresh`,
  `/client-auth/logout`): inalterados. Cliente continua autenticando via REST.
- **Handlers `agents:*`, `relay:*`, `client:*`**: já implantados, sem mudança
  pendente.
- **CORS / origin allowlist**: não impacta o app mobile (Flutter Android/iOS
  não respeita CORS no nível de socket); só impacta builds web. Se for fazer
  build web do `colmeia`, conferir `CORS_ALLOWED_ORIGINS` (ou equivalente do
  deploy) inclui o origin do app web.
- **Schema do banco**: nenhum DDL/migration novo é necessário pelo lado do
  Socket.

---

## 5. Procedimento operacional resumido

### 5.1 Pré-flight check

```bash
# No host do plug_server
echo $SOCKET_CONSUMER_ROLES
# Esperado: "user,admin,client" OU vazio (default do schema entra)
```

### 5.2 Aplicar ajuste

```bash
# Editar .env (ou ConfigMap/Secret/dashboard do orquestrador)
# Adicionar/atualizar:
SOCKET_CONSUMER_ROLES=user,admin,client

# Reiniciar
systemctl restart plug_server   # ou pm2 restart, docker compose restart, etc.
```

### 5.3 Conferir nos logs de boot

Procurar por:

- ✅ `Server listening on ...` — boot OK.
- ❌ `ZodError` em `SOCKET_CONSUMER_ROLES` — typo na env.
- ❌ `Cannot find module ...` ou crash genérico — não relacionado a esta mudança.

### 5.4 Healthcheck

```bash
curl -i https://plug-server.se7esistemassinop.com.br/api/v1/health
# Esperado: HTTP/1.1 200 OK
```

---

## 6. Validação do cliente — smokes e2e

> Os 3 smokes vivem em `test/integration/e2e/` no repo `colmeia`, marcados com
> a tag `e2e` (ficam fora da pipeline padrão de CI).

### 6.1 Pré-requisitos

- Conta `client` no `plug_server` ativa (mesmo deploy que recebeu o ajuste).
- Pelo menos 1 agente registrado e online (para o smoke `agents:command`).

### 6.2 Comando

```powershell
# Windows PowerShell
flutter test --tags e2e `
  --dart-define=E2E_API_BASE_URL=https://plug-server.se7esistemassinop.com.br/api/v1 `
  --dart-define=E2E_CLIENT_EMAIL=<seu-email> `
  --dart-define=E2E_CLIENT_PASSWORD=<sua-senha> `
  --dart-define=E2E_AGENT_ID=<id-de-agente-online> `
  test/integration/e2e/
```

```bash
# bash / zsh
flutter test --tags e2e \
  --dart-define=E2E_API_BASE_URL=https://plug-server.se7esistemassinop.com.br/api/v1 \
  --dart-define=E2E_CLIENT_EMAIL=<seu-email> \
  --dart-define=E2E_CLIENT_PASSWORD=<sua-senha> \
  --dart-define=E2E_AGENT_ID=<id-de-agente-online> \
  test/integration/e2e/
```

### 6.3 O que cada smoke valida

| Arquivo | Cobre |
| ------- | ----- |
| `socket_consumer_smoke_e2e_test.dart` | Login REST → handshake `/consumers` → `agents:command` `SELECT 1`. **É este que falhava com `Role 'client' not allowed`** antes do ajuste §2. |
| `socket_relay_smoke_e2e_test.dart` | `RelayCommandDispatcher.sendUnary` (canal `relay:rpc.request`). |
| `socket_presence_smoke_e2e_test.dart` | `AgentPresenceHint` gerado a partir do outcome de `agents:command` (camada 2 do PR-M). |

### 6.4 Resultado esperado

Todos os 3 verde. Se o `socket_consumer_smoke_e2e_test.dart` continuar
falhando com `Role 'client' is not allowed`, voltar à §2 — o restart do
servidor não pegou a env, ou o valor ainda não inclui `client`.

---

## 7. Rollback

Se algo der errado após o ajuste:

1. **Reverter a env**:

   ```bash
   # voltar ao valor anterior (ex.):
   SOCKET_CONSUMER_ROLES=user,admin
   # ou remover a linha
   ```

2. **Reiniciar** o `plug_server`.

3. **Cliente**: o app `colmeia` por padrão usa REST (`AGENT_BRIDGE_TRANSPORT=rest`).
   Builds com socket ligado vão receber `Role 'client' is not allowed` e
   degradar — basta o usuário voltar a uma build REST (release atual já é
   REST por default).

> O ajuste é seguro: **não há perda de dados**, **não há migration**, e o
> rollback é simples (env + restart). REST continua funcionando inalterado
> em qualquer cenário.

---

## 8. FAQ / troubleshooting

### "O smoke ainda falha com `Role 'client' is not allowed` mesmo após o ajuste"

- Confirmar que a env foi **carregada** pelo processo (`echo $SOCKET_CONSUMER_ROLES`
  dentro do container/host onde o Node está rodando).
- Confirmar que **o processo foi reiniciado** (Zod só lê `process.env` no boot).
- Verificar se o orquestrador (Docker / PM2 / k8s) tem **multi-instância** —
  todas as réplicas precisam receber a mesma env.

### "Quero rodar o app mobile contra o servidor — como?"

No `colmeia`, usar o perfil `colmeia (socket, Android tablet)` ou
`colmeia (socket + relay, Android tablet)` em `.vscode/launch.json` (ambos
passam `AGENT_BRIDGE_TRANSPORT=socket` via `--dart-define`).

### "O servidor já tinha `SOCKET_CONSUMER_ROLES` correto. Por que o smoke falhou?"

Possibilidades:

- O `client` autenticou com role diferente — ver o JWT decodificado no
  cliente (`AuthSession.accessToken`) e conferir o claim `role`.
- O middleware está rejeitando por `SOCKET_AGENT_ROLES` antes do consumer
  check (precedência). Ver `authenticateConsumerSocket` linha por linha.
- O deploy atrás de proxy está descartando o header `Authorization` ou o
  query `auth.token`. Conferir CDN/load balancer.

### "Posso liberar `client` apenas em homolog primeiro?"

Sim. Aplicar o ajuste só na instância de homolog, validar com smoke, depois
promover pra prod. Os perfis do `colmeia` aceitam `--dart-define=API_BASE_URL=https://homolog-...`
para apontar pra homolog.

### "Quando vai ser preciso voltar aqui?"

- Quando o cliente entregar **PR-N** (Hybrid REST↔Socket fallback) — pode
  precisar de novas envs de health-check do servidor.
- Quando entregar **P3 / Fase 3** do plano cliente (gzip async, dedup
  pós-reconexão, OTel propagation) — pode ajustar
  `PAYLOAD_FRAME_ASYNC_GZIP_MIN_UTF8_BYTES` ou adicionar headers OTel.
- Sempre que o time de servidor mudar defaults relevantes em `env.ts`.

---

## 9. Referências cruzadas

### No `colmeia`

- `docs/Features/socket/socket_consumer_channel_plan.md` — plano executivo
  completo (PR-A → PR-M, smokes e2e, auditoria de boot).
- `docs/Features/socket/consumer_socket_connection_design.md` — design da
  conexão única (handshake, reconnect, refresh).
- `docs/Features/socket/socket_command_dispatcher_design.md` — design do
  dispatcher.
- `docs/Features/socket/agent_presence_realtime_design.md` — design das 3
  camadas de presença.
- `docs/Features/socket/socket_channel_performance_review.md` — review de
  performance e estratégia de transporte.
- `lib/core/config/env_keys.dart` — todas as envs do **cliente**.
- `lib/core/socket/` — implementação do stack socket.

### No `plug_server`

- `docs/socket_relay_protocol.md` — spec do protocolo `relay:*`.
- `docs/socket_client_sdk.md` — guia para clientes (PayloadFrame, handshake).
- `docs/api_rest_bridge.md` — REST bridge (REST↔Socket inverso, do servidor
  pro agente).
- `docs/client_agent_business_rules.md` — regras de role / claim por
  namespace.
- `src/shared/config/env.ts` — schema Zod de envs (fonte de verdade).
- `.env.example` — template oficial.

---

_Última atualização: alinhado com a entrega de Fase 2 do canal Socket
(commit `ea60f9c` no `colmeia`). Atualizar este doc sempre que houver_
_mudança operacional do lado servidor que afete o cliente._
