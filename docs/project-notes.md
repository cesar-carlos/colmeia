# Colmeia — notas do projeto

Caderno vivo para decisões, integrações e lembretes operacionais. As regras canônicas de código ficam em `.cursor/rules/` (ver `rules_index.mdc` e `project_specifics.mdc`).

## Visão geral

- **Stack:** Flutter (Android e iOS), Material 3, `go_router`, `provider`, `dio`, `get_it`.
- **Arquitetura:** por feature (`presentation` / `application` / `domain` / `data`); detalhes em `clean_architecture.mdc`.

## Ambiente e build

- Flags úteis via `--dart-define` (ver `lib/core/config/app_environment.dart`):
  - `API_BASE_URL` — base da API (quando aplicável).
  - `USE_FAKE_BACKEND` — backend fake para desenvolvimento (padrão atual conforme código).
  - `SENTRY_DSN` — DSN do Sentry; vazio desativa o SDK.
  - `SENTRY_DEBUG` — com DSN definido, habilita Sentry em builds **debug**.
  - `SENTRY_TRACES_SAMPLE_RATE` — taxa de traces (string, ex.: `0.2`; inválido usa fallback).

Exemplo (release):

```bash
flutter build apk --dart-define=SENTRY_DSN=https://...@...ingest.sentry.io/...
```

## Observabilidade

- **Sentry:** inicialização em `lib/core/observability/sentry_bootstrap.dart`, acoplada ao `bootstrap` da app.
- **Logging:** `lib/core/logging/app_logger.dart`.

## Segurança e dados sensíveis

- Tokens: `flutter_secure_storage` via `lib/core/storage/app_secure_storage_factory.dart`.
- Não commitar `.env` nem DSNs; `.gitignore` cobre `.env` e `.env.*` (exceto `.env.example`, se existir).

## Documentação adicional neste repositório

| Caminho          | Conteúdo (resumo)     |
| ---------------- | --------------------- |
| `docs/analysis/` | Análises em texto     |
| `docs/design/`   | Referências de design |

## CI e qualidade local

- **GitHub Actions:** `.github/workflows/flutter_ci.yml` — `flutter pub get`, `analyze`, `test` na branch `main`.
- **Versão do Flutter no CI:** fixada em `3.41.2` (alinhada ao time / máquinas locais).
- **Dependabot:** `.github/dependabot.yml` — ecossistema `pub`, agendamento mensal.
- Comandos úteis no dia a dia:

```bash
flutter analyze
flutter test
dart format lib test
```

## Pontos de entrada no código

| O quê                                  | Onde                                                                |
| -------------------------------------- | ------------------------------------------------------------------- |
| `main`                                 | `lib/main.dart` → `bootstrap()`                                     |
| Bootstrap (Sentry, DI, `runApp`)       | `lib/app/bootstrap.dart`                                            |
| Tema e tokens                          | `lib/app/theme/` (`app_theme.dart`, `app_theme_tokens` / extensões) |
| Rotas e nomes                          | `lib/app/router/app_routes.dart`, composição em `app_router.dart`   |
| Injeção de dependência                 | `lib/core/di/injector*.dart`                                        |
| Cliente HTTP                           | `lib/core/network/app_dio_client.dart`                              |
| Cache local (Hive) e prefixos de chave | `lib/core/cache/`, datasources em `features/*/data/`                |

## Plataformas e escopo

- **Alvo:** Android e iOS (app corporativo; evitar expandir web/desktop sem necessidade).
- **Web:** se fizer build web, há estratégia de URL em `lib/app/web_url_strategy*.dart` e `<base href>` no `web/index.html`.

## Design e UX

- Material 3 customizado; preferir tokens e componentes compartilhados em `lib/shared/` em vez de cores hardcoded nas features.
- Regras de UI/UX: `.cursor/rules/ui_ux_design.mdc` e `flutter_widgets.mdc`.

## Testes

- Estratégia: `.cursor/rules/testing.mdc` e `testing_dart_flutter.mdc`.
- Estrutura de pastas em `test/` espelha `lib/` por feature ou módulo compartilhado.

## Versionamento e releases

- Versão do pacote / build: `pubspec.yaml` (`version:` e número de build `+`).
- O CI atual só valida código (`analyze` + `test`); **não** publica nas lojas — deploy é manual ou outro pipeline.
- Completar pelo time quando o processo existir:

| Item                             | Valor / link                                                |
| -------------------------------- | ----------------------------------------------------------- |
| Onde publicar                    | Play Console / App Store Connect / MDM / outro: _a definir_ |
| Canais (interno, beta, produção) | _a definir_                                                 |
| Quem aprova release              | _a definir_                                                 |

## Backend e integrações

Comportamento **já implementado** no app (ver `AppEnvironment` + `AppDioClient`):

| Tópico     | Detalhe                                                                                                                                                                                                                                                         |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Modo fake  | `USE_FAKE_BACKEND` tem **padrão `true`**: usa implementações em memória (`FakeAuthRemoteDataSource`, etc.) sem rede real.                                                                                                                                       |
| API real   | Definir `--dart-define=USE_FAKE_BACKEND=false` **e** `API_BASE_URL=https://...` (sem barra final desnecessária; o Dio usa como base). Se `API_BASE_URL` estiver vazio com fake desligado, o app **registra um aviso** no log e chamadas relativas podem falhar. |
| Transporte | JSON via `dio`; timeouts de **15 s** (connect, receive, send).                                                                                                                                                                                                  |
| Sessão     | Tokens em armazenamento seguro; backend é fonte de verdade para autorização (`project_specifics`).                                                                                                                                                              |

Anotações **externas ao repositório** (preencher):

| Item                                             | Onde anotar           |
| ------------------------------------------------ | --------------------- |
| URL base por ambiente (dev / homolog / prod)     | Tabela ou link abaixo |
| Contrato da API (OpenAPI, Postman, repo backend) | _link ou caminho_     |
| Auth corporativa (provedor, refresh, escopos)    | _resumo_              |

```
Dev:        (a definir)
Homolog:    (a definir)
Produção:   (a definir)
```

## Time e responsabilidades

Substituir os placeholders quando o time definir donos e canais:

| Papel / necessidade                                | Contato ou link                                     |
| -------------------------------------------------- | --------------------------------------------------- |
| Owner técnico ou produto                           | _a definir_                                         |
| Canal do time (Slack, Teams, etc.)                 | _a definir_                                         |
| Incidentes em produção                             | _a definir_ (ex.: projeto Sentry, runbook, plantão) |
| Documentação de produto (Confluence, Notion, etc.) | _a definir_                                         |

## Ideias extras que valem anotação

- Decisões de **pacotes** (por que `drift`, `syncfusion`, etc.) quando não couber em ADR formal.
- **Limites conhecidos** da API (rate limit, paginação máxima, timeouts).
- **Mapeamento loja / tenant** e como isso aparece nos headers ou query params.
- **Checklist manual** antes de release (smoke em login, troca de loja, relatório X).
- Links para **Figma**, **Jira/Linear**, **Confluence** do produto.

---

_Atualize este arquivo quando houver decisões novas (integrações, URLs, convenções de time)._
