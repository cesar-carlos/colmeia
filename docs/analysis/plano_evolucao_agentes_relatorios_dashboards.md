# Plano de Evolucao dos Agentes para Relatorios e Dashboards

## Objetivo

Este documento resume, em formato executivo, como evoluir o Colmeia da manutencao de agentes ja implementada para uma arquitetura de consultas que alimente dashboards, graficos e relatorios.

## Estado atual

Hoje o projeto ja possui:

- autenticacao e sessao com `Dio` e refresh automatico
- contexto de usuario e permissoes
- dashboard principal consumindo API central
- infraestrutura visual compartilhada para relatorios
- feature de manutencao de agentes do cliente
- cache local e fila de pendencias para acoes sobre agentes

Isso significa que a base de acesso, autorizacao e manutencao das fontes de dados ja existe.

### Classificacao de status

- `implementado`: manutencao de agentes, dashboards iniciais, cache leve, auth e contexto
- `planejado`: camada de consulta por agentes para dashboards e relatorios
- `fora do escopo imediato`: consolidacao complexa multi-fonte e offline-first analitico

## Visao alvo

O objetivo e fazer com que os agentes aprovados do cliente passem a funcionar como fontes reais de consulta analitica.

Na visao final:

- o cliente mantem sua lista de agentes aprovados
- cada agente representa uma fonte de dados conectada
- dashboards e relatorios consultam um ou varios agentes
- o app normaliza os resultados recebidos
- a UI renderiza KPIs, graficos e tabelas a partir dessa camada

## Principios de implementacao

- reaproveitar a infraestrutura atual de `Dio`, auth, erros e cache
- manter separacao por feature e por camada
- nao acoplar a consulta ao tipo de widget visual
- comecar com consulta simples antes de concorrencia multi-agente
- usar `RACE` apenas onde houver ganho real de latencia
- manter o backend e a API como fonte final de autorizacao

## Macroetapas

### Fase 1: Consolidar contratos de consulta

Objetivo:

- definir o contrato tecnico e semantico da consulta por agente

Entregas:

- entidades como `AgentQueryRequest`, `AgentQueryPlan`, `AgentQueryResult`
- contratos de repositorio para execucao de consulta
- definicao de filtros, metadados e formato normalizado de resposta
- definicao de falhas tipadas para consulta

Resultado esperado:

- uma base de dominio clara para novas consultas

Dependencias principais:

- definicao do endpoint de consulta
- definicao do `queryKey`

### Fase 2: Implementar consulta single-source

Objetivo:

- executar consulta em um unico agente aprovado

Entregas:

- nova feature de consulta por agentes
- datasource remoto para endpoint de query
- repository + use case de execucao
- validacao de elegibilidade do agente
- retorno normalizado desacoplado da UI

Resultado esperado:

- primeiro caminho funcional fim a fim para leitura analitica via agente

Dependencias principais:

- lista de agentes aprovados
- criterio de elegibilidade por consulta

### Fase 3: Integrar um dashboard piloto

Objetivo:

- provar a arquitetura com um caso de uso real e pequeno

Entregas:

- um card, widget ou dashboard piloto alimentado por consulta de agente
- mapeamento do resultado para KPI, serie ou grafico
- logging tecnico da execucao

Resultado esperado:

- validacao da latencia, payload e mapeamento visual

Entregavel alvo:

- primeiro KPI ou grafico real vindo de agente

### Fase 4: Integrar um relatorio piloto

Objetivo:

- validar o encaixe da consulta com os componentes compartilhados de relatorio

Entregas:

- um relatorio piloto ligado a consulta de agente
- suporte a filtros
- suporte a paginacao orientada ao servidor/agente
- traducao de filtros da UI para o payload da consulta

Resultado esperado:

- primeiro fluxo de tabela/relatorio baseado em agente

Entregavel alvo:

- primeiro relatorio com filtros e paginacao orientada ao servidor/agente

### Fase 5: Implementar multi-source `RACE`

Objetivo:

- reduzir tempo de resposta quando mais de um agente puder responder a mesma consulta

Entregas:

- planner de execucao multi-agente
- dispatch paralelo
- timeout por agente
- timeout global
- cancelamento ou descarte das respostas remanescentes
- identificacao do agente vencedor

Resultado esperado:

- consulta paralela com menor latencia percebida

Decisoes a fechar:

- regra de vitoria
- regra de cancelamento
- condicoes de elegibilidade multi-agente

### Fase 6: Observabilidade e tuning

Objetivo:

- entender comportamento real da arquitetura e ajustar performance

Entregas:

- logs estruturados por consulta
- duracao por agente
- taxa de timeout
- taxa de falha por agente
- identificacao de agente vencedor nas corridas

Resultado esperado:

- base concreta para tuning operacional

### Fase 7: Cache seletivo de leitura

Objetivo:

- reduzir chamadas repetidas em cenarios de leitura recorrente

Entregas:

- cache por `queryKey`
- metadados da ultima execucao bem-sucedida
- TTL por tipo de consulta
- politicas claras de invalidacao

Resultado esperado:

- melhor experiencia sem aumentar demais a complexidade

## Ordem recomendada de entrega

1. contratos de consulta
2. consulta single-source
3. dashboard piloto
4. relatorio piloto
5. multi-source `RACE`
6. observabilidade
7. cache seletivo

## Fora do escopo inicial

Para evitar excesso de complexidade no inicio, nao entrar de imediato com:

- merge complexo offline
- agregacao pesada no app entre muitas fontes
- estrategias avancadas alem de `single` e `race`
- mecanismo generico para todos os tipos de consulta sem primeiro validar pilotos
- offline-first completo para resultados analiticos

## Dependencias tecnicas a reaproveitar

### Ja existentes

- `AppDioClient`
- `AuthInterceptor`
- `AppResult`
- `AppFailure`
- `AppCacheStore`
- `HiveAppCacheStore`
- `GetIt`
- `AppReportViewer`
- feature `client_agents`

### Novas

Entram apenas as abstracoes novas da feature de consulta, sem quebrar a base atual.

## Referencias de codigo relacionadas

- `lib/features/client_agents/`
- `lib/features/dashboards/`
- `lib/shared/widgets/reports/`
- `lib/core/network/app_dio_client.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/cache/app_cache_store.dart`

## Riscos principais

- usar `RACE` em cenarios que exigem consolidacao real
- acoplar a camada de consulta a widgets especificos
- definir um contrato de retorno muito tecnico e pouco reutilizavel
- trazer volume grande demais para consolidar no app
- nao ter metrica suficiente para diagnosticar lentidao por agente
- crescer a feature antes de validar um dashboard e um relatorio piloto

## Matriz de mitigacao

| Risco | Mitigacao |
| --- | --- |
| Acoplamento da consulta a widgets | manter contratos intermediarios e normalizados |
| `RACE` mal aplicado | habilitar apenas em consultas elegiveis para primeiro sucesso |
| Falta de endpoint claro | fechar contrato da API antes da Fase 2 |
| Excesso de escopo no piloto | limitar cada fase a um entregavel validavel |
| Drift entre documentacao e codigo | manter referencias de codigo e status `implementado` vs `planejado` |

## Criterios de sucesso

Esta evolucao pode ser considerada bem-sucedida quando:

- uma consulta simples por agente funcionar ponta a ponta
- um dashboard piloto usar resultado de agente com estabilidade
- um relatorio piloto usar resultado de agente com filtros e paginacao
- a estrategia `RACE` reduzir latencia sem degradar consistencia
- o app continuar reaproveitando a infraestrutura central existente

## Recomendacao executiva

O melhor caminho nao e tentar ligar todos os relatorios e dashboards aos agentes de uma vez. O mais seguro e:

1. formalizar o contrato de consulta
2. validar um caso simples
3. validar um dashboard
4. validar um relatorio
5. so depois adicionar consulta concorrente multi-agente

## Documentos relacionados

- `docs/analysis/agentes_como_fontes_de_dados.md`
- `docs/analysis/consulta_multi_agente_para_relatorios_e_graficos.md`

## Conclusao

O projeto ja concluiu a etapa de preparar os agentes como fontes autorizadas do cliente. A evolucao natural agora e transformar essa base em uma camada de consulta analitica reutilizavel, com crescimento controlado, pilotos pequenos e suporte futuro a execucao concorrente quando ela realmente trouxer ganho de desempenho.
