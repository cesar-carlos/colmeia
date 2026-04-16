# Agentes Como Fontes de Dados

## Visao geral

No contexto do Colmeia, cada agente funciona como uma **fonte de dados conectada a uma base de dados especifica**. O cliente nao consulta a base diretamente pelo app. Em vez disso, o app trabalha com a ideia de que:

- cada agente representa uma conexao disponivel para leitura de dados
- o cliente precisa ter o agente em sua lista de agentes aprovados
- somente agentes aprovados podem ser usados futuramente em consultas
- esses dados servirao como insumo para dashboards, graficos e relatorios

Em outras palavras, o agente se comporta como um `data source` externo governado pela API.

## Papel funcional do agente

O agente e a ponte entre o aplicativo e uma base de dados conectada fora do app. Isso permite que a aplicacao trabalhe com multiplas origens de dados sem acoplar a UI a detalhes de conexao, banco, host, credenciais ou dialeto SQL.

O papel do agente no produto pode ser resumido assim:

- expor uma origem de dados elegivel para consulta
- permitir que o cliente mantenha sua propria lista de agentes disponiveis
- informar situacao cadastral e situacao operacional do agente
- servir como base para consultas futuras que alimentarao graficos e relatorios

## Estado atual no codigo

O app ja possui uma feature dedicada para manutencao dos agentes do cliente em `lib/features/client_agents/`, organizada em `presentation`, `application`, `domain` e `data`.

### Status

- `implementado`: manutencao da lista de agentes do cliente
- `implementado`: cache local, fila offline e sincronizacao de pendencias
- `implementado`: leitura de status operacional por endpoint de agentes online
- `planejado`: uso dos agentes como camada real de consulta para dashboards e relatorios
- `fora do escopo imediato`: agregacao complexa multi-fonte dentro do app

Essa feature ja cobre:

- listagem de agentes aprovados para a conta do cliente
- consulta de detalhe de um agente aprovado
- historico de solicitacoes de acesso
- solicitacao manual de acesso por `agentId`
- fila local de acoes pendentes para solicitar ou remover acesso
- sincronizacao posterior dessas pendencias com a API
  (varias pendencias de `requestAccess` no mesmo sync viram um ou mais
  `POST /client/me/agents` em lotes de ate 50 ids; remocoes pendentes usam
  `DELETE /client/me/agents/{id}` em paralelo entre si, com limite de
  concorrencia; linhas presas em `syncing` por interrupcao anterior sao
  revertidas para `queued` antes de cada sync)
- leitura de status operacional via endpoint de agentes online

No shell principal do app, a area de agentes ja esta exposta pela rota `/agents`.

## Fluxo funcional atual de manutencao

Hoje o ciclo de manutencao funciona assim:

1. o cliente abre a tela de agentes
2. o app carrega tres conjuntos principais:
   - agentes ja aprovados para a conta
   - solicitacoes de acesso
   - pendencias locais de sincronizacao
3. o cliente informa um ou mais `agentIds` manualmente para solicitar acesso
4. o cliente pode remover acesso de um agente ja aprovado
5. essas alteracoes entram primeiro em uma fila local
6. o app tenta sincronizar automaticamente quando ha pendencias elegiveis
7. o usuario tambem pode disparar sincronizacao manual
8. apos sincronizar, o app atualiza snapshots locais de agentes aprovados, solicitacoes e status online

Esse desenho prepara o produto para redes instaveis e reduz perda de intencao do usuario.

## Rotas da API ja mapeadas

As rotas relevantes ja foram centralizadas em `lib/core/network/api_routes.dart`.

### Manutencao do cliente

- `GET /client/me/agents`
- `GET /client/me/agents/{agentId}`
- `POST /client/me/agents`
- `DELETE /client/me/agents`
- `DELETE /client/me/agents/{agentId}` (same effect as bulk delete with one id; used on pending sync)
- `GET /client/me/agent-access-requests`

### Descoberta e catalogo

- `GET /agents/catalog`

### Status operacional

- `GET /agents`

### Observacao importante

O fluxo atual exposto no app do cliente **nao depende mais de um catalogo navegavel na UI**. A solicitacao de acesso foi alinhada ao contrato real da API e hoje acontece por entrada manual de `agentId`.

O endpoint `GET /agents/catalog` continua mapeado no modulo e pode ser reaproveitado em evolucoes futuras, mas ele **nao faz parte do fluxo principal atual da UX do cliente** enquanto nao houver contrato de descoberta claramente fechado para esse perfil.

O endpoint `GET /agents` esta sendo usado como fonte de status operacional para identificar agentes conectados, o que hoje alimenta os estados:

- `online`
- `offline`
- `unknown`

Ja a situacao cadastral do agente vem do proprio perfil retornado pela API, com estados como `active` e `inactive`.

## Base tecnica reutilizada

A implementacao de agentes segue a infraestrutura padrao ja existente no projeto, sem criar um cliente HTTP paralelo.

### HTTP

O consumo usa `Dio` via a configuracao central de `AppDioClient`, com:

- `baseUrl` normalizada
- timeouts padrao
- logging padrao
- headers JSON

### Autenticacao

As chamadas passam pelo `AuthInterceptor`, que:

- injeta `Bearer token`
- ignora rotas publicas quando necessario
- tenta refresh automatico em falhas `401`

### Persistencia local

O cache da feature usa `AppCacheStore`, cuja implementacao atual e `HiveAppCacheStore`.

Isso significa que agentes reutilizam a mesma estrategia estrutural ja usada no app para leitura remota com fallback local.

### Referencias de codigo

- `lib/features/client_agents/data/repositories/client_agents_repository_impl.dart`
- `lib/features/client_agents/data/datasources/client_agents_remote_datasource.dart`
- `lib/features/client_agents/data/datasources/client_agents_local_datasource.dart`
- `lib/features/client_agents/presentation/controllers/client_agents_controller.dart`
- `lib/features/client_agents/presentation/pages/client_agents_page.dart`
- `lib/features/client_agents/presentation/pages/client_agent_detail_page.dart`
- `lib/core/network/api_routes.dart`

## Persistencia local e resiliencia

Um ponto importante da feature e que ela nao trata manutencao de agentes como tela puramente online. O app ja guarda estado local rico para manter contexto e suportar sincronizacao posterior.

### O que fica salvo

- agentes aprovados paginados
- historico de solicitacoes paginado
- detalhe de agente aprovado por `agentId`
- status online dos agentes
- fila de acoes pendentes

O modulo ainda possui estrutura tecnica para cache de catalogo paginado, mas esse dado nao compoe a UX principal atual do cliente.

### Como o cache foi modelado

As chaves locais incluem contexto suficiente para evitar mistura de resultados:

- `userId`
- `page`
- `pageSize`
- `search`
- `status`

Isso reduz inconsistencias entre consultas paginadas e filtradas.

### TTL de status online

O status operacional dos agentes online usa reaproveitamento local com `maxAge` de 1 minuto antes de tentar novo refresh remoto.

### Estados da fila local

As acoes pendentes usam os estados:

- `queued`
- `syncing`
- `failed`
- `synced`

Os tipos de acao hoje sao:

- `requestAccess`
- `removeAccess`

## Regras de manutencao implementadas

Algumas regras de negocio ja estao refletidas no repositorio:

- nao solicitar acesso para agente ja aprovado
- nao remover acesso de agente que nao esta aprovado
- evitar duplicidade da mesma acao pendente
- colapsar acoes opostas quando fizer sentido
- processar sincronizacao item a item
- manter somente pendencias que falharam

Isso e importante porque a lista de agentes do cliente passa a ser uma fronteira de autorizacao funcional para consultas futuras.

## Estados visiveis no app

A UI atual de `ClientAgentsPage` organiza a manutencao em tres abas:

- `Meus agentes`
- `Solicitar acesso`
- `Solicitacoes`

O usuario consegue:

- visualizar agentes aprovados
- abrir detalhe de um agente
- solicitar acesso informando um ou mais `agentIds`
- remover acesso
- acompanhar pendencias locais
- ver feedback de itens enfileirados localmente e de sincronizacao automatica
- disparar sincronizacao manual

O detalhe do agente mostra informacoes como:

- nome
- nome fantasia
- documento
- email
- telefone
- cidade

## Permissoes

Ja existe preparacao no dominio de usuario para a permissao `manageAgents`.

Hoje, porem, a navegacao para agentes ainda esta liberada no controller de contexto de usuario. Isso indica que:

- a modelagem de permissao ja foi preparada
- a restricao fina de acesso ainda nao esta fechada na UI
- o backend continua sendo a fonte final de autorizacao

## Relacao com dashboards e relatorios

O objetivo maior do produto continua sendo dashboards e relatorios dinamicos.

Hoje:

- dashboards reais ja consomem a API central por `GET /dashboards/overview`
- o repositorio de dashboard ja usa leitura remota com fallback em cache
- o modulo de relatorios ainda nao esta ativo em rotas de producao
- o app ja possui componentes compartilhados robustos para visualizacao tabular em `lib/shared/widgets/reports/`

Isso deixa claro que a feature de agentes nao e um fim em si. Ela prepara a camada de **origens de dados autorizadas** que podera abastecer:

- consultas de dashboards
- consultas de relatorios
- comparacoes entre origens
- consolidacao de resultados

## Como os agentes entram na proxima fase

Na fase atual, agentes sao uma feature de cadastro, acesso e disponibilidade.

Na proxima fase, eles devem evoluir para uma feature de **orquestracao de consultas**. O fluxo esperado passa a ser:

1. o usuario escolhe um dashboard ou relatorio
2. o app identifica quais agentes aprovados podem atender aquela consulta
3. a consulta e enviada para um agente ou para varios agentes ao mesmo tempo
4. os resultados retornados sao normalizados
5. a camada de aplicacao consolida a resposta
6. a presentation alimenta cards, graficos e grids

## Estrategia futura de consulta multi-agente

Quando uma consulta puder usar mais de um agente simultaneamente, faz sentido usar uma estrategia de concorrencia do tipo `RACE` para reduzir latencia percebida.

### Objetivo da estrategia

Enviar varias consultas assincronas ao mesmo tempo para ganhar velocidade quando houver multiplas fontes elegiveis.

### Leitura conceitual

Essa estrategia pode assumir variacoes diferentes, por exemplo:

- retornar o primeiro resultado valido
- retornar o primeiro resultado completo dentro de uma regra de qualidade
- combinar respostas parciais em paralelo quando o caso exigir agregacao

### Cuidados importantes

Essa parte ainda nao esta implementada no codigo atual e deve ser desenhada com criterios claros:

- qual agente e elegivel para cada consulta
- quando usar um unico agente
- quando usar varios em paralelo
- o que significa "vencer" a corrida
- como cancelar requisicoes restantes
- como lidar com timeout parcial
- como lidar com respostas inconsistentes entre agentes
- como registrar observabilidade por agente participante

### Recomendacao tecnica

Para dashboards e relatorios, a melhor leitura inicial e separar duas estrategias:

- `single-source query`: consulta em um agente especifico
- `multi-source race query`: consulta paralela em mais de um agente aprovado

Isso evita acoplamento precoce e permite evolucao gradual do modulo.

## Decisoes abertas

Existem algumas decisoes que ainda precisam ser fechadas antes da implementacao da camada de consulta:

- qual endpoint real executara consultas por agente
- quais tipos de consulta poderao usar mais de um agente
- se `RACE` aceitara o primeiro sucesso ou o primeiro sucesso qualificado
- como sera o cancelamento das requisicoes restantes
- como a elegibilidade de agente sera resolvida por `queryKey`
- quais metadados precisam voltar no resultado para dashboards e relatorios

## Proposta de modelo mental para o produto

Uma forma simples de entender a arquitetura funcional e:

- `agente` = origem de dados conectada
- `lista de agentes do cliente` = conjunto de fontes autorizadas para aquela conta
- `consulta` = requisicao de leitura enviada a uma ou mais fontes
- `resultado consolidado` = resposta preparada para visualizacao
- `dashboard/relatorio` = camada final de apresentacao do dado consultado

## Pontos relevantes para a futura documentacao funcional

Ao detalhar a evolucao do produto, vale registrar estes principios:

- o app nao fala direto com banco; ele fala com agentes via API
- cada agente representa uma conexao de leitura reutilizavel
- estar no catalogo nao basta; o agente precisa estar aprovado para a conta
- status cadastral e status operacional sao coisas diferentes
- manutencao de agentes e pre-condicao para consultas futuras
- a camada de agentes e base para dashboards e relatorios multi-fonte
- a API continua sendo a fonte de verdade sobre acesso e autorizacao
- cache local existe para resiliencia, nao para transformar o modulo em offline-first completo

## Limitacoes atuais identificadas

Pelo estado atual do codigo, ainda faltam etapas para a visao completa de agentes como fontes de consulta:

- nao existe ainda um executor de consulta contra agentes
- nao existe ainda contrato de query de relatorio orientado a agentes
- nao existe ainda agregador de respostas multi-agente
- nao existe ainda cancelamento/coordenacao de corrida entre agentes
- a permissao `manageAgents` ainda nao governa de fato o acesso da rota na UI
- o modulo de relatorios ainda nao esta religado nas rotas principais

## Matriz de riscos e mitigacao

| Risco                                                            | Impacto                           | Mitigacao sugerida                                                |
| ---------------------------------------------------------------- | --------------------------------- | ----------------------------------------------------------------- |
| Confundir manutencao de agentes com camada de consulta ja pronta | expectativa incorreta de escopo   | marcar explicitamente `implementado` vs `planejado`               |
| Consultar agente nao aprovado                                    | quebra de regra funcional         | resolver elegibilidade sempre a partir da lista aprovada da conta |
| Status online stale                                              | decisao ruim de origem            | manter TTL curto e permitir refresh                               |
| Excesso de logica de consulta na UI                              | acoplamento e baixa testabilidade | criar feature propria de consulta por agentes                     |
| Falhas parciais na sincronizacao de manutencao                   | pendencias invisiveis ao usuario  | manter fila local com estados e erro por item                     |

## Roadmap tecnico ligado a agentes

1. manter a manutencao de agentes como fronteira de autorizacao funcional
2. criar contratos de consulta por agente
3. criar executor `single-source`
4. validar um dashboard piloto
5. validar um relatorio piloto
6. adicionar `multi-source race` quando houver ganho real

## Direcao recomendada

Com base no estado atual do projeto, a sequencia mais coerente para evolucao e:

1. consolidar o conceito de agente como `data source` oficial da conta
2. definir contratos de consulta por agente
3. definir contrato de consulta multi-agente com concorrencia
4. normalizar resultados para consumo por dashboards e relatorios
5. integrar os primeiros relatorios prioritarios sobre essa camada
6. reaproveitar os widgets de relatorios e grids ja existentes

## Documentos relacionados

- `docs/analysis/consulta_multi_agente_para_relatorios_e_graficos.md`
- `docs/analysis/plano_evolucao_agentes_relatorios_dashboards.md`

## Conclusao

Os agentes ja estao bem posicionados no projeto como a camada de preparacao para consultas analiticas futuras. A manutencao da lista do cliente, o cache local, a sincronizacao de pendencias e o status operacional ja formam uma base consistente.

A proxima etapa natural do Colmeia e transformar essa base em uma camada de execucao de consultas sobre fontes autorizadas, permitindo alimentar dashboards e relatorios a partir de um ou varios agentes, inclusive com estrategia concorrente quando houver ganho real de desempenho.
