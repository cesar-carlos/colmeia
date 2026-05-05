# Windows Install e Release

Indice canonico da documentacao de instalacao Windows e release oficial do
Colmeia.

## Fluxos principais

### Instalar uma release

1. Conferir [requirements.md](requirements.md)
2. Baixar o instalador na pagina de releases
3. Seguir [installation_guide.md](installation_guide.md)

### Gerar um instalador local

1. Revisar [release_guide.md](release_guide.md)
2. (Opcional) Copiar `.env.release.example` para `.env.release` na raiz para embutir
   o feed oficial no binario Windows (auto-update).
3. Se alterou icones em `assets/icons/`, executar `dart run flutter_launcher_icons`
   e commitar alteracoes geradas antes do instalador.
4. Executar `python installer/build_installer.py`

Saida esperada:

```text
installer/dist/Colmeia-Setup-{MAJOR.MINOR.PATCH}.exe
```

### Publicar uma release oficial

1. Atualizar `pubspec.yaml`
2. Garantir sincronismo com `python installer/update_version.py`
3. Criar a tag `vX.Y.Z` em um commit ja alcancavel a partir de `main`
4. Aprovar o environment `production`, quando configurado
5. Deixar o GitHub Actions publicar `.exe` Windows, `apk` Android, `aab`
   Android, seus `.sha256` e `appcast.xml`
6. Se `main` tiver protecao restritiva, configurar `APPCAST_PUSH_TOKEN`

## Documentos

- [installation_guide.md](installation_guide.md): instalacao e desinstalacao no Windows
- [requirements.md](requirements.md): compatibilidade e prerequisitos
- [release_guide.md](release_guide.md): versionamento, tags e release no GitHub
- [auto_update_setup.md](auto_update_setup.md): feed oficial e validacao do updater
