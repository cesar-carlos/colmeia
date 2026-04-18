# `plug_server` — guia de ajustes operacionais

Esta pasta documenta tudo que o **time de servidor (`plug_server`)** precisa ajustar
ou conferir para que features do app `colmeia` funcionem corretamente em
produção. Todo o conteúdo aqui é **operacional** (env, deploy, validação) —
não há mudança de código de servidor pendente.

## Índice

| Documento | Escopo | Quando ler |
| --------- | ------ | ---------- |
| [`socket_channel_server_setup.md`](./socket_channel_server_setup.md) | Canal Socket `/consumers` (PR-A → PR-M do `colmeia`): role allowlist, transports, PayloadFrame, relay, presença, validação via smoke e2e. | **Antes** de ligar `AGENT_BRIDGE_TRANSPORT=socket` em qualquer build (interna, homolog, prod). |

## Repositório do servidor

`d:\Developer\plug_database\plug_server` — referências cruzadas:

- `src/shared/config/env.ts` — schema Zod com defaults de todas as envs.
- `.env.example` — template oficial de `.env` (manter sincronizado com o schema).
- `src/presentation/socket/auth/socket_namespace_auth.middleware.ts` — gate de
  role por namespace (`/agents`, `/consumers`).
- `docs/socket_relay_protocol.md`, `docs/socket_client_sdk.md`,
  `docs/api_rest_bridge.md`, `docs/client_agent_business_rules.md` — specs
  canónicas do servidor.

## Convenção

- **Nunca** documentar segredos (DSN, tokens, senhas) aqui — só nomes de envs e
  valores não-sensíveis (defaults, allowlist de roles, transports).
- **Cada** ajuste obrigatório precisa vir com (a) o "antes/depois" explícito,
  (b) o procedimento de aplicação, (c) o critério de aceitação.
- Mudanças no servidor que afetem o `colmeia` devem ser refletidas tanto em
  `docs/Features/socket/socket_consumer_channel_plan.md` (lado cliente) quanto
  aqui (lado servidor).
