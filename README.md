# Colmeia

App Flutter corporativo para dashboards, relatorios e consultas analiticas em contexto multi-loja e multi-perfil.

## Visao geral

O Colmeia usa uma API central como fluxo principal de integracao e foi desenhado para evoluir de forma incremental, com:

- autenticacao e controle de sessao
- permissoes por usuario e por escopo
- dashboards com integracao real inicial
- cache local leve e controlado
- manutencao de agentes do cliente por lista aprovada, solicitacoes e fila local
- preparacao para relatorios e consultas multi-agente

## Estado atual

### Ja implementado

- login, sessao e refresh automatico de token
- contexto de usuario e escopo por loja
- dashboard principal
- cache local com `Hive`
- manutencao de agentes do cliente com:
- agentes aprovados
- solicitacao manual por `agentId`
- historico de solicitacoes
- fila local de pendencias e sincronizacao

### Em evolucao

- religar relatorios na navegacao principal
- transformar agentes aprovados em fontes reais de consulta
- suportar consultas `single-source` e `multi-source race`

## Stack principal

- Flutter
- Dart
- `Provider`
- `Dio`
- `GetIt`
- `GoRouter`
- `Hive`
- `flutter_secure_storage`

## Estrutura de alto nivel

```text
lib/
  core/
  features/
  shared/
```

O projeto segue organizacao por feature e separacao em camadas, priorizando `presentation`, `application`, `domain` e `data` quando a complexidade justificar.

## Documentacao

A documentacao de analise e planejamento fica em `docs/analysis/`.

Leituras principais:

- `docs/analysis/README.md`
- `docs/analysis/analise.md`
- `docs/analysis/analise_tecnica.md`
- `docs/analysis/agentes_como_fontes_de_dados.md`
- `docs/analysis/consulta_multi_agente_para_relatorios_e_graficos.md`
- `docs/analysis/plano_evolucao_agentes_relatorios_dashboards.md`

## Ambiente de desenvolvimento

Com Flutter configurado, os comandos mais comuns sao:

```bash
flutter pub get
python tool/ci_preflight.py
flutter analyze
dart format lib test
flutter test
flutter run
```

`python tool/ci_preflight.py` espelha os gates baratos do job `analyze` do
Flutter CI (templates de env, format e sync de versao). Antes de push/release,
prefira esse comando a descobrir a falha so no GitHub.

Guias de release por plataforma: `docs/install/release_guide.md` (Windows/Android),
`docs/install/android_guide.md`, `docs/install/ios_guide.md`.

## Direcao do produto

O objetivo atual do Colmeia e consolidar uma base mobile para leitura analitica corporativa, mantendo:

- backend como fonte final de autorizacao
- REST como integracao principal
- cache leve no MVP
- agentes aprovados como futuras fontes de dados autorizadas

## Observacao

Os levantamentos iniciais originais foram consolidados em Markdown dentro de `docs/analysis/`, que agora funciona como referencia principal para contexto de negocio, arquitetura e roadmap.
