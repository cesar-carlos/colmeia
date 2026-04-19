// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get shellNavDashboardLabel => 'Visao geral';

  @override
  String get shellNavDashboardSubtitle => 'Resumo operacional e KPIs';

  @override
  String get shellNavAgentsLabel => 'Agentes';

  @override
  String get shellNavAgentsSubtitle => 'Fontes de dados e acessos';

  @override
  String get shellNavSettingsLabel => 'Perfil';

  @override
  String get shellNavSettingsSubtitle => 'Conta e preferencias';

  @override
  String get shellNavSalesLabel => 'Vendas';

  @override
  String get shellNavSalesSubtitle =>
      'Pedidos, receita e indicadores comerciais';

  @override
  String get shellNavReturnsLabel => 'Devolucoes';

  @override
  String get shellNavReturnsSubtitle => 'Devolucoes, trocas e notas de credito';

  @override
  String get shellNavFinanceLabel => 'Financeiro';

  @override
  String get shellNavFinanceSubtitle =>
      'Fluxo de caixa, contas a receber e a pagar';

  @override
  String get shellNavPurchasesLabel => 'Compras';

  @override
  String get shellNavPurchasesSubtitle => 'Fornecedores e pedidos de compra';

  @override
  String get shellNavInventoryLabel => 'Estoque';

  @override
  String get shellNavInventorySubtitle => 'Niveis de estoque e movimentacoes';

  @override
  String get shellPlaceholderUnderConstructionTitle => 'Em construcao';

  @override
  String get shellPlaceholderUnderConstructionBody =>
      'Esta secao estara disponivel em uma atualizacao futura.';

  @override
  String get shellAppBrandName => 'Colmeia';

  @override
  String get shellOpenSettingsSemantics => 'Abrir configuracoes';

  @override
  String get shellOpenProfileSemantics => 'Abrir perfil e conta';

  @override
  String get shellNavSignOut => 'Sair';

  @override
  String get shellNavSigningOut => 'Saindo...';

  @override
  String get shellNavSignOutSemanticsLoading => 'Encerrando sessao';

  @override
  String get shellSignOutDialogTitle => 'Sair da conta?';

  @override
  String get shellSignOutDialogConfirm => 'Sair';

  @override
  String get shellSignOutDialogMessage =>
      'Voce precisara entrar novamente para acessar os dados.';

  @override
  String get shellNavMainSemantics => 'Navegacao principal';

  @override
  String get userPermissionViewDashboard => 'Visao geral';

  @override
  String get userPermissionManageAgents => 'Gestao de agentes';

  @override
  String get userPermissionViewSales => 'Vendas (acesso ao modulo)';

  @override
  String get userPermissionViewReturns => 'Devolucoes (acesso ao modulo)';

  @override
  String get userPermissionViewFinance => 'Financeiro (acesso ao modulo)';

  @override
  String get userPermissionViewPurchases => 'Compras (acesso ao modulo)';

  @override
  String get userPermissionViewInventory => 'Estoque (acesso ao modulo)';

  @override
  String get dashboardPartialAgentQueriesTitle =>
      'Dados da visao geral incompletos';

  @override
  String get dashboardPartialAgentQueriesMessage =>
      'Alguns agentes aprovados nao retornaram dados. Os totais podem estar incompletos.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Agentes sem token de cliente salvo';

  @override
  String get dashboardMissingClientTokenMessage =>
      'Estes agentes aprovados foram ignorados porque nao ha token de cliente local. Cadastre o token na tela do agente para incluir os dados.';

  @override
  String get overviewResumoUnknownPaymentMethod =>
      'Forma de pagamento não informada';

  @override
  String get overviewResumoUnknownUserName => 'Utilizador não informado';

  @override
  String get dashboardSetupRequiredTitle =>
      'Salve um token de cliente para carregar os dados';

  @override
  String get dashboardSetupRequiredMessage =>
      'Nenhum agente com acesso aprovado possui token de cliente salvo neste dispositivo. Abra a gestao de agentes para cadastrar o token e liberar a consulta da visao geral.';

  @override
  String dashboardViewAffectedAgentsList(int count) {
    return 'Ver lista ($count)';
  }

  @override
  String get dashboardAffectedAgentsSheetTitlePartialFailure =>
      'Agentes que nao retornaram dados';

  @override
  String get dashboardAffectedAgentsSheetTitleMissingToken =>
      'Agentes sem token de cliente salvo';

  @override
  String get dashboardAffectedAgentsSheetTitleSetupRequired =>
      'Agentes aprovados sem token de cliente neste dispositivo';

  @override
  String get dashboardMultiAgentAggregationTitle => 'Varios agentes';

  @override
  String get dashboardMultiAgentAggregationMessage =>
      'Este resumo agrega dados de varios agentes aprovados. Se houver sobreposicao entre bases, os totais podem ficar acima de uma unica fonte.';

  @override
  String get dashboardPaymentSummaryTitle => 'Resumo por forma de pagamento';

  @override
  String get dashboardPaymentSummarySubtitle =>
      'Detalhamento de vendas, ticket medio e participacao.';

  @override
  String get dashboardPaymentSummaryEmptyTitle => 'Sem formas de pagamento';

  @override
  String get dashboardPaymentSummaryEmptyMessage =>
      'Nao ha linhas de forma de pagamento para este periodo.';

  @override
  String get dashboardPaymentSummaryHeaderRevenueAbbr => 'FATURAM.';

  @override
  String get dashboardPaymentSummaryTooltipRevenueAbbr =>
      'Faturamento no periodo selecionado';

  @override
  String get dashboardPaymentSummaryHeaderParticipationAbbr => 'PARTIC.';

  @override
  String get dashboardPaymentSummaryTooltipParticipationAbbr =>
      'Participacao percentual no faturamento total';

  @override
  String get dashboardPaymentSummaryHeaderSales => 'VENDAS';

  @override
  String get dashboardPaymentSummaryHeaderAvgTicket => 'TICKET\nMEDIO';

  @override
  String get dashboardPaymentSummaryLoadingSemantics =>
      'Carregando resumo por forma de pagamento…';

  @override
  String get dashboardHomeFiltersAgentsLabel => 'AGENTES';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visao geral para listar os agentes.';

  @override
  String get dashboardHomeFiltersYearMonthLabel => 'ANO / MÊS';

  @override
  String get dashboardHomeFiltersCurrentMonth => 'Mês atual';

  @override
  String get dashboardHomeFiltersPeriodLast30Days => 'Últimos 30 dias';

  @override
  String get dashboardHomeFiltersReferenceRangeLabel => 'PERÍODO';

  @override
  String dashboardHomeFiltersReferenceRangeHelper(int maxDays) {
    return 'Opcional. Escolha início e fim — o intervalo pode atravessar vários meses (no máximo $maxDays dias corridos). Totais e rankings seguem esse período. O gráfico mensal continua com 12 meses até o mês do último dia.';
  }

  @override
  String get dashboardHomeFiltersReferenceRangePickerTitle =>
      'Selecionar período';

  @override
  String get dashboardHomeFiltersYearMonthCustomDisplay => 'Personalizado';

  @override
  String dashboardHomeFiltersReferenceRangeMaxDurationSnackbar(int maxDays) {
    return 'O intervalo selecionado não pode passar de $maxDays dias corridos.';
  }

  @override
  String get overviewPeriodTagCustomRangePrefix => 'Período';

  @override
  String overviewAgentFilterAllAgentsSummary(int count) {
    return 'Todos os agentes ($count)';
  }

  @override
  String overviewAgentFilterSelectedCount(int count) {
    return '$count agentes selecionados';
  }

  @override
  String get overviewAgentFilterRefineAction => 'Refinar seleção';

  @override
  String get overviewAgentFilterEditAction => 'Editar';

  @override
  String get overviewAgentFilterSheetTitle => 'Selecionar agentes';

  @override
  String get overviewAgentFilterSheetSearchHint => 'Buscar agentes…';

  @override
  String get overviewAgentFilterSelectMatching =>
      'Selecionar todos os filtrados';

  @override
  String get overviewAgentFilterApply => 'Aplicar';

  @override
  String get overviewAgentFilterCancel => 'Cancelar';

  @override
  String get overviewAgentFilterNoSearchResults =>
      'Nenhum agente corresponde à busca.';

  @override
  String get overviewAgentFilterMissingClientTokenBanner =>
      'Agentes sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get overviewAgentFilterMissingClientTokenRowSubtitle =>
      'Sem token neste dispositivo — consultas SQL são ignoradas.';

  @override
  String get chartCategoryDonutEmptyForFilter =>
      'Sem dados de categorias para este recorte.';

  @override
  String get dashboardAgentRankingTitle => 'Ranking por agente';

  @override
  String get dashboardAgentRankingSubtitle =>
      'Faturamento total por agente no periodo.';

  @override
  String get dashboardUserRankingTitle => 'Ranking por operador';

  @override
  String get dashboardUserRankingSubtitle =>
      'Faturamento por operador no periodo.';

  @override
  String get overviewAgentRankingEmpty =>
      'Sem faturamento por agente neste período.';

  @override
  String get overviewUserRankingEmpty =>
      'Sem faturamento por operador neste período.';

  @override
  String get overviewDefaultGreetingName => 'Gestor';

  @override
  String overviewGreetingEyebrow(String name) {
    return 'Olá, $name';
  }

  @override
  String get overviewHomeSubtitle =>
      'Resumo consolidado dos agentes aprovados (todas as filiais conectadas).';

  @override
  String get overviewHomeAlertsSectionTitle => 'Avisos';

  @override
  String get overviewLoadErrorTitle =>
      'Nao foi possivel carregar a visao geral';

  @override
  String get overviewStaleCacheTitle => 'Dados salvos neste aparelho';

  @override
  String get overviewStaleCacheMessage =>
      'Nao foi possivel atualizar agora. Os numeros abaixo refletem o ultimo resumo obtido com sucesso.';

  @override
  String get overviewLoadingPaymentKpisSemantics =>
      'Carregando indicadores de pagamento…';

  @override
  String get overviewLoadingPaymentMixSemantics =>
      'Carregando mix de formas de pagamento…';

  @override
  String get overviewLoadingPaymentBarSemantics =>
      'Carregando faturamento por forma de pagamento…';

  @override
  String get overviewLoadingRankingsSemantics => 'Carregando rankings…';

  @override
  String get overviewLoadingMonthlyParcelsSemantics =>
      'Carregando grafico dos ultimos 12 meses…';

  @override
  String get overviewLoadingWeekdaySalesSemantics =>
      'Carregando gráfico de vendas por dia da semana…';

  @override
  String get overviewMonthlyParcelsTitle => 'Ultimos 12 meses';

  @override
  String get overviewMonthlyParcelsSubtitle =>
      'Quantidade de vendas e total em parcelas por mes (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSalesSeriesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsAmountSeriesLabel => 'Valor em parcelas';

  @override
  String get overviewMonthlyParcelsEmpty =>
      'Sem dados mensais para este periodo.';

  @override
  String get overviewMonthlyParcelsLoadFailed =>
      'Nao foi possivel carregar o grafico mensal. Tente novamente mais tarde.';

  @override
  String get overviewMonthlyParcelsChartSemantics =>
      'Grafico dos ultimos doze meses de vendas e valor em parcelas';

  @override
  String get overviewMonthlyParcelsSubtitleValueView =>
      'Total em parcelas e quantidade de vendas por mes (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSwitchSalesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsSwitchValueLabel => 'Valor';

  @override
  String get overviewMonthlyParcelsChartSemanticsValueView =>
      'Grafico dos ultimos doze meses de valor em parcelas e vendas';

  @override
  String get overviewWeekdaySalesTitle => 'Vendas por dia da semana';

  @override
  String get overviewWeekdayRevenueTitle => 'Receita por dia da semana';

  @override
  String get overviewWeekdaySalesSubtitle =>
      'Distribuição por dia da semana no período selecionado (todas as filiais no âmbito).';

  @override
  String get overviewWeekdaySalesEmpty =>
      'Sem dados por dia da semana neste período.';

  @override
  String get overviewWeekdaySalesLoadFailed =>
      'Não foi possível carregar o gráfico por dia da semana. Tente novamente mais tarde.';

  @override
  String get overviewWeekdaySalesChartSemantics =>
      'Gráfico de vendas e valor em parcelas por dia da semana';

  @override
  String get overviewWeekdayRevenueChartSemantics =>
      'Gráfico de receita e vendas por dia da semana';

  @override
  String get overviewWeekdayChartScopeHint =>
      'Agregado em todas as filiais no âmbito selecionado.';

  @override
  String overviewWeekdaySalesTooltip(
    String weekday,
    String salesCount,
    String salesAmount,
  ) {
    return '$weekday: $salesCount vendas - $salesAmount';
  }

  @override
  String get overviewWeekdayMetricSalesCountLabel => 'Vendas';

  @override
  String get overviewWeekdayMetricSalesAmountLabel => 'Receita';

  @override
  String overviewWeekdaySalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topSalesCount,
  ) {
    return 'Total $totalSalesCount vendas e $totalSalesAmount no período selecionado. Dia com maior volume: $topWeekday, com $topSalesCount vendas.';
  }

  @override
  String overviewWeekdayRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topSalesAmount,
  ) {
    return 'Total $totalSalesAmount e $totalSalesCount vendas no período selecionado. Dia com maior valor: $topWeekday, com $topSalesAmount.';
  }

  @override
  String get overviewWeekdaySunday => 'Domingo';

  @override
  String get overviewWeekdayMonday => 'Segunda-feira';

  @override
  String get overviewWeekdayTuesday => 'Terça-feira';

  @override
  String get overviewWeekdayWednesday => 'Quarta-feira';

  @override
  String get overviewWeekdayThursday => 'Quinta-feira';

  @override
  String get overviewWeekdayFriday => 'Sexta-feira';

  @override
  String get overviewWeekdaySaturday => 'Sábado';

  @override
  String get overviewWeekdayUserSalesTitle =>
      'Vendas por dia da semana e usuário';

  @override
  String get overviewWeekdayUserRevenueTitle =>
      'Receita por dia da semana e usuário';

  @override
  String get overviewWeekdayUserSalesSubtitle =>
      'Dias da semana no eixo horizontal; cada cor é um usuário (ver legenda). Período e âmbito de filiais como no painel.';

  @override
  String get overviewWeekdayUserSalesEmpty =>
      'Sem dados por usuário e dia da semana neste período.';

  @override
  String get overviewWeekdayUserSalesLoadFailed =>
      'Não foi possível carregar o gráfico por usuário e dia da semana. Tente novamente mais tarde.';

  @override
  String get overviewWeekdayUserSalesChartSemantics =>
      'Gráfico de vendas e valor em parcelas por dia da semana e usuário';

  @override
  String get overviewWeekdayUserRevenueChartSemantics =>
      'Gráfico de receita e vendas por dia da semana e usuário';

  @override
  String get overviewWeekdayUserChartScopeHint =>
      'Agregado em todas as filiais no âmbito selecionado.';

  @override
  String get overviewWeekdayUserGroupedOthersLabel => 'Outros';

  @override
  String overviewWeekdayUserGroupedTruncationFootnote(
    int shown,
    String othersLabel,
  ) {
    return 'São mostrados os $shown usuários com totais mais altos; os restantes são somados em \"$othersLabel\".';
  }

  @override
  String overviewWeekdayUserSalesTooltip(
    String weekday,
    String userName,
    String salesCount,
    String salesAmount,
  ) {
    return '$weekday, $userName: $salesCount vendas - $salesAmount';
  }

  @override
  String overviewWeekdayUserSalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topUserName,
    String topSalesCount,
  ) {
    return 'Total $totalSalesCount vendas e $totalSalesAmount no período selecionado. Maior barra: $topWeekday, $topUserName com $topSalesCount vendas.';
  }

  @override
  String overviewWeekdayUserRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topUserName,
    String topSalesAmount,
  ) {
    return 'Total $totalSalesAmount e $totalSalesCount vendas no período selecionado. Maior barra: $topWeekday, $topUserName com $topSalesAmount.';
  }

  @override
  String get overviewLoadingWeekdayUserSalesSemantics =>
      'Carregando gráfico de vendas por dia da semana e usuário…';

  @override
  String get overviewKpiTotalRevenue => 'Faturamento total';

  @override
  String get overviewKpiSales => 'Vendas';

  @override
  String get overviewKpiAvgTicket => 'Ticket medio';

  @override
  String get overviewKpiPaymentMethodCount => 'Formas de pagamento';

  @override
  String get overviewPaymentMixTitle => 'Mix por forma de pagamento';

  @override
  String get overviewPaymentMixSubtitle =>
      'Participacao percentual no faturamento do periodo.';

  @override
  String get overviewPaymentMixDonutTotalLabel => 'TOTAL';

  @override
  String get overviewCategoryMixTitle => 'Vendas por categoria';

  @override
  String get overviewCategoryMixDonutAnnualTotalLabel => 'TOTAL ANUAL';

  @override
  String get overviewCategoryMixMoreOptionsTooltip => 'Mais opcoes';

  @override
  String get overviewCategoryMixMenuComingSoon => 'Menu em breve.';

  @override
  String get appCategoryDonutCardLoadingSemantics =>
      'Carregando grafico de categorias…';

  @override
  String appCategoryDonutCardEmptySemantics(String title) {
    return '$title, sem dados';
  }

  @override
  String appCategoryDonutCardCategoriesSemantics(String title, int count) {
    return '$title, $count categorias';
  }

  @override
  String appCategoryDonutChartSemantics(String summary) {
    return 'Grafico de rosca. $summary';
  }

  @override
  String get overviewPaymentBarTitle => 'Faturamento por forma de pagamento';

  @override
  String get overviewPaymentBarSubtitle => 'Valor total acumulado no periodo.';

  @override
  String get overviewPaymentBarEmpty =>
      'Sem faturamento por forma de pagamento neste periodo.';

  @override
  String overviewPaymentBarTooltip(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get overviewComparisonChartLoading =>
      'Carregando gráfico comparativo…';

  @override
  String get overviewComparisonBarHorizontalScrollHint =>
      'Deslize horizontalmente para ver todos os itens.';

  @override
  String get chartComparisonPlotFloorNotice =>
      'Barras muito baixas são exibidas com altura mínima para leitura. Os valores nos rótulos são exatos.';

  @override
  String get chartComparisonExtremeValueSpreadNotice =>
      'Há valores em ordens de grandeza muito diferentes; verifique unidades ou agregação se os totais parecerem incorretos.';

  @override
  String get chartComparisonLoadingDefault => 'Carregando gráfico comparativo…';

  @override
  String get chartComparisonEmptyDefault => 'Nada para comparar no momento.';

  @override
  String get chartComparisonPanGestureHint =>
      'Deslize o gráfico horizontalmente para ver mais categorias.';

  @override
  String get chartComboLoadingDefault =>
      'Carregando gráfico de barras e linha…';

  @override
  String get chartComboEmptyDefault =>
      'Sem dados combinados para este recorte.';

  @override
  String get chartComboPanGestureHint =>
      'Deslize horizontalmente no grafico para ver mais periodos.';

  @override
  String chartComboPanChartA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grafico de barras e linha, $count categorias.',
      one: 'Grafico de barras e linha, uma categoria.',
    );
    return '$_temp0 Deslize horizontalmente para ver todas.';
  }

  @override
  String chartComparisonPanChartA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gráfico de barras, $count categorias.',
      one: 'Gráfico de barras, uma categoria.',
    );
    return '$_temp0 Deslize o gráfico horizontalmente para ver todas.';
  }

  @override
  String overviewSemanticsPaymentMethodRow(String label) {
    return 'Forma de pagamento $label';
  }

  @override
  String overviewSemanticsRevenue(String amount) {
    return 'Faturamento $amount';
  }

  @override
  String overviewSemanticsSalesCount(String count) {
    return 'Vendas $count';
  }

  @override
  String overviewSemanticsAvgTicket(String amount) {
    return 'Ticket medio $amount';
  }

  @override
  String overviewSemanticsSharePercent(String value) {
    return '$value por cento';
  }

  @override
  String get overviewNoApprovedAgentsUserMessage =>
      'Nenhum agente aprovado esta disponivel para carregar a visao geral.';

  @override
  String get overviewLoadFailedUserMessage =>
      'Nao foi possivel carregar a visao geral.';

  @override
  String get overviewSaveClientTokenForAgentUserMessage =>
      'Cadastre o token do cliente para este agente para consultar dados.';

  @override
  String get clientAgentsDataSourcesEyebrow => 'Fontes de dados';

  @override
  String get clientAgentsPageTitle => 'Gestao de agentes';

  @override
  String get clientAgentsPageSubtitle =>
      'Acompanhe seus agentes aprovados, solicite novos acessos e consulte o andamento das solicitacoes.';

  @override
  String clientAgentsPendingActionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acoes para enviar',
      one: '1 acao para enviar',
    );
    return '$_temp0';
  }

  @override
  String get clientAgentsRefresh => 'Atualizar';

  @override
  String get clientAgentsSubmitRequests => 'Enviar solicitacoes';

  @override
  String get clientAgentsActionFailedTitle =>
      'Nao foi possivel concluir a acao';

  @override
  String get clientAgentsMaintenanceTitle => 'Manutencao de agentes';

  @override
  String get clientAgentsMaintenanceSubtitle =>
      'Use as abas para ver agentes aprovados, pedir novos acessos e acompanhar o historico das solicitacoes.';

  @override
  String get clientAgentsTabMyAgents => 'Meus agentes';

  @override
  String get clientAgentsTabRequestAccess => 'Solicitar acesso';

  @override
  String get clientAgentsTabRequests => 'Solicitacoes';

  @override
  String get clientAgentsLoadApprovedErrorTitle =>
      'Nao foi possivel carregar seus agentes';

  @override
  String clientAgentsEmptyApproved(String tabLabel) {
    return 'Nenhum agente aprovado no momento. Solicite acesso na aba \"$tabLabel\".';
  }

  @override
  String get clientAgentsNoTradeName => 'Sem nome fantasia';

  @override
  String get agentCatalogInactive => 'inativo';

  @override
  String get agentCatalogActive => 'ativo';

  @override
  String get agentConnectionOnline => 'online';

  @override
  String get agentConnectionOffline => 'offline';

  @override
  String get agentConnectionUnknown => 'Estado de ligação desconhecido';

  @override
  String get clientAgentsRemoveAccess => 'Remover acesso';

  @override
  String get clientAgentsApprovedBulkSelect =>
      'Selecionar para remocao em lote';

  @override
  String get clientAgentsApprovedBulkCancel => 'Cancelar selecao';

  @override
  String clientAgentsApprovedBulkRemove(int count) {
    return 'Remover selecionados ($count)';
  }

  @override
  String get clientAgentsBulkRemoveConfirmTitle =>
      'Enfileirar remocao para varios agentes?';

  @override
  String clientAgentsBulkRemoveConfirmMessage(int count) {
    return 'A remocao de acesso para $count agentes sera preparada e enviada no proximo sync.';
  }

  @override
  String get clientAgentsBulkRemoveConfirmBack => 'Voltar';

  @override
  String get clientAgentsBulkRemoveConfirmAction => 'Enfileirar remocao';

  @override
  String get clientAgentsApprovedBulkSelectAll => 'Selecionar todos';

  @override
  String get clientAgentsApprovedBulkClearSelection => 'Limpar selecao';

  @override
  String get clientAgentsRequestAccessIntro1 =>
      'Use uma ou mais linhas para solicitar acesso. Cada linha precisa de um UUID de agente; informe o client token quando o agente exigir para execucao SQL.';

  @override
  String get clientAgentsRequestAccessIntro2 =>
      'O agentId deve ser informado pelo responsavel do agente ou por um fluxo externo. Quando a solicitacao for aprovada, o agente sera liberado automaticamente para esta conta.';

  @override
  String get clientAgentsRequestAccessIntroToken =>
      'O client token fica em cache neste dispositivo enquanto a aprovacao esta pendente e e enviado ao servidor Colmeia assim que o agente for vinculado.';

  @override
  String get clientAgentsRequestAccessAddRow => 'Adicionar linha de agente';

  @override
  String get clientAgentsRequestAccessRemoveRow => 'Remover linha';

  @override
  String clientAgentsRequestAccessRowTitle(int index) {
    return 'Agente $index';
  }

  @override
  String get clientAgentsClientTokenLabel => 'Client token';

  @override
  String get clientAgentsClientTokenHint =>
      'Opcional — cache local, enviado ao servidor apos aprovacao';

  @override
  String get clientAgentsClientTokenShow => 'Mostrar token';

  @override
  String get clientAgentsClientTokenHide => 'Ocultar token';

  @override
  String get clientAgentsAgentIdsLabel => 'Agent ID';

  @override
  String get clientAgentsRequestAccessCta => 'Solicitar acesso';

  @override
  String get clientAgentsValidationNeedOneValidId =>
      'Informe pelo menos um agentId valido para continuar.';

  @override
  String clientAgentsValidationInvalidIds(String ids) {
    return 'Os seguintes agentIds sao invalidos: $ids.';
  }

  @override
  String clientAgentsValidationTokenTooLong(int limit, String ids) {
    return 'O client token deve ter no maximo $limit caracteres. Reduza para: $ids.';
  }

  @override
  String clientAgentsDuplicatedIdsNote(String ids) {
    return 'IDs duplicados foram ignorados automaticamente: $ids.';
  }

  @override
  String get clientAgentsLoadRequestsErrorTitle =>
      'Nao foi possivel carregar as solicitacoes';

  @override
  String get clientAgentsLoadPendingErrorTitle =>
      'Nao foi possivel carregar os envios pendentes';

  @override
  String get clientAgentsNoRequestsYet => 'Sem solicitacoes no momento.';

  @override
  String get clientAgentsRequestStatusPending => 'Pendente';

  @override
  String get clientAgentsRequestStatusApproved => 'Aprovado';

  @override
  String get clientAgentsRequestStatusRejected => 'Rejeitado';

  @override
  String get clientAgentsRequestStatusExpired => 'Expirado';

  @override
  String get clientAgentsRequestStatusUnknown => 'Desconhecido';

  @override
  String get clientAgentsRequestDescPending =>
      'Em analise pelo responsavel do agente.';

  @override
  String get clientAgentsRequestDescApproved =>
      'Aprovado e disponivel para esta conta.';

  @override
  String get clientAgentsRequestDescRejected =>
      'Nao foi aprovado pelo responsavel do agente.';

  @override
  String get clientAgentsRequestDescExpired =>
      'A solicitacao expirou. Envie novamente se necessario.';

  @override
  String get clientAgentsRequestDescUnknown =>
      'O status dessa solicitacao ainda nao esta disponivel.';

  @override
  String get clientAgentsPendingDescQueued => 'Pronto para envio.';

  @override
  String get clientAgentsPendingDescSyncing => 'Enviando agora.';

  @override
  String get clientAgentsPendingDescFailed =>
      'Nao foi possivel enviar. Tente novamente.';

  @override
  String get clientAgentsPendingDescSynced => 'Enviado.';

  @override
  String get clientAgentsPendingChipRequest => 'Solicitar';

  @override
  String get clientAgentsPendingChipRemove => 'Remover';

  @override
  String get clientAgentsPendingChipQueued => 'pronto para envio';

  @override
  String get clientAgentsPendingChipSyncing => 'enviando';

  @override
  String get clientAgentsPendingChipFailed => 'falhou';

  @override
  String get clientAgentsPendingChipSynced => 'enviado';

  @override
  String clientAgentsPendingSendTitle(String agentId) {
    return 'Envio pendente: $agentId';
  }

  @override
  String get clientAgentsSessionUnavailableLoad =>
      'Sessao indisponivel para carregar agentes.';

  @override
  String get clientAgentsSessionUnavailableRequest =>
      'Sessao indisponivel para solicitar acesso.';

  @override
  String get clientAgentsSessionUnavailableRemove =>
      'Sessao indisponivel para remover acesso.';

  @override
  String get clientAgentsSessionUnavailableSync =>
      'Sessao indisponivel para sincronizar pendencias.';

  @override
  String get clientAgentDetailSessionUnavailable =>
      'Sessao indisponivel para carregar o agente.';

  @override
  String get appInlineErrorRetry => 'Tentar novamente';

  @override
  String get clientAgentsNoLocalPendingToSync =>
      'Nao ha pendencias locais para sincronizar.';

  @override
  String get clientAgentsRequestBlockedFallback =>
      'Nao foi possivel registrar a solicitacao informada.';

  @override
  String clientAgentsRequestBlockedIntro(String details) {
    return 'Nenhum novo agente pode ser solicitado com os IDs informados. $details';
  }

  @override
  String clientAgentsRequestBlockedAlreadyApproved(String ids) {
    return 'Ja aprovados: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyReview(String ids) {
    return 'Ja em analise: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyQueued(String ids) {
    return 'Ja preparados para envio: $ids.';
  }

  @override
  String get clientAgentsRequestQueuedWatchingSingle =>
      'Solicitacao enviada. Vamos acompanhar a aprovacao automaticamente.';

  @override
  String clientAgentsRequestQueuedWatchingPlural(int count) {
    return '$count solicitacoes enviadas. Vamos acompanhar as aprovacoes automaticamente.';
  }

  @override
  String clientAgentsRequestQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados porque ja estavam aprovados ou em analise.';
  }

  @override
  String get clientAgentsRequestRelinkUpdatedSingle =>
      'Esse agente ja esta aprovado no servidor. A lista de agentes foi atualizada.';

  @override
  String clientAgentsRequestRelinkUpdatedPlural(int count) {
    return '$count agentes ja estavam aprovados no servidor. A lista de agentes foi atualizada.';
  }

  @override
  String clientAgentsRequestRelinkAndQueued(
    String relinkSummary,
    String queueSummary,
  ) {
    return '$relinkSummary. $queueSummary';
  }

  @override
  String get clientAgentsRelinkPendingNotCleared =>
      'Nao foi possivel limpar solicitacoes pendentes locais; elas podem ser reenviadas na proxima sincronizacao.';

  @override
  String get clientAgentsRemoveBlockedFallback =>
      'Nao foi possivel registrar a remocao informada.';

  @override
  String clientAgentsRemoveBlockedIntro(String details) {
    return 'Nenhum novo agente pode ser removido com os IDs informados. $details';
  }

  @override
  String clientAgentsRemoveBlockedNotApproved(String ids) {
    return 'Sem acesso aprovado: $ids.';
  }

  @override
  String clientAgentsRemoveBlockedAlreadyQueued(String ids) {
    return 'Remocao ja preparada para envio: $ids.';
  }

  @override
  String get clientAgentsRemoveQueuedSingle =>
      'Remocao de acesso preparada e enviada para sincronizacao.';

  @override
  String clientAgentsRemoveQueuedPlural(int count) {
    return '$count remocoes de acesso preparadas e enviadas para sincronizacao.';
  }

  @override
  String clientAgentsRemoveQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados.';
  }

  @override
  String get clientAgentsSyncSuccessSingle => '1 pendencia foi sincronizada.';

  @override
  String clientAgentsSyncSuccessPlural(int count) {
    return '$count pendencias foram sincronizadas.';
  }

  @override
  String get clientAgentsSyncSuccessNoneCompleted =>
      'A sincronizacao terminou, mas nenhuma pendencia foi aplicada.';

  @override
  String clientAgentsSyncSuccessSomeFailedSuffix(int count) {
    return ' $count acao(oes) falhou e permanece na fila para nova tentativa.';
  }

  @override
  String get clientAgentsSyncSuccessAutoSuffix =>
      ' O envio aconteceu automaticamente.';

  @override
  String get clientAgentsSyncSuccessManualSuffix =>
      ' A tela ja foi atualizada com o status mais recente.';

  @override
  String get clientAgentsSyncSuccessPollingSuffix =>
      ' Vamos acompanhar a aprovacao automaticamente.';

  @override
  String get clientAgentsSyncSuccessAlreadyApprovedSingle =>
      ' Um agente ja estava aprovado no servidor.';

  @override
  String clientAgentsSyncSuccessAlreadyApprovedPlural(int count) {
    return ' $count agentes ja estavam aprovados no servidor.';
  }

  @override
  String get clientAgentsSyncSuccessDebouncedSingle =>
      ' Uma solicitacao foi atualizada recentemente (sem novo email).';

  @override
  String clientAgentsSyncSuccessDebouncedPlural(int count) {
    return ' $count solicitacoes foram atualizadas recentemente (sem novo email).';
  }

  @override
  String clientAgentsPollApprovedSingle(String tabLabel) {
    return 'Acesso aprovado. O agente ja esta disponivel em \"$tabLabel\".';
  }

  @override
  String clientAgentsPollApprovedPlural(int count, String tabLabel) {
    return '$count acessos foram aprovados. Os agentes ja estao disponiveis em \"$tabLabel\".';
  }

  @override
  String get clientAgentsPollDeniedSingle =>
      '1 solicitacao foi encerrada sem aprovacao.';

  @override
  String clientAgentsPollDeniedPlural(int count) {
    return '$count solicitacoes foram encerradas sem aprovacao.';
  }

  @override
  String get clientAgentsPollTimeoutSingle =>
      '1 solicitacao ainda esta em analise. Atualize esta tela mais tarde para verificar o resultado.';

  @override
  String clientAgentsPollTimeoutPlural(int count) {
    return '$count solicitacoes seguem em analise e voce pode atualizar esta tela mais tarde para verificar o resultado.';
  }

  @override
  String get clientAgentsPollRemainingSingle =>
      'Ainda ha 1 solicitacao em analise.';

  @override
  String clientAgentsPollRemainingPlural(int count) {
    return 'Ainda ha $count solicitacoes em analise.';
  }

  @override
  String get clientAgentDetailEyebrow => 'Detalhe';

  @override
  String get clientAgentDetailTitle => 'Agente';

  @override
  String get clientAgentDetailSubtitle =>
      'Informacoes detalhadas do agente aprovado para esta conta.';

  @override
  String get clientAgentDetailLoadErrorTitle =>
      'Nao foi possivel carregar o agente';

  @override
  String get clientAgentFieldTradeName => 'Nome fantasia';

  @override
  String get clientAgentFieldDocument => 'Documento';

  @override
  String get clientAgentFieldCnpjCpf => 'CNPJ/CPF';

  @override
  String get clientAgentFieldEmail => 'Email';

  @override
  String get clientAgentFieldPhone => 'Telefone';

  @override
  String get clientAgentFieldCity => 'Cidade';

  @override
  String get clientAgentValueNotAvailable => 'N/A';

  @override
  String get clientAgentAddressNotProvided => 'Endereco nao informado';

  @override
  String get clientAgentDetailSectionContact => 'Contato';

  @override
  String get clientAgentDetailSectionAddress => 'Endereco';

  @override
  String get clientAgentDetailSectionNotes => 'Anotacoes';

  @override
  String get clientAgentDetailSectionRecord => 'Registro';

  @override
  String get clientAgentDetailSectionServerToken => 'Client token';

  @override
  String get clientAgentDetailSectionServerTokenSubtitle =>
      'Salvo no servidor Colmeia e encaminhado ao agente como `params.client_token` quando este cliente executa SQL via bridge. O token tambem fica em cache neste dispositivo para dashboards seguirem funcionando brevemente sem conexao.';

  @override
  String get clientAgentDetailServerTokenSave => 'Salvar token';

  @override
  String get clientAgentDetailServerTokenRemove => 'Remover token';

  @override
  String get clientAgentDetailServerTokenSaved => 'Token salvo no servidor.';

  @override
  String get clientAgentDetailServerTokenRemoved =>
      'Token removido do servidor.';

  @override
  String get clientAgentDetailServerTokenStatusConfigured =>
      'Token configurado para este agente no servidor.';

  @override
  String get clientAgentDetailServerTokenStatusMissing =>
      'Nenhum token configurado no servidor ainda.';

  @override
  String get clientAgentDetailServerTokenStatusUnknown =>
      'Status do token nao carregado — atualize a tela com acesso a internet para confirmar.';

  @override
  String get clientAgentDetailServerTokenLoadError =>
      'Nao foi possivel ler o token atual no servidor. Exibindo o ultimo valor em cache neste dispositivo, se houver.';

  @override
  String get clientAgentDetailSectionEditProfile => 'Perfil no catálogo';

  @override
  String get clientAgentDetailSaveProfile => 'Salvar perfil';

  @override
  String get clientAgentDetailProfileSaved => 'Perfil salvo no servidor.';

  @override
  String get clientAgentDetailProfileNameRequired =>
      'Informe o nome / razão social.';

  @override
  String get clientAgentFieldLegalName => 'Nome / razão social';

  @override
  String get clientAgentFieldNumber => 'Número';

  @override
  String get clientAgentFieldId => 'Agent ID';

  @override
  String get clientAgentFieldDocumentType => 'Tipo';

  @override
  String get clientAgentFieldMobile => 'Celular';

  @override
  String get clientAgentFieldStatus => 'Status';

  @override
  String get clientAgentFieldConnection => 'Conexao';

  @override
  String get clientAgentFieldNotes => 'Notas';

  @override
  String get clientAgentFieldObservation => 'Observacao';

  @override
  String get clientAgentFieldStreet => 'Rua';

  @override
  String get clientAgentFieldDistrict => 'Bairro';

  @override
  String get clientAgentFieldPostalCode => 'CEP';

  @override
  String get clientAgentFieldState => 'Estado';

  @override
  String get clientAgentFieldCreatedAt => 'Desde';

  @override
  String get clientAgentFieldUpdatedAt => 'Atualizado';

  @override
  String get clientAgentFieldProfileUpdatedAt => 'Perfil atualizado';

  @override
  String get clientAgentsFilterSheetTitle => 'Filtros de agentes';

  @override
  String get clientAgentsFilterSearchLabel => 'Buscar agente';

  @override
  String get clientAgentsFilterSearchHint => 'Nome, agentId ou nome fantasia';

  @override
  String get clientAgentsFilterConnectionLabel => 'Conexao';

  @override
  String get clientAgentsFilterConnectionOnline => 'Online';

  @override
  String get clientAgentsFilterConnectionOffline => 'Offline';

  @override
  String get clientAgentsFilterConnectionUnknown => 'Desconhecido';

  @override
  String get clientAgentsFilterCatalogLabel => 'Catalogo';

  @override
  String get clientAgentsFilterCatalogActive => 'Ativo';

  @override
  String get clientAgentsFilterCatalogInactive => 'Inativo';

  @override
  String clientAgentsFilterSummarySearch(String query) {
    return 'Busca: $query';
  }

  @override
  String clientAgentsFilterSummaryConnection(String label) {
    return 'Conexao: $label';
  }

  @override
  String clientAgentsFilterSummaryCatalog(String label) {
    return 'Catalogo: $label';
  }

  @override
  String get clientAgentsEmptyFilteredApproved =>
      'Nenhum agente corresponde aos filtros selecionados.';

  @override
  String get clientAgentsRequestsFilterSheetTitle => 'Filtros de solicitacoes';

  @override
  String get clientAgentsRequestsFilterSearchLabel => 'Buscar';

  @override
  String get clientAgentsRequestsFilterSearchHint =>
      'Nome do agente ou agent ID';

  @override
  String get clientAgentsRequestsFilterStatusLabel => 'Status da solicitacao';

  @override
  String get clientAgentsRequestsFilterPendingLabel => 'Envio pendente';

  @override
  String clientAgentsRequestsFilterSummaryRequest(String label) {
    return 'Solicitacao: $label';
  }

  @override
  String clientAgentsRequestsFilterSummaryPending(String label) {
    return 'Pendente: $label';
  }

  @override
  String get clientAgentsFiltersTooltip => 'Filtros';

  @override
  String clientAgentsFiltersTooltipActive(int count) {
    return 'Filtros ($count ativos)';
  }

  @override
  String get clientAgentsEmptyFilteredRequests =>
      'Nenhuma solicitacao corresponde aos filtros selecionados.';

  @override
  String get clientAgentsPendingFilterQueued => 'Pronto para enviar';

  @override
  String get clientAgentsPendingFilterSyncing => 'Enviando…';

  @override
  String get clientAgentsPendingFilterFailed => 'Falhou';

  @override
  String get clientAgentsPendingFilterSynced => 'Enviado';

  @override
  String get reportFiltersTitle => 'Filtros';

  @override
  String reportFiltersTitleWithContext(String title) {
    return 'Filtros - $title';
  }

  @override
  String get reportFiltersDescription =>
      'Ajuste a consulta e aplique somente os recortes que fazem sentido para esta analise.';

  @override
  String reportFiltersFieldCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campos',
      one: '1 campo',
    );
    return '$_temp0';
  }

  @override
  String reportFiltersRequiredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obrigatorios',
      one: '1 obrigatorio',
    );
    return '$_temp0';
  }

  @override
  String reportFiltersActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos',
      one: '1 ativo',
    );
    return '$_temp0';
  }

  @override
  String get reportFiltersClearAction => 'Limpar';

  @override
  String get reportFiltersApplyAction => 'Aplicar filtros';

  @override
  String get reportFiltersButton => 'Filtros';

  @override
  String reportFiltersButtonActive(int count) {
    return 'Filtros ($count ativos)';
  }

  @override
  String get reportFiltersClearTooltip => 'Limpar';

  @override
  String get reportFiltersClearAllTooltip => 'Limpar filtros';

  @override
  String get reportFiltersAdvancedButton => 'Filtros avancados';

  @override
  String get reportInlineFiltersHint => 'Filtrar...';

  @override
  String get reportInlineFiltersAllOption => 'Todos';

  @override
  String get reportInlineFiltersSelectPeriod => 'Selecionar periodo';

  @override
  String get reportInlineFiltersSelectDate => 'Selecionar data';

  @override
  String get reportFiltersAppliedSectionTitle => 'Filtros aplicados';

  @override
  String get clientAgentsErrorLoadCatalog =>
      'Nao foi possivel carregar o catalogo de agentes.';

  @override
  String get clientAgentsErrorLoadCatalogAgent =>
      'Nao foi possivel carregar este agente do catalogo.';

  @override
  String get clientAgentsErrorLoadClientAccessStatus =>
      'Nao foi possivel ler o status da solicitacao de acesso.';

  @override
  String get clientAgentsErrorLoadApproved =>
      'Nao foi possivel carregar os agentes aprovados para esta conta.';

  @override
  String get clientAgentsErrorLoadAgentDetail =>
      'Nao foi possivel carregar os dados do agente.';

  @override
  String get clientAgentsErrorProbeApproved =>
      'Nao foi possivel verificar se o agente ja esta ligado a esta conta.';

  @override
  String get clientAgentsErrorLoadAccessRequests =>
      'Nao foi possivel carregar o historico de solicitacoes.';

  @override
  String get clientAgentsErrorReadPending =>
      'Nao foi possivel carregar as acoes pendentes de sincronizacao.';

  @override
  String get clientAgentsErrorQueueRequest =>
      'Nao foi possivel registrar a solicitacao para sincronizacao.';

  @override
  String get clientAgentsErrorQueueRemove =>
      'Nao foi possivel registrar a remocao para sincronizacao.';

  @override
  String get clientAgentsErrorSyncAction =>
      'Nao foi possivel sincronizar a alteracao do agente.';

  @override
  String get clientAgentsErrorSyncPending =>
      'Nao foi possivel sincronizar as acoes pendentes de agentes.';

  @override
  String get clientAgentsErrorGetClientAgentToken =>
      'Nao foi possivel ler o token do agente no servidor.';

  @override
  String get clientAgentsErrorSaveClientAgentToken =>
      'Nao foi possivel salvar o token do agente no servidor.';

  @override
  String get clientAgentsErrorRemoveClientAgentToken =>
      'Nao foi possivel remover o token do agente no servidor.';

  @override
  String get clientAgentsErrorAgentDocumentConflict =>
      'Este CPF/CNPJ ja esta vinculado a outro agente no catalogo. Para alterar o vinculo, entre em contato com o suporte.';

  @override
  String get agentSqlErrorAuthenticationFailed =>
      'A autenticacao para consultar este agente e invalida ou expirou.';

  @override
  String get agentSqlErrorPermissionDenied =>
      'Voce nao tem permissao para consultar estes dados neste agente.';

  @override
  String get agentSqlErrorTransportTimeout =>
      'O agente demorou mais do que o esperado para responder. Tente novamente.';

  @override
  String get agentSqlErrorNetworkError =>
      'Nao foi possivel alcancar o agente agora. Tente novamente.';

  @override
  String get agentSqlErrorRateLimited =>
      'Muitas tentativas de consulta foram feitas. Aguarde um instante e tente novamente.';

  @override
  String get agentSqlErrorValidationFailed =>
      'A consulta informada e invalida.';

  @override
  String get agentSqlErrorExecutionFailed =>
      'Nao foi possivel executar a consulta.';

  @override
  String get agentSqlErrorTransactionFailed =>
      'Nao foi possivel concluir a transacao da consulta.';

  @override
  String get agentSqlErrorConnectionPoolExhausted =>
      'O servidor esta ocupado para processar a consulta agora. Tente novamente em instantes.';

  @override
  String get agentSqlErrorResultTooLarge =>
      'A consulta retornou dados demais. Refine os filtros e tente novamente.';

  @override
  String get agentSqlErrorDatabaseConnectionFailed =>
      'Nao foi possivel conectar ao banco para executar a consulta.';

  @override
  String get agentSqlErrorQueryTimeout =>
      'A consulta demorou mais do que o esperado.';

  @override
  String get agentSqlErrorInvalidDatabaseConfig =>
      'A configuracao de acesso ao banco deste agente esta invalida.';

  @override
  String get agentSqlErrorExecutionNotFound =>
      'A execucao solicitada nao foi encontrada.';

  @override
  String get agentSqlErrorExecutionCancelled => 'A consulta foi cancelada.';

  @override
  String get agentSqlErrorGeneric =>
      'Nao foi possivel concluir a consulta no agente.';

  @override
  String get formsDemoEyebrow => 'Formularios';

  @override
  String get formsDemoTitle => 'Campos compartilhados';

  @override
  String get formsDemoIntroSubtitle =>
      'Validacao, estados habilitado/desabilitado, date pickers no Form, FormBuilder como nos relatorios e agrupamentos.';

  @override
  String get formsDemoFieldLibraryOverline => 'Biblioteca de campos';

  @override
  String get formsDemoSharedFormControlsTitle =>
      'Campos de formulario compartilhados';

  @override
  String get formsDemoPreviewBadge => 'Preview';

  @override
  String get formsDemoShowcaseSubtitle =>
      'Campos base, seletores e wrappers de calendario no mesmo ritmo visual do sistema.';

  @override
  String get formsDemoFieldsEnabledLabel => 'Campos habilitados';

  @override
  String get formsDemoShowcaseFieldsEnabledHelper =>
      'Ativa ou desativa toda a superficie de exemplos abaixo.';

  @override
  String get formsDemoFormStateTitle => 'Estado do formulario';

  @override
  String get formsDemoFormStateSubtitle =>
      'Desligue para inspecionar campos desabilitados.';

  @override
  String get formsDemoFormStateFieldsEnabledHelper =>
      'Aplica o estado disabled em todos os exemplos abaixo.';

  @override
  String get formsDemoTextEmailPasswordTitle => 'AppTextField, e-mail e senha';

  @override
  String get formsDemoTextEmailPasswordSubtitle =>
      'Dados fake; enviar dispara validacao.';

  @override
  String get formsDemoFullNameLabel => 'Nome completo';

  @override
  String get formsDemoFullNameHint => 'Como no cadastro';

  @override
  String get formsDemoNameValidatorMinLength =>
      'Informe pelo menos 3 caracteres.';

  @override
  String get formsDemoCorporateEmailLabel => 'E-mail corporativo';

  @override
  String get formsDemoPasswordLabel => 'Senha';

  @override
  String get formsDemoNotesLabel => 'Observacoes';

  @override
  String get formsDemoNotesHint => 'Opcional';

  @override
  String get formsDemoDatePickersFormTitle => 'Date pickers no Form';

  @override
  String get formsDemoDatePickersFormSubtitle =>
      'Form nativo + FormField. Toque em Aplicar no sheet para confirmar; fechar sem aplicar mantem o valor. Remover limpa de forma explicita.';

  @override
  String get formsDemoReferenceDateLabel => 'Data de referencia';

  @override
  String get formsDemoReferenceDateHelper =>
      'Abre em bottom sheet com calendario estilizado.';

  @override
  String get formsDemoSelectReferenceDateTitle =>
      'Selecionar data de referencia';

  @override
  String get formsDemoReferenceDateRequiredError =>
      'Selecione a data de referencia.';

  @override
  String get formsDemoAssessmentPeriodLabel => 'Periodo de captacao desejado';

  @override
  String get formsDemoAssessmentPeriodHelper =>
      'Ideal para filtros e consultas analiticas.';

  @override
  String get formsDemoSelectPeriodTitle => 'Selecionar periodo';

  @override
  String get formsDemoAssessmentPeriodRequiredError =>
      'Selecione o periodo de captacao completo.';

  @override
  String get formsDemoDateRangeMiddle => ' a ';

  @override
  String get formsDemoCheckboxTitle => 'AppCheckboxField';

  @override
  String get formsDemoCheckboxSubtitle => 'Aceite ficticio.';

  @override
  String get formsDemoCheckboxLabel => 'Receber resumo semanal por e-mail';

  @override
  String get formsDemoCheckboxHelper =>
      'Envia alertas, resumos e atualizacoes de indicadores.';

  @override
  String get formsDemoRadioCompactTitle => 'AppRadioGroup compacto';

  @override
  String get formsDemoRadioCompactSubtitle =>
      'Selecao unica no padrao inline do design system.';

  @override
  String get formsDemoPeriodDaily => 'Diario';

  @override
  String get formsDemoPeriodMonthly => 'Mensal';

  @override
  String get formsDemoPeriodQuarterly => 'Trimestral';

  @override
  String get formsDemoChoiceChipTitle => 'AppChoiceChip';

  @override
  String get formsDemoChoiceChipSubtitle =>
      'Selecao pontual em chips para contexto, loja ou escopo.';

  @override
  String get formsDemoScopeHeadquarters => 'Matriz';

  @override
  String get formsDemoScopeStoreCenter => 'Loja Centro';

  @override
  String get formsDemoScopeStoreSouth => 'Loja Sul';

  @override
  String get formsDemoDropdownMenusTitle => 'Dropdown menus';

  @override
  String get formsDemoDropdownMenusSubtitle =>
      'Selecao unica e multi-select search no mesmo padrao visual das referencias light/dark.';

  @override
  String get formsDemoStandardSelectLabel => 'Standard Select';

  @override
  String get formsDemoSelectHiveNodeHint => 'Select Hive Node...';

  @override
  String get formsDemoMultiSelectSearchLabel => 'Multi-Select Search';

  @override
  String get formsDemoHiveNodeAlphaCore => 'Alpha Core';

  @override
  String get formsDemoHiveNodeDeltaNode => 'Delta Node';

  @override
  String get formsDemoHiveNodeSigmaGrid => 'Sigma Grid';

  @override
  String get formsDemoTagAnalytics => 'Analytics';

  @override
  String get formsDemoTagCloud => 'Cloud';

  @override
  String get formsDemoTagAutomation => 'Automation';

  @override
  String get formsDemoTagSecurity => 'Security';

  @override
  String get formsDemoFormBuilderSectionTitle =>
      'FormBuilder + dropdowns e datas';

  @override
  String get formsDemoFormBuilderSectionSubtitle =>
      'Mesmos wrappers dos relatorios: dropdown, multi-select e os mesmos date pickers da secao Form acima (FormBuilderField + AppFormBuilderDate*).';

  @override
  String get formsDemoFormBuilderNodeLabel => 'Select node (FormBuilder)';

  @override
  String get formsDemoFormBuilderNodeHelper =>
      'Selecao unica com o wrapper compartilhado.';

  @override
  String get formsDemoFormBuilderTagsLabel => 'Tags (FormBuilder)';

  @override
  String get formsDemoFormBuilderTagsHelper =>
      'Busca inline com chips removiveis.';

  @override
  String get formsDemoFormBuilderDateRequiredLabel =>
      'Data obrigatoria (FormBuilder)';

  @override
  String get formsDemoFormBuilderDateRequiredHelper =>
      'Validacao com form_builder_validators.';

  @override
  String get formsDemoFormBuilderSelectDateTitle =>
      'Selecionar data (FormBuilder)';

  @override
  String get formsDemoFormBuilderRangeLabel => 'Periodo (FormBuilder)';

  @override
  String get formsDemoFormBuilderRangeHelper => 'Opcional nesta demo.';

  @override
  String get formsDemoFormBuilderSelectRangeTitle =>
      'Selecionar periodo (FormBuilder)';

  @override
  String get formsDemoValidateFormBuilderButton => 'Validar FormBuilder';

  @override
  String get formsDemoValidateFormSubmitButton => 'Validar envio (Form)';

  @override
  String formsDemoFormValidSnackbar(String refLabel, String rangeLabel) {
    return 'Formulario valido (demo fake). Ref: $refLabel. Periodo: $rangeLabel.';
  }

  @override
  String formsDemoFormBuilderValidSnackbar(
    String dateLabel,
    String rangeLabel,
  ) {
    return 'FormBuilder valido (demo fake). Data: $dateLabel. Periodo: $rangeLabel.';
  }

  @override
  String get formsDemoLegendInput => 'Input';

  @override
  String get formsDemoLegendSelection => 'Selection';

  @override
  String get formsDemoLegendDate => 'Date';

  @override
  String get formsDemoLegendFormBuilder => 'FormBuilder';

  @override
  String get datePickerPlaceholderSelectDate => 'Selecione uma data';

  @override
  String get dateRangePickerPlaceholderSelectPeriod => 'Selecione o periodo';

  @override
  String get datePickerSheetDefaultTitle => 'Selecionar data';

  @override
  String get dateRangePickerSheetDefaultTitle => 'Selecionar periodo';

  @override
  String get datePickerClearSelectionTooltip => 'Limpar selecao';

  @override
  String get datePickerSheetRemoveDate => 'Remover data';

  @override
  String get dateRangePickerSheetRemovePeriod => 'Remover periodo';

  @override
  String get datePickerSheetCloseTooltip => 'Fechar';

  @override
  String get datePickerSheetApply => 'Aplicar';

  @override
  String get datePickerSemanticsFallbackLabel => 'Data';

  @override
  String get dateRangePickerSemanticsFallbackLabel => 'Periodo';

  @override
  String get areaTrendDemoIntroEyebrow => 'Graficos de area';

  @override
  String get areaTrendDemoIntroTitle => 'AppAreaTrendChart';

  @override
  String get areaTrendDemoIntroSubtitle =>
      'Tendencia temporal com area preenchida: gradiente, marcadores, zoom, variantes de estilo e evento estruturado por serie/ponto.';

  @override
  String get areaTrendDemoShowcaseTitle =>
      'Tendencia temporal com preenchimento';

  @override
  String get areaTrendDemoShowcaseSubtitle =>
      'Grafico de area para volume, crescimento e comparativos no tempo, com boa leitura de massa e intensidade.';

  @override
  String get areaTrendDemoShowcaseBadge => 'Trend';

  @override
  String get areaTrendDemoShowcaseHighlightTimeSeries => 'Serie temporal';

  @override
  String get areaTrendDemoShowcaseHighlightGradientMarkers =>
      'Gradiente e markers';

  @override
  String get areaTrendDemoShowcaseHighlightMultiseries => 'Multiseries';

  @override
  String get areaTrendDemoS01Title => '1. Faturamento semanal';

  @override
  String get areaTrendDemoS01Subtitle =>
      'Area com gradiente, eixo formatado, tooltip e tap.';

  @override
  String get areaTrendDemoS02Title => '2. Com marcadores de ponto';

  @override
  String get areaTrendDemoS02Subtitle =>
      'Cada ponto recebe um marcador visivel.';

  @override
  String get areaTrendDemoS03Title => '3. Sem gradiente (area solida)';

  @override
  String get areaTrendDemoS03Subtitle =>
      'showGradientFill: false para area plana.';

  @override
  String get areaTrendDemoS04Title => '4. Pedidos por hora';

  @override
  String get areaTrendDemoS04Subtitle =>
      'Pico operacional do dia — escala de unidades.';

  @override
  String get areaTrendDemoS05Title => '5. Compacto sem shell';

  @override
  String get areaTrendDemoS05Subtitle =>
      'Preset compact, sem eixos e sem shell interno.';

  @override
  String get areaTrendDemoS06Title => '6. Estado de loading';

  @override
  String get areaTrendDemoS07Title => '7. Estado vazio';

  @override
  String get areaTrendDemoEmptyMessage =>
      'Sem dados para o periodo selecionado.';

  @override
  String get areaTrendDemoS08Title => '8. Multi-series (comparativo de lojas)';

  @override
  String get areaTrendDemoS08Subtitle =>
      'Tres lojas sobrepostas com palette automatica. Legenda ativada.';

  @override
  String get areaTrendDemoS09Title => '9. Multi-series com trackball';

  @override
  String get areaTrendDemoS09Subtitle =>
      'Toque na area para ver os valores de todas as series na mesma posicao do eixo X.';

  @override
  String get areaTrendDemoS10Title => '10. Cores por entrada';

  @override
  String get areaTrendDemoS10Subtitle =>
      'Cor customizada por AppAreaTrendEntry.';

  @override
  String get areaTrendDemoSeriesRevenue => 'Faturamento';

  @override
  String get areaTrendDemoSeriesTarget => 'Meta';

  @override
  String get areaTrendDemoStoreCenter => 'Centro';

  @override
  String get areaTrendDemoStoreNorth => 'Norte';

  @override
  String get areaTrendDemoStoreSouth => 'Sul';

  @override
  String get areaTrendDemoDefaultSeriesName => 'serie principal';

  @override
  String areaTrendDemoTapSnackbar(
    String seriesLabel,
    String pointLabel,
    String valueLabel,
  ) {
    return 'Area: $seriesLabel • $pointLabel = $valueLabel';
  }

  @override
  String areaTrendDemoA11ySection(int sectionIndex, String sectionTitle) {
    return 'Demonstracao de grafico $sectionIndex: $sectionTitle';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get shellNavDashboardLabel => 'Visao geral';

  @override
  String get shellNavDashboardSubtitle => 'Resumo operacional e KPIs';

  @override
  String get shellNavAgentsLabel => 'Agentes';

  @override
  String get shellNavAgentsSubtitle => 'Fontes de dados e acessos';

  @override
  String get shellNavSettingsLabel => 'Perfil';

  @override
  String get shellNavSettingsSubtitle => 'Conta e preferencias';

  @override
  String get shellNavSalesLabel => 'Vendas';

  @override
  String get shellNavSalesSubtitle =>
      'Pedidos, receita e indicadores comerciais';

  @override
  String get shellNavReturnsLabel => 'Devolucoes';

  @override
  String get shellNavReturnsSubtitle => 'Devolucoes, trocas e notas de credito';

  @override
  String get shellNavFinanceLabel => 'Financeiro';

  @override
  String get shellNavFinanceSubtitle =>
      'Fluxo de caixa, contas a receber e a pagar';

  @override
  String get shellNavPurchasesLabel => 'Compras';

  @override
  String get shellNavPurchasesSubtitle => 'Fornecedores e pedidos de compra';

  @override
  String get shellNavInventoryLabel => 'Estoque';

  @override
  String get shellNavInventorySubtitle => 'Niveis de estoque e movimentacoes';

  @override
  String get shellPlaceholderUnderConstructionTitle => 'Em construcao';

  @override
  String get shellPlaceholderUnderConstructionBody =>
      'Esta secao estara disponivel em uma atualizacao futura.';

  @override
  String get shellAppBrandName => 'Colmeia';

  @override
  String get shellOpenSettingsSemantics => 'Abrir configuracoes';

  @override
  String get shellOpenProfileSemantics => 'Abrir perfil e conta';

  @override
  String get shellNavSignOut => 'Sair';

  @override
  String get shellNavSigningOut => 'Saindo...';

  @override
  String get shellNavSignOutSemanticsLoading => 'Encerrando sessao';

  @override
  String get shellSignOutDialogTitle => 'Sair da conta?';

  @override
  String get shellSignOutDialogConfirm => 'Sair';

  @override
  String get shellSignOutDialogMessage =>
      'Voce precisara entrar novamente para acessar os dados.';

  @override
  String get shellNavMainSemantics => 'Navegacao principal';

  @override
  String get userPermissionViewDashboard => 'Visao geral';

  @override
  String get userPermissionManageAgents => 'Gestao de agentes';

  @override
  String get userPermissionViewSales => 'Vendas (acesso ao modulo)';

  @override
  String get userPermissionViewReturns => 'Devolucoes (acesso ao modulo)';

  @override
  String get userPermissionViewFinance => 'Financeiro (acesso ao modulo)';

  @override
  String get userPermissionViewPurchases => 'Compras (acesso ao modulo)';

  @override
  String get userPermissionViewInventory => 'Estoque (acesso ao modulo)';

  @override
  String get dashboardPartialAgentQueriesTitle =>
      'Dados da visao geral incompletos';

  @override
  String get dashboardPartialAgentQueriesMessage =>
      'Alguns agentes aprovados nao retornaram dados. Os totais podem estar incompletos.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Agentes sem token de cliente salvo';

  @override
  String get dashboardMissingClientTokenMessage =>
      'Estes agentes aprovados foram ignorados porque nao ha token de cliente local. Cadastre o token na tela do agente para incluir os dados.';

  @override
  String get overviewResumoUnknownPaymentMethod =>
      'Forma de pagamento não informada';

  @override
  String get overviewResumoUnknownUserName => 'Utilizador não informado';

  @override
  String get dashboardSetupRequiredTitle =>
      'Salve um token de cliente para carregar os dados';

  @override
  String get dashboardSetupRequiredMessage =>
      'Nenhum agente com acesso aprovado possui token de cliente salvo neste dispositivo. Abra a gestao de agentes para cadastrar o token e liberar a consulta da visao geral.';

  @override
  String dashboardViewAffectedAgentsList(int count) {
    return 'Ver lista ($count)';
  }

  @override
  String get dashboardAffectedAgentsSheetTitlePartialFailure =>
      'Agentes que nao retornaram dados';

  @override
  String get dashboardAffectedAgentsSheetTitleMissingToken =>
      'Agentes sem token de cliente salvo';

  @override
  String get dashboardAffectedAgentsSheetTitleSetupRequired =>
      'Agentes aprovados sem token de cliente neste dispositivo';

  @override
  String get dashboardMultiAgentAggregationTitle => 'Varios agentes';

  @override
  String get dashboardMultiAgentAggregationMessage =>
      'Este resumo agrega dados de varios agentes aprovados. Se houver sobreposicao entre bases, os totais podem ficar acima de uma unica fonte.';

  @override
  String get dashboardPaymentSummaryTitle => 'Resumo por forma de pagamento';

  @override
  String get dashboardPaymentSummarySubtitle =>
      'Detalhamento de vendas, ticket medio e participacao.';

  @override
  String get dashboardPaymentSummaryEmptyTitle => 'Sem formas de pagamento';

  @override
  String get dashboardPaymentSummaryEmptyMessage =>
      'Nao ha linhas de forma de pagamento para este periodo.';

  @override
  String get dashboardPaymentSummaryHeaderRevenueAbbr => 'FATURAM.';

  @override
  String get dashboardPaymentSummaryTooltipRevenueAbbr =>
      'Faturamento no periodo selecionado';

  @override
  String get dashboardPaymentSummaryHeaderParticipationAbbr => 'PARTIC.';

  @override
  String get dashboardPaymentSummaryTooltipParticipationAbbr =>
      'Participacao percentual no faturamento total';

  @override
  String get dashboardPaymentSummaryHeaderSales => 'VENDAS';

  @override
  String get dashboardPaymentSummaryHeaderAvgTicket => 'TICKET\nMEDIO';

  @override
  String get dashboardPaymentSummaryLoadingSemantics =>
      'Carregando resumo por forma de pagamento…';

  @override
  String get dashboardHomeFiltersAgentsLabel => 'AGENTES';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visao geral para listar os agentes.';

  @override
  String get dashboardHomeFiltersYearMonthLabel => 'ANO / MÊS';

  @override
  String get dashboardHomeFiltersCurrentMonth => 'Mês atual';

  @override
  String get dashboardHomeFiltersPeriodLast30Days => 'Últimos 30 dias';

  @override
  String get dashboardHomeFiltersReferenceRangeLabel => 'PERÍODO';

  @override
  String dashboardHomeFiltersReferenceRangeHelper(int maxDays) {
    return 'Opcional. Escolha início e fim — o intervalo pode atravessar vários meses (no máximo $maxDays dias corridos). Totais e rankings seguem esse período. O gráfico mensal continua com 12 meses até o mês do último dia.';
  }

  @override
  String get dashboardHomeFiltersReferenceRangePickerTitle =>
      'Selecionar período';

  @override
  String get dashboardHomeFiltersYearMonthCustomDisplay => 'Personalizado';

  @override
  String dashboardHomeFiltersReferenceRangeMaxDurationSnackbar(int maxDays) {
    return 'O intervalo selecionado não pode passar de $maxDays dias corridos.';
  }

  @override
  String get overviewPeriodTagCustomRangePrefix => 'Período';

  @override
  String overviewAgentFilterAllAgentsSummary(int count) {
    return 'Todos os agentes ($count)';
  }

  @override
  String overviewAgentFilterSelectedCount(int count) {
    return '$count agentes selecionados';
  }

  @override
  String get overviewAgentFilterRefineAction => 'Refinar seleção';

  @override
  String get overviewAgentFilterEditAction => 'Editar';

  @override
  String get overviewAgentFilterSheetTitle => 'Selecionar agentes';

  @override
  String get overviewAgentFilterSheetSearchHint => 'Buscar agentes…';

  @override
  String get overviewAgentFilterSelectMatching =>
      'Selecionar todos os filtrados';

  @override
  String get overviewAgentFilterApply => 'Aplicar';

  @override
  String get overviewAgentFilterCancel => 'Cancelar';

  @override
  String get overviewAgentFilterNoSearchResults =>
      'Nenhum agente corresponde à busca.';

  @override
  String get overviewAgentFilterMissingClientTokenBanner =>
      'Agentes sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get overviewAgentFilterMissingClientTokenRowSubtitle =>
      'Sem token neste dispositivo — consultas SQL são ignoradas.';

  @override
  String get chartCategoryDonutEmptyForFilter =>
      'Sem dados de categorias para este recorte.';

  @override
  String get dashboardAgentRankingTitle => 'Ranking por agente';

  @override
  String get dashboardAgentRankingSubtitle =>
      'Faturamento total por agente no periodo.';

  @override
  String get dashboardUserRankingTitle => 'Ranking por operador';

  @override
  String get dashboardUserRankingSubtitle =>
      'Faturamento por operador no periodo.';

  @override
  String get overviewAgentRankingEmpty =>
      'Sem faturamento por agente neste período.';

  @override
  String get overviewUserRankingEmpty =>
      'Sem faturamento por operador neste período.';

  @override
  String get overviewDefaultGreetingName => 'Gestor';

  @override
  String overviewGreetingEyebrow(String name) {
    return 'Olá, $name';
  }

  @override
  String get overviewHomeSubtitle =>
      'Resumo consolidado dos agentes aprovados (todas as filiais conectadas).';

  @override
  String get overviewHomeAlertsSectionTitle => 'Avisos';

  @override
  String get overviewLoadErrorTitle =>
      'Nao foi possivel carregar a visao geral';

  @override
  String get overviewStaleCacheTitle => 'Dados salvos neste aparelho';

  @override
  String get overviewStaleCacheMessage =>
      'Nao foi possivel atualizar agora. Os numeros abaixo refletem o ultimo resumo obtido com sucesso.';

  @override
  String get overviewLoadingPaymentKpisSemantics =>
      'Carregando indicadores de pagamento…';

  @override
  String get overviewLoadingPaymentMixSemantics =>
      'Carregando mix de formas de pagamento…';

  @override
  String get overviewLoadingPaymentBarSemantics =>
      'Carregando faturamento por forma de pagamento…';

  @override
  String get overviewLoadingRankingsSemantics => 'Carregando rankings…';

  @override
  String get overviewLoadingMonthlyParcelsSemantics =>
      'Carregando grafico dos ultimos 12 meses…';

  @override
  String get overviewLoadingWeekdaySalesSemantics =>
      'Carregando gráfico de vendas por dia da semana…';

  @override
  String get overviewMonthlyParcelsTitle => 'Ultimos 12 meses';

  @override
  String get overviewMonthlyParcelsSubtitle =>
      'Quantidade de vendas e total em parcelas por mes (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSalesSeriesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsAmountSeriesLabel => 'Valor em parcelas';

  @override
  String get overviewMonthlyParcelsEmpty =>
      'Sem dados mensais para este periodo.';

  @override
  String get overviewMonthlyParcelsLoadFailed =>
      'Nao foi possivel carregar o grafico mensal. Tente novamente mais tarde.';

  @override
  String get overviewMonthlyParcelsChartSemantics =>
      'Grafico dos ultimos doze meses de vendas e valor em parcelas';

  @override
  String get overviewMonthlyParcelsSubtitleValueView =>
      'Total em parcelas e quantidade de vendas por mes (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSwitchSalesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsSwitchValueLabel => 'Valor';

  @override
  String get overviewMonthlyParcelsChartSemanticsValueView =>
      'Grafico dos ultimos doze meses de valor em parcelas e vendas';

  @override
  String get overviewWeekdaySalesTitle => 'Vendas por dia da semana';

  @override
  String get overviewWeekdayRevenueTitle => 'Receita por dia da semana';

  @override
  String get overviewWeekdaySalesSubtitle =>
      'Distribuição por dia da semana no período selecionado (todas as filiais no âmbito).';

  @override
  String get overviewWeekdaySalesEmpty =>
      'Sem dados por dia da semana neste período.';

  @override
  String get overviewWeekdaySalesLoadFailed =>
      'Não foi possível carregar o gráfico por dia da semana. Tente novamente mais tarde.';

  @override
  String get overviewWeekdaySalesChartSemantics =>
      'Gráfico de vendas e valor em parcelas por dia da semana';

  @override
  String get overviewWeekdayRevenueChartSemantics =>
      'Gráfico de receita e vendas por dia da semana';

  @override
  String get overviewWeekdayChartScopeHint =>
      'Agregado em todas as filiais no âmbito selecionado.';

  @override
  String overviewWeekdaySalesTooltip(
    String weekday,
    String salesCount,
    String salesAmount,
  ) {
    return '$weekday: $salesCount vendas - $salesAmount';
  }

  @override
  String get overviewWeekdayMetricSalesCountLabel => 'Vendas';

  @override
  String get overviewWeekdayMetricSalesAmountLabel => 'Receita';

  @override
  String overviewWeekdaySalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topSalesCount,
  ) {
    return 'Total $totalSalesCount vendas e $totalSalesAmount no período selecionado. Dia com maior volume: $topWeekday, com $topSalesCount vendas.';
  }

  @override
  String overviewWeekdayRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topSalesAmount,
  ) {
    return 'Total $totalSalesAmount e $totalSalesCount vendas no período selecionado. Dia com maior valor: $topWeekday, com $topSalesAmount.';
  }

  @override
  String get overviewWeekdaySunday => 'Domingo';

  @override
  String get overviewWeekdayMonday => 'Segunda-feira';

  @override
  String get overviewWeekdayTuesday => 'Terça-feira';

  @override
  String get overviewWeekdayWednesday => 'Quarta-feira';

  @override
  String get overviewWeekdayThursday => 'Quinta-feira';

  @override
  String get overviewWeekdayFriday => 'Sexta-feira';

  @override
  String get overviewWeekdaySaturday => 'Sábado';

  @override
  String get overviewWeekdayUserSalesTitle =>
      'Vendas por dia da semana e usuário';

  @override
  String get overviewWeekdayUserRevenueTitle =>
      'Receita por dia da semana e usuário';

  @override
  String get overviewWeekdayUserSalesSubtitle =>
      'Dias da semana no eixo horizontal; cada cor é um usuário (ver legenda). Período e âmbito de filiais como no painel.';

  @override
  String get overviewWeekdayUserSalesEmpty =>
      'Sem dados por usuário e dia da semana neste período.';

  @override
  String get overviewWeekdayUserSalesLoadFailed =>
      'Não foi possível carregar o gráfico por usuário e dia da semana. Tente novamente mais tarde.';

  @override
  String get overviewWeekdayUserSalesChartSemantics =>
      'Gráfico de vendas e valor em parcelas por dia da semana e usuário';

  @override
  String get overviewWeekdayUserRevenueChartSemantics =>
      'Gráfico de receita e vendas por dia da semana e usuário';

  @override
  String get overviewWeekdayUserChartScopeHint =>
      'Agregado em todas as filiais no âmbito selecionado.';

  @override
  String get overviewWeekdayUserGroupedOthersLabel => 'Outros';

  @override
  String overviewWeekdayUserGroupedTruncationFootnote(
    int shown,
    String othersLabel,
  ) {
    return 'São mostrados os $shown usuários com totais mais altos; os restantes são somados em \"$othersLabel\".';
  }

  @override
  String overviewWeekdayUserSalesTooltip(
    String weekday,
    String userName,
    String salesCount,
    String salesAmount,
  ) {
    return '$weekday, $userName: $salesCount vendas - $salesAmount';
  }

  @override
  String overviewWeekdayUserSalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topUserName,
    String topSalesCount,
  ) {
    return 'Total $totalSalesCount vendas e $totalSalesAmount no período selecionado. Maior barra: $topWeekday, $topUserName com $topSalesCount vendas.';
  }

  @override
  String overviewWeekdayUserRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topUserName,
    String topSalesAmount,
  ) {
    return 'Total $totalSalesAmount e $totalSalesCount vendas no período selecionado. Maior barra: $topWeekday, $topUserName com $topSalesAmount.';
  }

  @override
  String get overviewLoadingWeekdayUserSalesSemantics =>
      'Carregando gráfico de vendas por dia da semana e usuário…';

  @override
  String get overviewKpiTotalRevenue => 'Faturamento total';

  @override
  String get overviewKpiSales => 'Vendas';

  @override
  String get overviewKpiAvgTicket => 'Ticket medio';

  @override
  String get overviewKpiPaymentMethodCount => 'Formas de pagamento';

  @override
  String get overviewPaymentMixTitle => 'Mix por forma de pagamento';

  @override
  String get overviewPaymentMixSubtitle =>
      'Participacao percentual no faturamento do periodo.';

  @override
  String get overviewPaymentMixDonutTotalLabel => 'TOTAL';

  @override
  String get overviewCategoryMixTitle => 'Vendas por categoria';

  @override
  String get overviewCategoryMixDonutAnnualTotalLabel => 'TOTAL ANUAL';

  @override
  String get overviewCategoryMixMoreOptionsTooltip => 'Mais opcoes';

  @override
  String get overviewCategoryMixMenuComingSoon => 'Menu em breve.';

  @override
  String get appCategoryDonutCardLoadingSemantics =>
      'Carregando grafico de categorias…';

  @override
  String appCategoryDonutCardEmptySemantics(String title) {
    return '$title, sem dados';
  }

  @override
  String appCategoryDonutCardCategoriesSemantics(String title, int count) {
    return '$title, $count categorias';
  }

  @override
  String appCategoryDonutChartSemantics(String summary) {
    return 'Grafico de rosca. $summary';
  }

  @override
  String get overviewPaymentBarTitle => 'Faturamento por forma de pagamento';

  @override
  String get overviewPaymentBarSubtitle => 'Valor total acumulado no periodo.';

  @override
  String get overviewPaymentBarEmpty =>
      'Sem faturamento por forma de pagamento neste periodo.';

  @override
  String overviewPaymentBarTooltip(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get overviewComparisonChartLoading =>
      'Carregando gráfico comparativo…';

  @override
  String get overviewComparisonBarHorizontalScrollHint =>
      'Deslize horizontalmente para ver todos os itens.';

  @override
  String get chartComparisonPlotFloorNotice =>
      'Barras muito baixas são exibidas com altura mínima para leitura. Os valores nos rótulos são exatos.';

  @override
  String get chartComparisonExtremeValueSpreadNotice =>
      'Há valores em ordens de grandeza muito diferentes; verifique unidades ou agregação se os totais parecerem incorretos.';

  @override
  String get chartComparisonLoadingDefault => 'Carregando gráfico comparativo…';

  @override
  String get chartComparisonEmptyDefault => 'Nada para comparar no momento.';

  @override
  String get chartComparisonPanGestureHint =>
      'Deslize o gráfico horizontalmente para ver mais categorias.';

  @override
  String get chartComboLoadingDefault =>
      'Carregando gráfico de barras e linha…';

  @override
  String get chartComboEmptyDefault =>
      'Sem dados combinados para este recorte.';

  @override
  String get chartComboPanGestureHint =>
      'Deslize horizontalmente no grafico para ver mais periodos.';

  @override
  String chartComboPanChartA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grafico de barras e linha, $count categorias.',
      one: 'Grafico de barras e linha, uma categoria.',
    );
    return '$_temp0 Deslize horizontalmente para ver todas.';
  }

  @override
  String chartComparisonPanChartA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gráfico de barras, $count categorias.',
      one: 'Gráfico de barras, uma categoria.',
    );
    return '$_temp0 Deslize o gráfico horizontalmente para ver todas.';
  }

  @override
  String overviewSemanticsPaymentMethodRow(String label) {
    return 'Forma de pagamento $label';
  }

  @override
  String overviewSemanticsRevenue(String amount) {
    return 'Faturamento $amount';
  }

  @override
  String overviewSemanticsSalesCount(String count) {
    return 'Vendas $count';
  }

  @override
  String overviewSemanticsAvgTicket(String amount) {
    return 'Ticket medio $amount';
  }

  @override
  String overviewSemanticsSharePercent(String value) {
    return '$value por cento';
  }

  @override
  String get overviewNoApprovedAgentsUserMessage =>
      'Nenhum agente aprovado esta disponivel para carregar a visao geral.';

  @override
  String get overviewLoadFailedUserMessage =>
      'Nao foi possivel carregar a visao geral.';

  @override
  String get overviewSaveClientTokenForAgentUserMessage =>
      'Cadastre o token do cliente para este agente para consultar dados.';

  @override
  String get clientAgentsDataSourcesEyebrow => 'Fontes de dados';

  @override
  String get clientAgentsPageTitle => 'Gestao de agentes';

  @override
  String get clientAgentsPageSubtitle =>
      'Acompanhe seus agentes aprovados, solicite novos acessos e consulte o andamento das solicitacoes.';

  @override
  String clientAgentsPendingActionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acoes para enviar',
      one: '1 acao para enviar',
    );
    return '$_temp0';
  }

  @override
  String get clientAgentsRefresh => 'Atualizar';

  @override
  String get clientAgentsSubmitRequests => 'Enviar solicitacoes';

  @override
  String get clientAgentsActionFailedTitle =>
      'Nao foi possivel concluir a acao';

  @override
  String get clientAgentsMaintenanceTitle => 'Manutencao de agentes';

  @override
  String get clientAgentsMaintenanceSubtitle =>
      'Use as abas para ver agentes aprovados, pedir novos acessos e acompanhar o historico das solicitacoes.';

  @override
  String get clientAgentsTabMyAgents => 'Meus agentes';

  @override
  String get clientAgentsTabRequestAccess => 'Solicitar acesso';

  @override
  String get clientAgentsTabRequests => 'Solicitacoes';

  @override
  String get clientAgentsLoadApprovedErrorTitle =>
      'Nao foi possivel carregar seus agentes';

  @override
  String clientAgentsEmptyApproved(String tabLabel) {
    return 'Nenhum agente aprovado no momento. Solicite acesso na aba \"$tabLabel\".';
  }

  @override
  String get clientAgentsNoTradeName => 'Sem nome fantasia';

  @override
  String get agentCatalogInactive => 'inativo';

  @override
  String get agentCatalogActive => 'ativo';

  @override
  String get agentConnectionOnline => 'online';

  @override
  String get agentConnectionOffline => 'offline';

  @override
  String get agentConnectionUnknown => 'Estado de ligação desconhecido';

  @override
  String get clientAgentsRemoveAccess => 'Remover acesso';

  @override
  String get clientAgentsApprovedBulkSelect =>
      'Selecionar para remocao em lote';

  @override
  String get clientAgentsApprovedBulkCancel => 'Cancelar selecao';

  @override
  String clientAgentsApprovedBulkRemove(int count) {
    return 'Remover selecionados ($count)';
  }

  @override
  String get clientAgentsBulkRemoveConfirmTitle =>
      'Enfileirar remocao para varios agentes?';

  @override
  String clientAgentsBulkRemoveConfirmMessage(int count) {
    return 'A remocao de acesso para $count agentes sera preparada e enviada no proximo sync.';
  }

  @override
  String get clientAgentsBulkRemoveConfirmBack => 'Voltar';

  @override
  String get clientAgentsBulkRemoveConfirmAction => 'Enfileirar remocao';

  @override
  String get clientAgentsApprovedBulkSelectAll => 'Selecionar todos';

  @override
  String get clientAgentsApprovedBulkClearSelection => 'Limpar selecao';

  @override
  String get clientAgentsRequestAccessIntro1 =>
      'Use uma ou mais linhas para solicitar acesso. Cada linha precisa de um UUID de agente; informe o client token quando o agente exigir para execucao SQL.';

  @override
  String get clientAgentsRequestAccessIntro2 =>
      'O agentId deve ser informado pelo responsavel do agente ou por um fluxo externo. Quando a solicitacao for aprovada, o agente sera liberado automaticamente para esta conta.';

  @override
  String get clientAgentsRequestAccessIntroToken =>
      'O client token fica em cache neste dispositivo enquanto a aprovacao esta pendente e e enviado ao servidor Colmeia assim que o agente for vinculado.';

  @override
  String get clientAgentsRequestAccessAddRow => 'Adicionar linha de agente';

  @override
  String get clientAgentsRequestAccessRemoveRow => 'Remover linha';

  @override
  String clientAgentsRequestAccessRowTitle(int index) {
    return 'Agente $index';
  }

  @override
  String get clientAgentsClientTokenLabel => 'Client token';

  @override
  String get clientAgentsClientTokenHint =>
      'Opcional — cache local, enviado ao servidor apos aprovacao';

  @override
  String get clientAgentsClientTokenShow => 'Mostrar token';

  @override
  String get clientAgentsClientTokenHide => 'Ocultar token';

  @override
  String get clientAgentsAgentIdsLabel => 'Agent ID';

  @override
  String get clientAgentsRequestAccessCta => 'Solicitar acesso';

  @override
  String get clientAgentsValidationNeedOneValidId =>
      'Informe pelo menos um agentId valido para continuar.';

  @override
  String clientAgentsValidationInvalidIds(String ids) {
    return 'Os seguintes agentIds sao invalidos: $ids.';
  }

  @override
  String clientAgentsValidationTokenTooLong(int limit, String ids) {
    return 'O client token deve ter no maximo $limit caracteres. Reduza para: $ids.';
  }

  @override
  String clientAgentsDuplicatedIdsNote(String ids) {
    return 'IDs duplicados foram ignorados automaticamente: $ids.';
  }

  @override
  String get clientAgentsLoadRequestsErrorTitle =>
      'Nao foi possivel carregar as solicitacoes';

  @override
  String get clientAgentsLoadPendingErrorTitle =>
      'Nao foi possivel carregar os envios pendentes';

  @override
  String get clientAgentsNoRequestsYet => 'Sem solicitacoes no momento.';

  @override
  String get clientAgentsRequestStatusPending => 'Pendente';

  @override
  String get clientAgentsRequestStatusApproved => 'Aprovado';

  @override
  String get clientAgentsRequestStatusRejected => 'Rejeitado';

  @override
  String get clientAgentsRequestStatusExpired => 'Expirado';

  @override
  String get clientAgentsRequestStatusUnknown => 'Desconhecido';

  @override
  String get clientAgentsRequestDescPending =>
      'Em analise pelo responsavel do agente.';

  @override
  String get clientAgentsRequestDescApproved =>
      'Aprovado e disponivel para esta conta.';

  @override
  String get clientAgentsRequestDescRejected =>
      'Nao foi aprovado pelo responsavel do agente.';

  @override
  String get clientAgentsRequestDescExpired =>
      'A solicitacao expirou. Envie novamente se necessario.';

  @override
  String get clientAgentsRequestDescUnknown =>
      'O status dessa solicitacao ainda nao esta disponivel.';

  @override
  String get clientAgentsPendingDescQueued => 'Pronto para envio.';

  @override
  String get clientAgentsPendingDescSyncing => 'Enviando agora.';

  @override
  String get clientAgentsPendingDescFailed =>
      'Nao foi possivel enviar. Tente novamente.';

  @override
  String get clientAgentsPendingDescSynced => 'Enviado.';

  @override
  String get clientAgentsPendingChipRequest => 'Solicitar';

  @override
  String get clientAgentsPendingChipRemove => 'Remover';

  @override
  String get clientAgentsPendingChipQueued => 'pronto para envio';

  @override
  String get clientAgentsPendingChipSyncing => 'enviando';

  @override
  String get clientAgentsPendingChipFailed => 'falhou';

  @override
  String get clientAgentsPendingChipSynced => 'enviado';

  @override
  String clientAgentsPendingSendTitle(String agentId) {
    return 'Envio pendente: $agentId';
  }

  @override
  String get clientAgentsSessionUnavailableLoad =>
      'Sessao indisponivel para carregar agentes.';

  @override
  String get clientAgentsSessionUnavailableRequest =>
      'Sessao indisponivel para solicitar acesso.';

  @override
  String get clientAgentsSessionUnavailableRemove =>
      'Sessao indisponivel para remover acesso.';

  @override
  String get clientAgentsSessionUnavailableSync =>
      'Sessao indisponivel para sincronizar pendencias.';

  @override
  String get clientAgentDetailSessionUnavailable =>
      'Sessao indisponivel para carregar o agente.';

  @override
  String get appInlineErrorRetry => 'Tentar novamente';

  @override
  String get clientAgentsNoLocalPendingToSync =>
      'Nao ha pendencias locais para sincronizar.';

  @override
  String get clientAgentsRequestBlockedFallback =>
      'Nao foi possivel registrar a solicitacao informada.';

  @override
  String clientAgentsRequestBlockedIntro(String details) {
    return 'Nenhum novo agente pode ser solicitado com os IDs informados. $details';
  }

  @override
  String clientAgentsRequestBlockedAlreadyApproved(String ids) {
    return 'Ja aprovados: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyReview(String ids) {
    return 'Ja em analise: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyQueued(String ids) {
    return 'Ja preparados para envio: $ids.';
  }

  @override
  String get clientAgentsRequestQueuedWatchingSingle =>
      'Solicitacao enviada. Vamos acompanhar a aprovacao automaticamente.';

  @override
  String clientAgentsRequestQueuedWatchingPlural(int count) {
    return '$count solicitacoes enviadas. Vamos acompanhar as aprovacoes automaticamente.';
  }

  @override
  String clientAgentsRequestQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados porque ja estavam aprovados ou em analise.';
  }

  @override
  String get clientAgentsRequestRelinkUpdatedSingle =>
      'Esse agente ja esta aprovado no servidor. A lista de agentes foi atualizada.';

  @override
  String clientAgentsRequestRelinkUpdatedPlural(int count) {
    return '$count agentes ja estavam aprovados no servidor. A lista de agentes foi atualizada.';
  }

  @override
  String clientAgentsRequestRelinkAndQueued(
    String relinkSummary,
    String queueSummary,
  ) {
    return '$relinkSummary. $queueSummary';
  }

  @override
  String get clientAgentsRelinkPendingNotCleared =>
      'Nao foi possivel limpar solicitacoes pendentes locais; elas podem ser reenviadas na proxima sincronizacao.';

  @override
  String get clientAgentsRemoveBlockedFallback =>
      'Nao foi possivel registrar a remocao informada.';

  @override
  String clientAgentsRemoveBlockedIntro(String details) {
    return 'Nenhum novo agente pode ser removido com os IDs informados. $details';
  }

  @override
  String clientAgentsRemoveBlockedNotApproved(String ids) {
    return 'Sem acesso aprovado: $ids.';
  }

  @override
  String clientAgentsRemoveBlockedAlreadyQueued(String ids) {
    return 'Remocao ja preparada para envio: $ids.';
  }

  @override
  String get clientAgentsRemoveQueuedSingle =>
      'Remocao de acesso preparada e enviada para sincronizacao.';

  @override
  String clientAgentsRemoveQueuedPlural(int count) {
    return '$count remocoes de acesso preparadas e enviadas para sincronizacao.';
  }

  @override
  String clientAgentsRemoveQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados.';
  }

  @override
  String get clientAgentsSyncSuccessSingle => '1 pendencia foi sincronizada.';

  @override
  String clientAgentsSyncSuccessPlural(int count) {
    return '$count pendencias foram sincronizadas.';
  }

  @override
  String get clientAgentsSyncSuccessNoneCompleted =>
      'A sincronizacao terminou, mas nenhuma pendencia foi aplicada.';

  @override
  String clientAgentsSyncSuccessSomeFailedSuffix(int count) {
    return ' $count acao(oes) falhou e permanece na fila para nova tentativa.';
  }

  @override
  String get clientAgentsSyncSuccessAutoSuffix =>
      ' O envio aconteceu automaticamente.';

  @override
  String get clientAgentsSyncSuccessManualSuffix =>
      ' A tela ja foi atualizada com o status mais recente.';

  @override
  String get clientAgentsSyncSuccessPollingSuffix =>
      ' Vamos acompanhar a aprovacao automaticamente.';

  @override
  String get clientAgentsSyncSuccessAlreadyApprovedSingle =>
      ' Um agente ja estava aprovado no servidor.';

  @override
  String clientAgentsSyncSuccessAlreadyApprovedPlural(int count) {
    return ' $count agentes ja estavam aprovados no servidor.';
  }

  @override
  String get clientAgentsSyncSuccessDebouncedSingle =>
      ' Uma solicitacao foi atualizada recentemente (sem novo email).';

  @override
  String clientAgentsSyncSuccessDebouncedPlural(int count) {
    return ' $count solicitacoes foram atualizadas recentemente (sem novo email).';
  }

  @override
  String clientAgentsPollApprovedSingle(String tabLabel) {
    return 'Acesso aprovado. O agente ja esta disponivel em \"$tabLabel\".';
  }

  @override
  String clientAgentsPollApprovedPlural(int count, String tabLabel) {
    return '$count acessos foram aprovados. Os agentes ja estao disponiveis em \"$tabLabel\".';
  }

  @override
  String get clientAgentsPollDeniedSingle =>
      '1 solicitacao foi encerrada sem aprovacao.';

  @override
  String clientAgentsPollDeniedPlural(int count) {
    return '$count solicitacoes foram encerradas sem aprovacao.';
  }

  @override
  String get clientAgentsPollTimeoutSingle =>
      '1 solicitacao ainda esta em analise. Atualize esta tela mais tarde para verificar o resultado.';

  @override
  String clientAgentsPollTimeoutPlural(int count) {
    return '$count solicitacoes seguem em analise e voce pode atualizar esta tela mais tarde para verificar o resultado.';
  }

  @override
  String get clientAgentsPollRemainingSingle =>
      'Ainda ha 1 solicitacao em analise.';

  @override
  String clientAgentsPollRemainingPlural(int count) {
    return 'Ainda ha $count solicitacoes em analise.';
  }

  @override
  String get clientAgentDetailEyebrow => 'Detalhe';

  @override
  String get clientAgentDetailTitle => 'Agente';

  @override
  String get clientAgentDetailSubtitle =>
      'Informacoes detalhadas do agente aprovado para esta conta.';

  @override
  String get clientAgentDetailLoadErrorTitle =>
      'Nao foi possivel carregar o agente';

  @override
  String get clientAgentFieldTradeName => 'Nome fantasia';

  @override
  String get clientAgentFieldDocument => 'Documento';

  @override
  String get clientAgentFieldCnpjCpf => 'CNPJ/CPF';

  @override
  String get clientAgentFieldEmail => 'Email';

  @override
  String get clientAgentFieldPhone => 'Telefone';

  @override
  String get clientAgentFieldCity => 'Cidade';

  @override
  String get clientAgentValueNotAvailable => 'N/A';

  @override
  String get clientAgentAddressNotProvided => 'Endereco nao informado';

  @override
  String get clientAgentDetailSectionContact => 'Contato';

  @override
  String get clientAgentDetailSectionAddress => 'Endereco';

  @override
  String get clientAgentDetailSectionNotes => 'Anotacoes';

  @override
  String get clientAgentDetailSectionRecord => 'Registro';

  @override
  String get clientAgentDetailSectionServerToken => 'Client token';

  @override
  String get clientAgentDetailSectionServerTokenSubtitle =>
      'Salvo no servidor Colmeia e encaminhado ao agente como `params.client_token` quando este cliente executa SQL via bridge. O token tambem fica em cache neste dispositivo para dashboards seguirem funcionando brevemente sem conexao.';

  @override
  String get clientAgentDetailServerTokenSave => 'Salvar token';

  @override
  String get clientAgentDetailServerTokenRemove => 'Remover token';

  @override
  String get clientAgentDetailServerTokenSaved => 'Token salvo no servidor.';

  @override
  String get clientAgentDetailServerTokenRemoved =>
      'Token removido do servidor.';

  @override
  String get clientAgentDetailServerTokenStatusConfigured =>
      'Token configurado para este agente no servidor.';

  @override
  String get clientAgentDetailServerTokenStatusMissing =>
      'Nenhum token configurado no servidor ainda.';

  @override
  String get clientAgentDetailServerTokenStatusUnknown =>
      'Status do token nao carregado — atualize a tela com acesso a internet para confirmar.';

  @override
  String get clientAgentDetailServerTokenLoadError =>
      'Nao foi possivel ler o token atual no servidor. Exibindo o ultimo valor em cache neste dispositivo, se houver.';

  @override
  String get clientAgentDetailSectionEditProfile => 'Perfil no catálogo';

  @override
  String get clientAgentDetailSaveProfile => 'Salvar perfil';

  @override
  String get clientAgentDetailProfileSaved => 'Perfil salvo no servidor.';

  @override
  String get clientAgentDetailProfileNameRequired =>
      'Informe o nome / razão social.';

  @override
  String get clientAgentFieldLegalName => 'Nome / razão social';

  @override
  String get clientAgentFieldNumber => 'Número';

  @override
  String get clientAgentFieldId => 'Agent ID';

  @override
  String get clientAgentFieldDocumentType => 'Tipo';

  @override
  String get clientAgentFieldMobile => 'Celular';

  @override
  String get clientAgentFieldStatus => 'Status';

  @override
  String get clientAgentFieldConnection => 'Conexao';

  @override
  String get clientAgentFieldNotes => 'Notas';

  @override
  String get clientAgentFieldObservation => 'Observacao';

  @override
  String get clientAgentFieldStreet => 'Rua';

  @override
  String get clientAgentFieldDistrict => 'Bairro';

  @override
  String get clientAgentFieldPostalCode => 'CEP';

  @override
  String get clientAgentFieldState => 'Estado';

  @override
  String get clientAgentFieldCreatedAt => 'Desde';

  @override
  String get clientAgentFieldUpdatedAt => 'Atualizado';

  @override
  String get clientAgentFieldProfileUpdatedAt => 'Perfil atualizado';

  @override
  String get clientAgentsFilterSheetTitle => 'Filtros de agentes';

  @override
  String get clientAgentsFilterSearchLabel => 'Buscar agente';

  @override
  String get clientAgentsFilterSearchHint => 'Nome, agentId ou nome fantasia';

  @override
  String get clientAgentsFilterConnectionLabel => 'Conexao';

  @override
  String get clientAgentsFilterConnectionOnline => 'Online';

  @override
  String get clientAgentsFilterConnectionOffline => 'Offline';

  @override
  String get clientAgentsFilterConnectionUnknown => 'Desconhecido';

  @override
  String get clientAgentsFilterCatalogLabel => 'Catalogo';

  @override
  String get clientAgentsFilterCatalogActive => 'Ativo';

  @override
  String get clientAgentsFilterCatalogInactive => 'Inativo';

  @override
  String clientAgentsFilterSummarySearch(String query) {
    return 'Busca: $query';
  }

  @override
  String clientAgentsFilterSummaryConnection(String label) {
    return 'Conexao: $label';
  }

  @override
  String clientAgentsFilterSummaryCatalog(String label) {
    return 'Catalogo: $label';
  }

  @override
  String get clientAgentsEmptyFilteredApproved =>
      'Nenhum agente corresponde aos filtros selecionados.';

  @override
  String get clientAgentsRequestsFilterSheetTitle => 'Filtros de solicitacoes';

  @override
  String get clientAgentsRequestsFilterSearchLabel => 'Buscar';

  @override
  String get clientAgentsRequestsFilterSearchHint =>
      'Nome do agente ou agent ID';

  @override
  String get clientAgentsRequestsFilterStatusLabel => 'Status da solicitacao';

  @override
  String get clientAgentsRequestsFilterPendingLabel => 'Envio pendente';

  @override
  String clientAgentsRequestsFilterSummaryRequest(String label) {
    return 'Solicitacao: $label';
  }

  @override
  String clientAgentsRequestsFilterSummaryPending(String label) {
    return 'Pendente: $label';
  }

  @override
  String get clientAgentsFiltersTooltip => 'Filtros';

  @override
  String clientAgentsFiltersTooltipActive(int count) {
    return 'Filtros ($count ativos)';
  }

  @override
  String get clientAgentsEmptyFilteredRequests =>
      'Nenhuma solicitacao corresponde aos filtros selecionados.';

  @override
  String get clientAgentsPendingFilterQueued => 'Pronto para enviar';

  @override
  String get clientAgentsPendingFilterSyncing => 'Enviando…';

  @override
  String get clientAgentsPendingFilterFailed => 'Falhou';

  @override
  String get clientAgentsPendingFilterSynced => 'Enviado';

  @override
  String get reportFiltersTitle => 'Filtros';

  @override
  String reportFiltersTitleWithContext(String title) {
    return 'Filtros - $title';
  }

  @override
  String get reportFiltersDescription =>
      'Ajuste a consulta e aplique somente os recortes que fazem sentido para esta analise.';

  @override
  String reportFiltersFieldCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campos',
      one: '1 campo',
    );
    return '$_temp0';
  }

  @override
  String reportFiltersRequiredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obrigatorios',
      one: '1 obrigatorio',
    );
    return '$_temp0';
  }

  @override
  String reportFiltersActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos',
      one: '1 ativo',
    );
    return '$_temp0';
  }

  @override
  String get reportFiltersClearAction => 'Limpar';

  @override
  String get reportFiltersApplyAction => 'Aplicar filtros';

  @override
  String get reportFiltersButton => 'Filtros';

  @override
  String reportFiltersButtonActive(int count) {
    return 'Filtros ($count ativos)';
  }

  @override
  String get reportFiltersClearTooltip => 'Limpar';

  @override
  String get reportFiltersClearAllTooltip => 'Limpar filtros';

  @override
  String get reportFiltersAdvancedButton => 'Filtros avancados';

  @override
  String get reportInlineFiltersHint => 'Filtrar...';

  @override
  String get reportInlineFiltersAllOption => 'Todos';

  @override
  String get reportInlineFiltersSelectPeriod => 'Selecionar periodo';

  @override
  String get reportInlineFiltersSelectDate => 'Selecionar data';

  @override
  String get reportFiltersAppliedSectionTitle => 'Filtros aplicados';

  @override
  String get clientAgentsErrorLoadCatalog =>
      'Nao foi possivel carregar o catalogo de agentes.';

  @override
  String get clientAgentsErrorLoadCatalogAgent =>
      'Nao foi possivel carregar este agente do catalogo.';

  @override
  String get clientAgentsErrorLoadClientAccessStatus =>
      'Nao foi possivel ler o status da solicitacao de acesso.';

  @override
  String get clientAgentsErrorLoadApproved =>
      'Nao foi possivel carregar os agentes aprovados para esta conta.';

  @override
  String get clientAgentsErrorLoadAgentDetail =>
      'Nao foi possivel carregar os dados do agente.';

  @override
  String get clientAgentsErrorProbeApproved =>
      'Nao foi possivel verificar se o agente ja esta ligado a esta conta.';

  @override
  String get clientAgentsErrorLoadAccessRequests =>
      'Nao foi possivel carregar o historico de solicitacoes.';

  @override
  String get clientAgentsErrorReadPending =>
      'Nao foi possivel carregar as acoes pendentes de sincronizacao.';

  @override
  String get clientAgentsErrorQueueRequest =>
      'Nao foi possivel registrar a solicitacao para sincronizacao.';

  @override
  String get clientAgentsErrorQueueRemove =>
      'Nao foi possivel registrar a remocao para sincronizacao.';

  @override
  String get clientAgentsErrorSyncAction =>
      'Nao foi possivel sincronizar a alteracao do agente.';

  @override
  String get clientAgentsErrorSyncPending =>
      'Nao foi possivel sincronizar as acoes pendentes de agentes.';

  @override
  String get clientAgentsErrorGetClientAgentToken =>
      'Nao foi possivel ler o token do agente no servidor.';

  @override
  String get clientAgentsErrorSaveClientAgentToken =>
      'Nao foi possivel salvar o token do agente no servidor.';

  @override
  String get clientAgentsErrorRemoveClientAgentToken =>
      'Nao foi possivel remover o token do agente no servidor.';

  @override
  String get clientAgentsErrorAgentDocumentConflict =>
      'Este CPF/CNPJ ja esta vinculado a outro agente no catalogo. Para alterar o vinculo, entre em contato com o suporte.';

  @override
  String get agentSqlErrorAuthenticationFailed =>
      'A autenticacao para consultar este agente e invalida ou expirou.';

  @override
  String get agentSqlErrorPermissionDenied =>
      'Voce nao tem permissao para consultar estes dados neste agente.';

  @override
  String get agentSqlErrorTransportTimeout =>
      'O agente demorou mais do que o esperado para responder. Tente novamente.';

  @override
  String get agentSqlErrorNetworkError =>
      'Nao foi possivel alcancar o agente agora. Tente novamente.';

  @override
  String get agentSqlErrorRateLimited =>
      'Muitas tentativas de consulta foram feitas. Aguarde um instante e tente novamente.';

  @override
  String get agentSqlErrorValidationFailed =>
      'A consulta informada e invalida.';

  @override
  String get agentSqlErrorExecutionFailed =>
      'Nao foi possivel executar a consulta.';

  @override
  String get agentSqlErrorTransactionFailed =>
      'Nao foi possivel concluir a transacao da consulta.';

  @override
  String get agentSqlErrorConnectionPoolExhausted =>
      'O servidor esta ocupado para processar a consulta agora. Tente novamente em instantes.';

  @override
  String get agentSqlErrorResultTooLarge =>
      'A consulta retornou dados demais. Refine os filtros e tente novamente.';

  @override
  String get agentSqlErrorDatabaseConnectionFailed =>
      'Nao foi possivel conectar ao banco para executar a consulta.';

  @override
  String get agentSqlErrorQueryTimeout =>
      'A consulta demorou mais do que o esperado.';

  @override
  String get agentSqlErrorInvalidDatabaseConfig =>
      'A configuracao de acesso ao banco deste agente esta invalida.';

  @override
  String get agentSqlErrorExecutionNotFound =>
      'A execucao solicitada nao foi encontrada.';

  @override
  String get agentSqlErrorExecutionCancelled => 'A consulta foi cancelada.';

  @override
  String get agentSqlErrorGeneric =>
      'Nao foi possivel concluir a consulta no agente.';

  @override
  String get formsDemoEyebrow => 'Formularios';

  @override
  String get formsDemoTitle => 'Campos compartilhados';

  @override
  String get formsDemoIntroSubtitle =>
      'Validacao, estados habilitado/desabilitado, date pickers no Form, FormBuilder como nos relatorios e agrupamentos.';

  @override
  String get formsDemoFieldLibraryOverline => 'Biblioteca de campos';

  @override
  String get formsDemoSharedFormControlsTitle =>
      'Campos de formulario compartilhados';

  @override
  String get formsDemoPreviewBadge => 'Preview';

  @override
  String get formsDemoShowcaseSubtitle =>
      'Campos base, seletores e wrappers de calendario no mesmo ritmo visual do sistema.';

  @override
  String get formsDemoFieldsEnabledLabel => 'Campos habilitados';

  @override
  String get formsDemoShowcaseFieldsEnabledHelper =>
      'Ativa ou desativa toda a superficie de exemplos abaixo.';

  @override
  String get formsDemoFormStateTitle => 'Estado do formulario';

  @override
  String get formsDemoFormStateSubtitle =>
      'Desligue para inspecionar campos desabilitados.';

  @override
  String get formsDemoFormStateFieldsEnabledHelper =>
      'Aplica o estado disabled em todos os exemplos abaixo.';

  @override
  String get formsDemoTextEmailPasswordTitle => 'AppTextField, e-mail e senha';

  @override
  String get formsDemoTextEmailPasswordSubtitle =>
      'Dados fake; enviar dispara validacao.';

  @override
  String get formsDemoFullNameLabel => 'Nome completo';

  @override
  String get formsDemoFullNameHint => 'Como no cadastro';

  @override
  String get formsDemoNameValidatorMinLength =>
      'Informe pelo menos 3 caracteres.';

  @override
  String get formsDemoCorporateEmailLabel => 'E-mail corporativo';

  @override
  String get formsDemoPasswordLabel => 'Senha';

  @override
  String get formsDemoNotesLabel => 'Observacoes';

  @override
  String get formsDemoNotesHint => 'Opcional';

  @override
  String get formsDemoDatePickersFormTitle => 'Date pickers no Form';

  @override
  String get formsDemoDatePickersFormSubtitle =>
      'Form nativo + FormField. Toque em Aplicar no sheet para confirmar; fechar sem aplicar mantem o valor. Remover limpa de forma explicita.';

  @override
  String get formsDemoReferenceDateLabel => 'Data de referencia';

  @override
  String get formsDemoReferenceDateHelper =>
      'Abre em bottom sheet com calendario estilizado.';

  @override
  String get formsDemoSelectReferenceDateTitle =>
      'Selecionar data de referencia';

  @override
  String get formsDemoReferenceDateRequiredError =>
      'Selecione a data de referencia.';

  @override
  String get formsDemoAssessmentPeriodLabel => 'Periodo de captacao desejado';

  @override
  String get formsDemoAssessmentPeriodHelper =>
      'Ideal para filtros e consultas analiticas.';

  @override
  String get formsDemoSelectPeriodTitle => 'Selecionar periodo';

  @override
  String get formsDemoAssessmentPeriodRequiredError =>
      'Selecione o periodo de captacao completo.';

  @override
  String get formsDemoDateRangeMiddle => ' a ';

  @override
  String get formsDemoCheckboxTitle => 'AppCheckboxField';

  @override
  String get formsDemoCheckboxSubtitle => 'Aceite ficticio.';

  @override
  String get formsDemoCheckboxLabel => 'Receber resumo semanal por e-mail';

  @override
  String get formsDemoCheckboxHelper =>
      'Envia alertas, resumos e atualizacoes de indicadores.';

  @override
  String get formsDemoRadioCompactTitle => 'AppRadioGroup compacto';

  @override
  String get formsDemoRadioCompactSubtitle =>
      'Selecao unica no padrao inline do design system.';

  @override
  String get formsDemoPeriodDaily => 'Diario';

  @override
  String get formsDemoPeriodMonthly => 'Mensal';

  @override
  String get formsDemoPeriodQuarterly => 'Trimestral';

  @override
  String get formsDemoChoiceChipTitle => 'AppChoiceChip';

  @override
  String get formsDemoChoiceChipSubtitle =>
      'Selecao pontual em chips para contexto, loja ou escopo.';

  @override
  String get formsDemoScopeHeadquarters => 'Matriz';

  @override
  String get formsDemoScopeStoreCenter => 'Loja Centro';

  @override
  String get formsDemoScopeStoreSouth => 'Loja Sul';

  @override
  String get formsDemoDropdownMenusTitle => 'Dropdown menus';

  @override
  String get formsDemoDropdownMenusSubtitle =>
      'Selecao unica e multi-select search no mesmo padrao visual das referencias light/dark.';

  @override
  String get formsDemoStandardSelectLabel => 'Standard Select';

  @override
  String get formsDemoSelectHiveNodeHint => 'Select Hive Node...';

  @override
  String get formsDemoMultiSelectSearchLabel => 'Multi-Select Search';

  @override
  String get formsDemoHiveNodeAlphaCore => 'Alpha Core';

  @override
  String get formsDemoHiveNodeDeltaNode => 'Delta Node';

  @override
  String get formsDemoHiveNodeSigmaGrid => 'Sigma Grid';

  @override
  String get formsDemoTagAnalytics => 'Analytics';

  @override
  String get formsDemoTagCloud => 'Cloud';

  @override
  String get formsDemoTagAutomation => 'Automation';

  @override
  String get formsDemoTagSecurity => 'Security';

  @override
  String get formsDemoFormBuilderSectionTitle =>
      'FormBuilder + dropdowns e datas';

  @override
  String get formsDemoFormBuilderSectionSubtitle =>
      'Mesmos wrappers dos relatorios: dropdown, multi-select e os mesmos date pickers da secao Form acima (FormBuilderField + AppFormBuilderDate*).';

  @override
  String get formsDemoFormBuilderNodeLabel => 'Select node (FormBuilder)';

  @override
  String get formsDemoFormBuilderNodeHelper =>
      'Selecao unica com o wrapper compartilhado.';

  @override
  String get formsDemoFormBuilderTagsLabel => 'Tags (FormBuilder)';

  @override
  String get formsDemoFormBuilderTagsHelper =>
      'Busca inline com chips removiveis.';

  @override
  String get formsDemoFormBuilderDateRequiredLabel =>
      'Data obrigatoria (FormBuilder)';

  @override
  String get formsDemoFormBuilderDateRequiredHelper =>
      'Validacao com form_builder_validators.';

  @override
  String get formsDemoFormBuilderSelectDateTitle =>
      'Selecionar data (FormBuilder)';

  @override
  String get formsDemoFormBuilderRangeLabel => 'Periodo (FormBuilder)';

  @override
  String get formsDemoFormBuilderRangeHelper => 'Opcional nesta demo.';

  @override
  String get formsDemoFormBuilderSelectRangeTitle =>
      'Selecionar periodo (FormBuilder)';

  @override
  String get formsDemoValidateFormBuilderButton => 'Validar FormBuilder';

  @override
  String get formsDemoValidateFormSubmitButton => 'Validar envio (Form)';

  @override
  String formsDemoFormValidSnackbar(String refLabel, String rangeLabel) {
    return 'Formulario valido (demo fake). Ref: $refLabel. Periodo: $rangeLabel.';
  }

  @override
  String formsDemoFormBuilderValidSnackbar(
    String dateLabel,
    String rangeLabel,
  ) {
    return 'FormBuilder valido (demo fake). Data: $dateLabel. Periodo: $rangeLabel.';
  }

  @override
  String get formsDemoLegendInput => 'Input';

  @override
  String get formsDemoLegendSelection => 'Selection';

  @override
  String get formsDemoLegendDate => 'Date';

  @override
  String get formsDemoLegendFormBuilder => 'FormBuilder';

  @override
  String get datePickerPlaceholderSelectDate => 'Selecione uma data';

  @override
  String get dateRangePickerPlaceholderSelectPeriod => 'Selecione o periodo';

  @override
  String get datePickerSheetDefaultTitle => 'Selecionar data';

  @override
  String get dateRangePickerSheetDefaultTitle => 'Selecionar periodo';

  @override
  String get datePickerClearSelectionTooltip => 'Limpar selecao';

  @override
  String get datePickerSheetRemoveDate => 'Remover data';

  @override
  String get dateRangePickerSheetRemovePeriod => 'Remover periodo';

  @override
  String get datePickerSheetCloseTooltip => 'Fechar';

  @override
  String get datePickerSheetApply => 'Aplicar';

  @override
  String get datePickerSemanticsFallbackLabel => 'Data';

  @override
  String get dateRangePickerSemanticsFallbackLabel => 'Periodo';

  @override
  String get areaTrendDemoIntroEyebrow => 'Graficos de area';

  @override
  String get areaTrendDemoIntroTitle => 'AppAreaTrendChart';

  @override
  String get areaTrendDemoIntroSubtitle =>
      'Tendencia temporal com area preenchida: gradiente, marcadores, zoom, variantes de estilo e evento estruturado por serie/ponto.';

  @override
  String get areaTrendDemoShowcaseTitle =>
      'Tendencia temporal com preenchimento';

  @override
  String get areaTrendDemoShowcaseSubtitle =>
      'Grafico de area para volume, crescimento e comparativos no tempo, com boa leitura de massa e intensidade.';

  @override
  String get areaTrendDemoShowcaseBadge => 'Trend';

  @override
  String get areaTrendDemoShowcaseHighlightTimeSeries => 'Serie temporal';

  @override
  String get areaTrendDemoShowcaseHighlightGradientMarkers =>
      'Gradiente e markers';

  @override
  String get areaTrendDemoShowcaseHighlightMultiseries => 'Multiseries';

  @override
  String get areaTrendDemoS01Title => '1. Faturamento semanal';

  @override
  String get areaTrendDemoS01Subtitle =>
      'Area com gradiente, eixo formatado, tooltip e tap.';

  @override
  String get areaTrendDemoS02Title => '2. Com marcadores de ponto';

  @override
  String get areaTrendDemoS02Subtitle =>
      'Cada ponto recebe um marcador visivel.';

  @override
  String get areaTrendDemoS03Title => '3. Sem gradiente (area solida)';

  @override
  String get areaTrendDemoS03Subtitle =>
      'showGradientFill: false para area plana.';

  @override
  String get areaTrendDemoS04Title => '4. Pedidos por hora';

  @override
  String get areaTrendDemoS04Subtitle =>
      'Pico operacional do dia — escala de unidades.';

  @override
  String get areaTrendDemoS05Title => '5. Compacto sem shell';

  @override
  String get areaTrendDemoS05Subtitle =>
      'Preset compact, sem eixos e sem shell interno.';

  @override
  String get areaTrendDemoS06Title => '6. Estado de loading';

  @override
  String get areaTrendDemoS07Title => '7. Estado vazio';

  @override
  String get areaTrendDemoEmptyMessage =>
      'Sem dados para o periodo selecionado.';

  @override
  String get areaTrendDemoS08Title => '8. Multi-series (comparativo de lojas)';

  @override
  String get areaTrendDemoS08Subtitle =>
      'Tres lojas sobrepostas com palette automatica. Legenda ativada.';

  @override
  String get areaTrendDemoS09Title => '9. Multi-series com trackball';

  @override
  String get areaTrendDemoS09Subtitle =>
      'Toque na area para ver os valores de todas as series na mesma posicao do eixo X.';

  @override
  String get areaTrendDemoS10Title => '10. Cores por entrada';

  @override
  String get areaTrendDemoS10Subtitle =>
      'Cor customizada por AppAreaTrendEntry.';

  @override
  String get areaTrendDemoSeriesRevenue => 'Faturamento';

  @override
  String get areaTrendDemoSeriesTarget => 'Meta';

  @override
  String get areaTrendDemoStoreCenter => 'Centro';

  @override
  String get areaTrendDemoStoreNorth => 'Norte';

  @override
  String get areaTrendDemoStoreSouth => 'Sul';

  @override
  String get areaTrendDemoDefaultSeriesName => 'serie principal';

  @override
  String areaTrendDemoTapSnackbar(
    String seriesLabel,
    String pointLabel,
    String valueLabel,
  ) {
    return 'Area: $seriesLabel • $pointLabel = $valueLabel';
  }

  @override
  String areaTrendDemoA11ySection(int sectionIndex, String sectionTitle) {
    return 'Demonstracao de grafico $sectionIndex: $sectionTitle';
  }
}
