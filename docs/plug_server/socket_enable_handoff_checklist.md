# Checklist de Handoff — Habilitar Socket para o Colmeia

> **Para quem**: equipe responsável pela infra / deploy do
> `plug_server` (`https://plug-server.se7esistemassinop.com.br`)
> e do nginx upstream.
>
> **Objetivo**: deixar o ambiente pronto para o cliente Colmeia
> Flutter ligar `AGENT_BRIDGE_TRANSPORT=socket` em produção.
>
> **Tempo estimado**: 30–60 min (sem contar reload de nginx).
>
> **Status do lado Flutter** (este repo): 100 % implementado e
> testado (1.070+ unit tests verdes). Esperando só este checklist.
>
> **Documento companheiro**: `docs/plug_server/socket_channel_server_setup.md`
> (referência técnica detalhada do hub).

---

## TL;DR — o que precisa ser feito

| # | Onde | O quê | Tipo |
| - | ---- | ----- | ---- |
| 1 | nginx upstream | **Sticky session** por `socket.io` (cookie ou `ip_hash`). | Obrigatório (multi-réplica) |
| 2 | `.env` do `plug_server` | `SOCKET_CONSUMER_ROLES=user,admin,client` | Obrigatório |
| 3 | `.env` do `plug_server` | `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true` | Recomendado |
| 4 | `.env` do `plug_server` | (opcional) `PAYLOAD_SIGN_OUTBOUND` + `PAYLOAD_SIGNING_KEY[_ID]` | Defesa em profundidade |
| 5 | Reiniciar o `plug_server` | Para o Zod re-parsear `process.env`. | Obrigatório |
| 6 | Validação | Reportar o `X-Hub-Instance-Id` para confirmar sticky session. | Obrigatório |

> **Quando todos os 6 estiverem verdes, avise a equipe do Colmeia
> Flutter** — flipamos a flag `AGENT_BRIDGE_TRANSPORT=socket` no
> nosso `.env` e fazemos smoke test em ~15 min.

---

## Passo 1 — Sticky session no nginx

### Por quê (não pule)

O `plug_server` mantém estado **em memória, por instância**:
conversações relay, pending bridge requests, registry de agentes.
Quando o cliente abre uma `relay:conversation.start` na instância
A, o `relay:rpc.request` seguinte **precisa cair na mesma
instância** — caso contrário o hub responde `protocol_not_ready`
ou simplesmente perde a conversa.

Não há sticky → relay quebra de forma não-determinística.
Comum vc ver "funciona às vezes" em janelas curtas (sorte do
LB) e quebrar em produção sob carga.

### Se você só tem 1 réplica do `plug_server`

**Pode pular** — todo tráfego cai no mesmo lugar por definição.
Confirme isso antes de seguir (a verificação é trivial — veja
"Verificação do Passo 1" abaixo).

### Configuração

Duas opções (escolha uma):

**Opção A — `ip_hash`** (mais simples, funciona bem se cada
usuário tem IP público estável):

```nginx
upstream colmeia_hub {
    ip_hash;
    server hub-1.internal:3000;
    server hub-2.internal:3000;
    # ... outras réplicas
}

server {
    server_name plug-server.se7esistemassinop.com.br;
    # ... ssl, etc.

    location /socket.io/ {
        proxy_pass http://colmeia_hub;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }

    # Demais paths (REST etc.) podem ficar como já estão.
}
```

⚠️ `ip_hash` distribui mal quando muitos usuários compartilham
o mesmo IP público (NAT corporativo, mobile carrier-grade NAT).
Para mobile prefira a Opção B.

**Opção B — Cookie de afinidade** (preferida para mobile / NAT):

```nginx
upstream colmeia_hub {
    sticky cookie hub_node expires=1h domain=plug-server.se7esistemassinop.com.br path=/;
    server hub-1.internal:3000;
    server hub-2.internal:3000;
    # ... outras réplicas
}
```

Requer o módulo `nginx-sticky-module-ng` ou nginx Plus.
A directive `sticky cookie` cria um cookie no primeiro request e
roteia futuras conexões pra mesma replica enquanto o cookie
existir.

### Verificação do Passo 1

A app Colmeia já loga o header `X-Hub-Instance-Id` em toda
resposta REST (commit interno desta sprint). Para verificar:

```bash
# A partir de qualquer máquina autenticada (substitua o token):
for i in 1 2 3 4 5; do
  curl -sI \
    -H "Authorization: Bearer SEU_TOKEN" \
    https://plug-server.se7esistemassinop.com.br/api/v1/client-auth/me \
    | grep -i x-hub-instance-id
done
```

**Resultado esperado:**
- Se há **só 1 réplica**: o mesmo valor sempre. Sticky N/A. ✅
- Se há **multi-réplica + sticky funcionando**: o mesmo valor sempre
  para o mesmo cliente. ✅
- Se há **multi-réplica sem sticky**: valores variando entre
  chamadas consecutivas. ❌ — **NÃO ligue socket** até consertar.

> Sem o header de resposta? Significa que o `plug_server` não está
> emitindo `X-Hub-Instance-Id` (versão antiga). Atualize o
> `plug_server` antes de seguir.

---

## Passo 2 — `SOCKET_CONSUMER_ROLES` inclui `client`

**No `.env` do deploy do `plug_server`** (não do Colmeia):

```bash
SOCKET_CONSUMER_ROLES=user,admin,client
```

### Por quê

O JWT que o app Colmeia usa carrega `role: client`. Sem essa env
o handshake do `/consumers` rejeita o token com 401 (e o app cai
em estado `ConsumerSocketUnauthorized`).

### Verificação do Passo 2

Olhe o `.env` ou o output de `printenv | grep SOCKET_CONSUMER_ROLES`
no host do `plug_server`. Tem que aparecer literalmente:

```
SOCKET_CONSUMER_ROLES=user,admin,client
```

(Vírgulas sem espaços, sem aspas, sem `[ ]`.)

---

## Passo 3 — Push de catálogo (recomendado)

**No `.env` do deploy do `plug_server`**:

```bash
SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true
```

### Por quê

Quando o catálogo de um agente muda (nome, status, profile_version,
etc.), o hub broadcasta `client:agent.profile.updated` para todos
os consumers que têm acesso a esse agente. O Colmeia tem um
listener pronto que consome esse evento e atualiza o estado em
tempo real.

**Sem essa env, o app cai em modo polling** — funciona, mas:
- Latência maior para detectar revogações de token / renomeação.
- Mais carga REST em `loadApprovedAgents`.
- A UX dos cards in-card de "token revogado" (commit `24ea32f`)
  não dispara em tempo real.

### Verificação do Passo 3

Idem Passo 2 — olhe o `.env`. Em runtime, o app Colmeia loga
quando recebe um evento `client:agent.profile.updated`; vai dar
para confirmar via Sentry depois do go-live.

---

## Passo 4 — HMAC outbound (defesa em profundidade, opcional)

**Pular se** o ambiente é interno-only e o TLS é confiável (caso
mais comum). **Aplicar se** o ambiente tem MITM intermediário
plausível ou requisitos de compliance que exigem assinatura de
mensagens.

```bash
# No .env do plug_server
PAYLOAD_SIGN_OUTBOUND=true
PAYLOAD_SIGNING_KEY=<gere com `openssl rand -base64 32`>
PAYLOAD_SIGNING_KEY_ID=hub-2026-q2  # opcional, para rotação de chaves
```

Quando ligar isso, **avise** a equipe Colmeia para também
preencher no `.env` do app:

```bash
SOCKET_PAYLOAD_SIGNING_KEY=<mesma_chave_byte_a_byte>
SOCKET_PAYLOAD_SIGNING_KEY_ID=hub-2026-q2  # se aplicável
# Opcional, modo estrito (rejeita inbound sem assinatura):
SOCKET_PAYLOAD_REQUIRE_SIGNATURE=true
```

⚠️ A chave precisa ser **byte-for-byte idêntica** nos dois lados
(a app trata como UTF-8 ao gerar o HMAC). Se vc gerar com
`openssl rand -base64 32`, copie o resultado **inteiro** com o `=`
final, sem aspas.

---

## Passo 5 — Reiniciar o `plug_server`

```bash
# pm2:
pm2 restart plug_server

# docker-compose:
docker-compose restart plug_server

# systemd:
systemctl restart plug_server
```

O Zod do `plug_server` re-parseia `process.env` no boot —
mudanças no `.env` não pegam até o restart.

### Verificação do Passo 5

```bash
# Confirme que o processo subiu sem erro de validação:
pm2 logs plug_server --lines 50    # ou o equivalente do seu deploy
```

Procure por:
- `Server listening on :3000` (ou similar).
- **Ausência** de `ZodError` no boot — se aparecer, alguma env
  está mal formatada.

---

## Passo 6 — Validação final + handoff

Antes de avisar a equipe Colmeia, confirme:

- [ ] Passo 1 verificado — `X-Hub-Instance-Id` consistente em 5+
      chamadas REST consecutivas.
- [ ] Passo 2 — `SOCKET_CONSUMER_ROLES` contém `client` no `.env`
      ativo do processo (cheque com `printenv` no host, não só no
      arquivo).
- [ ] Passo 3 — `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true`
      ativo (mesma verificação).
- [ ] Passo 4 — só se aplicar; chave compartilhada com a equipe
      Colmeia por canal seguro (não git, não Slack público).
- [ ] Passo 5 — `plug_server` rodando sem ZodError.

### Mensagem para a equipe Colmeia

Mande algo como:

> Pronto pro go-live socket. Configurado:
>
> - Sticky session: **[ip_hash | cookie | N/A 1 réplica]**
> - `SOCKET_CONSUMER_ROLES=user,admin,client` ✅
> - `SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true` ✅
> - HMAC outbound: **[habilitado | não]** — chave compartilhada via [canal]
>
> `X-Hub-Instance-Id` em 5 chamadas consecutivas: `[uuid-A] x5` (ou
> distribuição se multi-réplica).

A equipe Colmeia então:

1. Edita `.env` local com `AGENT_BRIDGE_TRANSPORT=socket`,
   `SOCKET_RELAY_ENABLED=true`, `SOCKET_PRESENCE_LISTENER_ENABLED=true`.
2. Builda QA e roda os 6 passos do smoke test em
   `docs/Features/socket/socket_production_rollout_runbook.md` § 3
   (~5 min).
3. Promove pra produção em rolling release.

---

## Rollback

Se algo der errado depois do flip no Colmeia:

1. **Lado Colmeia**: reverter o `.env` para `AGENT_BRIDGE_TRANSPORT=rest`,
   redeploy. Drena automaticamente no próximo app resume / re-login.
2. **Lado Servidor**: nenhuma mudança necessária — REST continua
   funcionando paralelo. As envs do Passo 2/3/4 não quebram REST.

Por isso é seguro deixar as envs do servidor ligadas mesmo que o
Colmeia volte pra REST temporariamente. Não há custo operacional
em manter `SOCKET_*` habilitado quando ninguém está conectando.

---

## FAQ rápido

**P: Posso testar apenas alguns usuários antes de promover?**
R: Sim — o flip é por build do app, então uma release Beta /
canary com `AGENT_BRIDGE_TRANSPORT=socket` para um % dos
usuários funciona. Não precisa de feature flag server-side.

**P: O `plug_server` precisa ser atualizado?**
R: Não — todo o protocolo socket descrito aqui já está implantado
no servidor (referência: `plug_server/docs/socket_relay_protocol.md`).
Apenas configuração de ambiente + sticky session no upstream.

**P: Quanto tempo o cliente fica conectado?**
R: Conexão dura enquanto a app está em foreground. No background
(`AppLifecycleState.paused`) ele desconecta; ao voltar
(`resumed`) reconecta — economia de bateria mobile, sem perda
funcional. O hub não precisa configurar nada para isso.

**P: O que acontece se o hub estiver overload?**
R: O hub envia `app:error` com `retryAfterMs` (já implementado).
A app respeita o hint e backa off — comportamento correto
implementado no commit `853336b` desta sprint.

**P: E se a sticky session quebrar no meio do uso?**
R: O cliente vê `protocol_not_ready` na próxima request, o gate
de retry arma com cool-down e a UI mostra "Tente em Ns". Não
crasha. Mas a UX degrada — daí a importância do Passo 1.

---

## Documentos relacionados

- **Servidor (referência técnica detalhada)**:
  `docs/plug_server/socket_channel_server_setup.md`
- **Cliente (runbook de produção, todos os modos)**:
  `docs/Features/socket/socket_production_rollout_runbook.md`
- **Protocolo (fonte da verdade)**:
  `plug_server/docs/socket_relay_protocol.md` (no repo do servidor).
