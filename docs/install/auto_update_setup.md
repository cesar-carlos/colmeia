# Auto-Update Windows

Configuracao operacional do updater Windows do Colmeia.

## Visao geral

O Colmeia usa `auto_updater` com WinSparkle no Windows.

O feed e resolvido nesta ordem:

1. `--dart-define=AUTO_UPDATE_FEED_URL=...`
2. `.env.release` da raiz, consumido por `installer/build_installer.py`
   (modelo versionado: copie `.env.example` → `.env.release`)

No GitHub Actions (workflow de tag), o URL vem do ambiente do job; opcionalmente
substitua pela variavel de repositorio **`APPCAST_FEED_URL`** (ver `installer/readme.md`).

Se `AUTO_UPDATE_FEED_URL` estiver vazio ou invalido, a UI de update no Windows
permanece visivel apenas em modo informativo e a checagem manual fica
desabilitada.

## Feed oficial

[raw.githubusercontent.com/cesar-carlos/colmeia/main/appcast.xml](https://raw.githubusercontent.com/cesar-carlos/colmeia/main/appcast.xml)

## Comportamento no app

- Inicializacao do feed apenas em builds Windows
- Checagem inicial em background ao subir o app
- Checagem agendada a cada 1 hora
- Acao manual em `Configuracoes` > `Atualizacoes do app`
- Mobile, web e demais plataformas nao inicializam o updater

## Release e appcast

Ao criar a tag `vX.Y.Z`, o workflow `Windows Release`:

1. gera o instalador `Colmeia-Setup-X.Y.Z.exe`;
2. publica o asset na GitHub Release;
3. atualiza `appcast.xml` em `main`;
4. preserva apenas os itens mais recentes no feed.

Se `main` for protegida de forma a bloquear o token padrao do Actions,
configure o secret `APPCAST_PUSH_TOKEN` para a etapa de publicacao do
`appcast.xml`.

## Smoke test recomendado

1. Instale uma versao Windows antiga do Colmeia
2. Publique uma nova versao por tag
3. Aguarde o workflow concluir
4. Abra a versao antiga
5. Entre em `Configuracoes`
6. Use `Verificar atualizacoes`

Valide:

- com release nova: o updater encontra a nova versao;
- sem release nova: a UI informa que o build ja esta atualizado;
- com feed ausente/invalido: a UI explica por que o updater esta desabilitado.

## Limites aceitos na v1

- sem `sparkle:dsaSignature`
- sem `dsa_pub.pem` embutido no `Runner.rc`
- sem assinatura Authenticode

Esses pontos ficam para uma fase posterior de hardening.
