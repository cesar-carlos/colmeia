# Analise do Projeto Colmeia

## Objetivo deste diretorio

Este diretorio concentra os levantamentos de negocio, arquitetura e evolucao do Colmeia. Ele registra:

- a visao inicial do produto
- a analise tecnica inicial
- o alinhamento desses levantamentos com o estado atual do projeto
- a evolucao do papel dos agentes como fontes de dados
- o plano de crescimento para dashboards e relatorios orientados por agentes

## Glossario rapido

- `agente`: conexao autorizada que representa uma fonte de dados consultavel para a conta do cliente
- `agente aprovado`: agente que ja faz parte da lista de agentes permitidos da conta
- `fonte de dados`: origem de dados que pode atender dashboards, graficos ou relatorios
- `single-source query`: consulta executada contra um unico agente
- `multi-source race query`: consulta enviada em paralelo para mais de um agente, aceitando o primeiro resultado valido
- `queryKey`: identificador logico da consulta, usado para roteamento, cache e observabilidade

## Estado atual do repositorio

### Ja implementado

- autenticacao e sessao com `Dio`
- refresh automatico de token
- contexto de usuario e permissao por escopo
- dashboard principal com integracao real inicial
- cache local leve com `Hive`
- manutencao de agentes do cliente
- agentes aprovados, detalhe, solicitacoes, solicitacao manual por `agentId` e fila local de pendencias

### Parcialmente implementado

- permissao especifica para agentes modelada, mas ainda nao aplicada como restricao fina de rota
- infraestrutura visual de relatorios pronta para reuso
- estrategia de cache e fallback aplicada em modulos ja ativos
- design para cache de fatos consolidados por repositorio: `docs/cache_repo/`

### Planejado

- religar relatorios na navegacao principal
- criar camada de consulta por agentes
- suportar consultas `single-source`
- suportar consultas `multi-source race`
- alimentar dashboards e relatorios a partir de agentes aprovados

### Fora do escopo imediato

- offline-first completo para dados analiticos
- consolidacao complexa multi-fonte no app desde a primeira entrega
- estrategias avancadas alem de `single-source` e `RACE`

## Fluxo macro do objetivo final

O fluxo esperado de alto nivel para o produto pode ser resumido assim:

```text
UI
-> controller / use case
-> resolucao de agentes elegiveis
-> execucao de consulta por agente
-> normalizacao do resultado
-> adaptacao para dashboard ou relatorio
-> renderizacao final
```

## Leitura recomendada

### 1. Visao funcional inicial

Arquivo:

- `analise.md`

Use este documento para entender:

- o problema de negocio que o app resolve
- o contexto multi-loja e multi-perfil
- a visao inicial de dashboards e relatorios

### 2. Visao tecnica inicial

Arquivo:

- `analise_tecnica.md`

Use este documento para entender:

- a direcao arquitetural inicial
- a proposta de camadas
- a estrategia de dados, cache e autorizacao

### 3. Comparacao com o estado atual

Arquivo:

- `alinhamento_levantamentos_iniciais.md`

Use este documento para entender:

- o que continua valido nos levantamentos antigos
- o que mudou no projeto real
- onde existem inconsistencias de stack ou cronograma

### 4. Agentes como fontes de dados

Arquivo:

- `agentes_como_fontes_de_dados.md`

Use este documento para entender:

- o papel funcional dos agentes
- o que ja foi implementado na manutencao de agentes
- como os agentes entram na estrategia futura do produto
- quais partes ja existem no codigo e quais ainda sao planejadas

### 5. Consulta multi-agente

Arquivo:

- `consulta_multi_agente_para_relatorios_e_graficos.md`

Use este documento para entender:

- como desenhar a camada de consulta por agentes
- como suportar `single-source` e `multi-source race`
- como encaixar essa camada em dashboards e relatorios
- quais decisoes ainda estao em aberto

### 6. Plano executivo de evolucao

Arquivo:

- `plano_evolucao_agentes_relatorios_dashboards.md`

Use este documento para entender:

- a ordem recomendada de implementacao
- as fases de entrega
- riscos e criterios de sucesso

## Sintese do objetivo atual do projeto

Hoje, o objetivo do Colmeia pode ser resumido assim:

- app mobile Flutter corporativo
- foco em dashboards e relatorios analiticos
- operacao multi-loja e multi-perfil
- API central como fluxo principal
- autorizacao validada no backend
- cache local leve e controlado
- agentes como futuras fontes de dados autorizadas
- evolucao gradual para consultas multi-agente

## Dependencias reais do projeto atual

Estas dependencias e decisoes de stack ajudam a evitar drift com os levantamentos antigos:

- estado de apresentacao com `Provider`
- HTTP com `Dio`
- injecao de dependencia com `GetIt`
- cache local leve com `Hive`
- armazenamento seguro de sessao com `flutter_secure_storage`
- navegacao com `GoRouter`

## O que continua valido dos levantamentos iniciais

- Flutter como base mobile
- arquitetura por feature e em camadas
- REST como principal meio de integracao
- socket como complemento, nao como dependencia central
- cache leve no MVP
- backend como fonte final de autorizacao
- dashboards e relatorios como foco funcional do produto

## O que mudou no projeto real

As principais mudancas em relacao aos levantamentos iniciais sao:

- o projeto usa `Provider`, nao `Riverpod`
- o projeto usa cache leve com `Hive`, nao `SQLite/Drift`
- relatorios ainda nao estao ativos na navegacao principal
- agentes passaram a ter um papel importante como futuras fontes de dados

## Como ler implementado vs planejado

Para evitar confusao entre visao de produto e estado real do codigo:

- quando um documento falar em `implementado`, a capacidade ja existe no repositorio
- quando falar em `planejado`, a capacidade faz parte da evolucao proposta
- quando falar em `fora do escopo imediato`, a ideia foi registrada, mas nao deve orientar implementacao agora

## Arquivos historicos

Os arquivos abaixo foram mantidos como registro historico da descoberta inicial:

- `analise.txt`
- `analise_tecnica.txt`

Eles continuam uteis como origem conceitual, mas os arquivos `.md` devem ser tratados como referencia mais atualizada e mais facil de consultar.

## Ordem de referencia sugerida

Se a pergunta for sobre negocio:

- `analise.md`

Se a pergunta for sobre arquitetura:

- `analise_tecnica.md`

Se a pergunta for sobre aderencia ao projeto atual:

- `alinhamento_levantamentos_iniciais.md`

Se a pergunta for sobre agentes:

- `agentes_como_fontes_de_dados.md`

Se a pergunta for sobre consultas futuras:

- `consulta_multi_agente_para_relatorios_e_graficos.md`

Se a pergunta for sobre roadmap:

- `plano_evolucao_agentes_relatorios_dashboards.md`

## Referencias de codigo uteis

- `lib/features/client_agents/`
- `lib/features/overview/`
- `lib/shared/widgets/reports/`
- `lib/core/network/app_dio_client.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/cache/app_cache_store.dart`

## Conclusao

Este diretorio passa a funcionar como base viva de analise do Colmeia: os arquivos `.txt` preservam o historico, enquanto os `.md` concentram a leitura consolidada e mais alinhada ao estado atual e ao objetivo final do projeto.
