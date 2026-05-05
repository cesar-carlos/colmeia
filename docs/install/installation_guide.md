# Guia de Instalacao - Colmeia

Passo a passo para instalar o Colmeia no Windows.

## Pre-requisitos

- Windows 10 ou Windows 11, 64 bits
- Permissao de administrador para executar o instalador
- Microsoft Visual C++ Redistributable x64
- Conexao com a internet para baixar releases e usar auto-update

Detalhes em [requirements.md](requirements.md).

## Passo 1: Baixar o instalador

1. Abra a pagina de releases do repositorio:
   [github.com/cesar-carlos/colmeia/releases](https://github.com/cesar-carlos/colmeia/releases)
2. Baixe o arquivo `Colmeia-Setup-{versao}.exe`
3. Salve o arquivo em uma pasta local, como `Downloads`

## Passo 2: Executar o instalador

1. Clique com o botao direito em `Colmeia-Setup-{versao}.exe`
2. Escolha `Executar como administrador`
3. Confirme o UAC do Windows

## Passo 3: Concluir o assistente

1. Avance pela tela inicial
2. Escolha a pasta de instalacao, se quiser mudar a padrao
3. Opcionalmente marque o atalho da area de trabalho
4. Clique em `Instalar`
5. Ao final, clique em `Concluir`

## Instalacao silenciosa

Para distribuicao por TI:

```powershell
Colmeia-Setup-{versao}.exe /VERYSILENT /NORESTART /LOG
```

## Validacao pos-instalacao

1. Abra o Colmeia pelo menu Iniciar
2. Entre em `Configuracoes`
3. Confirme a versao exibida na tela
4. Em builds Windows com feed configurado, use `Verificar atualizacoes`

## Desinstalacao

1. Abra `Configuracoes` do Windows > `Aplicativos`
2. Localize `Colmeia`
3. Clique em `Desinstalar`

## Limites conhecidos da v1

- O auto-update esta disponivel apenas para builds Windows
- A v1 nao usa assinatura DSA nem code signing Authenticode
- O Windows SmartScreen pode exibir avisos ate a fase de hardening
