# Sales Live Map Validation Checklist

## Objetivo

Usar este checklist para validar consistencia visual, comportamento funcional e baseline de desempenho do `Sales Live Map` depois de mudancas na feature ou no chart compartilhado.

Os numeros observados devem ser tratados como baseline comparavel entre execucoes no mesmo ambiente. Nao use este documento para impor limites absolutos entre maquinas diferentes.

## Preparacao

1. Executar a aplicacao em `profile` ou `release`.
2. Abrir a demo `AppBrazilStoreSalesMapChart`.
3. Habilitar captura de logs do app para observar:
   - `Brazil store sales map snapshot data built`
   - `Brazil store sales map snapshot built`
   - `SalesLiveMapRefreshMetrics`
   - `Sales live map refresh completed...`
4. Registrar data, plataforma, modo de execucao, viewport e hash/branch da build.

## Checklist visual

- Inline e fullscreen usam a mesma identidade visual de card, tipografia, seletor de metrica e controles flutuantes.
- As diferencas visuais entre inline e fullscreen se limitam ao header/close e a sidebar desktop.
- O skeleton inicial usa a mesma composicao visual do mapa carregado.
- O selector de metrica continua funcional em inline e fullscreen.
- A sidebar desktop so aparece em fullscreen ou na demo operacional quando explicitamente habilitada.

## Checklist funcional na tela real

- Carga inicial conclui sem erro e mostra KPIs, painel parcial quando aplicavel e o mapa.
- Trocar a metrica nao dispara novo `loadProgressive`.
- Abrir fullscreen nao dispara novo reload.
- Fechar fullscreen nao dispara novo reload.
- Com fullscreen aberto, existe apenas uma instancia ativa do chart.
- Refresh com fullscreen aberto atualiza o mesmo chart aberto.
- Busca lateral, hover e selecao lateral nao recriam `snapshot data`.

## Checklist de profiling na demo

Executar os tres presets deterministas da demo operacional:

1. `50` pontos
2. `200` pontos
3. `500` pontos

Para cada preset:

- Medir o tempo percebido de primeira pintura do mapa.
- Trocar entre `Receita` e `Vendas`.
- Abrir e fechar a sidebar desktop quando aplicavel.
- Digitar uma busca lateral curta e limpar a busca.
- Registrar os logs de `snapshot data` e `snapshot built`.

Repetir cada cenario com:

- sidebar desktop habilitada
- sidebar desktop desabilitada

## Checklist de profiling na tela real

Executar e registrar logs para:

1. carga inicial da tela
2. troca de metrica
3. abrir fullscreen
4. fechar fullscreen
5. refresh manual com fullscreen aberto
6. busca lateral em fullscreen

Em cada interacao, confirmar:

- `snapshot data` nao e reconstruido quando a mudanca e apenas visual
- a quantidade de grupos e itens laterais nos logs se mantem estavel para o mesmo payload
- `SalesLiveMapRefreshMetrics` continua refletindo apenas o reload de dados, nao interacoes visuais

## Resultado esperado

- Sem drift visual relevante entre inline e fullscreen.
- Sem reload extra ao alternar metrica ou fullscreen.
- Sem recomputacao pesada desnecessaria em hover, busca lateral ou selecao.
- Logs suficientes para comparar regressao entre builds futuras.
