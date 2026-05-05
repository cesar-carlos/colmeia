# Requisitos do Sistema

Compatibilidade e prerequisitos para instalar o Colmeia via instalador Windows.

## Minimos

| Item | Requisito |
| --- | --- |
| Sistema operacional | Windows 10 ou Windows 11 |
| Arquitetura | x64 |
| Memoria RAM | 4 GB |
| Espaco em disco | 500 MB livres |
| Permissoes | Administrador para instalar |
| Runtime | Microsoft Visual C++ Redistributable x64 |

Download do runtime:

[vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe)

## Observacoes operacionais

- O instalador valida a presenca do Visual C++ Redistributable x64
- Em instalacoes silenciosas, o aviso vai para o log do Inno Setup
- O auto-update depende de acesso HTTPS ao GitHub Releases e ao GitHub Raw

## Rede

Para usar o updater Windows, o ambiente deve permitir:

- `https://github.com`
- `https://raw.githubusercontent.com`

## Limites da v1

- Sem assinatura DSA no appcast
- Sem assinatura Authenticode do executavel/instalador
- SmartScreen pode exigir confirmacao manual em alguns ambientes
