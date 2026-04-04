# Analise Inicial do Produto

## Objetivo do projeto

O Colmeia nasce como um aplicativo mobile em Flutter para iOS e Android, voltado para consumo analitico de dados operacionais e gerenciais. A proposta inicial do produto e entregar:

- dashboards dinamicos
- relatorios gerenciais
- autenticacao e controle de sessao
- permissoes por usuario
- segmentacao por loja
- suporte futuro a atualizacao quase em tempo real

O contexto assumido desde o inicio e de uma operacao multi-loja, com usuarios em diferentes perfis e dados consolidados em infraestrutura central.

## Leitura deste documento

- `historico`: este documento consolida a visao funcional inicial
- `alinhado`: a maior parte do objetivo de produto continua valida
- `nao e referencia de stack`: para decisoes concretas do repositorio, consulte os documentos tecnicos e de alinhamento

## Contexto de negocio

Os levantamentos iniciais apontam um produto corporativo para uma rede com aproximadamente 60 lojas, em que:

- cada loja possui um identificador proprio
- os dados sao centralizados
- ha diferentes niveis de acesso
- um usuario pode enxergar uma ou varias lojas

Os perfis mapeados inicialmente foram:

- vendedor
- gerente individual
- gerente geral

Mesmo com variacoes futuras de nomenclatura, a ideia principal continua valida: o app precisa atender cenarios multi-perfil e multi-loja.

## Premissas iniciais

As premissas que seguem corretas e continuam aderentes ao projeto sao:

- o app consome uma API central
- o backend e a fonte oficial da verdade
- autorizacao real deve ocorrer no backend
- REST e o transporte principal
- socket ou tempo real entram como complemento
- cache local deve ser controlado para nao aumentar demais a complexidade

## Problema que o app resolve

O problema central nao e apenas exibir informacao, mas permitir leitura analitica segura e organizada em um cenario com:

- varias lojas
- varios perfis
- varios niveis de permissao
- filtros por contexto
- dashboards e relatorios dinamicos

Isso posiciona o Colmeia como um sistema mobile de consulta analitica multi-loja.

## Direcao arquitetural sugerida no levantamento

O levantamento inicial ja apontava uma organizacao em camadas com:

- presentation
- application
- domain
- data

Tambem sugeria:

- Flutter no frontend
- Dio para HTTP
- GoRouter para navegacao
- cache leve no MVP
- autorizacao centralizada no backend

Essa direcao geral continua correta.

## O que foi refinado depois

Com a evolucao do projeto, alguns pontos de negocio ganharam mais definicao:

- os agentes passaram a ser entendidos como futuras fontes de dados
- dashboards continuam ativos como prioridade
- relatorios seguem no objetivo do produto, mas ainda nao estao ativos na navegacao principal
- a evolucao do app passou a considerar consulta por um ou varios agentes

## Navegacao funcional inicial

O fluxo sugerido no levantamento inicial foi:

1. login
2. selecao de contexto
3. dashboard principal
4. dashboards detalhados
5. relatorios
6. perfil e configuracoes

Esse desenho continua coerente como visao de produto, embora o estado atual do repositorio ainda nao tenha o modulo de relatorios religado na navegacao principal.

## Modelagem funcional sugerida

As entidades sugeridas no levantamento inicial foram:

- usuario
- perfil
- loja
- permissao
- dashboard
- widget de dashboard
- relatorio

Essa modelagem continua adequada como visao de dominio de alto nivel.

## Dashboards dinamicos

O levantamento inicial acertou ao sugerir dashboards baseados em metadados do backend, com widgets configuraveis e regras de exibicao. Isso continua alinhado com a necessidade do produto de evoluir sem exigir nova versao para cada pequena mudanca.

## Entrega sugerida no levantamento

O desenho de fases iniciais foi:

- Fase 1: login, sessao, permissoes, escolha de loja, dashboard principal e relatorios prioritarios
- Fase 2: filtros salvos, comparativos, cache melhor e socket pontual
- Fase 3: dashboards mais configuraveis e evolucao do tempo real

Como visao de produto, a sequencia continua boa. Como sequencia real de implementacao do repositorio, alguns pontos mudaram e foram registrados no documento de alinhamento.

## Leitura atualizada

O levantamento inicial continua valido como documento de visao funcional. O que mudou foi o refinamento do produto:

- hoje o projeto usa manutencao de agentes como uma nova capacidade funcional relevante
- os agentes passaram a ser tratados como futuras fontes de dados
- relatorios continuam importantes, mas ainda nao estao na navegacao ativa
- a implementacao real adotou escolhas tecnicas diferentes em alguns pontos

## Conclusao

Como base de negocio e produto, o levantamento inicial segue consistente com o objetivo maior do Colmeia: entregar uma plataforma mobile de consulta analitica segura, escalavel e preparada para multiplas fontes, multiplas lojas e multiplos perfis.

## Documentos relacionados

- `docs/analysis/analise_tecnica.md`
- `docs/analysis/alinhamento_levantamentos_iniciais.md`
- `docs/analysis/agentes_como_fontes_de_dados.md`
