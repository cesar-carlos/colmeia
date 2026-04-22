# `plug_server` — guia de ajustes operacionais

Esta pasta documenta tudo que o **time de servidor (`plug_server`)** precisa ajustar
ou conferir para que features do app `colmeia` funcionem corretamente em
produção. Todo o conteúdo aqui é **operacional** (env, deploy, validação) —
não há mudança de código de servidor pendente.

## Índice

| Documento                                                                              | Escopo                                                                                                                                                                        | Quando ler                                                                     |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [`socket_smoke_2026_04_19_action_items.md`](./socket_smoke_2026_04_19_action_items.md) | **Achados do smoke test de 2026-04-19** + **auditoria cruzada** ao `plug_server` (`env.ts` + `docs/api_rest_bridge.md`): 3 ações, verificação de PID, critérios de aceitação. | **Agora** — para resolver os bloqueios atuais e finalizar o rollout do socket. |

> **Histórico**: documentos genéricos anteriores
> (`socket_channel_server_setup.md`, `socket_enable_handoff_checklist.md`)
> foram removidos em favor do snapshot focado acima. Histórico
> completo no `git log` se precisar consultar a referência técnica
> antiga (commits `36cdaf1` e `891ee4f`).

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
