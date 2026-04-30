// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get shellNavDashboardLabel => 'Visão geral';

  @override
  String get shellNavDashboardSubtitle => 'Resumo operacional e KPIs';

  @override
  String get shellNavAgentsLabel => 'Agentes';

  @override
  String get shellNavAgentsSubtitle => 'Fontes de dados e acessos';

  @override
  String get shellNavSettingsLabel => 'Perfil';

  @override
  String get shellNavSettingsSubtitle => 'Conta e preferências';

  @override
  String get shellNavSalesLabel => 'Vendas';

  @override
  String get shellNavSalesSubtitle =>
      'Pedidos, receita e indicadores comerciais';

  @override
  String get shellNavReturnsLabel => 'Devoluções';

  @override
  String get shellNavReturnsSubtitle => 'Devoluções, trocas e notas de crédito';

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
  String get shellNavInventorySubtitle => 'Níveis de estoque e movimentações';

  @override
  String get shellPlaceholderUnderConstructionTitle => 'Em construção';

  @override
  String get shellPlaceholderUnderConstructionBody =>
      'Esta seção estará disponível em uma atualização futura.';

  @override
  String get shellAppBrandName => 'Colmeia';

  @override
  String get shellOpenSettingsSemantics => 'Abrir configurações';

  @override
  String get shellOpenProfileSemantics => 'Abrir perfil e conta';

  @override
  String get shellNavSignOut => 'Sair';

  @override
  String get shellNavSigningOut => 'Saindo...';

  @override
  String get shellNavSignOutSemanticsLoading => 'Encerrando sessão';

  @override
  String get shellSignOutDialogTitle => 'Sair da conta?';

  @override
  String get shellSignOutDialogConfirm => 'Sair';

  @override
  String get shellSignOutDialogMessage =>
      'Você precisará entrar novamente para acessar os dados.';

  @override
  String get shellNavMainSemantics => 'Navegação principal';

  @override
  String get userPermissionViewDashboard => 'Visão geral';

  @override
  String get userPermissionManageAgents => 'Gestão de agentes';

  @override
  String get userPermissionViewSales => 'Vendas (acesso ao módulo)';

  @override
  String get userPermissionViewReturns => 'Devoluções (acesso ao módulo)';

  @override
  String get userPermissionViewFinance => 'Financeiro (acesso ao módulo)';

  @override
  String get userPermissionViewPurchases => 'Compras (acesso ao módulo)';

  @override
  String get userPermissionViewInventory => 'Estoque (acesso ao módulo)';

  @override
  String get dashboardPartialAgentQueriesTitle =>
      'Dados da visão geral incompletos';

  @override
  String get dashboardPartialAgentQueriesMessage =>
      'Alguns agentes aprovados não retornaram dados. Os totais podem estar incompletos.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Agentes sem token de cliente salvo';

  @override
  String get dashboardMissingClientTokenMessage =>
      'Estes agentes aprovados foram ignorados porque não há token de cliente local. Cadastre o token na tela do agente para incluir os dados.';

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
      'Nenhum agente com acesso aprovado possui token de cliente salvo neste dispositivo. Abra a gestão de agentes para cadastrar o token e liberar a consulta da visão geral.';

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
  String get dashboardAgentsOfflineTitle => 'Agentes offline no momento';

  @override
  String get dashboardAgentsOfflineMessage =>
      'Estes agentes aprovados têm um token salvo, mas o hub os reporta como desconectados. Peça ao operador para reconectá-los e tente novamente.';

  @override
  String get dashboardAffectedAgentsSheetTitleOffline =>
      'Agentes reportados como offline pelo hub';

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
  String get dashboardHomeFiltersAgentsLabel => 'AGENTES';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visao geral para listar os agentes.';

  @override
  String get dashboardHomeFiltersYearMonthLabel => 'ANO / MÊS';

  @override
  String get dashboardHomeFiltersCurrentMonth => 'Mês atual';

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
  String get overviewTopProductsTitle => 'Produtos mais vendidos';

  @override
  String overviewTopProductsSubtitle(int count) {
    return 'Por agente (sem unir cadastros). Até $count produtos.';
  }

  @override
  String get overviewTopProductsNoEligibleAgents =>
      'Nenhum agente disponível para este gráfico. Salve o token no agente ou ajuste o filtro.';

  @override
  String get overviewTopProductsInvalidPeriod =>
      'O período selecionado não é válido para este gráfico.';

  @override
  String get overviewTopProductsEmpty =>
      'Sem vendas de produto neste período para este agente.';

  @override
  String get overviewTopProductsLoadFailed =>
      'Não foi possível carregar este gráfico. Tente novamente.';

  @override
  String get overviewTopProductsLoadingSemantics =>
      'Carregando gráfico de produtos…';

  @override
  String overviewTopProductsTooltipLine(
    int sales,
    String items,
    String revenue,
    String cost,
    String margin,
  ) {
    return '$sales vendas · $items itens · $revenue faturamento · $cost custo rep. · $margin% margem';
  }

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
  String get chartOpenFullscreenTooltip => 'Abrir gráfico em tela cheia';

  @override
  String get chartCloseFullscreenTooltip => 'Fechar gráfico em tela cheia';

  @override
  String get chartFullscreenUnavailableTitle => 'Gráfico indisponível';

  @override
  String get chartFullscreenUnavailableMessage =>
      'Não foi possível abrir este gráfico em tela cheia. Volte e tente novamente.';

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
  String get clientAgentsMaintenanceSubtitleOwner =>
      'Use as abas para gerir agentes aprovados, reenviar solicitacoes de clientes e revisar acessos dos agentes que voce administra.';

  @override
  String get clientAgentsTabMyAgents => 'Meus agentes';

  @override
  String get clientAgentsTabRequestAccess => 'Solicitar acesso';

  @override
  String get clientAgentsTabRequests => 'Solicitacoes';

  @override
  String get clientAgentsTabOwnerRequests => 'Revisar solicitacoes';

  @override
  String get clientAgentsTabOwnerClients => 'Clientes aprovados';

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
  String get clientAgentsRetryRequestAction => 'Tentar novamente';

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
  String get clientAgentsRetryMissingRequestId =>
      'Esta solicitacao nao pode ser reenviada porque o identificador nao esta disponivel.';

  @override
  String get clientAgentsRetrySuccess =>
      'A solicitacao foi reenviada. Vamos continuar acompanhando a aprovacao.';

  @override
  String get clientAgentsDiscardQueuedRequestAction => 'Remover da fila';

  @override
  String get clientAgentsDiscardQueuedRequestSuccess =>
      'O envio pendente foi removido. Voce pode solicitar acesso de novo quando quiser.';

  @override
  String get clientAgentsDiscardQueuedRequestInvalidState =>
      'Este envio nao pode ser removido da fila no estado atual.';

  @override
  String get clientAgentsOwnerActionFailedTitle =>
      'Nao foi possivel concluir a acao do responsavel';

  @override
  String get clientAgentsOwnerRequestsLoadErrorTitle =>
      'Nao foi possivel carregar as solicitacoes para revisao';

  @override
  String get clientAgentsOwnerRequestsEmpty =>
      'Nenhuma solicitacao de cliente precisa da sua revisao agora.';

  @override
  String get clientAgentsOwnerApproveAction => 'Aprovar';

  @override
  String get clientAgentsOwnerRejectAction => 'Rejeitar';

  @override
  String get clientAgentsOwnerRequestsStatusPending =>
      'Aguardando sua decisao para este agente.';

  @override
  String get clientAgentsOwnerRequestsStatusApproved =>
      'Aprovada e ja disponivel para o cliente.';

  @override
  String get clientAgentsOwnerRequestsStatusRejected =>
      'Rejeitada durante a revisao do responsavel.';

  @override
  String get clientAgentsOwnerRequestsStatusExpired =>
      'Expirou antes da revisao final.';

  @override
  String get clientAgentsOwnerRequestsStatusUnknown =>
      'O status mais recente da revisao nao esta disponivel.';

  @override
  String get clientAgentsOwnerApproveSuccess =>
      'A solicitacao de acesso foi aprovada.';

  @override
  String get clientAgentsOwnerRejectSuccess =>
      'A solicitacao de acesso foi rejeitada.';

  @override
  String get clientAgentsOwnerClientsEmptyAgents =>
      'Nenhum agente administrado esta disponivel para esta conta ainda.';

  @override
  String get clientAgentsOwnerClientsAgentSelectorLabel => 'Agente';

  @override
  String get clientAgentsOwnerClientsAgentSelectorHint =>
      'Escolha um agente administrado';

  @override
  String get clientAgentsOwnerClientsLoadErrorTitle =>
      'Nao foi possivel carregar os clientes aprovados';

  @override
  String get clientAgentsOwnerClientsEmpty =>
      'Nenhum cliente aprovado esta vinculado a este agente ainda.';

  @override
  String get clientAgentsOwnerClientsApprovedSubtitle =>
      'Aprovado para este agente.';

  @override
  String get clientAgentsOwnerRevokeAction => 'Revogar acesso';

  @override
  String get clientAgentsOwnerRevokeSuccess =>
      'O acesso do cliente foi revogado.';

  @override
  String get clientAgentDetailSessionUnavailable =>
      'Sessao indisponivel para carregar o agente.';

  @override
  String get appInlineErrorRetry => 'Tentar novamente';

  @override
  String appInlineErrorRetryCountdown(int seconds) {
    return 'Tentar em ${seconds}s';
  }

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
  String clientAgentsSyncRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para esperarmos. Tente de novo em ${seconds}s.';
  }

  @override
  String clientAgentsRequestAccessRetryAfterCountdown(int seconds) {
    return 'Muitas solicitacoes de acesso. Tente de novo em ${seconds}s.';
  }

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
  String get clientAgentDetailRefreshFromAgent => 'Recarregar do agente';

  @override
  String get clientAgentDetailRefreshFromAgentSuccess =>
      'Perfil recarregado direto do agente.';

  @override
  String get clientAgentDetailRefreshFromAgentUnsupported =>
      'Este agente nao implementa agent.getProfile via RPC.';

  @override
  String clientAgentDetailRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para aguardar. Tente novamente em ${seconds}s.';
  }

  @override
  String get clientAgentDetailSectionPolicy => 'Permissoes deste token';

  @override
  String get clientAgentDetailSectionPolicySubtitle =>
      'Resolvidas pelo agente para o token atualmente salvo no servidor. Se a politica mudar apos revogacao ou alteracao de escopo, recarregue a tela.';

  @override
  String get clientAgentDetailPolicyFullAccess =>
      'Acesso total (todas as tabelas, views e permissoes).';

  @override
  String get clientAgentDetailPolicyAllTables =>
      'Permitido em todas as tabelas.';

  @override
  String get clientAgentDetailPolicyAllViews => 'Permitido em todas as views.';

  @override
  String get clientAgentDetailPolicyAllPermissions =>
      'Tem todas as permissoes.';

  @override
  String get clientAgentDetailPolicyTablesLabel => 'Tabelas permitidas';

  @override
  String get clientAgentDetailPolicyViewsLabel => 'Views permitidas';

  @override
  String get clientAgentDetailPolicyPermissionsLabel => 'Permissoes';

  @override
  String get clientAgentDetailPolicyRevoked =>
      'Este token esta marcado como revogado pelo agente.';

  @override
  String get clientAgentDetailPolicyRevokedSaveNewToken => 'Salvar novo token';

  @override
  String get clientAgentDetailPolicyUnsupported =>
      'Este agente nao expoe introspecao da politica do token.';

  @override
  String get clientAgentDetailPolicyEmpty =>
      'O agente nao retornou nenhuma regra para este token.';

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
  String get clientAgentsErrorRetryClientAccessRequest =>
      'Nao foi possivel reenviar esta solicitacao de acesso.';

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
  String get clientAgentsErrorLoadManagedAgents =>
      'Nao foi possivel carregar os agentes administrados.';

  @override
  String get clientAgentsErrorLoadOwnerAccessRequests =>
      'Nao foi possivel carregar as solicitacoes de acesso para revisao.';

  @override
  String get clientAgentsErrorApproveOwnerAccessRequest =>
      'Nao foi possivel aprovar esta solicitacao de acesso.';

  @override
  String get clientAgentsErrorRejectOwnerAccessRequest =>
      'Nao foi possivel rejeitar esta solicitacao de acesso.';

  @override
  String get clientAgentsErrorLoadOwnerApprovedClients =>
      'Nao foi possivel carregar os clientes aprovados deste agente.';

  @override
  String get clientAgentsErrorRevokeOwnerClientAccess =>
      'Nao foi possivel revogar este acesso de cliente.';

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
  String get clientAgentsErrorAgentProfileCasMismatch =>
      'Outro dispositivo atualizou este agente. Recarregue a tela e reaplique suas alteracoes.';

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
  String get formsDemoDatePickersFormTitle => 'Date pickers no Form';

  @override
  String get formsDemoDatePickersFormSubtitle =>
      'Form nativo + FormField. Toque em Aplicar no sheet para confirmar; fechar sem aplicar mantem o valor. Remover limpa de forma explicita.';

  @override
  String get formsDemoFormBuilderSectionTitle =>
      'FormBuilder + dropdowns e datas';

  @override
  String get formsDemoFormBuilderSectionSubtitle =>
      'Mesmos wrappers dos relatorios: dropdown, multi-select e os mesmos date pickers da secao Form acima (FormBuilderField + AppFormBuilderDate*).';

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
  String get overviewLucratividadeTitle => 'Lucratividade por agente';

  @override
  String get overviewLucratividadeSubtitle =>
      'Receita, custo e margem no periodo selecionado, por agente (todas as filiais somadas).';

  @override
  String get overviewLucratividadeSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeSwitchMargin => 'Margem %';

  @override
  String get overviewLucratividadeProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeCostSeriesLabel => 'Custo reposicao';

  @override
  String get overviewLucratividadeMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLucratividadeEmpty =>
      'Sem dados de lucratividade para este periodo.';

  @override
  String get overviewLucratividadeMultiAgentHint =>
      'Nenhum agente aprovado esta disponivel para carregar a lucratividade. Adicione ou conecte um agente primeiro.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Carregando grafico de lucratividade por filial…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Lucratividade mensal do produto';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Receita, custo de reposicao e margem por mes (agente selecionado).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'Sem dados de lucratividade para este periodo.';

  @override
  String get overviewLucratividadeMensalMultiAgentHint =>
      'Selecione um unico agente para visualizar a lucratividade mensal.';

  @override
  String get overviewLucratividadeMensalSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeMensalSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeMensalSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeMensalSwitchMargin => 'Margem %';

  @override
  String get overviewLucratividadeMensalProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeMensalRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeMensalCostSeriesLabel => 'Custo reposicao';

  @override
  String get overviewLucratividadeMensalMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLoadingLucratividadeMensalSemantics =>
      'Carregando grafico de lucratividade mensal do produto…';

  @override
  String get salesHubTitle => 'Vendas';

  @override
  String get salesHubSubtitle =>
      'Acesse e gerencie informacoes comerciais por categoria.';

  @override
  String get salesAgentPickerLabel => 'Agente';

  @override
  String get salesAgentPickerEmpty => 'Selecione um agente';

  @override
  String get salesAgentPickerSheetTitle => 'Selecione um agente';

  @override
  String get salesAgentRequiredTitle => 'Selecao de agente obrigatoria';

  @override
  String get salesAgentRequiredMessage =>
      'Selecione um agente para visualizar essas informacoes.';

  @override
  String get salesCardOpenAccountsTitle => 'Contas em Aberto';

  @override
  String get salesCardPaidAccountsTitle => 'Contas Pagas';

  @override
  String get salesCardPaymentHistoryTitle => 'Historico de Pagamentos';

  @override
  String get salesCardNewPaymentTitle => 'Novo Pagamento';

  @override
  String get salesCardProdutoRankLucroTitle => 'Ranking de produtos';

  @override
  String get salesCardMonthlyPnlTitle => 'Resultado mensal';

  @override
  String get salesCardProdutoTendenciaTitle => 'Tendencia de vendas';

  @override
  String get salesMonthlyPnlPageSubtitle =>
      'Venda, lucro e custo da mercadoria por mes na filial selecionada. A janela termina no mes de referencia.';

  @override
  String get salesMonthlyPnlFilterAnchorMonth => 'Mes de referencia';

  @override
  String get salesMonthlyPnlChartTitle => 'Resultado mensal';

  @override
  String get salesMonthlyPnlChartSubtitle =>
      'Venda, lucro e custo da mercadoria por mes (filial selecionada).';

  @override
  String get salesMonthlyPnlSeriesSalesLabel => 'Vendas';

  @override
  String get salesMonthlyPnlSeriesProfitLabel => 'Lucro';

  @override
  String get salesMonthlyPnlSeriesCostLabel => 'Custo da mercadoria';

  @override
  String get salesMonthlyPnlEmpty => 'Sem dados mensais para este periodo.';

  @override
  String get salesMonthlyPnlLoadFailed =>
      'Nao foi possivel carregar o grafico mensal. Tente novamente mais tarde.';

  @override
  String get salesMonthlyPnlChartSemantics =>
      'Grafico do resultado mensal com venda, lucro e custo da mercadoria na filial selecionada';

  @override
  String get salesProdutoRankLucroChartTitle => 'Top produtos';

  @override
  String get salesProdutoRankLucroFilterPeriod => 'Periodo';

  @override
  String get salesProdutoRankLucroFilterSortBy => 'Metrica';

  @override
  String get salesProdutoRankLucroSortQuantity => 'Quantidade vendida';

  @override
  String get salesProdutoRankLucroSortProfit => 'Lucro total';

  @override
  String get salesProdutoTendenciaPageSubtitle =>
      'Visao executiva da tendencia de venda por produto com resumo, movers e detalhe paginado.';

  @override
  String get salesProdutoTendenciaFilterCurrentPeriod => 'Periodo atual';

  @override
  String get salesProdutoTendenciaFilterPreviousPeriod => 'Periodo anterior';

  @override
  String get salesProdutoTendenciaFilterSearch => 'Busca';

  @override
  String get salesProdutoTendenciaFilterSearchHint => 'Produto, grupo ou marca';

  @override
  String get salesProdutoTendenciaFilterClassification => 'Classificacao';

  @override
  String get salesProdutoTendenciaFilterGroup => 'Grupo';

  @override
  String get salesProdutoTendenciaFilterBrand => 'Marca';

  @override
  String get salesProdutoTendenciaFilterPageSize => 'Linhas por pagina';

  @override
  String get salesProdutoTendenciaFilterAllOption => 'Todos';

  @override
  String get salesProdutoTendenciaSummaryTitle => 'Resumo executivo';

  @override
  String get salesProdutoTendenciaSummarySubtitle =>
      'Visao geral da movimentacao por classificacao de tendencia.';

  @override
  String get salesProdutoTendenciaSummaryByClassificacaoTitle =>
      'Produtos por classificacao';

  @override
  String get salesProdutoTendenciaSummaryByClassificacaoSubtitle =>
      'Distribuicao e impacto dentro da pagina carregada.';

  @override
  String get salesProdutoTendenciaTopMoversTitle => 'Top movers';

  @override
  String get salesProdutoTendenciaTopMoversSubtitle =>
      'Maiores altas e quedas no periodo selecionado.';

  @override
  String get salesProdutoTendenciaTopGainersTitle => 'Top 5 altas';

  @override
  String get salesProdutoTendenciaTopLosersTitle => 'Top 5 quedas';

  @override
  String get salesProdutoTendenciaDetailsTitle => 'Detalhes';

  @override
  String get salesProdutoTendenciaDetailsSubtitle =>
      'Lista paginada com produto, classificacao, grupo e marca.';

  @override
  String get salesProdutoTendenciaDetailsEntityLabel => 'linhas';

  @override
  String get salesProdutoTendenciaNoData =>
      'Sem dados de tendencia para os filtros selecionados.';

  @override
  String get salesProdutoTendenciaKpiGrowing => 'Produtos crescendo';

  @override
  String get salesProdutoTendenciaKpiFalling => 'Produtos caindo';

  @override
  String get salesProdutoTendenciaKpiNewProducts => 'Produtos novos';

  @override
  String get salesProdutoTendenciaKpiStopped => 'Parou de vender';

  @override
  String get salesProdutoTendenciaKpiNetImpact => 'Impacto liquido (qtd)';

  @override
  String get salesProdutoTendenciaColProduct => 'Produto';

  @override
  String get salesProdutoTendenciaColClassificacao => 'Classificacao';

  @override
  String get salesProdutoTendenciaColGrupo => 'Grupo';

  @override
  String get salesProdutoTendenciaColMarca => 'Marca';

  @override
  String get salesProdutoTendenciaColDiferenca => 'Diferenca';

  @override
  String get salesProdutoTendenciaColPercentual => 'Tendencia %';

  @override
  String get salesProdutoTendenciaClassificacaoStopped => 'Parou de vender';

  @override
  String get salesProdutoTendenciaClassificacaoNew => 'Novo produto';

  @override
  String get salesProdutoTendenciaClassificacaoGrowing => 'Crescendo';

  @override
  String get salesProdutoTendenciaClassificacaoFalling => 'Caindo';

  @override
  String get salesProdutoTendenciaClassificacaoStable => 'Estavel';

  @override
  String salesProdutoTendenciaActiveFiltersSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros extras',
      one: '1 filtro extra',
      zero: 'Sem filtros extras',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaDetailsNotice(String pageSize) {
    return 'Pode haver mais linhas no resultado. Use a paginacao para carregar as proximas paginas (tamanho atual: $pageSize).';
  }

  @override
  String get agentStatusPending => 'Pendente';

  @override
  String get agentStatusRejected => 'Rejeitado';

  @override
  String get agentStatusUnknown => 'Desconhecido';

  @override
  String get reportFiltersApplyButton => 'Aplicar';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get shellNavDashboardLabel => 'Visão geral';

  @override
  String get shellNavDashboardSubtitle => 'Resumo operacional e KPIs';

  @override
  String get shellNavAgentsLabel => 'Agentes';

  @override
  String get shellNavAgentsSubtitle => 'Fontes de dados e acessos';

  @override
  String get shellNavSettingsLabel => 'Perfil';

  @override
  String get shellNavSettingsSubtitle => 'Conta e preferências';

  @override
  String get shellNavSalesLabel => 'Vendas';

  @override
  String get shellNavSalesSubtitle =>
      'Pedidos, receita e indicadores comerciais';

  @override
  String get shellNavReturnsLabel => 'Devoluções';

  @override
  String get shellNavReturnsSubtitle => 'Devoluções, trocas e notas de crédito';

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
  String get shellNavInventorySubtitle => 'Níveis de estoque e movimentações';

  @override
  String get shellPlaceholderUnderConstructionTitle => 'Em construção';

  @override
  String get shellPlaceholderUnderConstructionBody =>
      'Esta seção estará disponível em uma atualização futura.';

  @override
  String get shellAppBrandName => 'Colmeia';

  @override
  String get shellOpenSettingsSemantics => 'Abrir configurações';

  @override
  String get shellOpenProfileSemantics => 'Abrir perfil e conta';

  @override
  String get shellNavSignOut => 'Sair';

  @override
  String get shellNavSigningOut => 'Saindo...';

  @override
  String get shellNavSignOutSemanticsLoading => 'Encerrando sessão';

  @override
  String get shellSignOutDialogTitle => 'Sair da conta?';

  @override
  String get shellSignOutDialogConfirm => 'Sair';

  @override
  String get shellSignOutDialogMessage =>
      'Você precisará entrar novamente para acessar os dados.';

  @override
  String get shellNavMainSemantics => 'Navegação principal';

  @override
  String get userPermissionViewDashboard => 'Visão geral';

  @override
  String get userPermissionManageAgents => 'Gestão de agentes';

  @override
  String get userPermissionViewSales => 'Vendas (acesso ao módulo)';

  @override
  String get userPermissionViewReturns => 'Devoluções (acesso ao módulo)';

  @override
  String get userPermissionViewFinance => 'Financeiro (acesso ao módulo)';

  @override
  String get userPermissionViewPurchases => 'Compras (acesso ao módulo)';

  @override
  String get userPermissionViewInventory => 'Estoque (acesso ao módulo)';

  @override
  String get dashboardPartialAgentQueriesTitle =>
      'Dados da visão geral incompletos';

  @override
  String get dashboardPartialAgentQueriesMessage =>
      'Alguns agentes aprovados não retornaram dados. Os totais podem estar incompletos.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Agentes sem token de cliente salvo';

  @override
  String get dashboardMissingClientTokenMessage =>
      'Estes agentes aprovados foram ignorados porque não há token de cliente local. Cadastre o token na tela do agente para incluir os dados.';

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
      'Nenhum agente com acesso aprovado possui token de cliente salvo neste dispositivo. Abra a gestão de agentes para cadastrar o token e liberar a consulta da visão geral.';

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
  String get dashboardAgentsOfflineTitle => 'Agentes offline no momento';

  @override
  String get dashboardAgentsOfflineMessage =>
      'Estes agentes aprovados têm um token salvo, mas o hub os reporta como desconectados. Peça ao operador para reconectá-los e tente novamente.';

  @override
  String get dashboardAffectedAgentsSheetTitleOffline =>
      'Agentes reportados como offline pelo hub';

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
  String get dashboardHomeFiltersAgentsLabel => 'AGENTES';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visao geral para listar os agentes.';

  @override
  String get dashboardHomeFiltersYearMonthLabel => 'ANO / MÊS';

  @override
  String get dashboardHomeFiltersCurrentMonth => 'Mês atual';

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
  String get overviewTopProductsTitle => 'Produtos mais vendidos';

  @override
  String overviewTopProductsSubtitle(int count) {
    return 'Por agente (sem unir cadastros). Até $count produtos.';
  }

  @override
  String get overviewTopProductsNoEligibleAgents =>
      'Nenhum agente disponível para este gráfico. Salve o token no agente ou ajuste o filtro.';

  @override
  String get overviewTopProductsInvalidPeriod =>
      'O período selecionado não é válido para este gráfico.';

  @override
  String get overviewTopProductsEmpty =>
      'Sem vendas de produto neste período para este agente.';

  @override
  String get overviewTopProductsLoadFailed =>
      'Não foi possível carregar este gráfico. Tente novamente.';

  @override
  String get overviewTopProductsLoadingSemantics =>
      'Carregando gráfico de produtos…';

  @override
  String overviewTopProductsTooltipLine(
    int sales,
    String items,
    String revenue,
    String cost,
    String margin,
  ) {
    return '$sales vendas · $items itens · $revenue faturamento · $cost custo rep. · $margin% margem';
  }

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
  String get chartOpenFullscreenTooltip => 'Abrir gráfico em tela cheia';

  @override
  String get chartCloseFullscreenTooltip => 'Fechar gráfico em tela cheia';

  @override
  String get chartFullscreenUnavailableTitle => 'Gráfico indisponível';

  @override
  String get chartFullscreenUnavailableMessage =>
      'Não foi possível abrir este gráfico em tela cheia. Volte e tente novamente.';

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
  String get clientAgentsMaintenanceSubtitleOwner =>
      'Use as abas para gerir agentes aprovados, reenviar solicitacoes de clientes e revisar acessos dos agentes que voce administra.';

  @override
  String get clientAgentsTabMyAgents => 'Meus agentes';

  @override
  String get clientAgentsTabRequestAccess => 'Solicitar acesso';

  @override
  String get clientAgentsTabRequests => 'Solicitacoes';

  @override
  String get clientAgentsTabOwnerRequests => 'Revisar solicitacoes';

  @override
  String get clientAgentsTabOwnerClients => 'Clientes aprovados';

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
  String get clientAgentsRetryRequestAction => 'Tentar novamente';

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
  String get clientAgentsRetryMissingRequestId =>
      'Esta solicitacao nao pode ser reenviada porque o identificador nao esta disponivel.';

  @override
  String get clientAgentsRetrySuccess =>
      'A solicitacao foi reenviada. Vamos continuar acompanhando a aprovacao.';

  @override
  String get clientAgentsDiscardQueuedRequestAction => 'Remover da fila';

  @override
  String get clientAgentsDiscardQueuedRequestSuccess =>
      'O envio pendente foi removido. Voce pode solicitar acesso de novo quando quiser.';

  @override
  String get clientAgentsDiscardQueuedRequestInvalidState =>
      'Este envio nao pode ser removido da fila no estado atual.';

  @override
  String get clientAgentsOwnerActionFailedTitle =>
      'Nao foi possivel concluir a acao do responsavel';

  @override
  String get clientAgentsOwnerRequestsLoadErrorTitle =>
      'Nao foi possivel carregar as solicitacoes para revisao';

  @override
  String get clientAgentsOwnerRequestsEmpty =>
      'Nenhuma solicitacao de cliente precisa da sua revisao agora.';

  @override
  String get clientAgentsOwnerApproveAction => 'Aprovar';

  @override
  String get clientAgentsOwnerRejectAction => 'Rejeitar';

  @override
  String get clientAgentsOwnerRequestsStatusPending =>
      'Aguardando sua decisao para este agente.';

  @override
  String get clientAgentsOwnerRequestsStatusApproved =>
      'Aprovada e ja disponivel para o cliente.';

  @override
  String get clientAgentsOwnerRequestsStatusRejected =>
      'Rejeitada durante a revisao do responsavel.';

  @override
  String get clientAgentsOwnerRequestsStatusExpired =>
      'Expirou antes da revisao final.';

  @override
  String get clientAgentsOwnerRequestsStatusUnknown =>
      'O status mais recente da revisao nao esta disponivel.';

  @override
  String get clientAgentsOwnerApproveSuccess =>
      'A solicitacao de acesso foi aprovada.';

  @override
  String get clientAgentsOwnerRejectSuccess =>
      'A solicitacao de acesso foi rejeitada.';

  @override
  String get clientAgentsOwnerClientsEmptyAgents =>
      'Nenhum agente administrado esta disponivel para esta conta ainda.';

  @override
  String get clientAgentsOwnerClientsAgentSelectorLabel => 'Agente';

  @override
  String get clientAgentsOwnerClientsAgentSelectorHint =>
      'Escolha um agente administrado';

  @override
  String get clientAgentsOwnerClientsLoadErrorTitle =>
      'Nao foi possivel carregar os clientes aprovados';

  @override
  String get clientAgentsOwnerClientsEmpty =>
      'Nenhum cliente aprovado esta vinculado a este agente ainda.';

  @override
  String get clientAgentsOwnerClientsApprovedSubtitle =>
      'Aprovado para este agente.';

  @override
  String get clientAgentsOwnerRevokeAction => 'Revogar acesso';

  @override
  String get clientAgentsOwnerRevokeSuccess =>
      'O acesso do cliente foi revogado.';

  @override
  String get clientAgentDetailSessionUnavailable =>
      'Sessao indisponivel para carregar o agente.';

  @override
  String get appInlineErrorRetry => 'Tentar novamente';

  @override
  String appInlineErrorRetryCountdown(int seconds) {
    return 'Tentar em ${seconds}s';
  }

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
  String clientAgentsSyncRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para esperarmos. Tente de novo em ${seconds}s.';
  }

  @override
  String clientAgentsRequestAccessRetryAfterCountdown(int seconds) {
    return 'Muitas solicitacoes de acesso. Tente de novo em ${seconds}s.';
  }

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
  String get clientAgentDetailRefreshFromAgent => 'Recarregar do agente';

  @override
  String get clientAgentDetailRefreshFromAgentSuccess =>
      'Perfil recarregado direto do agente.';

  @override
  String get clientAgentDetailRefreshFromAgentUnsupported =>
      'Este agente nao implementa agent.getProfile via RPC.';

  @override
  String clientAgentDetailRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para aguardar. Tente novamente em ${seconds}s.';
  }

  @override
  String get clientAgentDetailSectionPolicy => 'Permissoes deste token';

  @override
  String get clientAgentDetailSectionPolicySubtitle =>
      'Resolvidas pelo agente para o token atualmente salvo no servidor. Se a politica mudar apos revogacao ou alteracao de escopo, recarregue a tela.';

  @override
  String get clientAgentDetailPolicyFullAccess =>
      'Acesso total (todas as tabelas, views e permissoes).';

  @override
  String get clientAgentDetailPolicyAllTables =>
      'Permitido em todas as tabelas.';

  @override
  String get clientAgentDetailPolicyAllViews => 'Permitido em todas as views.';

  @override
  String get clientAgentDetailPolicyAllPermissions =>
      'Tem todas as permissoes.';

  @override
  String get clientAgentDetailPolicyTablesLabel => 'Tabelas permitidas';

  @override
  String get clientAgentDetailPolicyViewsLabel => 'Views permitidas';

  @override
  String get clientAgentDetailPolicyPermissionsLabel => 'Permissoes';

  @override
  String get clientAgentDetailPolicyRevoked =>
      'Este token esta marcado como revogado pelo agente.';

  @override
  String get clientAgentDetailPolicyRevokedSaveNewToken => 'Salvar novo token';

  @override
  String get clientAgentDetailPolicyUnsupported =>
      'Este agente nao expoe introspecao da politica do token.';

  @override
  String get clientAgentDetailPolicyEmpty =>
      'O agente nao retornou nenhuma regra para este token.';

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
  String get clientAgentsErrorRetryClientAccessRequest =>
      'Nao foi possivel reenviar esta solicitacao de acesso.';

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
  String get clientAgentsErrorLoadManagedAgents =>
      'Nao foi possivel carregar os agentes administrados.';

  @override
  String get clientAgentsErrorLoadOwnerAccessRequests =>
      'Nao foi possivel carregar as solicitacoes de acesso para revisao.';

  @override
  String get clientAgentsErrorApproveOwnerAccessRequest =>
      'Nao foi possivel aprovar esta solicitacao de acesso.';

  @override
  String get clientAgentsErrorRejectOwnerAccessRequest =>
      'Nao foi possivel rejeitar esta solicitacao de acesso.';

  @override
  String get clientAgentsErrorLoadOwnerApprovedClients =>
      'Nao foi possivel carregar os clientes aprovados deste agente.';

  @override
  String get clientAgentsErrorRevokeOwnerClientAccess =>
      'Nao foi possivel revogar este acesso de cliente.';

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
  String get clientAgentsErrorAgentProfileCasMismatch =>
      'Outro dispositivo atualizou este agente. Recarregue a tela e reaplique suas alteracoes.';

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
  String get formsDemoDatePickersFormTitle => 'Date pickers no Form';

  @override
  String get formsDemoDatePickersFormSubtitle =>
      'Form nativo + FormField. Toque em Aplicar no sheet para confirmar; fechar sem aplicar mantem o valor. Remover limpa de forma explicita.';

  @override
  String get formsDemoFormBuilderSectionTitle =>
      'FormBuilder + dropdowns e datas';

  @override
  String get formsDemoFormBuilderSectionSubtitle =>
      'Mesmos wrappers dos relatorios: dropdown, multi-select e os mesmos date pickers da secao Form acima (FormBuilderField + AppFormBuilderDate*).';

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
  String get overviewLucratividadeTitle => 'Lucratividade por agente';

  @override
  String get overviewLucratividadeSubtitle =>
      'Receita, custo e margem no periodo selecionado, por agente (todas as filiais somadas).';

  @override
  String get overviewLucratividadeSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeSwitchMargin => 'Margem %';

  @override
  String get overviewLucratividadeProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeCostSeriesLabel => 'Custo reposicao';

  @override
  String get overviewLucratividadeMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLucratividadeEmpty =>
      'Sem dados de lucratividade para este periodo.';

  @override
  String get overviewLucratividadeMultiAgentHint =>
      'Nenhum agente aprovado esta disponivel para carregar a lucratividade. Adicione ou conecte um agente primeiro.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Carregando grafico de lucratividade por filial…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Lucratividade mensal do produto';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Receita, custo de reposicao e margem por mes (agente selecionado).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'Sem dados de lucratividade para este periodo.';

  @override
  String get overviewLucratividadeMensalMultiAgentHint =>
      'Selecione um unico agente para visualizar a lucratividade mensal.';

  @override
  String get overviewLucratividadeMensalSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeMensalSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeMensalSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeMensalSwitchMargin => 'Margem %';

  @override
  String get overviewLucratividadeMensalProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeMensalRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeMensalCostSeriesLabel => 'Custo reposicao';

  @override
  String get overviewLucratividadeMensalMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLoadingLucratividadeMensalSemantics =>
      'Carregando grafico de lucratividade mensal do produto…';

  @override
  String get salesHubTitle => 'Vendas';

  @override
  String get salesHubSubtitle =>
      'Acesse e gerencie informacoes comerciais por categoria.';

  @override
  String get salesAgentPickerLabel => 'Agente';

  @override
  String get salesAgentPickerEmpty => 'Selecione um agente';

  @override
  String get salesAgentPickerSheetTitle => 'Selecione um agente';

  @override
  String get salesAgentRequiredTitle => 'Selecao de agente obrigatoria';

  @override
  String get salesAgentRequiredMessage =>
      'Selecione um agente para visualizar essas informacoes.';

  @override
  String get salesCardOpenAccountsTitle => 'Contas em Aberto';

  @override
  String get salesCardPaidAccountsTitle => 'Contas Pagas';

  @override
  String get salesCardPaymentHistoryTitle => 'Historico de Pagamentos';

  @override
  String get salesCardNewPaymentTitle => 'Novo Pagamento';

  @override
  String get salesCardProdutoRankLucroTitle => 'Ranking de produtos';

  @override
  String get salesCardMonthlyPnlTitle => 'Resultado mensal';

  @override
  String get salesCardProdutoTendenciaTitle => 'Tendencia de vendas';

  @override
  String get salesMonthlyPnlPageSubtitle =>
      'Venda, lucro e custo da mercadoria por mes na filial selecionada. A janela termina no mes de referencia.';

  @override
  String get salesMonthlyPnlFilterAnchorMonth => 'Mes de referencia';

  @override
  String get salesMonthlyPnlChartTitle => 'Resultado mensal';

  @override
  String get salesMonthlyPnlChartSubtitle =>
      'Venda, lucro e custo da mercadoria por mes (filial selecionada).';

  @override
  String get salesMonthlyPnlSeriesSalesLabel => 'Vendas';

  @override
  String get salesMonthlyPnlSeriesProfitLabel => 'Lucro';

  @override
  String get salesMonthlyPnlSeriesCostLabel => 'Custo da mercadoria';

  @override
  String get salesMonthlyPnlEmpty => 'Sem dados mensais para este periodo.';

  @override
  String get salesMonthlyPnlLoadFailed =>
      'Nao foi possivel carregar o grafico mensal. Tente novamente mais tarde.';

  @override
  String get salesMonthlyPnlChartSemantics =>
      'Grafico do resultado mensal com venda, lucro e custo da mercadoria na filial selecionada';

  @override
  String get salesProdutoRankLucroChartTitle => 'Top produtos';

  @override
  String get salesProdutoRankLucroFilterPeriod => 'Periodo';

  @override
  String get salesProdutoRankLucroFilterSortBy => 'Metrica';

  @override
  String get salesProdutoRankLucroSortQuantity => 'Quantidade vendida';

  @override
  String get salesProdutoRankLucroSortProfit => 'Lucro total';

  @override
  String get salesProdutoTendenciaPageSubtitle =>
      'Visao executiva da tendencia de venda por produto com resumo, movers e detalhe paginado.';

  @override
  String get salesProdutoTendenciaFilterCurrentPeriod => 'Periodo atual';

  @override
  String get salesProdutoTendenciaFilterPreviousPeriod => 'Periodo anterior';

  @override
  String get salesProdutoTendenciaFilterSearch => 'Busca';

  @override
  String get salesProdutoTendenciaFilterSearchHint => 'Produto, grupo ou marca';

  @override
  String get salesProdutoTendenciaFilterClassification => 'Classificacao';

  @override
  String get salesProdutoTendenciaFilterGroup => 'Grupo';

  @override
  String get salesProdutoTendenciaFilterBrand => 'Marca';

  @override
  String get salesProdutoTendenciaFilterPageSize => 'Linhas por pagina';

  @override
  String get salesProdutoTendenciaFilterAllOption => 'Todos';

  @override
  String get salesProdutoTendenciaSummaryTitle => 'Resumo executivo';

  @override
  String get salesProdutoTendenciaSummarySubtitle =>
      'Visao geral da movimentacao por classificacao de tendencia.';

  @override
  String get salesProdutoTendenciaSummaryByClassificacaoTitle =>
      'Produtos por classificacao';

  @override
  String get salesProdutoTendenciaSummaryByClassificacaoSubtitle =>
      'Distribuicao e impacto dentro da pagina carregada.';

  @override
  String get salesProdutoTendenciaTopMoversTitle => 'Top movers';

  @override
  String get salesProdutoTendenciaTopMoversSubtitle =>
      'Maiores altas e quedas no periodo selecionado.';

  @override
  String get salesProdutoTendenciaTopGainersTitle => 'Top 5 altas';

  @override
  String get salesProdutoTendenciaTopLosersTitle => 'Top 5 quedas';

  @override
  String get salesProdutoTendenciaDetailsTitle => 'Detalhes';

  @override
  String get salesProdutoTendenciaDetailsSubtitle =>
      'Lista paginada com produto, classificacao, grupo e marca.';

  @override
  String get salesProdutoTendenciaDetailsEntityLabel => 'linhas';

  @override
  String get salesProdutoTendenciaNoData =>
      'Sem dados de tendencia para os filtros selecionados.';

  @override
  String get salesProdutoTendenciaKpiGrowing => 'Produtos crescendo';

  @override
  String get salesProdutoTendenciaKpiFalling => 'Produtos caindo';

  @override
  String get salesProdutoTendenciaKpiNewProducts => 'Produtos novos';

  @override
  String get salesProdutoTendenciaKpiStopped => 'Parou de vender';

  @override
  String get salesProdutoTendenciaKpiNetImpact => 'Impacto liquido (qtd)';

  @override
  String get salesProdutoTendenciaColProduct => 'Produto';

  @override
  String get salesProdutoTendenciaColClassificacao => 'Classificacao';

  @override
  String get salesProdutoTendenciaColGrupo => 'Grupo';

  @override
  String get salesProdutoTendenciaColMarca => 'Marca';

  @override
  String get salesProdutoTendenciaColDiferenca => 'Diferenca';

  @override
  String get salesProdutoTendenciaColPercentual => 'Tendencia %';

  @override
  String get salesProdutoTendenciaClassificacaoStopped => 'Parou de vender';

  @override
  String get salesProdutoTendenciaClassificacaoNew => 'Novo produto';

  @override
  String get salesProdutoTendenciaClassificacaoGrowing => 'Crescendo';

  @override
  String get salesProdutoTendenciaClassificacaoFalling => 'Caindo';

  @override
  String get salesProdutoTendenciaClassificacaoStable => 'Estavel';

  @override
  String salesProdutoTendenciaActiveFiltersSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros extras',
      one: '1 filtro extra',
      zero: 'Sem filtros extras',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaDetailsNotice(String pageSize) {
    return 'Pode haver mais linhas no resultado. Use a paginacao para carregar as proximas paginas (tamanho atual: $pageSize).';
  }

  @override
  String get agentStatusPending => 'Pendente';

  @override
  String get agentStatusRejected => 'Rejeitado';

  @override
  String get agentStatusUnknown => 'Desconhecido';

  @override
  String get reportFiltersApplyButton => 'Aplicar';
}
