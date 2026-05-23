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
  String shellSectionBreadcrumbSemantics(String sectionName) {
    return 'Ir para o início da seção $sectionName';
  }

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
      'Algumas filiais aprovadas não retornaram dados. Os totais podem estar incompletos.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Filiais sem token de cliente salvo';

  @override
  String get dashboardMissingClientTokenMessage =>
      'Estas filiais aprovadas foram ignoradas porque não há token de cliente local. Cadastre o token na gestão de filiais para incluir os dados.';

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
      'Nenhuma filial aprovada possui token de cliente salvo neste dispositivo. Abra a gestão de filiais para cadastrar o token e liberar a consulta da visão geral.';

  @override
  String dashboardViewAffectedAgentsList(int count) {
    return 'Ver filiais ($count)';
  }

  @override
  String get dashboardAffectedAgentsSheetTitlePartialFailure =>
      'Filiais que não retornaram dados';

  @override
  String get dashboardAffectedAgentsSheetTitleMissingToken =>
      'Filiais sem token de cliente salvo';

  @override
  String get dashboardAffectedAgentsSheetTitleSetupRequired =>
      'Filiais aprovadas sem token de cliente neste dispositivo';

  @override
  String get dashboardAgentsOfflineTitle => 'Filiais offline no momento';

  @override
  String get dashboardAgentsOfflineMessage =>
      'Estas filiais aprovadas têm um token salvo, mas o hub as reporta como desconectadas. Peça ao operador para reconectá-las e tente novamente.';

  @override
  String get dashboardAffectedAgentsSheetTitleOffline =>
      'Filiais reportadas como offline pelo hub';

  @override
  String get dashboardMultiAgentAggregationTitle => 'Varias filiais';

  @override
  String get dashboardMultiAgentAggregationMessage =>
      'Este resumo agrega dados de varias filiais aprovadas. Se houver sobreposição entre bases, os totais podem ficar acima de uma unica fonte.';

  @override
  String get overviewHomeAlertErrorDetailsButton => 'Detalhes do erro';

  @override
  String get overviewHomeAlertDetailsCopiedSnackbar =>
      'Copiado para a área de transferência';

  @override
  String get overviewHomeAlertFailureSourcePaymentResumo =>
      'Consulta resumo por forma de pagamento';

  @override
  String get overviewHomeAlertFailureSourceLucratividadePeriod =>
      'Consulta lucratividade (período)';

  @override
  String get overviewHomeAlertDetailsUserLine => 'O que ocorreu';

  @override
  String get overviewHomeAlertDetailsTechnicalLine => 'Detalhe técnico';

  @override
  String get overviewHomeAlertDetailsNoEntries =>
      'Não há linhas de diagnóstico para este aviso.';

  @override
  String get overviewHomeAlertDetailsStaleIntro =>
      'Estes números vêm do último resumo obtido com sucesso neste aparelho.\n\n';

  @override
  String get overviewHomeAlertErrorDetailsSemanticsLabel =>
      'Abre uma folha com o texto de diagnóstico completo. Pode selecionar e copiar.';

  @override
  String get overviewHomeAlertDetailsCopySemanticsLabel =>
      'Copia o texto de diagnóstico para a área de transferência';

  @override
  String overviewHomeAlertDetailsAgentSemanticSummary(
    String agentName,
    String agentId,
    String sourceLabel,
    String userMessage,
  ) {
    return '$agentName, identificador da filial $agentId. $sourceLabel. $userMessage.';
  }

  @override
  String get dashboardPaymentSummaryTitle => 'Resumo por forma de pagamento';

  @override
  String get dashboardPaymentSummarySubtitle =>
      'Detalhamento de vendas, ticket médio e participação.';

  @override
  String get dashboardPaymentSummaryEmptyTitle => 'Sem formas de pagamento';

  @override
  String get dashboardPaymentSummaryEmptyMessage =>
      'Não há linhas de forma de pagamento para este período.';

  @override
  String get dashboardPaymentSummaryHeaderRevenueAbbr => 'FATURAM.';

  @override
  String get dashboardPaymentSummaryTooltipRevenueAbbr =>
      'Faturamento no período selecionado';

  @override
  String get dashboardPaymentSummaryHeaderParticipationAbbr => 'PARTIC.';

  @override
  String get dashboardPaymentSummaryTooltipParticipationAbbr =>
      'Participação percentual no faturamento total';

  @override
  String get dashboardPaymentSummaryHeaderSales => 'VENDAS';

  @override
  String get dashboardPaymentSummaryHeaderAvgTicket => 'TICKET\nMEDIO';

  @override
  String get dashboardHomeFiltersAgentsLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visão geral para listar as filiais.';

  @override
  String get dashboardHomeFiltersBranchesLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersBranchesEmptyHint =>
      'Carregue a visão geral para listar as filiais.';

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
    return 'Todas as filiais ($count)';
  }

  @override
  String overviewHomeBranchFilterAllBranchesSummary(int count) {
    return 'Todas as filiais ($count)';
  }

  @override
  String overviewAgentFilterSelectedCount(int count) {
    return '$count filiais selecionadas';
  }

  @override
  String overviewHomeBranchFilterSelectedCount(int count) {
    return '$count filiais selecionadas';
  }

  @override
  String get overviewAgentFilterRefineAction => 'Refinar filiais';

  @override
  String get overviewAgentFilterEditAction => 'Editar';

  @override
  String get overviewAgentFilterSheetTitle => 'Selecionar filiais';

  @override
  String get overviewAgentFilterSheetSearchHint => 'Buscar filiais…';

  @override
  String get overviewHomeBranchFilterSheetTitle => 'Selecionar filiais';

  @override
  String get overviewHomeBranchFilterSheetSearchHint => 'Buscar filiais…';

  @override
  String get overviewHomeBranchFilterSelectAll => 'Selecionar todos';

  @override
  String get overviewHomeBranchFilterSelectAllFullRoster =>
      'Todas as filiais (lista completa)';

  @override
  String get overviewHomeBranchFilterDeselectAll => 'Desmarcar todos';

  @override
  String get overviewHomeBranchFilterSelectMatching =>
      'Selecionar todas as filiais filtradas';

  @override
  String get overviewHomeBranchFilterDeselectMatching =>
      'Desmarcar filiais filtradas';

  @override
  String overviewHomeBranchFilterSelectionCount(
    int selectedCount,
    int totalCount,
  ) {
    return '$selectedCount de $totalCount filiais selecionadas';
  }

  @override
  String get overviewHomeBranchFilterApplyRequiresSelectionHint =>
      'Escolha pelo menos uma filial para aplicar.';

  @override
  String get overviewHomeBranchFilterSheetUseAllBranches =>
      'Usar todas as filiais';

  @override
  String get overviewHomeBranchFilterApplyDisabledSemantics =>
      'Aplicar. Desativado. Selecione pelo menos uma filial.';

  @override
  String get overviewHomeBranchFilterRefineAction => 'Refinar filiais';

  @override
  String get overviewHomeBranchFilterEditAction => 'Editar';

  @override
  String get overviewHomeBranchFilterApply => 'Aplicar';

  @override
  String get overviewHomeBranchFilterCancel => 'Cancelar';

  @override
  String get overviewHomeBranchFilterMissingClientTokenRowSubtitle =>
      'Sem token neste dispositivo para esta filial — consultas SQL são ignoradas.';

  @override
  String get overviewAgentFilterApply => 'Aplicar';

  @override
  String get overviewAgentFilterCancel => 'Cancelar';

  @override
  String get overviewAgentFilterNoSearchResults =>
      'Nenhuma filial corresponde à busca.';

  @override
  String get overviewHomeBranchFilterNoSearchResults =>
      'Nenhuma filial corresponde à busca.';

  @override
  String get overviewAgentFilterMissingClientTokenBanner =>
      'Filiais sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get overviewHomeBranchFilterMissingClientTokenBanner =>
      'Filiais sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get overviewAgentFilterMissingClientTokenRowSubtitle =>
      'Sem token neste dispositivo para esta filial — consultas SQL são ignoradas.';

  @override
  String get chartCategoryDonutEmptyForFilter =>
      'Sem dados de categorias para este recorte.';

  @override
  String get dashboardAgentRankingTitle => 'Ranking por filial';

  @override
  String get dashboardAgentRankingSubtitle =>
      'Faturamento total por filial no período.';

  @override
  String get dashboardUserRankingTitle => 'Ranking por operador';

  @override
  String get dashboardUserRankingSubtitle =>
      'Faturamento por operador no período.';

  @override
  String get overviewAgentRankingEmpty =>
      'Sem faturamento por filial neste período.';

  @override
  String get overviewUserRankingEmpty =>
      'Sem faturamento por operador neste período.';

  @override
  String get overviewTopProductsTitle => 'Produtos mais vendidos';

  @override
  String overviewTopProductsSubtitle(int count) {
    return 'Por filial (sem unir cadastros). Até $count produtos.';
  }

  @override
  String get overviewTopProductsNoEligibleAgents =>
      'Nenhuma filial disponível para este gráfico. Salve o token na filial ou ajuste o filtro.';

  @override
  String get overviewTopProductsInvalidPeriod =>
      'O período selecionado não é válido para este gráfico.';

  @override
  String get overviewTopProductsEmpty =>
      'Sem vendas de produto neste período para esta filial.';

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
      'Resumo consolidado das filiais aprovadas (ligadas ao hub).';

  @override
  String get overviewHomeManageBranchesAction => 'Gestão de filiais';

  @override
  String get overviewHomeAlertsSectionTitle => 'Avisos';

  @override
  String get overviewLoadErrorTitle =>
      'Não foi possível carregar a visão geral';

  @override
  String get overviewStaleCacheTitle => 'Dados salvos neste aparelho';

  @override
  String get overviewStaleCacheMessage =>
      'Não foi possível atualizar agora. Os números abaixo refletem o último resumo obtido com sucesso.';

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
      'Carregando gráfico dos últimos 12 meses…';

  @override
  String get overviewLoadingWeekdaySalesSemantics =>
      'Carregando gráfico de vendas por dia da semana…';

  @override
  String get overviewMonthlyParcelsTitle => 'Últimos 12 meses';

  @override
  String get overviewMonthlyParcelsSubtitle =>
      'Quantidade de vendas e total em parcelas por mês (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSalesSeriesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsAmountSeriesLabel => 'Valor em parcelas';

  @override
  String get overviewMonthlyParcelsEmpty =>
      'Sem dados mensais para este período.';

  @override
  String get overviewMonthlyParcelsLoadFailed =>
      'Não foi possível carregar o gráfico mensal. Tente novamente mais tarde.';

  @override
  String get overviewMonthlyParcelsChartSemantics =>
      'Gráfico dos últimos doze meses de vendas e valor em parcelas';

  @override
  String get overviewMonthlyParcelsSubtitleValueView =>
      'Total em parcelas e quantidade de vendas por mês (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSwitchSalesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsSwitchValueLabel => 'Valor';

  @override
  String get overviewMonthlyParcelsChartSemanticsValueView =>
      'Gráfico dos últimos doze meses de valor em parcelas e vendas';

  @override
  String get overviewDailySalesTitle => 'Vendas por dia';

  @override
  String get overviewDailySalesSubtitle =>
      'Totais por dia civil no período selecionado (agregado das filiais no escopo).';

  @override
  String get overviewDailySalesEmpty =>
      'Sem dados de vendas diárias neste período.';

  @override
  String get overviewDailySalesLoadFailed =>
      'Não foi possível carregar o gráfico de vendas diárias. Tente novamente mais tarde.';

  @override
  String get overviewDailySalesChartSemantics =>
      'Gráfico de quantidade de vendas e faturamento por dia';

  @override
  String get overviewDailySalesRevenueChartSemantics =>
      'Gráfico de faturamento e quantidade de vendas por dia';

  @override
  String get overviewLoadingDailySalesSemantics =>
      'Carregando gráfico de vendas diárias';

  @override
  String overviewDailySalesTooltip(
    String date,
    String salesCount,
    String salesAmount,
  ) {
    return '$date: $salesCount vendas - $salesAmount';
  }

  @override
  String get overviewDailySalesAxisDowMon => 'Segunda';

  @override
  String get overviewDailySalesAxisDowTue => 'Terça';

  @override
  String get overviewDailySalesAxisDowWed => 'Quarta';

  @override
  String get overviewDailySalesAxisDowThu => 'Quinta';

  @override
  String get overviewDailySalesAxisDowFri => 'Sexta';

  @override
  String get overviewDailySalesAxisDowSat => 'Sábado';

  @override
  String get overviewDailySalesAxisDowSun => 'Domingo';

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
  String get overviewKpiAvgTicket => 'Ticket médio';

  @override
  String get overviewUserRankingChartSemanticsExtra =>
      'Cada barra mostra o faturamento total e o ticket médio daquele operador.';

  @override
  String get overviewKpiPaymentMethodCount => 'Formas de pagamento';

  @override
  String get overviewPaymentMixTitle => 'Mix por forma de pagamento';

  @override
  String get overviewPaymentMixSubtitle =>
      'Participação percentual no faturamento do período.';

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
      'Carregando gráfico de categorias…';

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
    return 'Gráfico de rosca. $summary';
  }

  @override
  String get overviewPaymentBarTitle => 'Faturamento por forma de pagamento';

  @override
  String get overviewPaymentBarSubtitle => 'Valor total acumulado no período.';

  @override
  String get overviewPaymentBarEmpty =>
      'Sem faturamento por forma de pagamento neste período.';

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
  String get chartFullscreenDataSnapshotHint =>
      'Os valores do mapa refletem os dados carregados ao abrir a tela cheia.';

  @override
  String get regionMapMetricGroupLabel => 'Métrica';

  @override
  String get regionMapScopeGroupLabel => 'Escopo';

  @override
  String get regionMapRootScopeLabel => 'Todas as regiões';

  @override
  String get regionMapLoadingMessage => 'Carregando mapa…';

  @override
  String get regionMapEmptyStateMessage =>
      'Nenhum dado territorial para exibir.';

  @override
  String get regionMapMetricSelectorSemanticsLabel => 'Métrica do mapa';

  @override
  String get regionMapScopeSemanticsLabel => 'Escopo territorial';

  @override
  String get regionMapDrillUpToRegionsLabel => 'Voltar para regiões';

  @override
  String get regionMapDrillUpToStatesLabel => 'Voltar para estados';

  @override
  String get regionMapDrillUpToCitiesLabel => 'Voltar para cidades';

  @override
  String get regionMapDrillUpLabel => 'Voltar';

  @override
  String get regionMapDrillUpTooltip => 'Retornar ao nível anterior do mapa';

  @override
  String regionMapViewFullScopeTooltip(String label) {
    return 'Ver mapa completo ($label)';
  }

  @override
  String regionMapViewFullScopeSemanticLabel(String label) {
    return 'Ver mapa completo $label';
  }

  @override
  String regionMapFocusScopeTooltip(String label) {
    return 'Focar em $label';
  }

  @override
  String regionMapFocusScopeSemanticLabel(String label) {
    return 'Focar em $label';
  }

  @override
  String get brazilStoreSalesMapMetricGroupLabel => 'Métrica';

  @override
  String get brazilStoreSalesMapRegionGroupLabel => 'Região';

  @override
  String get brazilStoreSalesMapLoadingMessage => 'Carregando mapa do Brasil…';

  @override
  String get brazilStoreSalesMapMarkerSizeLegend => 'Tamanho do ponto';

  @override
  String get brazilStoreSalesMapLegendRevenuePerState => 'Receita por UF';

  @override
  String get brazilStoreSalesMapLegendSalesPerState => 'Vendas por UF';

  @override
  String get brazilStoreSalesMapShowBranchOnMapAction => 'Destacar no mapa';

  @override
  String get brazilStoreSalesMapUnpinBranchButton => 'Desfixar no mapa';

  @override
  String get brazilStoreSalesMapMetricRevenueShort => 'Receita';

  @override
  String get brazilStoreSalesMapMetricSalesShort => 'Vendas';

  @override
  String get brazilStoreSalesMapLegendButton => 'Legenda';

  @override
  String brazilStoreSalesMapStateBucketTooltip(
    String stateName,
    String uf,
    String revenue,
    String salesCount,
    String storeCount,
  ) {
    return '$stateName / $uf\n$revenue | $salesCount vendas | $storeCount lojas';
  }

  @override
  String brazilStoreSalesMapStateInlineTooltip(
    String stateName,
    String uf,
    String revenue,
    String salesCount,
    String storeCount,
  ) {
    return '$stateName ($uf) | $revenue | $salesCount vendas | $storeCount lojas';
  }

  @override
  String get brazilStoreSalesMapSemanticsStoreOnMap => 'Loja no mapa';

  @override
  String get brazilStoreSalesMapSemanticsSalesLoadingSuffix =>
      ', vendas carregando';

  @override
  String get brazilStoreSalesMapSemanticsSalesUnavailableSuffix =>
      ', vendas indisponíveis';

  @override
  String brazilStoreSalesMapSemanticsClusterStores(
    String storeCount,
    String cityLabel,
    String revenue,
    String salesCount,
    String salesStatusSuffix,
  ) {
    return '$storeCount lojas em $cityLabel, $revenue, $salesCount vendas$salesStatusSuffix';
  }

  @override
  String brazilStoreSalesMapSemanticsSingleStore(
    String storeName,
    String cityLabel,
    String revenue,
    String salesCount,
    String salesStatusSuffix,
  ) {
    return '$storeName, $cityLabel, $revenue, $salesCount vendas$salesStatusSuffix';
  }

  @override
  String brazilStoreSalesMapSemanticsStateAggregate(
    String stateName,
    String revenue,
    String salesCount,
    String storeCount,
  ) {
    return '$stateName, $revenue, $salesCount vendas, $storeCount lojas';
  }

  @override
  String brazilStoreSalesMapDetailChipSales(String count) {
    return '$count vendas';
  }

  @override
  String brazilStoreSalesMapDetailChipBranches(String count) {
    return '$count filiais';
  }

  @override
  String brazilStoreSalesMapStateSelectedSubtitle(String uf) {
    return '$uf selecionado';
  }

  @override
  String brazilStoreSalesMapCarouselPosition(String current, String total) {
    return '$current de $total';
  }

  @override
  String get brazilStoreSalesMapBranchDetailSemanticsLabel =>
      'Detalhes da filial no mapa';

  @override
  String get brazilStoreSalesMapSalesLoadingLabel => 'Carregando vendas';

  @override
  String brazilStoreSalesMapDataQualityLead(String count) {
    return '$count lojas não exibidas';
  }

  @override
  String brazilStoreSalesMapDataQualityInvalidCoords(String count) {
    return '$count com coordenada inválida';
  }

  @override
  String brazilStoreSalesMapDataQualityUnknownUf(String count) {
    return '$count com UF desconhecida';
  }

  @override
  String brazilStoreSalesMapDataQualityOutsideClip(String count) {
    return '$count fora do recorte';
  }

  @override
  String salesLiveMapFilterBranchSummaryLine(
    String city,
    String uf,
    String agentName,
  ) {
    return '$city/$uf — Filial $agentName';
  }

  @override
  String salesLiveMapFilterBranchCodesLine(
    String codEmpresa,
    String codFilial,
  ) {
    return 'Empresa: $codEmpresa  Filial: $codFilial';
  }

  @override
  String get brazilStoreSalesMapCloseBranchDetailsTooltip => 'Fechar detalhes';

  @override
  String get brazilStoreSalesMapBranchPinnedChip => 'Filial fixada';

  @override
  String get brazilStoreSalesMapSalesUnavailableFallback =>
      'Vendas indisponíveis';

  @override
  String get brazilStoreSalesMapSelectBranchButton => 'Selecionar filial';

  @override
  String get brazilStoreSalesMapChooseBranchMenuTooltip => 'Escolher filial';

  @override
  String get brazilStoreSalesMapBranchNavigationPreviousTooltip =>
      'Filial anterior';

  @override
  String get brazilStoreSalesMapBranchNavigationNextTooltip => 'Próxima filial';

  @override
  String get brazilStoreSalesMapMarkerGroupTotalTitle => 'Total do ponto';

  @override
  String get brazilStoreSalesMapDefaultBranchName => 'Filial sem nome';

  @override
  String get brazilStoreSalesMapSidebarTitle => 'Filiais visíveis';

  @override
  String brazilStoreSalesMapSidebarSummary(int count, String revenue) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filiais visíveis',
      one: '1 filial visível',
    );
    return '$_temp0 · $revenue';
  }

  @override
  String brazilStoreSalesMapSidebarCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filiais visíveis',
      one: '1 filial visível',
    );
    return '$_temp0';
  }

  @override
  String brazilStoreSalesMapSidebarRevenueSummary(String revenue) {
    return 'Total no recorte: $revenue';
  }

  @override
  String get brazilStoreSalesMapSidebarSearchPlaceholder =>
      'Buscar filial ou cidade';

  @override
  String get brazilStoreSalesMapSidebarSearchSemanticsLabel =>
      'Buscar filial ou cidade na lista do mapa';

  @override
  String get brazilStoreSalesMapSidebarEmptyStateTitle =>
      'Nenhuma filial visível';

  @override
  String get brazilStoreSalesMapSidebarEmptyStateMessage =>
      'Ajuste a regiao do mapa ou limpe o escopo ativo para listar filiais neste painel.';

  @override
  String get brazilStoreSalesMapSidebarSearchEmptyStateTitle =>
      'Nenhuma filial encontrada';

  @override
  String get brazilStoreSalesMapSidebarSearchEmptyStateMessage =>
      'Ajuste a busca para localizar filiais neste recorte.';

  @override
  String get brazilStoreSalesMapSidebarZeroSalesLabel =>
      'Sem vendas no período';

  @override
  String get brazilStoreSalesMapSidebarCollapseTooltip =>
      'Ocultar lista de filiais';

  @override
  String get brazilStoreSalesMapSidebarExpandTooltip =>
      'Mostrar lista de filiais';

  @override
  String brazilStoreSalesMapAgentChipWithName(String agentName) {
    return 'Filial $agentName';
  }

  @override
  String brazilStoreSalesMapIbgeCodeLabel(String code) {
    return 'IBGE $code';
  }

  @override
  String get brazilStoreSalesMapLocationProvidedGeoPoint =>
      'Coordenada da filial';

  @override
  String get brazilStoreSalesMapLocationIbge => 'Geolocalização IBGE';

  @override
  String get brazilStoreSalesMapLocationCep => 'Geolocalização CEP';

  @override
  String get brazilStoreSalesMapLocationCityUf => 'Geolocalização cidade/UF';

  @override
  String get brazilStoreSalesMapLocationCapitalUf => 'Capital da UF';

  @override
  String get brazilStoreSalesMapLocationStateUf => 'Centro da UF';

  @override
  String get brazilStoreSalesMapLocationUnknown =>
      'Origem da coordenada não informada';

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
    return 'Ticket médio $amount';
  }

  @override
  String overviewSemanticsSharePercent(String value) {
    return '$value por cento';
  }

  @override
  String get overviewNoApprovedAgentsUserMessage =>
      'Nenhuma filial aprovada está disponível para carregar a visão geral.';

  @override
  String get overviewLoadFailedUserMessage =>
      'Não foi possível carregar a visão geral.';

  @override
  String get clientAgentsDataSourcesEyebrow => 'Fontes de dados';

  @override
  String get clientAgentsPageTitle => 'Gestão de agentes';

  @override
  String get clientAgentsPageSubtitle =>
      'Acompanhe seus agentes aprovados, solicite novos acessos e consulte o andamento das solicitações.';

  @override
  String clientAgentsPendingActionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ações para enviar',
      one: '1 ação para enviar',
    );
    return '$_temp0';
  }

  @override
  String get clientAgentsRefresh => 'Atualizar';

  @override
  String get clientAgentsSubmitRequests => 'Enviar solicitações';

  @override
  String get clientAgentsActionFailedTitle =>
      'Não foi possível concluir a ação';

  @override
  String get clientAgentsMaintenanceTitle => 'Manutenção de agentes';

  @override
  String get clientAgentsMaintenanceSubtitle =>
      'Use as abas para ver agentes aprovados, pedir novos acessos e acompanhar o histórico das solicitações.';

  @override
  String get clientAgentsMaintenanceSubtitleOwner =>
      'Use as abas para gerir agentes aprovados, reenviar solicitações de clientes e revisar acessos dos agentes que você administra.';

  @override
  String get clientAgentsTabMyAgents => 'Meus agentes';

  @override
  String get clientAgentsTabRequestAccess => 'Solicitar acesso';

  @override
  String get clientAgentsTabRequests => 'Solicitações';

  @override
  String get clientAgentsTabOwnerRequests => 'Revisar solicitações';

  @override
  String get clientAgentsTabOwnerClients => 'Clientes aprovados';

  @override
  String get clientAgentsLoadApprovedErrorTitle =>
      'Não foi possível carregar seus agentes';

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
      'Selecionar para remoção em lote';

  @override
  String get clientAgentsApprovedBulkCancel => 'Cancelar seleção';

  @override
  String clientAgentsApprovedBulkRemove(int count) {
    return 'Remover selecionados ($count)';
  }

  @override
  String get clientAgentsBulkRemoveConfirmTitle =>
      'Enfileirar remoção para varios agentes?';

  @override
  String clientAgentsBulkRemoveConfirmMessage(int count) {
    return 'A remoção de acesso para $count agentes será preparada e enviada no próximo sync.';
  }

  @override
  String get clientAgentsBulkRemoveConfirmBack => 'Voltar';

  @override
  String get clientAgentsBulkRemoveConfirmAction => 'Enfileirar remoção';

  @override
  String get clientAgentsApprovedBulkSelectAll => 'Selecionar todos';

  @override
  String get clientAgentsApprovedBulkClearSelection => 'Limpar seleção';

  @override
  String get clientAgentsRequestAccessIntro1 =>
      'Use uma ou mais linhas para solicitar acesso. Cada linha precisa de um UUID de agente; informe o client token quando o agente exigir para execução SQL.';

  @override
  String get clientAgentsRequestAccessIntro2 =>
      'O agentId deve ser informado pelo responsável do agente ou por um fluxo externo. Quando a solicitação for aprovada, o agente será liberado automáticamente para esta conta.';

  @override
  String get clientAgentsRequestAccessIntroToken =>
      'O client token fica em cache neste dispositivo enquanto a aprovação está pendente e é enviado ao servidor Colmeia assim que o agente for vinculado.';

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
      'Opcional — cache local, enviado ao servidor após aprovação';

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
      'Enter at least one valid agent ID to continue.';

  @override
  String clientAgentsValidationInvalidIds(String ids) {
    return 'The following agent IDs are invalid: $ids.';
  }

  @override
  String clientAgentsValidationTokenTooLong(int limit, String ids) {
    return 'The client token must be $limit characters or fewer. Shorten it for: $ids.';
  }

  @override
  String clientAgentsDuplicatedIdsNote(String ids) {
    return 'IDs duplicados foram ignorados automáticamente: $ids.';
  }

  @override
  String get clientAgentsLoadRequestsErrorTitle =>
      'Não foi possível carregar as solicitações';

  @override
  String get clientAgentsLoadPendingErrorTitle =>
      'Não foi possível carregar os envios pendentes';

  @override
  String get clientAgentsNoRequestsYet => 'Sem solicitações no momento.';

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
      'Em análise pelo responsável do agente.';

  @override
  String get clientAgentsRequestDescApproved =>
      'Aprovado e disponível para esta conta.';

  @override
  String get clientAgentsRequestDescRejected =>
      'Não foi aprovado pelo responsável do agente.';

  @override
  String get clientAgentsRequestDescExpired =>
      'A solicitação expirou. Envie novamente se necessário.';

  @override
  String get clientAgentsRequestDescUnknown =>
      'O status dessa solicitação ainda não está disponível.';

  @override
  String get clientAgentsRetryRequestAction => 'Tentar novamente';

  @override
  String get clientAgentsPendingDescQueued => 'Pronto para envio.';

  @override
  String get clientAgentsPendingDescSyncing => 'Enviando agora.';

  @override
  String get clientAgentsPendingDescFailed =>
      'Não foi possível enviar. Tente novamente.';

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
      'Sessao indisponível para carregar agentes.';

  @override
  String get clientAgentsSessionUnavailableRequest =>
      'Sessao indisponível para solicitar acesso.';

  @override
  String get clientAgentsSessionUnavailableRemove =>
      'Sessao indisponível para remover acesso.';

  @override
  String get clientAgentsSessionUnavailableSync =>
      'Sessao indisponível para sincronizar pendências.';

  @override
  String get clientAgentsRetryMissingRequestId =>
      'Esta solicitação não pode ser reenviada porque o identificador não está disponível.';

  @override
  String get clientAgentsRetrySuccess =>
      'A solicitação foi reenviada. Vamos continuar acompanhando a aprovação.';

  @override
  String get clientAgentsDiscardQueuedRequestAction => 'Remover da fila';

  @override
  String get clientAgentsDiscardQueuedRequestSuccess =>
      'O envio pendente foi removido. Você pode solicitar acesso de novo quando quiser.';

  @override
  String get clientAgentsDiscardQueuedRequestInvalidState =>
      'Este envio não pode ser removido da fila no estado atual.';

  @override
  String get clientAgentsOwnerActionFailedTitle =>
      'Não foi possível concluir a ação do responsável';

  @override
  String get clientAgentsOwnerRequestsLoadErrorTitle =>
      'Não foi possível carregar as solicitações para revisão';

  @override
  String get clientAgentsOwnerRequestsEmpty =>
      'Nenhuma solicitação de cliente precisa da sua revisão agora.';

  @override
  String get clientAgentsOwnerApproveAction => 'Aprovar';

  @override
  String get clientAgentsOwnerRejectAction => 'Rejeitar';

  @override
  String get clientAgentsOwnerRequestsStatusPending =>
      'Aguardando sua decisao para este agente.';

  @override
  String get clientAgentsOwnerRequestsStatusApproved =>
      'Aprovada e já disponível para o cliente.';

  @override
  String get clientAgentsOwnerRequestsStatusRejected =>
      'Rejeitada durante a revisão do responsável.';

  @override
  String get clientAgentsOwnerRequestsStatusExpired =>
      'Expirou antes da revisão final.';

  @override
  String get clientAgentsOwnerRequestsStatusUnknown =>
      'O status mais recente da revisão não está disponível.';

  @override
  String get clientAgentsOwnerApproveSuccess =>
      'A solicitação de acesso foi aprovada.';

  @override
  String get clientAgentsOwnerRejectSuccess =>
      'A solicitação de acesso foi rejeitada.';

  @override
  String get clientAgentsOwnerClientsEmptyAgents =>
      'Nenhum agente administrado está disponível para esta conta ainda.';

  @override
  String get clientAgentsOwnerClientsAgentSelectorLabel => 'Agente';

  @override
  String get clientAgentsOwnerClientsAgentSelectorHint =>
      'Escolha um agente administrado';

  @override
  String get clientAgentsOwnerClientsLoadErrorTitle =>
      'Não foi possível carregar os clientes aprovados';

  @override
  String get clientAgentsOwnerClientsEmpty =>
      'Nenhum cliente aprovado está vinculado a este agente ainda.';

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
      'Sessao indisponível para carregar o agente.';

  @override
  String get appInlineErrorRetry => 'Tentar novamente';

  @override
  String appInlineErrorRetryCountdown(int seconds) {
    return 'Tentar em ${seconds}s';
  }

  @override
  String get clientAgentsNoLocalPendingToSync =>
      'Não há pendências locais para sincronizar.';

  @override
  String get clientAgentsRequestBlockedFallback =>
      'Não foi possível registrar a solicitação informada.';

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
    return 'Já em análise: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyQueued(String ids) {
    return 'Ja preparados para envio: $ids.';
  }

  @override
  String get clientAgentsRequestQueuedWatchingSingle =>
      'Solicitação enviada. Vamos acompanhar a aprovação automáticamente.';

  @override
  String clientAgentsRequestQueuedWatchingPlural(int count) {
    return '$count solicitações enviadas. Vamos acompanhar as aprovações automáticamente.';
  }

  @override
  String clientAgentsRequestQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados porque já estavam aprovados ou em análise.';
  }

  @override
  String get clientAgentsRequestRelinkUpdatedSingle =>
      'Esse agente já está aprovado no servidor. A lista de agentes foi atualizada.';

  @override
  String clientAgentsRequestRelinkUpdatedPlural(int count) {
    return '$count agentes já estavam aprovados no servidor. A lista de agentes foi atualizada.';
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
      'Não foi possível limpar solicitações pendentes locais; elas podem ser reenviadas na próxima sincronização.';

  @override
  String get clientAgentsRemoveBlockedFallback =>
      'Não foi possível registrar a remoção informada.';

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
    return 'Remoção ja preparada para envio: $ids.';
  }

  @override
  String get clientAgentsRemoveQueuedSingle =>
      'Remoção de acesso preparada e enviada para sincronização.';

  @override
  String clientAgentsRemoveQueuedPlural(int count) {
    return '$count remoções de acesso preparadas e enviadas para sincronização.';
  }

  @override
  String clientAgentsRemoveQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados.';
  }

  @override
  String get clientAgentsSyncSuccessSingle => '1 pendência foi sincronizada.';

  @override
  String clientAgentsSyncSuccessPlural(int count) {
    return '$count pendências foram sincronizadas.';
  }

  @override
  String get clientAgentsSyncSuccessNoneCompleted =>
      'A sincronização terminou, mas nenhuma pendência foi aplicada.';

  @override
  String clientAgentsSyncRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para esperarmos. Tente de novo em ${seconds}s.';
  }

  @override
  String clientAgentsRequestAccessRetryAfterCountdown(int seconds) {
    return 'Muitas solicitações de acesso. Tente de novo em ${seconds}s.';
  }

  @override
  String clientAgentsSyncSuccessSomeFailedSuffix(int count) {
    return ' $count ação(oes) falhou e permanece na fila para nova tentativa.';
  }

  @override
  String get clientAgentsSyncSuccessAutoSuffix =>
      ' O envio aconteceu automáticamente.';

  @override
  String get clientAgentsSyncSuccessManualSuffix =>
      ' A tela ja foi atualizada com o status mais recente.';

  @override
  String get clientAgentsSyncSuccessPollingSuffix =>
      ' Vamos acompanhar a aprovação automáticamente.';

  @override
  String get clientAgentsSyncSuccessAlreadyApprovedSingle =>
      ' Um agente já estava aprovado no servidor.';

  @override
  String clientAgentsSyncSuccessAlreadyApprovedPlural(int count) {
    return ' $count agentes já estavam aprovados no servidor.';
  }

  @override
  String get clientAgentsSyncSuccessDebouncedSingle =>
      ' Uma solicitação foi atualizada recentemente (sem novo email).';

  @override
  String clientAgentsSyncSuccessDebouncedPlural(int count) {
    return ' $count solicitações foram atualizadas recentemente (sem novo email).';
  }

  @override
  String clientAgentsPollApprovedSingle(String tabLabel) {
    return 'Acesso aprovado. O agente ja está disponível em \"$tabLabel\".';
  }

  @override
  String clientAgentsPollApprovedPlural(int count, String tabLabel) {
    return '$count acessos foram aprovados. Os agentes ja estão disponíveis em \"$tabLabel\".';
  }

  @override
  String get clientAgentsPollDeniedSingle =>
      '1 solicitação foi encerrada sem aprovação.';

  @override
  String clientAgentsPollDeniedPlural(int count) {
    return '$count solicitações foram encerradas sem aprovação.';
  }

  @override
  String get clientAgentsPollTimeoutSingle =>
      '1 solicitação ainda está em análise. Atualize esta tela mais tarde para verificar o resultado.';

  @override
  String clientAgentsPollTimeoutPlural(int count) {
    return '$count solicitações seguem em análise e você pode atualizar esta tela mais tarde para verificar o resultado.';
  }

  @override
  String get clientAgentsPollRemainingSingle =>
      'Ainda há 1 solicitação em análise.';

  @override
  String clientAgentsPollRemainingPlural(int count) {
    return 'Ainda há $count solicitações em análise.';
  }

  @override
  String get clientAgentDetailEyebrow => 'Detalhe';

  @override
  String get clientAgentDetailTitle => 'Agente';

  @override
  String get clientAgentDetailSubtitle =>
      'Informações detalhadas do agente aprovado para esta conta.';

  @override
  String get clientAgentDetailLoadErrorTitle =>
      'Não foi possível carregar o agente';

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
  String get clientAgentDetailSectionNotes => 'Anotações';

  @override
  String get clientAgentDetailSectionRecord => 'Registro';

  @override
  String get clientAgentDetailSectionServerToken => 'Client token';

  @override
  String get clientAgentDetailSectionServerTokenSubtitle =>
      'Salvo no servidor Colmeia e encaminhado ao agente como `params.client_token` quando este cliente executa SQL via bridge. O token também fica em cache neste dispositivo para dashboards seguirem funcionando brevemente sem conexão.';

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
      'Status do token não carregado — atualize a tela com acesso a internet para confirmar.';

  @override
  String get clientAgentDetailRefreshFromAgent => 'Recarregar do agente';

  @override
  String get clientAgentDetailRefreshFromAgentSuccess =>
      'Perfil recarregado direto do agente.';

  @override
  String get clientAgentDetailRefreshFromAgentUnsupported =>
      'Este agente não implementa agent.getProfile via RPC.';

  @override
  String clientAgentDetailRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para aguardar. Tente novamente em ${seconds}s.';
  }

  @override
  String get clientAgentDetailSectionPolicy => 'Permissoes deste token';

  @override
  String get clientAgentDetailSectionPolicySubtitle =>
      'Resolvidas pelo agente para o token atualmente salvo no servidor. Se a política mudar após revogação ou alteração de escopo, recarregue a tela.';

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
      'Este token está marcado como revogado pelo agente.';

  @override
  String get clientAgentDetailPolicyRevokedSaveNewToken => 'Salvar novo token';

  @override
  String get clientAgentDetailPolicyUnsupported =>
      'Este agente não expõe introspecção da política do token.';

  @override
  String get clientAgentDetailPolicyEmpty =>
      'O agente não retornou nenhuma regra para este token.';

  @override
  String get clientAgentDetailSectionEditProfile => 'Perfil no catálogo';

  @override
  String get clientAgentDetailSaveProfile => 'Salvar perfil';

  @override
  String clientAgentDetailCopyFieldTooltip(String label) {
    return 'Copiar $label para a area de transferencia';
  }

  @override
  String get clientAgentDetailCopiedSnackbar =>
      'Copiado para a area de transferencia';

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
  String get clientAgentFieldConnection => 'Conexão';

  @override
  String get clientAgentFieldNotes => 'Notas';

  @override
  String get clientAgentFieldObservation => 'Observação';

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
  String get clientAgentsFilterConnectionLabel => 'Conexão';

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
    return 'Conexão: $label';
  }

  @override
  String clientAgentsFilterSummaryCatalog(String label) {
    return 'Catalogo: $label';
  }

  @override
  String get clientAgentsEmptyFilteredApproved =>
      'Nenhum agente corresponde aos filtros selecionados.';

  @override
  String get clientAgentsRequestsFilterSheetTitle => 'Filtros de solicitações';

  @override
  String get clientAgentsRequestsFilterSearchLabel => 'Buscar';

  @override
  String get clientAgentsRequestsFilterSearchHint =>
      'Nome do agente ou agent ID';

  @override
  String get clientAgentsRequestsFilterStatusLabel => 'Status da solicitação';

  @override
  String get clientAgentsRequestsFilterPendingLabel => 'Envio pendente';

  @override
  String clientAgentsRequestsFilterSummaryRequest(String label) {
    return 'Solicitação: $label';
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
      'Nenhuma solicitação corresponde aos filtros selecionados.';

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
      'Ajuste a consulta e aplique somente os recortes que fazem sentido para esta análise.';

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
  String get reportInlineFiltersSelectPeriod => 'Selecionar período';

  @override
  String get reportInlineFiltersSelectDate => 'Selecionar data';

  @override
  String get reportFiltersAppliedSectionTitle => 'Filtros aplicados';

  @override
  String get clientAgentsErrorLoadCatalog =>
      'Não foi possível carregar o catalogo de agentes.';

  @override
  String get clientAgentsErrorLoadCatalogAgent =>
      'Não foi possível carregar este agente do catalogo.';

  @override
  String get clientAgentsErrorLoadClientAccessStatus =>
      'Não foi possível ler o status da solicitação de acesso.';

  @override
  String get clientAgentsErrorLoadApproved =>
      'Não foi possível carregar os agentes aprovados para esta conta.';

  @override
  String get clientAgentsErrorLoadAgentDetail =>
      'Não foi possível carregar os dados do agente.';

  @override
  String get clientAgentsErrorProbeApproved =>
      'Não foi possível verificar se o agente já está ligado a esta conta.';

  @override
  String get clientAgentsErrorLoadAccessRequests =>
      'Não foi possível carregar o histórico de solicitações.';

  @override
  String get clientAgentsErrorRetryClientAccessRequest =>
      'Não foi possível reenviar esta solicitação de acesso.';

  @override
  String get clientAgentsErrorReadPending =>
      'Não foi possível carregar as ações pendentes de sincronização.';

  @override
  String get clientAgentsErrorQueueRequest =>
      'Não foi possível registrar a solicitação para sincronização.';

  @override
  String get clientAgentsErrorQueueRemove =>
      'Não foi possível registrar a remoção para sincronização.';

  @override
  String get clientAgentsErrorSyncAction =>
      'Não foi possível sincronizar a alteração do agente.';

  @override
  String get clientAgentsErrorSyncPending =>
      'Não foi possível sincronizar as ações pendentes de agentes.';

  @override
  String get clientAgentsErrorLoadManagedAgents =>
      'Não foi possível carregar os agentes administrados.';

  @override
  String get clientAgentsErrorLoadOwnerAccessRequests =>
      'Não foi possível carregar as solicitações de acesso para revisão.';

  @override
  String get clientAgentsErrorApproveOwnerAccessRequest =>
      'Não foi possível aprovar esta solicitação de acesso.';

  @override
  String get clientAgentsErrorRejectOwnerAccessRequest =>
      'Não foi possível rejeitar esta solicitação de acesso.';

  @override
  String get clientAgentsErrorLoadOwnerApprovedClients =>
      'Não foi possível carregar os clientes aprovados deste agente.';

  @override
  String get clientAgentsErrorRevokeOwnerClientAccess =>
      'Não foi possível revogar este acesso de cliente.';

  @override
  String get clientAgentsErrorGetClientAgentToken =>
      'Não foi possível ler o token do agente no servidor.';

  @override
  String get clientAgentsErrorSaveClientAgentToken =>
      'Não foi possível salvar o token do agente no servidor.';

  @override
  String get clientAgentsErrorRemoveClientAgentToken =>
      'Não foi possível remover o token do agente no servidor.';

  @override
  String get clientAgentsErrorAgentDocumentConflict =>
      'Este CPF/CNPJ ja está vinculado a outro agente no catalogo. Para alterar o vinculo, entre em contato com o suporte.';

  @override
  String get clientAgentsErrorAgentProfileCasMismatch =>
      'Outro dispositivo atualizou este agente. Recarregue a tela e reaplique suas alterações.';

  @override
  String get agentSqlErrorAuthenticationFailed =>
      'A autenticação para consultar este agente e inválida ou expirou.';

  @override
  String get agentSqlErrorPermissionDenied =>
      'Você não tem permissão para consultar estes dados neste agente.';

  @override
  String get agentSqlErrorTransportTimeout =>
      'O agente demorou mais do que o esperado para responder. Tente novamente.';

  @override
  String get agentSqlErrorNetworkError =>
      'Não foi possível alcancar o agente agora. Tente novamente.';

  @override
  String get agentSqlErrorRateLimited =>
      'Muitas tentativas de consulta foram feitas. Aguarde um instante e tente novamente.';

  @override
  String get agentSqlErrorValidationFailed => 'The query is invalid.';

  @override
  String get agentSqlErrorExecutionFailed =>
      'Não foi possível executar a consulta.';

  @override
  String get agentSqlErrorTransactionFailed =>
      'Não foi possível concluir a transação da consulta.';

  @override
  String get agentSqlErrorConnectionPoolExhausted =>
      'O servidor esta ocupado para processar a consulta agora. Tente novamente em instantes.';

  @override
  String get agentSqlErrorResultTooLarge =>
      'A consulta retornou dados demais. Refine os filtros e tente novamente.';

  @override
  String get agentSqlErrorDatabaseConnectionFailed =>
      'Não foi possível conectar ao banco para executar a consulta.';

  @override
  String get agentSqlErrorQueryTimeout =>
      'A consulta demorou mais do que o esperado.';

  @override
  String get agentSqlErrorInvalidDatabaseConfig =>
      'A configuração de acesso ao banco deste agente esta inválida.';

  @override
  String get agentSqlErrorExecutionNotFound =>
      'A execução solicitada não foi encontrada.';

  @override
  String get agentSqlErrorExecutionCancelled => 'A consulta foi cancelada.';

  @override
  String get agentSqlErrorGeneric =>
      'Não foi possível concluir a consulta no agente.';

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
      'Mesmos wrappers dos relatorios: dropdown, multi-select e os mesmos date pickers da seção Form acima (FormBuilderField + AppFormBuilderDate*).';

  @override
  String get formsDemoValidateFormBuilderButton => 'Validate FormBuilder';

  @override
  String get formsDemoValidateFormSubmitButton => 'Validate submit (Form)';

  @override
  String formsDemoFormValidSnackbar(String refLabel, String rangeLabel) {
    return 'Formulário válido (demo fake). Ref: $refLabel. Período: $rangeLabel.';
  }

  @override
  String formsDemoFormBuilderValidSnackbar(
    String dateLabel,
    String rangeLabel,
  ) {
    return 'FormBuilder válido (demo fake). Data: $dateLabel. Período: $rangeLabel.';
  }

  @override
  String get datePickerPlaceholderSelectDate => 'Selecione uma data';

  @override
  String get dateRangePickerPlaceholderSelectPeriod => 'Selecione o período';

  @override
  String get datePickerSheetDefaultTitle => 'Selecionar data';

  @override
  String get dateRangePickerSheetDefaultTitle => 'Selecionar período';

  @override
  String get datePickerClearSelectionTooltip => 'Limpar seleção';

  @override
  String get datePickerSheetRemoveDate => 'Remover data';

  @override
  String get dateRangePickerSheetRemovePeriod => 'Remover período';

  @override
  String get datePickerSheetCloseTooltip => 'Fechar';

  @override
  String get datePickerSheetApply => 'Aplicar';

  @override
  String get datePickerSemanticsFallbackLabel => 'Data';

  @override
  String get dateRangePickerSemanticsFallbackLabel => 'Período';

  @override
  String get overviewLucratividadeTitle => 'Lucratividade por filial';

  @override
  String get overviewLucratividadeSubtitle =>
      'Receita, custo e margem no período selecionado (todas as filiais no escopo somadas).';

  @override
  String get overviewLucratividadeSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeSwitchMargin => 'Percentuais';

  @override
  String get overviewLucratividadePercentMetricCostShort => 'Custo %';

  @override
  String get overviewLucratividadePercentMetricGrossShort => 'Margem bruta';

  @override
  String get overviewLucratividadePercentMetricMarkupShort => 'Markup';

  @override
  String get overviewLucratividadePercentSeriesCostLabel =>
      'Percentual de custo';

  @override
  String get overviewLucratividadePercentSeriesGrossLabel =>
      'Margem de lucro bruto';

  @override
  String get overviewLucratividadePercentSeriesMarkupLabel =>
      'Markup sobre custo';

  @override
  String get overviewLucratividadePercentHelpCostBody =>
      'Custo / Venda × 100. Mostra qual parcela da receita corresponde ao custo de reposição.';

  @override
  String get overviewLucratividadePercentHelpGrossBody =>
      'Lucro / Venda × 100. Mostra qual parcela da receita permanece como lucro bruto.';

  @override
  String get overviewLucratividadePercentHelpMarkupBody =>
      'Lucro / Custo × 100. Mostra quanto o lucro representa em relação ao custo de reposição.';

  @override
  String get overviewLucratividadeMarkupNotApplicable => '—';

  @override
  String get overviewLucratividadePercentSemanticsCost =>
      'Percentual de custo sobre a venda.';

  @override
  String get overviewLucratividadePercentSemanticsGross =>
      'Margem de lucro bruto sobre a venda.';

  @override
  String get overviewLucratividadePercentSemanticsMarkup =>
      'Markup sobre o custo de reposição.';

  @override
  String get overviewLucratividadePercentIndicatorHeading =>
      'Indicador percentual';

  @override
  String get overviewLucratividadePercentIndicatorLabel => 'Indicador';

  @override
  String get overviewLucratividadePercentEmptyHelp =>
      'Sem dados para ilustrar este indicador.';

  @override
  String get overviewLucratividadeMarkupUndefinedTooltip =>
      'Markup não definido quando o custo de reposição é zero ou ausente.';

  @override
  String get overviewLucratividadePercentMetricCostTooltip =>
      'Parcela da receita correspondente ao custo de reposição (custo dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricGrossTooltip =>
      'Margem bruta sobre a venda (lucro dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricMarkupTooltip =>
      'Markup sobre o custo de reposição (lucro dividido pelo custo).';

  @override
  String get overviewLucratividadeMensalPercentChronologicalHint =>
      'Meses em ordem cronologica (sem ranking por valor).';

  @override
  String get overviewLucratividadeProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeCostSeriesLabel => 'Custo reposição';

  @override
  String get overviewLucratividadeMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLucratividadeEmpty =>
      'Sem dados de lucratividade para este período.';

  @override
  String get overviewLucratividadeMultiAgentHint =>
      'Nenhuma filial aprovada está disponível para carregar a lucratividade. Adicione ou conecte uma filial primeiro.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Carregando gráfico de lucratividade por filial…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Lucratividade mensal do produto';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Receita, custo de reposição e margem por mês (filial selecionada).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'Sem dados de lucratividade para este período.';

  @override
  String get overviewLucratividadeMensalMultiAgentHint =>
      'Selecione uma unica filial para visualizar a lucratividade mensal.';

  @override
  String get overviewLucratividadeMensalSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeMensalSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeMensalSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeMensalSwitchMargin => 'Percentuais';

  @override
  String get overviewLucratividadeMensalProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeMensalRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeMensalCostSeriesLabel => 'Custo reposição';

  @override
  String get overviewLucratividadeMensalMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLoadingLucratividadeMensalSemantics =>
      'Carregando gráfico de lucratividade mensal do produto…';

  @override
  String get salesHubTitle => 'Vendas';

  @override
  String get salesHubSubtitle =>
      'Acesse e gerencie informações comerciais por categoria.';

  @override
  String get shellNavSalesMonitoringLabel => 'Acompanhar vendas';

  @override
  String get shellNavSalesMonitoringSubtitle =>
      'Mapa e atualização por filtros';

  @override
  String get salesLiveMapTitle => 'Acompanhar vendas';

  @override
  String get salesLiveMapSubtitle =>
      'Mapa do Brasil com vendas por filial e atualização por filtros.';

  @override
  String get salesLiveMapSessionExpiredMessage =>
      'Sessao expirada. Entre novamente para consultar.';

  @override
  String get salesLiveMapAgentsLabel => 'Filiais';

  @override
  String get salesLiveMapPeriodLabel => 'Período';

  @override
  String get salesLiveMapMapLabel => 'Mapa';

  @override
  String get salesLiveMapParametersLabel => 'Parametros';

  @override
  String salesLiveMapParametersSummary(
    String origin,
    String finance,
    String preSale,
  ) {
    return '$origin | Financeiro $finance | Pre-venda $preSale';
  }

  @override
  String get salesLiveMapAgentsLoadingSummary => 'Carregando filiais';

  @override
  String get salesLiveMapAgentsNoneSummary => 'Sem filiais';

  @override
  String salesLiveMapAgentsAllWithTokenSummary(int count) {
    return 'Todas ($count)';
  }

  @override
  String salesLiveMapAgentsSelectedSummary(int count) {
    return '$count filial(is)';
  }

  @override
  String get salesLiveMapPeriodToday => 'Hoje';

  @override
  String get salesLiveMapPeriodLastSevenDays => 'Últimos 7 dias';

  @override
  String get salesLiveMapPeriodLastSevenDaysShort => '7 dias';

  @override
  String get salesLiveMapPeriodCurrentMonth => 'Mes atual';

  @override
  String get salesLiveMapPeriodCurrentMonthShort => 'Mes';

  @override
  String get salesLiveMapPeriodCustom => 'Personalizado';

  @override
  String get salesLiveMapMapPresetPoints => 'Pontos';

  @override
  String get salesLiveMapMapPresetBubbles => 'Bolhas';

  @override
  String get salesLiveMapMapPresetMunicipalities => 'Municípios';

  @override
  String get salesLiveMapMapPresetMunicipalitiesShort => 'Municípios';

  @override
  String get salesLiveMapMapPresetStateBubbles => 'Bolhas por UF';

  @override
  String get salesLiveMapMapPresetStateBubblesShort => 'UFs';

  @override
  String get salesLiveMapMapPresetStoreIcon => 'Icone loja';

  @override
  String get salesLiveMapMapPresetStoreIconShort => 'Loja';

  @override
  String get salesLiveMapLoadErrorTitle =>
      'Não foi possível carregar o acompanhamento';

  @override
  String get salesLiveMapLoadErrorRetryMessage =>
      'Tente atualizar a consulta novamente.';

  @override
  String get salesLiveMapMissingClientTokenSetupMessage =>
      'Nenhum agente selecionado possui token local para executar a consulta.';

  @override
  String get salesLiveMapEmptyNoSalesTitle => 'Sem vendas no período';

  @override
  String get salesLiveMapEmptyNoSalesMessage =>
      'A consulta foi executada, mas não encontrou vendas para os filtros atuais.';

  @override
  String get salesLiveMapEmptySelectionTitle => 'Seleção sem resultado';

  @override
  String get salesLiveMapEmptySelectionMessage =>
      'As filiais selecionadas não retornaram vendas neste período. Limpe a seleção para recarregar todas as filiais disponíveis.';

  @override
  String get salesLiveMapChartTitle => 'Vendas por filial no Brasil';

  @override
  String salesLiveMapChartSubtitlePending(String period) {
    return 'Período $period.';
  }

  @override
  String salesLiveMapChartSubtitleLoaded(
    String period,
    int mappedCount,
    int totalCount,
  ) {
    return 'Período $period. $mappedCount de $totalCount filiais posicionadas.';
  }

  @override
  String get salesLiveMapPartialTitle => 'Acompanhamento parcial';

  @override
  String salesLiveMapAgentQuerySummary(
    int plannedCount,
    int queriedCount,
    int salesCount,
    int noSalesCount,
  ) {
    return 'Filiais: $plannedCount planejada(s) | $queriedCount consultada(s) | $salesCount com vendas | $noSalesCount sem vendas';
  }

  @override
  String salesLiveMapPartialFailedAgents(int count) {
    return '$count filial(is) falharam na ultima consulta.';
  }

  @override
  String salesLiveMapPartialMissingTokenAgents(int count) {
    return '$count filial(is) sem client_token local.';
  }

  @override
  String salesLiveMapPartialOfflineAgents(int count) {
    return '$count filial(is) fora da presenca do hub.';
  }

  @override
  String salesLiveMapPartialRowCapReached(int count) {
    return '$count agente(s) atingiram o limite de linhas da consulta; o mapa pode estar incompleto.';
  }

  @override
  String salesLiveMapPartialMissingCoordinates(int count) {
    return '$count filial(is) sem coordenada resolvida.';
  }

  @override
  String salesLiveMapPartialNoSalesAgents(int count) {
    return '$count filial(is) sem vendas no período.';
  }

  @override
  String salesLiveMapPartialZeroedBranches(int count) {
    return '$count filial(is) exibidas com venda zerada.';
  }

  @override
  String salesLiveMapPartialUnavailableSalesBranches(int count) {
    return '$count filial(is) exibidas com venda indisponível por falha na consulta.';
  }

  @override
  String get salesLiveMapNoSalesAgentsTitle => 'Filiais sem vendas';

  @override
  String get salesLiveMapTechnicalDiagnosticsTitle => 'Diagnostico tecnico';

  @override
  String get salesLiveMapTechnicalDiagnosticsFilters => 'Filtros ativos';

  @override
  String get salesLiveMapTechnicalDiagnosticsQuery => 'Diagnostico da consulta';

  @override
  String get salesLiveMapFiltersTitle => 'Filtros de acompanhamento';

  @override
  String get salesLiveMapFiltersDescription =>
      'Escolha filiais, período e tipo visual do mapa.';

  @override
  String get salesLiveMapBranchesSectionTitle => 'Filiais';

  @override
  String get salesLiveMapBranchesSectionSubtitle =>
      'A lista aparece depois da primeira atualização do mapa.';

  @override
  String get salesLiveMapSelectAtLeastOneTokenBranch =>
      'Selecione ao menos uma filial com token local.';

  @override
  String get salesLiveMapNoApprovedAgents =>
      'Nenhuma filial aprovada disponível para consulta.';

  @override
  String get salesLiveMapBranchesLoadBeforeSelection =>
      'Atualize o mapa uma vez para listar as filiais disponíveis.';

  @override
  String get salesLiveMapSelectAllTokenBacked => 'Selecionar todas';

  @override
  String get salesLiveMapClearSelection => 'Desmarcar todas';

  @override
  String get salesLiveMapClearBranchSelectionAction =>
      'Limpar seleção de filiais';

  @override
  String get salesLiveMapClearSavedFiltersAction => 'Limpar filtros salvos';

  @override
  String get salesLiveMapMissingLocalToken => 'Sem token local';

  @override
  String get salesLiveMapCustomPeriodLabel => 'Período personalizado';

  @override
  String salesLiveMapCustomPeriodHelper(int maxDays) {
    return 'Limite de $maxDays dias por atualização.';
  }

  @override
  String get salesLiveMapCustomPeriodPickerTitle => 'Selecionar período';

  @override
  String get salesLiveMapMapTypeTitle => 'Tipo de mapa';

  @override
  String get salesLiveMapMapTypeSubtitle =>
      'Escolha como os pontos e totais devem aparecer.';

  @override
  String get salesLiveMapDetailLabel => 'Detalhamento';

  @override
  String get salesLiveMapDetailSubtitle =>
      'Escolha o nivel de agregação mostrado no mapa.';

  @override
  String get salesLiveMapDetailBranches => 'Filiais';

  @override
  String get salesLiveMapDetailMunicipalities => 'Municípios';

  @override
  String get salesLiveMapDetailStates => 'UFs';

  @override
  String get salesLiveMapVisualLabel => 'Visual';

  @override
  String get salesLiveMapVisualSubtitle =>
      'Escolha o estilo dos marcadores para filiais e municípios.';

  @override
  String get salesLiveMapVisualDot => 'Pontos';

  @override
  String get salesLiveMapVisualBubble => 'Bolhas';

  @override
  String get salesLiveMapVisualStoreIcon => 'Icone loja';

  @override
  String salesLiveMapDetailAutoMunicipalities(int threshold) {
    return 'Acima de $threshold filiais, municípios sao exibidos automáticamente para melhorar a leitura.';
  }

  @override
  String get salesLiveMapKpiRevenue => 'Receita total';

  @override
  String get salesLiveMapKpiSales => 'Vendas';

  @override
  String get salesLiveMapKpiBranchesOnMap => 'Filiais no mapa';

  @override
  String salesLiveMapKpiBranchesOnMapTooltip(
    int providedCount,
    int ibgeCount,
    int cepCount,
    int cityUfCount,
    int capitalUfCount,
    int stateUfCount,
    int missingCount,
  ) {
    return 'Geo: $providedCount informada | $ibgeCount IBGE | $cepCount CEP | $cityUfCount cidade/UF | $capitalUfCount capital/UF | $stateUfCount UF | $missingCount sem coordenada';
  }

  @override
  String get salesLiveMapKpiMunicipalitiesOnMap => 'Municípios no mapa';

  @override
  String get salesLiveMapKpiQueriedAgents => 'Filiais consultadas';

  @override
  String get salesBranchFilterLabel => 'FILIAIS';

  @override
  String get salesBranchFilterEmptyHint =>
      'Carregue o relatorio para listar as filiais.';

  @override
  String get salesBranchFilterSheetTitle => 'Selecionar filiais';

  @override
  String get salesBranchFilterSheetSearchHint => 'Buscar filiais…';

  @override
  String get salesBranchFilterNoSearchResults =>
      'Nenhuma filial corresponde à busca.';

  @override
  String get salesBranchFilterMissingClientTokenBanner =>
      'Filiais sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get salesBranchPickerEmpty => 'Selecione uma filial';

  @override
  String get salesBranchRequiredTitle => 'Seleção de filial obrigatoria';

  @override
  String get salesBranchRequiredMessage =>
      'Selecione uma filial para visualizar essas informações.';

  @override
  String get salesAgentPickerLabel => 'Filial';

  @override
  String get salesAgentPickerEmpty => 'Selecione uma filial';

  @override
  String get salesAgentPickerSheetTitle => 'Selecione uma filial';

  @override
  String get salesAgentRequiredTitle => 'Seleção de filial obrigatoria';

  @override
  String get salesAgentRequiredMessage =>
      'Selecione uma filial para visualizar essas informações.';

  @override
  String get salesCardOpenAccountsTitle => 'Contas em Aberto';

  @override
  String get salesCardPaidAccountsTitle => 'Contas Pagas';

  @override
  String get salesCardPaymentHistoryTitle => 'Histórico de Pagamentos';

  @override
  String get salesCardNewPaymentTitle => 'Novo Pagamento';

  @override
  String get salesCardProdutoRankLucroTitle => 'Ranking de produtos';

  @override
  String get salesCardMonthlyPnlTitle => 'Resultado mensal';

  @override
  String get salesCardResumoTotalDiarioVendasTitle => 'Vendas diárias';

  @override
  String get salesAutoRefreshOff => 'Desligado';

  @override
  String get salesAutoRefreshTooltip => 'Atualização automática';

  @override
  String get salesAutoRefreshNow => 'Atualizar agora';

  @override
  String salesAutoRefreshLastUpdatedAt(String time) {
    return 'Atualizado $time';
  }

  @override
  String salesAutoRefreshNextIn(String time) {
    return 'Próximo em $time';
  }

  @override
  String salesAutoRefreshRetryIn(String time) {
    return 'Nova tentativa em $time';
  }

  @override
  String get salesAutoRefreshPaused => 'Atualização automática pausada';

  @override
  String get salesAutoRefreshPausedLoading =>
      'Atualização automática pausada durante a carga';

  @override
  String get salesAutoRefreshPausedMissingLocalToken =>
      'Atualização automática pausada: token local necessário';

  @override
  String get salesAutoRefreshPausedNoEligibleSelection =>
      'Atualização automática pausada: selecione uma filial válida';

  @override
  String get salesAutoRefreshPausedUnsupportedViewport =>
      'Atualização automática disponível no desktop';

  @override
  String get salesAutoRefreshPausedHidden =>
      'Atualização automática pausada enquanto a tela estiver oculta';

  @override
  String get salesDailyTotalsChartTitle => 'Vendas por dia';

  @override
  String get salesDailyTotalsChartTitleAmount => 'Faturamento diário';

  @override
  String get salesDailyTotalsChartSubtitle =>
      'Totais por dia civil na filial e no mês de referência selecionados.';

  @override
  String get salesDailyTotalsChartEmpty =>
      'Sem dados de vendas diárias para esta filial e mês.';

  @override
  String get salesDailyTotalsChartLoadFailed =>
      'Não foi possível carregar as vendas diárias desta filial. Tente novamente mais tarde.';

  @override
  String get salesDailyTotalsChartSemanticsCount =>
      'Gráfico de quantidade de vendas e faturamento diários da filial selecionada';

  @override
  String get salesDailyTotalsChartSemanticsAmount =>
      'Gráfico de faturamento diário e quantidade de vendas da filial selecionada';

  @override
  String get salesDailyTotalsChartScopeHint =>
      'Uma filial; os totais seguem o filtro de mês de referência.';

  @override
  String salesDailyTotalsChartTooltip(
    String date,
    String salesCount,
    String salesAmount,
  ) {
    return '$date: $salesCount vendas - $salesAmount';
  }

  @override
  String get salesDailyTotalsMetricSalesCountLabel => 'Vendas';

  @override
  String get salesDailyTotalsMetricSalesAmountLabel => 'Faturamento';

  @override
  String salesDailyTotalsChartSubtitleCustomRange(
    String startDate,
    String endDate,
  ) {
    return 'Totais por dia civil na filial, de $startDate a $endDate.';
  }

  @override
  String get salesDailyTotalsChartScopeHintCustomRange =>
      'Uma filial; os totais diários seguem o intervalo selecionado. Os gráficos mensais continuam usando o mês de referência.';

  @override
  String get salesDailyTotalsFilterSummaryLabel => 'Totais diários';

  @override
  String salesDailyTotalsFilterSummaryCustomRangeValue(
    String startDate,
    String endDate,
  ) {
    return '$startDate – $endDate';
  }

  @override
  String get salesDailyTotalsFilterDailyPeriodSectionTitle =>
      'Período dos totais diários';

  @override
  String get salesDailyTotalsFilterDailyPeriodSameMonthLabel =>
      'Mesmo mês de referência';

  @override
  String get salesDailyTotalsFilterDailyPeriodCustomRangeLabel =>
      'Intervalo customizado';

  @override
  String get salesDailyTotalsFilterDailyPeriodPickerLabel =>
      'Intervalo de datas de venda';

  @override
  String get salesDailyTotalsFilterDailyPeriodPickerTitle =>
      'Selecionar período';

  @override
  String salesDailyTotalsFilterDailyPeriodHelper(int maxDays) {
    return 'No máximo $maxDays dias corridos.';
  }

  @override
  String get salesDailyTotalsFilterMonthlyChartsAnchorHint =>
      'Os gráficos de resultado mensal usam sempre o mês de referência acima; só os totais diários usam o intervalo abaixo.';

  @override
  String get salesDailyTotalsFilterCustomRangeAnchorIndependenceBanner =>
      'Alterar o mês de referência atualiza só os gráficos mensais. Os totais diários seguem as datas de venda abaixo até você ajustar o intervalo ou voltar ao modo mesmo mês.';

  @override
  String salesDailyTotalsFilterRangeTooLongSnackbar(int maxDays) {
    return 'Escolha um período de no máximo $maxDays dias.';
  }

  @override
  String salesMonthlyPnlFullscreenDailyTotalsPeriodSuffix(
    String startDate,
    String endDate,
  ) {
    return 'Totais diários: $startDate–$endDate.';
  }

  @override
  String get salesCardProdutoTendenciaTitle => 'Sales trend';

  @override
  String get salesCardProdutoTendenciaMediaMovelTitle =>
      'Sales trend (moving average)';

  @override
  String get salesMonthlyPnlPageSubtitle =>
      'Venda, lucro e custo da mercadoria por mês na filial selecionada. A janela termina no mes de referência.';

  @override
  String get salesMonthlyPnlFilterAnchorMonth => 'Mes de referência';

  @override
  String get salesMonthlyPnlChartTitle => 'Resultado mensal';

  @override
  String get salesMonthlyPnlChartSubtitle =>
      'Venda, lucro e custo da mercadoria por mês (filial selecionada).';

  @override
  String get salesMonthlyPnlSeriesSalesLabel => 'Vendas';

  @override
  String get salesMonthlyPnlSeriesProfitLabel => 'Lucro';

  @override
  String get salesMonthlyPnlSeriesCostLabel => 'Custo da mercadoria';

  @override
  String get salesMonthlyPnlEmpty => 'Sem dados mensais para este período.';

  @override
  String get salesMonthlyPnlLoadFailed =>
      'Não foi possível carregar o gráfico mensal. Tente novamente mais tarde.';

  @override
  String get salesMonthlyPnlChartSemantics =>
      'Gráfico do resultado mensal com venda, lucro e custo da mercadoria na filial selecionada';

  @override
  String get salesMonthlyPnlBarChartTitle => 'Comparativo mensal (barras)';

  @override
  String get salesMonthlyPnlBarChartSubtitle =>
      'As barras usam os mesmos totais mensais que o gráfico de linhas acima (venda, lucro e custo da mercadoria agregados — não médias por item). Os percentuais sao calculados a partir desses totais mensais.';

  @override
  String get salesMonthlyPnlBarDisplayValuesLabel => 'Valores';

  @override
  String get salesMonthlyPnlBarDisplayPercentLabel => 'Percentuais';

  @override
  String get salesMonthlyPnlBarDisplayValuesCompactLabel => 'Val.';

  @override
  String get salesMonthlyPnlBarDisplayPercentCompactLabel => '%';

  @override
  String salesMonthlyPnlFullscreenFilterSummary(
    String agentsLabel,
    String agentName,
    String anchorLabel,
    String anchorValue,
  ) {
    return '$agentsLabel: $agentName. $anchorLabel: $anchorValue.';
  }

  @override
  String get salesMonthlyPnlBarZerosOnlyMessage =>
      'Nada para plotar nesta vista na janela selecionada (todos os valores sao zero).';

  @override
  String get salesMonthlyPnlBarChartSemantics =>
      'Gráfico de barras agrupadas mensais de venda, lucro e custo da mercadoria';

  @override
  String salesMonthlyPnlBarSummarySemantics(
    String totalSales,
    String totalProfit,
    String totalCost,
    String topMonth,
    String topSales,
  ) {
    return 'Totais do período: $totalSales em vendas, $totalProfit de lucro, $totalCost de custo da mercadoria. Mes com maior venda: $topMonth ($topSales).';
  }

  @override
  String get salesProdutoRankLucroChartTitle => 'Top produtos';

  @override
  String get salesProdutoRankLucroFilterPeriod => 'Período';

  @override
  String get salesProdutoRankLucroFilterSortBy => 'Metrica';

  @override
  String get salesProdutoRankLucroSortQuantity => 'Quantidade vendida';

  @override
  String get salesProdutoRankLucroSortProfit => 'Lucro total';

  @override
  String get salesProdutoTendenciaPageSubtitle =>
      'Executive snapshot of product sales trend with summary, movers, and paged details.';

  @override
  String get salesProdutoTendenciaFilterCurrentPeriod => 'Current period';

  @override
  String get salesProdutoTendenciaFilterPreviousPeriod => 'Previous period';

  @override
  String get salesProdutoTendenciaComparisonCurrentChip => 'Current';

  @override
  String get salesProdutoTendenciaComparisonPreviousChip => 'Previous';

  @override
  String get salesProdutoTendenciaFilterSearch => 'Search term';

  @override
  String get salesProdutoTendenciaFilterSearchHint =>
      'Product, group, or brand';

  @override
  String get salesProdutoTendenciaFilterClassification => 'Classification';

  @override
  String get salesProdutoTendenciaFilterGroup => 'Group';

  @override
  String get salesProdutoTendenciaFilterBrand => 'Brand';

  @override
  String get salesProdutoTendenciaFilterPageSize => 'Rows per page';

  @override
  String get salesProdutoTendenciaFilterAllOption => 'All';

  @override
  String get salesProdutoTendenciaFilterQuickPeriodsTitle =>
      'Suggested periods';

  @override
  String get salesProdutoTendenciaFilterQuickPeriodsSubtitle =>
      'Pick a base window and the report will align the comparison for you.';

  @override
  String get salesProdutoTendenciaFilterPresetCurrentMonth => 'Current month';

  @override
  String get salesProdutoTendenciaFilterPresetPreviousMonth => 'Previous month';

  @override
  String get salesProdutoTendenciaFilterPresetLast7Days => 'Last 7 days';

  @override
  String get salesProdutoTendenciaFilterPresetLast30Days => 'Last 30 days';

  @override
  String get salesProdutoTendenciaFilterAutoAdjustPreviousAction =>
      'Adjust previous period';

  @override
  String get salesProdutoTendenciaFilterRuleHelperTitle => 'Comparison rule';

  @override
  String get salesProdutoTendenciaFilterRuleHelper =>
      'Compare full months with full months, or custom periods with the same number of days.';

  @override
  String get salesProdutoTendenciaFilterApplyDisabledTitle =>
      'Comparison needs adjustment';

  @override
  String get salesProdutoTendenciaFilterApplyDisabledHint =>
      'Update the periods above to enable the apply action.';

  @override
  String salesProdutoTendenciaFilterDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get salesProdutoTendenciaFilterRangeKindFullMonth => 'Full month';

  @override
  String get salesProdutoTendenciaFilterRangeKindCustom => 'Custom period';

  @override
  String get salesProdutoTendenciaFilterPeriodsOrderError =>
      'The previous period must end before the current period starts.';

  @override
  String get salesProdutoTendenciaFilterPeriodsEquivalentWindowError =>
      'Use equivalent comparison windows: full month versus full month, or custom period versus custom period with the same number of days.';

  @override
  String get salesProdutoTendenciaSummaryTitle => 'Executive summary';

  @override
  String get salesProdutoTendenciaSummarySubtitle =>
      'Overview of product movement by trend classification.';

  @override
  String get salesProdutoTendenciaSummaryByClassificacaoTitle =>
      'Products by classification';

  @override
  String get salesProdutoTendenciaSummaryByClassificacaoSubtitle =>
      'Distribution and impact in the loaded page.';

  @override
  String get salesProdutoTendenciaTopMoversTitle => 'Top movers';

  @override
  String get salesProdutoTendenciaTopMoversSubtitle =>
      'Highest growth and decline in the selected period.';

  @override
  String get salesProdutoTendenciaTopGainersTitle => 'Top 5 gainers';

  @override
  String get salesProdutoTendenciaTopLosersTitle => 'Top 5 losers';

  @override
  String get salesProdutoTendenciaDetailsTitle => 'Detailed rows';

  @override
  String get salesProdutoTendenciaDetailsSubtitle =>
      'Paginated detail with product, classification, and group.';

  @override
  String get salesProdutoTendenciaDetailsHorizontalScrollCaption =>
      'Swipe sideways to see all columns.';

  @override
  String get salesProdutoTendenciaFiltersAppliedSnackbar =>
      'Filters applied. Refreshing data.';

  @override
  String get salesProdutoTendenciaLoadingTrendSemantics =>
      'Loading sales trend…';

  @override
  String get salesProdutoTendenciaDetailsEntityLabel => 'rows';

  @override
  String get salesProdutoTendenciaNoData =>
      'No trend data for the selected filters.';

  @override
  String get salesProdutoTendenciaKpiGrowing => 'Growing products';

  @override
  String get salesProdutoTendenciaKpiFalling => 'Falling products';

  @override
  String get salesProdutoTendenciaKpiNewProducts => 'New products';

  @override
  String get salesProdutoTendenciaKpiStopped => 'Stopped selling';

  @override
  String get salesProdutoTendenciaKpiNetImpact => 'Net impact (qty)';

  @override
  String get salesProdutoTendenciaColProduct => 'Product';

  @override
  String get salesProdutoTendenciaColClassificacao => 'Classification';

  @override
  String get salesProdutoTendenciaColGrupo => 'Group';

  @override
  String get salesProdutoTendenciaColDiferenca => 'Delta';

  @override
  String get salesProdutoTendenciaColPercentual => 'Trend %';

  @override
  String get salesProdutoTendenciaClassificacaoStopped => 'Stopped selling';

  @override
  String get salesProdutoTendenciaClassificacaoNew => 'New product';

  @override
  String get salesProdutoTendenciaClassificacaoGrowing => 'Growing';

  @override
  String get salesProdutoTendenciaClassificacaoFalling => 'Falling';

  @override
  String get salesProdutoTendenciaClassificacaoStable => 'Stable';

  @override
  String salesProdutoTendenciaActiveFiltersSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count additional filters',
      one: '1 additional filter',
      zero: 'No additional filters',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaDetailsNotice(String pageSize) {
    return 'Results may contain more rows. Use pagination to load next pages (current size: $pageSize).';
  }

  @override
  String get salesProdutoTendenciaMediaMovelPageSubtitle =>
      'Moving-average dashboard with classification summary and paged product detail.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDias =>
      'Window size';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint =>
      'Number of days used in each moving average';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper =>
      'Use the same window size for the current and previous averages.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid =>
      'Enter a valid number of days greater than zero.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle =>
      'Quick windows';

  @override
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge(
    int maxDays,
  ) {
    return 'Use at most $maxDays days.';
  }

  @override
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaMediaMovelActiveFiltersSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count additional filters',
      one: '1 additional filter',
      zero: 'No additional filters',
    );
    return '$_temp0';
  }

  @override
  String get salesProdutoTendenciaMediaMovelFilterSearchHint =>
      'Product or group';

  @override
  String get salesProdutoTendenciaMediaMovelFiltersAppliedSnackbar =>
      'Filters applied. Refreshing moving-average trend.';

  @override
  String get salesProdutoTendenciaMediaMovelSelectAgentHint =>
      'Choose one sales agent to load the moving-average sales trend.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryTitle => 'Executive summary';

  @override
  String get salesProdutoTendenciaMediaMovelSummarySubtitle =>
      'Classification totals across the full filtered result.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableTitle =>
      'Summary unavailable';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableMessage =>
      'The summary could not be loaded, so the page is showing an estimate based on the current rows.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle =>
      'Products by classification';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle =>
      'Distribution of products across the full filtered result.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByImpactTitle =>
      'Impact by classification';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle =>
      'Net quantity impact of each classification across the full filtered result.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsTitle => 'Detailed rows';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsSubtitle =>
      'Paginated detail with product, averages, group, and trend classification.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption =>
      'Swipe sideways to see all columns.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsEntityLabel => 'rows';

  @override
  String salesProdutoTendenciaMediaMovelDetailsSortedBy(String sortLabel) {
    return 'Sorted by: $sortLabel';
  }

  @override
  String salesProdutoTendenciaMediaMovelDetailsNotice(String pageSize) {
    return 'Results may contain more rows. Use pagination to load next pages (current size: $pageSize).';
  }

  @override
  String get salesProdutoTendenciaMediaMovelNoData =>
      'No moving-average trend data for the selected filters.';

  @override
  String get salesProdutoTendenciaMediaMovelKpiGrowing => 'Growing products';

  @override
  String get salesProdutoTendenciaMediaMovelKpiFalling => 'Falling products';

  @override
  String get salesProdutoTendenciaMediaMovelKpiNewProducts => 'New products';

  @override
  String get salesProdutoTendenciaMediaMovelKpiStopped => 'Stopped selling';

  @override
  String get salesProdutoTendenciaMediaMovelKpiNetImpact => 'Net impact (qty)';

  @override
  String get salesProdutoTendenciaMediaMovelColProduct => 'Product';

  @override
  String get salesProdutoTendenciaMediaMovelColClassificacao =>
      'Classification';

  @override
  String get salesProdutoTendenciaMediaMovelColGrupo => 'Group';

  @override
  String get salesProdutoTendenciaMediaMovelColMediaAtual => 'Current avg.';

  @override
  String get salesProdutoTendenciaMediaMovelColMediaAnterior => 'Previous avg.';

  @override
  String get salesProdutoTendenciaMediaMovelColDiferenca => 'Delta';

  @override
  String get salesProdutoTendenciaMediaMovelColPercentual => 'Trend %';

  @override
  String get salesProdutoTendenciaMediaMovelFilterSortBy => 'Sort rows by';

  @override
  String get salesProdutoTendenciaMediaMovelSortTrendPercent =>
      'Trend percentage';

  @override
  String get salesProdutoTendenciaMediaMovelSortDifference => 'Delta';

  @override
  String get salesProdutoTendenciaMediaMovelSortProductName => 'Product name';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoStopped =>
      'Stopped selling';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoNew => 'New product';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoGrowing => 'Growing';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoFalling => 'Falling';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoStable => 'Stable';

  @override
  String get agentStatusPending => 'Pendente';

  @override
  String get agentStatusRejected => 'Rejeitado';

  @override
  String get agentStatusUnknown => 'Desconhecido';

  @override
  String get reportFiltersApplyButton => 'Aplicar';

  @override
  String get brazilStoreSalesMapCountryLabel => 'Brasil';

  @override
  String get brazilStoreSalesMapRegionNorth => 'Norte';

  @override
  String get brazilStoreSalesMapRegionNortheast => 'Nordeste';

  @override
  String get brazilStoreSalesMapRegionCenterWest => 'Centro-Oeste';

  @override
  String get brazilStoreSalesMapRegionSoutheast => 'Sudeste';

  @override
  String get brazilStoreSalesMapRegionSouth => 'Sul';

  @override
  String get brazilStoreSalesMapEmptyState => 'Sem lojas para exibir no mapa.';

  @override
  String get brazilStoreSalesMapPresetStandardLabel => 'Pontos';

  @override
  String get brazilStoreSalesMapPresetBubbleLabel => 'Bolhas';

  @override
  String get brazilStoreSalesMapPresetMunicipalityBubblesLabel => 'Municípios';

  @override
  String get brazilStoreSalesMapPresetStateBubblesLabel => 'Bolhas por UF';

  @override
  String get brazilStoreSalesMapPresetStoreIconLabel => 'Ícone loja';

  @override
  String get brazilStoreSalesMapPresetStandardTooltip =>
      'Exibe cada loja como ponto individual no mapa.';

  @override
  String get brazilStoreSalesMapPresetBubbleTooltip =>
      'Exibe lojas como bolhas proporcionais à métrica ativa.';

  @override
  String get brazilStoreSalesMapPresetMunicipalityBubblesTooltip =>
      'Agrupa lojas por município e exibe bolhas proporcionais à métrica ativa.';

  @override
  String get brazilStoreSalesMapPresetStateBubblesTooltip =>
      'Agrupa as lojas em bolhas posicionadas no centroide de cada UF.';

  @override
  String get brazilStoreSalesMapPresetStoreIconTooltip =>
      'Exibe cada loja com ícone operacional de unidade.';
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
  String shellSectionBreadcrumbSemantics(String sectionName) {
    return 'Ir para o início da seção $sectionName';
  }

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
      'Algumas filiais aprovadas não retornaram dados. Os totais podem estar incompletos.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Filiais sem token de cliente salvo';

  @override
  String get dashboardMissingClientTokenMessage =>
      'Estas filiais aprovadas foram ignoradas porque não há token de cliente local. Cadastre o token na gestão de filiais para incluir os dados.';

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
      'Nenhuma filial aprovada possui token de cliente salvo neste dispositivo. Abra a gestão de filiais para cadastrar o token e liberar a consulta da visão geral.';

  @override
  String dashboardViewAffectedAgentsList(int count) {
    return 'Ver filiais ($count)';
  }

  @override
  String get dashboardAffectedAgentsSheetTitlePartialFailure =>
      'Filiais que não retornaram dados';

  @override
  String get dashboardAffectedAgentsSheetTitleMissingToken =>
      'Filiais sem token de cliente salvo';

  @override
  String get dashboardAffectedAgentsSheetTitleSetupRequired =>
      'Filiais aprovadas sem token de cliente neste dispositivo';

  @override
  String get dashboardAgentsOfflineTitle => 'Filiais offline no momento';

  @override
  String get dashboardAgentsOfflineMessage =>
      'Estas filiais aprovadas têm um token salvo, mas o hub as reporta como desconectadas. Peça ao operador para reconectá-las e tente novamente.';

  @override
  String get dashboardAffectedAgentsSheetTitleOffline =>
      'Filiais reportadas como offline pelo hub';

  @override
  String get dashboardMultiAgentAggregationTitle => 'Varias filiais';

  @override
  String get dashboardMultiAgentAggregationMessage =>
      'Este resumo agrega dados de varias filiais aprovadas. Se houver sobreposição entre bases, os totais podem ficar acima de uma unica fonte.';

  @override
  String get overviewHomeAlertErrorDetailsButton => 'Detalhes do erro';

  @override
  String get overviewHomeAlertDetailsCopiedSnackbar =>
      'Copiado para a área de transferência';

  @override
  String get overviewHomeAlertFailureSourcePaymentResumo =>
      'Consulta resumo por forma de pagamento';

  @override
  String get overviewHomeAlertFailureSourceLucratividadePeriod =>
      'Consulta lucratividade (período)';

  @override
  String get overviewHomeAlertDetailsUserLine => 'O que ocorreu';

  @override
  String get overviewHomeAlertDetailsTechnicalLine => 'Detalhe técnico';

  @override
  String get overviewHomeAlertDetailsNoEntries =>
      'Não há linhas de diagnóstico para este aviso.';

  @override
  String get overviewHomeAlertDetailsStaleIntro =>
      'Estes números vêm do último resumo obtido com sucesso neste aparelho.\n\n';

  @override
  String get overviewHomeAlertErrorDetailsSemanticsLabel =>
      'Abre uma folha com o texto de diagnóstico completo. Pode selecionar e copiar.';

  @override
  String get overviewHomeAlertDetailsCopySemanticsLabel =>
      'Copia o texto de diagnóstico para a área de transferência';

  @override
  String overviewHomeAlertDetailsAgentSemanticSummary(
    String agentName,
    String agentId,
    String sourceLabel,
    String userMessage,
  ) {
    return '$agentName, identificador da filial $agentId. $sourceLabel. $userMessage.';
  }

  @override
  String get dashboardPaymentSummaryTitle => 'Resumo por forma de pagamento';

  @override
  String get dashboardPaymentSummarySubtitle =>
      'Detalhamento de vendas, ticket médio e participação.';

  @override
  String get dashboardPaymentSummaryEmptyTitle => 'Sem formas de pagamento';

  @override
  String get dashboardPaymentSummaryEmptyMessage =>
      'Não há linhas de forma de pagamento para este período.';

  @override
  String get dashboardPaymentSummaryHeaderRevenueAbbr => 'FATURAM.';

  @override
  String get dashboardPaymentSummaryTooltipRevenueAbbr =>
      'Faturamento no período selecionado';

  @override
  String get dashboardPaymentSummaryHeaderParticipationAbbr => 'PARTIC.';

  @override
  String get dashboardPaymentSummaryTooltipParticipationAbbr =>
      'Participação percentual no faturamento total';

  @override
  String get dashboardPaymentSummaryHeaderSales => 'VENDAS';

  @override
  String get dashboardPaymentSummaryHeaderAvgTicket => 'TICKET\nMEDIO';

  @override
  String get dashboardHomeFiltersAgentsLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visão geral para listar as filiais.';

  @override
  String get dashboardHomeFiltersBranchesLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersBranchesEmptyHint =>
      'Carregue a visão geral para listar as filiais.';

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
    return 'Todas as filiais ($count)';
  }

  @override
  String overviewHomeBranchFilterAllBranchesSummary(int count) {
    return 'Todas as filiais ($count)';
  }

  @override
  String overviewAgentFilterSelectedCount(int count) {
    return '$count filiais selecionadas';
  }

  @override
  String overviewHomeBranchFilterSelectedCount(int count) {
    return '$count filiais selecionadas';
  }

  @override
  String get overviewAgentFilterRefineAction => 'Refinar filiais';

  @override
  String get overviewAgentFilterEditAction => 'Editar';

  @override
  String get overviewAgentFilterSheetTitle => 'Selecionar filiais';

  @override
  String get overviewAgentFilterSheetSearchHint => 'Buscar filiais…';

  @override
  String get overviewHomeBranchFilterSheetTitle => 'Selecionar filiais';

  @override
  String get overviewHomeBranchFilterSheetSearchHint => 'Buscar filiais…';

  @override
  String get overviewHomeBranchFilterSelectAll => 'Selecionar todos';

  @override
  String get overviewHomeBranchFilterSelectAllFullRoster =>
      'Todas as filiais (lista completa)';

  @override
  String get overviewHomeBranchFilterDeselectAll => 'Desmarcar todos';

  @override
  String get overviewHomeBranchFilterSelectMatching =>
      'Selecionar todas as filiais filtradas';

  @override
  String get overviewHomeBranchFilterDeselectMatching =>
      'Desmarcar filiais filtradas';

  @override
  String overviewHomeBranchFilterSelectionCount(
    int selectedCount,
    int totalCount,
  ) {
    return '$selectedCount de $totalCount filiais selecionadas';
  }

  @override
  String get overviewHomeBranchFilterApplyRequiresSelectionHint =>
      'Escolha pelo menos uma filial para aplicar.';

  @override
  String get overviewHomeBranchFilterSheetUseAllBranches =>
      'Usar todas as filiais';

  @override
  String get overviewHomeBranchFilterApplyDisabledSemantics =>
      'Aplicar. Desativado. Selecione pelo menos uma filial.';

  @override
  String get overviewHomeBranchFilterRefineAction => 'Refinar filiais';

  @override
  String get overviewHomeBranchFilterEditAction => 'Editar';

  @override
  String get overviewHomeBranchFilterApply => 'Aplicar';

  @override
  String get overviewHomeBranchFilterCancel => 'Cancelar';

  @override
  String get overviewHomeBranchFilterMissingClientTokenRowSubtitle =>
      'Sem token neste dispositivo para esta filial — consultas SQL são ignoradas.';

  @override
  String get overviewAgentFilterApply => 'Aplicar';

  @override
  String get overviewAgentFilterCancel => 'Cancelar';

  @override
  String get overviewAgentFilterNoSearchResults =>
      'Nenhuma filial corresponde à busca.';

  @override
  String get overviewHomeBranchFilterNoSearchResults =>
      'Nenhuma filial corresponde à busca.';

  @override
  String get overviewAgentFilterMissingClientTokenBanner =>
      'Filiais sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get overviewHomeBranchFilterMissingClientTokenBanner =>
      'Filiais sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get overviewAgentFilterMissingClientTokenRowSubtitle =>
      'Sem token neste dispositivo para esta filial — consultas SQL são ignoradas.';

  @override
  String get chartCategoryDonutEmptyForFilter =>
      'Sem dados de categorias para este recorte.';

  @override
  String get dashboardAgentRankingTitle => 'Ranking por filial';

  @override
  String get dashboardAgentRankingSubtitle =>
      'Faturamento total por filial no período.';

  @override
  String get dashboardUserRankingTitle => 'Ranking por operador';

  @override
  String get dashboardUserRankingSubtitle =>
      'Faturamento por operador no período.';

  @override
  String get overviewAgentRankingEmpty =>
      'Sem faturamento por filial neste período.';

  @override
  String get overviewUserRankingEmpty =>
      'Sem faturamento por operador neste período.';

  @override
  String get overviewTopProductsTitle => 'Produtos mais vendidos';

  @override
  String overviewTopProductsSubtitle(int count) {
    return 'Por filial (sem unir cadastros). Até $count produtos.';
  }

  @override
  String get overviewTopProductsNoEligibleAgents =>
      'Nenhuma filial disponível para este gráfico. Salve o token na filial ou ajuste o filtro.';

  @override
  String get overviewTopProductsInvalidPeriod =>
      'O período selecionado não é válido para este gráfico.';

  @override
  String get overviewTopProductsEmpty =>
      'Sem vendas de produto neste período para esta filial.';

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
      'Resumo consolidado das filiais aprovadas (ligadas ao hub).';

  @override
  String get overviewHomeManageBranchesAction => 'Gestão de filiais';

  @override
  String get overviewHomeAlertsSectionTitle => 'Avisos';

  @override
  String get overviewLoadErrorTitle =>
      'Não foi possível carregar a visão geral';

  @override
  String get overviewStaleCacheTitle => 'Dados salvos neste aparelho';

  @override
  String get overviewStaleCacheMessage =>
      'Não foi possível atualizar agora. Os números abaixo refletem o último resumo obtido com sucesso.';

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
      'Carregando gráfico dos últimos 12 meses…';

  @override
  String get overviewLoadingWeekdaySalesSemantics =>
      'Carregando gráfico de vendas por dia da semana…';

  @override
  String get overviewMonthlyParcelsTitle => 'Últimos 12 meses';

  @override
  String get overviewMonthlyParcelsSubtitle =>
      'Quantidade de vendas e total em parcelas por mês (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSalesSeriesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsAmountSeriesLabel => 'Valor em parcelas';

  @override
  String get overviewMonthlyParcelsEmpty =>
      'Sem dados mensais para este período.';

  @override
  String get overviewMonthlyParcelsLoadFailed =>
      'Não foi possível carregar o gráfico mensal. Tente novamente mais tarde.';

  @override
  String get overviewMonthlyParcelsChartSemantics =>
      'Gráfico dos últimos doze meses de vendas e valor em parcelas';

  @override
  String get overviewMonthlyParcelsSubtitleValueView =>
      'Total em parcelas e quantidade de vendas por mês (todas as filiais no escopo).';

  @override
  String get overviewMonthlyParcelsSwitchSalesLabel => 'Vendas';

  @override
  String get overviewMonthlyParcelsSwitchValueLabel => 'Valor';

  @override
  String get overviewMonthlyParcelsChartSemanticsValueView =>
      'Gráfico dos últimos doze meses de valor em parcelas e vendas';

  @override
  String get overviewDailySalesTitle => 'Vendas por dia';

  @override
  String get overviewDailySalesSubtitle =>
      'Totais por dia civil no período selecionado (agregado das filiais no escopo).';

  @override
  String get overviewDailySalesEmpty =>
      'Sem dados de vendas diárias neste período.';

  @override
  String get overviewDailySalesLoadFailed =>
      'Não foi possível carregar o gráfico de vendas diárias. Tente novamente mais tarde.';

  @override
  String get overviewDailySalesChartSemantics =>
      'Gráfico de quantidade de vendas e faturamento por dia';

  @override
  String get overviewDailySalesRevenueChartSemantics =>
      'Gráfico de faturamento e quantidade de vendas por dia';

  @override
  String get overviewLoadingDailySalesSemantics =>
      'Carregando gráfico de vendas diárias';

  @override
  String overviewDailySalesTooltip(
    String date,
    String salesCount,
    String salesAmount,
  ) {
    return '$date: $salesCount vendas - $salesAmount';
  }

  @override
  String get overviewDailySalesAxisDowMon => 'Segunda';

  @override
  String get overviewDailySalesAxisDowTue => 'Terça';

  @override
  String get overviewDailySalesAxisDowWed => 'Quarta';

  @override
  String get overviewDailySalesAxisDowThu => 'Quinta';

  @override
  String get overviewDailySalesAxisDowFri => 'Sexta';

  @override
  String get overviewDailySalesAxisDowSat => 'Sábado';

  @override
  String get overviewDailySalesAxisDowSun => 'Domingo';

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
  String get overviewKpiAvgTicket => 'Ticket médio';

  @override
  String get overviewUserRankingChartSemanticsExtra =>
      'Cada barra mostra o faturamento total e o ticket médio daquele operador.';

  @override
  String get overviewKpiPaymentMethodCount => 'Formas de pagamento';

  @override
  String get overviewPaymentMixTitle => 'Mix por forma de pagamento';

  @override
  String get overviewPaymentMixSubtitle =>
      'Participação percentual no faturamento do período.';

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
      'Carregando gráfico de categorias…';

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
    return 'Gráfico de rosca. $summary';
  }

  @override
  String get overviewPaymentBarTitle => 'Faturamento por forma de pagamento';

  @override
  String get overviewPaymentBarSubtitle => 'Valor total acumulado no período.';

  @override
  String get overviewPaymentBarEmpty =>
      'Sem faturamento por forma de pagamento neste período.';

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
  String get chartFullscreenDataSnapshotHint =>
      'Os valores do mapa refletem os dados carregados ao abrir a tela cheia.';

  @override
  String get regionMapMetricGroupLabel => 'Métrica';

  @override
  String get regionMapScopeGroupLabel => 'Escopo';

  @override
  String get regionMapRootScopeLabel => 'Todas as regiões';

  @override
  String get regionMapLoadingMessage => 'Carregando mapa…';

  @override
  String get regionMapEmptyStateMessage =>
      'Nenhum dado territorial para exibir.';

  @override
  String get regionMapMetricSelectorSemanticsLabel => 'Métrica do mapa';

  @override
  String get regionMapScopeSemanticsLabel => 'Escopo territorial';

  @override
  String get regionMapDrillUpToRegionsLabel => 'Voltar para regiões';

  @override
  String get regionMapDrillUpToStatesLabel => 'Voltar para estados';

  @override
  String get regionMapDrillUpToCitiesLabel => 'Voltar para cidades';

  @override
  String get regionMapDrillUpLabel => 'Voltar';

  @override
  String get regionMapDrillUpTooltip => 'Retornar ao nível anterior do mapa';

  @override
  String regionMapViewFullScopeTooltip(String label) {
    return 'Ver mapa completo ($label)';
  }

  @override
  String regionMapViewFullScopeSemanticLabel(String label) {
    return 'Ver mapa completo $label';
  }

  @override
  String regionMapFocusScopeTooltip(String label) {
    return 'Focar em $label';
  }

  @override
  String regionMapFocusScopeSemanticLabel(String label) {
    return 'Focar em $label';
  }

  @override
  String get brazilStoreSalesMapMetricGroupLabel => 'Métrica';

  @override
  String get brazilStoreSalesMapRegionGroupLabel => 'Região';

  @override
  String get brazilStoreSalesMapLoadingMessage => 'Carregando mapa do Brasil…';

  @override
  String get brazilStoreSalesMapMarkerSizeLegend => 'Tamanho do ponto';

  @override
  String get brazilStoreSalesMapLegendRevenuePerState => 'Receita por UF';

  @override
  String get brazilStoreSalesMapLegendSalesPerState => 'Vendas por UF';

  @override
  String get brazilStoreSalesMapShowBranchOnMapAction => 'Destacar no mapa';

  @override
  String get brazilStoreSalesMapUnpinBranchButton => 'Desfixar no mapa';

  @override
  String get brazilStoreSalesMapMetricRevenueShort => 'Receita';

  @override
  String get brazilStoreSalesMapMetricSalesShort => 'Vendas';

  @override
  String get brazilStoreSalesMapLegendButton => 'Legenda';

  @override
  String brazilStoreSalesMapStateBucketTooltip(
    String stateName,
    String uf,
    String revenue,
    String salesCount,
    String storeCount,
  ) {
    return '$stateName / $uf\n$revenue | $salesCount vendas | $storeCount lojas';
  }

  @override
  String brazilStoreSalesMapStateInlineTooltip(
    String stateName,
    String uf,
    String revenue,
    String salesCount,
    String storeCount,
  ) {
    return '$stateName ($uf) | $revenue | $salesCount vendas | $storeCount lojas';
  }

  @override
  String get brazilStoreSalesMapSemanticsStoreOnMap => 'Loja no mapa';

  @override
  String get brazilStoreSalesMapSemanticsSalesLoadingSuffix =>
      ', vendas carregando';

  @override
  String get brazilStoreSalesMapSemanticsSalesUnavailableSuffix =>
      ', vendas indisponíveis';

  @override
  String brazilStoreSalesMapSemanticsClusterStores(
    String storeCount,
    String cityLabel,
    String revenue,
    String salesCount,
    String salesStatusSuffix,
  ) {
    return '$storeCount lojas em $cityLabel, $revenue, $salesCount vendas$salesStatusSuffix';
  }

  @override
  String brazilStoreSalesMapSemanticsSingleStore(
    String storeName,
    String cityLabel,
    String revenue,
    String salesCount,
    String salesStatusSuffix,
  ) {
    return '$storeName, $cityLabel, $revenue, $salesCount vendas$salesStatusSuffix';
  }

  @override
  String brazilStoreSalesMapSemanticsStateAggregate(
    String stateName,
    String revenue,
    String salesCount,
    String storeCount,
  ) {
    return '$stateName, $revenue, $salesCount vendas, $storeCount lojas';
  }

  @override
  String brazilStoreSalesMapDetailChipSales(String count) {
    return '$count vendas';
  }

  @override
  String brazilStoreSalesMapDetailChipBranches(String count) {
    return '$count filiais';
  }

  @override
  String brazilStoreSalesMapStateSelectedSubtitle(String uf) {
    return '$uf selecionado';
  }

  @override
  String brazilStoreSalesMapCarouselPosition(String current, String total) {
    return '$current de $total';
  }

  @override
  String get brazilStoreSalesMapBranchDetailSemanticsLabel =>
      'Detalhes da filial no mapa';

  @override
  String get brazilStoreSalesMapSalesLoadingLabel => 'Carregando vendas';

  @override
  String brazilStoreSalesMapDataQualityLead(String count) {
    return '$count lojas não exibidas';
  }

  @override
  String brazilStoreSalesMapDataQualityInvalidCoords(String count) {
    return '$count com coordenada inválida';
  }

  @override
  String brazilStoreSalesMapDataQualityUnknownUf(String count) {
    return '$count com UF desconhecida';
  }

  @override
  String brazilStoreSalesMapDataQualityOutsideClip(String count) {
    return '$count fora do recorte';
  }

  @override
  String salesLiveMapFilterBranchSummaryLine(
    String city,
    String uf,
    String agentName,
  ) {
    return '$city/$uf — Filial $agentName';
  }

  @override
  String salesLiveMapFilterBranchCodesLine(
    String codEmpresa,
    String codFilial,
  ) {
    return 'Empresa: $codEmpresa  Filial: $codFilial';
  }

  @override
  String get brazilStoreSalesMapCloseBranchDetailsTooltip => 'Fechar detalhes';

  @override
  String get brazilStoreSalesMapBranchPinnedChip => 'Filial fixada';

  @override
  String get brazilStoreSalesMapSalesUnavailableFallback =>
      'Vendas indisponíveis';

  @override
  String get brazilStoreSalesMapSelectBranchButton => 'Selecionar filial';

  @override
  String get brazilStoreSalesMapChooseBranchMenuTooltip => 'Escolher filial';

  @override
  String get brazilStoreSalesMapBranchNavigationPreviousTooltip =>
      'Filial anterior';

  @override
  String get brazilStoreSalesMapBranchNavigationNextTooltip => 'Próxima filial';

  @override
  String get brazilStoreSalesMapMarkerGroupTotalTitle => 'Total do ponto';

  @override
  String get brazilStoreSalesMapDefaultBranchName => 'Filial sem nome';

  @override
  String get brazilStoreSalesMapSidebarTitle => 'Filiais visíveis';

  @override
  String brazilStoreSalesMapSidebarSummary(int count, String revenue) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filiais visíveis',
      one: '1 filial visível',
    );
    return '$_temp0 · $revenue';
  }

  @override
  String brazilStoreSalesMapSidebarCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filiais visíveis',
      one: '1 filial visível',
    );
    return '$_temp0';
  }

  @override
  String brazilStoreSalesMapSidebarRevenueSummary(String revenue) {
    return 'Total no recorte: $revenue';
  }

  @override
  String get brazilStoreSalesMapSidebarSearchPlaceholder =>
      'Buscar filial ou cidade';

  @override
  String get brazilStoreSalesMapSidebarSearchSemanticsLabel =>
      'Buscar filial ou cidade na lista do mapa';

  @override
  String get brazilStoreSalesMapSidebarEmptyStateTitle =>
      'Nenhuma filial visível';

  @override
  String get brazilStoreSalesMapSidebarEmptyStateMessage =>
      'Ajuste a regiao do mapa ou limpe o escopo ativo para listar filiais neste painel.';

  @override
  String get brazilStoreSalesMapSidebarSearchEmptyStateTitle =>
      'Nenhuma filial encontrada';

  @override
  String get brazilStoreSalesMapSidebarSearchEmptyStateMessage =>
      'Ajuste a busca para localizar filiais neste recorte.';

  @override
  String get brazilStoreSalesMapSidebarZeroSalesLabel =>
      'Sem vendas no período';

  @override
  String get brazilStoreSalesMapSidebarCollapseTooltip =>
      'Ocultar lista de filiais';

  @override
  String get brazilStoreSalesMapSidebarExpandTooltip =>
      'Mostrar lista de filiais';

  @override
  String brazilStoreSalesMapAgentChipWithName(String agentName) {
    return 'Filial $agentName';
  }

  @override
  String brazilStoreSalesMapIbgeCodeLabel(String code) {
    return 'IBGE $code';
  }

  @override
  String get brazilStoreSalesMapLocationProvidedGeoPoint =>
      'Coordenada da filial';

  @override
  String get brazilStoreSalesMapLocationIbge => 'Geolocalização IBGE';

  @override
  String get brazilStoreSalesMapLocationCep => 'Geolocalização CEP';

  @override
  String get brazilStoreSalesMapLocationCityUf => 'Geolocalização cidade/UF';

  @override
  String get brazilStoreSalesMapLocationCapitalUf => 'Capital da UF';

  @override
  String get brazilStoreSalesMapLocationStateUf => 'Centro da UF';

  @override
  String get brazilStoreSalesMapLocationUnknown =>
      'Origem da coordenada não informada';

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
    return 'Ticket médio $amount';
  }

  @override
  String overviewSemanticsSharePercent(String value) {
    return '$value por cento';
  }

  @override
  String get overviewNoApprovedAgentsUserMessage =>
      'Nenhuma filial aprovada está disponível para carregar a visão geral.';

  @override
  String get overviewLoadFailedUserMessage =>
      'Não foi possível carregar a visão geral.';

  @override
  String get clientAgentsDataSourcesEyebrow => 'Fontes de dados';

  @override
  String get clientAgentsPageTitle => 'Gestão de agentes';

  @override
  String get clientAgentsPageSubtitle =>
      'Acompanhe seus agentes aprovados, solicite novos acessos e consulte o andamento das solicitações.';

  @override
  String clientAgentsPendingActionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ações para enviar',
      one: '1 ação para enviar',
    );
    return '$_temp0';
  }

  @override
  String get clientAgentsRefresh => 'Atualizar';

  @override
  String get clientAgentsSubmitRequests => 'Enviar solicitações';

  @override
  String get clientAgentsActionFailedTitle =>
      'Não foi possível concluir a ação';

  @override
  String get clientAgentsMaintenanceTitle => 'Manutenção de agentes';

  @override
  String get clientAgentsMaintenanceSubtitle =>
      'Use as abas para ver agentes aprovados, pedir novos acessos e acompanhar o histórico das solicitações.';

  @override
  String get clientAgentsMaintenanceSubtitleOwner =>
      'Use as abas para gerir agentes aprovados, reenviar solicitações de clientes e revisar acessos dos agentes que você administra.';

  @override
  String get clientAgentsTabMyAgents => 'Meus agentes';

  @override
  String get clientAgentsTabRequestAccess => 'Solicitar acesso';

  @override
  String get clientAgentsTabRequests => 'Solicitações';

  @override
  String get clientAgentsTabOwnerRequests => 'Revisar solicitações';

  @override
  String get clientAgentsTabOwnerClients => 'Clientes aprovados';

  @override
  String get clientAgentsLoadApprovedErrorTitle =>
      'Não foi possível carregar seus agentes';

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
      'Selecionar para remoção em lote';

  @override
  String get clientAgentsApprovedBulkCancel => 'Cancelar seleção';

  @override
  String clientAgentsApprovedBulkRemove(int count) {
    return 'Remover selecionados ($count)';
  }

  @override
  String get clientAgentsBulkRemoveConfirmTitle =>
      'Enfileirar remoção para varios agentes?';

  @override
  String clientAgentsBulkRemoveConfirmMessage(int count) {
    return 'A remoção de acesso para $count agentes será preparada e enviada no próximo sync.';
  }

  @override
  String get clientAgentsBulkRemoveConfirmBack => 'Voltar';

  @override
  String get clientAgentsBulkRemoveConfirmAction => 'Enfileirar remoção';

  @override
  String get clientAgentsApprovedBulkSelectAll => 'Selecionar todos';

  @override
  String get clientAgentsApprovedBulkClearSelection => 'Limpar seleção';

  @override
  String get clientAgentsRequestAccessIntro1 =>
      'Use uma ou mais linhas para solicitar acesso. Cada linha precisa de um UUID de agente; informe o client token quando o agente exigir para execução SQL.';

  @override
  String get clientAgentsRequestAccessIntro2 =>
      'O agentId deve ser informado pelo responsável do agente ou por um fluxo externo. Quando a solicitação for aprovada, o agente será liberado automáticamente para esta conta.';

  @override
  String get clientAgentsRequestAccessIntroToken =>
      'O client token fica em cache neste dispositivo enquanto a aprovação está pendente e é enviado ao servidor Colmeia assim que o agente for vinculado.';

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
      'Opcional — cache local, enviado ao servidor após aprovação';

  @override
  String get clientAgentsClientTokenShow => 'Mostrar token';

  @override
  String get clientAgentsClientTokenHide => 'Ocultar token';

  @override
  String get clientAgentsAgentIdsLabel => 'Agent ID';

  @override
  String get clientAgentsRequestAccessCta => 'Solicitar acesso';

  @override
  String clientAgentsDuplicatedIdsNote(String ids) {
    return 'IDs duplicados foram ignorados automáticamente: $ids.';
  }

  @override
  String get clientAgentsLoadRequestsErrorTitle =>
      'Não foi possível carregar as solicitações';

  @override
  String get clientAgentsLoadPendingErrorTitle =>
      'Não foi possível carregar os envios pendentes';

  @override
  String get clientAgentsNoRequestsYet => 'Sem solicitações no momento.';

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
      'Em análise pelo responsável do agente.';

  @override
  String get clientAgentsRequestDescApproved =>
      'Aprovado e disponível para esta conta.';

  @override
  String get clientAgentsRequestDescRejected =>
      'Não foi aprovado pelo responsável do agente.';

  @override
  String get clientAgentsRequestDescExpired =>
      'A solicitação expirou. Envie novamente se necessário.';

  @override
  String get clientAgentsRequestDescUnknown =>
      'O status dessa solicitação ainda não está disponível.';

  @override
  String get clientAgentsRetryRequestAction => 'Tentar novamente';

  @override
  String get clientAgentsPendingDescQueued => 'Pronto para envio.';

  @override
  String get clientAgentsPendingDescSyncing => 'Enviando agora.';

  @override
  String get clientAgentsPendingDescFailed =>
      'Não foi possível enviar. Tente novamente.';

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
      'Sessao indisponível para carregar agentes.';

  @override
  String get clientAgentsSessionUnavailableRequest =>
      'Sessao indisponível para solicitar acesso.';

  @override
  String get clientAgentsSessionUnavailableRemove =>
      'Sessao indisponível para remover acesso.';

  @override
  String get clientAgentsSessionUnavailableSync =>
      'Sessao indisponível para sincronizar pendências.';

  @override
  String get clientAgentsRetryMissingRequestId =>
      'Esta solicitação não pode ser reenviada porque o identificador não está disponível.';

  @override
  String get clientAgentsRetrySuccess =>
      'A solicitação foi reenviada. Vamos continuar acompanhando a aprovação.';

  @override
  String get clientAgentsDiscardQueuedRequestAction => 'Remover da fila';

  @override
  String get clientAgentsDiscardQueuedRequestSuccess =>
      'O envio pendente foi removido. Você pode solicitar acesso de novo quando quiser.';

  @override
  String get clientAgentsDiscardQueuedRequestInvalidState =>
      'Este envio não pode ser removido da fila no estado atual.';

  @override
  String get clientAgentsOwnerActionFailedTitle =>
      'Não foi possível concluir a ação do responsável';

  @override
  String get clientAgentsOwnerRequestsLoadErrorTitle =>
      'Não foi possível carregar as solicitações para revisão';

  @override
  String get clientAgentsOwnerRequestsEmpty =>
      'Nenhuma solicitação de cliente precisa da sua revisão agora.';

  @override
  String get clientAgentsOwnerApproveAction => 'Aprovar';

  @override
  String get clientAgentsOwnerRejectAction => 'Rejeitar';

  @override
  String get clientAgentsOwnerRequestsStatusPending =>
      'Aguardando sua decisao para este agente.';

  @override
  String get clientAgentsOwnerRequestsStatusApproved =>
      'Aprovada e já disponível para o cliente.';

  @override
  String get clientAgentsOwnerRequestsStatusRejected =>
      'Rejeitada durante a revisão do responsável.';

  @override
  String get clientAgentsOwnerRequestsStatusExpired =>
      'Expirou antes da revisão final.';

  @override
  String get clientAgentsOwnerRequestsStatusUnknown =>
      'O status mais recente da revisão não está disponível.';

  @override
  String get clientAgentsOwnerApproveSuccess =>
      'A solicitação de acesso foi aprovada.';

  @override
  String get clientAgentsOwnerRejectSuccess =>
      'A solicitação de acesso foi rejeitada.';

  @override
  String get clientAgentsOwnerClientsEmptyAgents =>
      'Nenhum agente administrado está disponível para esta conta ainda.';

  @override
  String get clientAgentsOwnerClientsAgentSelectorLabel => 'Agente';

  @override
  String get clientAgentsOwnerClientsAgentSelectorHint =>
      'Escolha um agente administrado';

  @override
  String get clientAgentsOwnerClientsLoadErrorTitle =>
      'Não foi possível carregar os clientes aprovados';

  @override
  String get clientAgentsOwnerClientsEmpty =>
      'Nenhum cliente aprovado está vinculado a este agente ainda.';

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
      'Sessao indisponível para carregar o agente.';

  @override
  String get appInlineErrorRetry => 'Tentar novamente';

  @override
  String appInlineErrorRetryCountdown(int seconds) {
    return 'Tentar em ${seconds}s';
  }

  @override
  String get clientAgentsNoLocalPendingToSync =>
      'Não há pendências locais para sincronizar.';

  @override
  String get clientAgentsRequestBlockedFallback =>
      'Não foi possível registrar a solicitação informada.';

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
    return 'Já em análise: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyQueued(String ids) {
    return 'Ja preparados para envio: $ids.';
  }

  @override
  String get clientAgentsRequestQueuedWatchingSingle =>
      'Solicitação enviada. Vamos acompanhar a aprovação automáticamente.';

  @override
  String clientAgentsRequestQueuedWatchingPlural(int count) {
    return '$count solicitações enviadas. Vamos acompanhar as aprovações automáticamente.';
  }

  @override
  String clientAgentsRequestQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados porque já estavam aprovados ou em análise.';
  }

  @override
  String get clientAgentsRequestRelinkUpdatedSingle =>
      'Esse agente já está aprovado no servidor. A lista de agentes foi atualizada.';

  @override
  String clientAgentsRequestRelinkUpdatedPlural(int count) {
    return '$count agentes já estavam aprovados no servidor. A lista de agentes foi atualizada.';
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
      'Não foi possível limpar solicitações pendentes locais; elas podem ser reenviadas na próxima sincronização.';

  @override
  String get clientAgentsRemoveBlockedFallback =>
      'Não foi possível registrar a remoção informada.';

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
    return 'Remoção ja preparada para envio: $ids.';
  }

  @override
  String get clientAgentsRemoveQueuedSingle =>
      'Remoção de acesso preparada e enviada para sincronização.';

  @override
  String clientAgentsRemoveQueuedPlural(int count) {
    return '$count remoções de acesso preparadas e enviadas para sincronização.';
  }

  @override
  String clientAgentsRemoveQueuedIgnoredSuffix(int count) {
    return '$count IDs foram ignorados.';
  }

  @override
  String get clientAgentsSyncSuccessSingle => '1 pendência foi sincronizada.';

  @override
  String clientAgentsSyncSuccessPlural(int count) {
    return '$count pendências foram sincronizadas.';
  }

  @override
  String get clientAgentsSyncSuccessNoneCompleted =>
      'A sincronização terminou, mas nenhuma pendência foi aplicada.';

  @override
  String clientAgentsSyncRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para esperarmos. Tente de novo em ${seconds}s.';
  }

  @override
  String clientAgentsRequestAccessRetryAfterCountdown(int seconds) {
    return 'Muitas solicitações de acesso. Tente de novo em ${seconds}s.';
  }

  @override
  String clientAgentsSyncSuccessSomeFailedSuffix(int count) {
    return ' $count ação(oes) falhou e permanece na fila para nova tentativa.';
  }

  @override
  String get clientAgentsSyncSuccessAutoSuffix =>
      ' O envio aconteceu automáticamente.';

  @override
  String get clientAgentsSyncSuccessManualSuffix =>
      ' A tela ja foi atualizada com o status mais recente.';

  @override
  String get clientAgentsSyncSuccessPollingSuffix =>
      ' Vamos acompanhar a aprovação automáticamente.';

  @override
  String get clientAgentsSyncSuccessAlreadyApprovedSingle =>
      ' Um agente já estava aprovado no servidor.';

  @override
  String clientAgentsSyncSuccessAlreadyApprovedPlural(int count) {
    return ' $count agentes já estavam aprovados no servidor.';
  }

  @override
  String get clientAgentsSyncSuccessDebouncedSingle =>
      ' Uma solicitação foi atualizada recentemente (sem novo email).';

  @override
  String clientAgentsSyncSuccessDebouncedPlural(int count) {
    return ' $count solicitações foram atualizadas recentemente (sem novo email).';
  }

  @override
  String clientAgentsPollApprovedSingle(String tabLabel) {
    return 'Acesso aprovado. O agente ja está disponível em \"$tabLabel\".';
  }

  @override
  String clientAgentsPollApprovedPlural(int count, String tabLabel) {
    return '$count acessos foram aprovados. Os agentes ja estão disponíveis em \"$tabLabel\".';
  }

  @override
  String get clientAgentsPollDeniedSingle =>
      '1 solicitação foi encerrada sem aprovação.';

  @override
  String clientAgentsPollDeniedPlural(int count) {
    return '$count solicitações foram encerradas sem aprovação.';
  }

  @override
  String get clientAgentsPollTimeoutSingle =>
      '1 solicitação ainda está em análise. Atualize esta tela mais tarde para verificar o resultado.';

  @override
  String clientAgentsPollTimeoutPlural(int count) {
    return '$count solicitações seguem em análise e você pode atualizar esta tela mais tarde para verificar o resultado.';
  }

  @override
  String get clientAgentsPollRemainingSingle =>
      'Ainda há 1 solicitação em análise.';

  @override
  String clientAgentsPollRemainingPlural(int count) {
    return 'Ainda há $count solicitações em análise.';
  }

  @override
  String get clientAgentDetailEyebrow => 'Detalhe';

  @override
  String get clientAgentDetailTitle => 'Agente';

  @override
  String get clientAgentDetailSubtitle =>
      'Informações detalhadas do agente aprovado para esta conta.';

  @override
  String get clientAgentDetailLoadErrorTitle =>
      'Não foi possível carregar o agente';

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
  String get clientAgentDetailSectionNotes => 'Anotações';

  @override
  String get clientAgentDetailSectionRecord => 'Registro';

  @override
  String get clientAgentDetailSectionServerToken => 'Client token';

  @override
  String get clientAgentDetailSectionServerTokenSubtitle =>
      'Salvo no servidor Colmeia e encaminhado ao agente como `params.client_token` quando este cliente executa SQL via bridge. O token também fica em cache neste dispositivo para dashboards seguirem funcionando brevemente sem conexão.';

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
      'Status do token não carregado — atualize a tela com acesso a internet para confirmar.';

  @override
  String get clientAgentDetailRefreshFromAgent => 'Recarregar do agente';

  @override
  String get clientAgentDetailRefreshFromAgentSuccess =>
      'Perfil recarregado direto do agente.';

  @override
  String get clientAgentDetailRefreshFromAgentUnsupported =>
      'Este agente não implementa agent.getProfile via RPC.';

  @override
  String clientAgentDetailRetryAfterCountdown(int seconds) {
    return 'O servidor pediu para aguardar. Tente novamente em ${seconds}s.';
  }

  @override
  String get clientAgentDetailSectionPolicy => 'Permissoes deste token';

  @override
  String get clientAgentDetailSectionPolicySubtitle =>
      'Resolvidas pelo agente para o token atualmente salvo no servidor. Se a política mudar após revogação ou alteração de escopo, recarregue a tela.';

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
      'Este token está marcado como revogado pelo agente.';

  @override
  String get clientAgentDetailPolicyRevokedSaveNewToken => 'Salvar novo token';

  @override
  String get clientAgentDetailPolicyUnsupported =>
      'Este agente não expõe introspecção da política do token.';

  @override
  String get clientAgentDetailPolicyEmpty =>
      'O agente não retornou nenhuma regra para este token.';

  @override
  String get clientAgentDetailSectionEditProfile => 'Perfil no catálogo';

  @override
  String get clientAgentDetailSaveProfile => 'Salvar perfil';

  @override
  String clientAgentDetailCopyFieldTooltip(String label) {
    return 'Copiar $label para a area de transferencia';
  }

  @override
  String get clientAgentDetailCopiedSnackbar =>
      'Copiado para a area de transferencia';

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
  String get clientAgentFieldConnection => 'Conexão';

  @override
  String get clientAgentFieldNotes => 'Notas';

  @override
  String get clientAgentFieldObservation => 'Observação';

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
  String get clientAgentsFilterConnectionLabel => 'Conexão';

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
    return 'Conexão: $label';
  }

  @override
  String clientAgentsFilterSummaryCatalog(String label) {
    return 'Catalogo: $label';
  }

  @override
  String get clientAgentsEmptyFilteredApproved =>
      'Nenhum agente corresponde aos filtros selecionados.';

  @override
  String get clientAgentsRequestsFilterSheetTitle => 'Filtros de solicitações';

  @override
  String get clientAgentsRequestsFilterSearchLabel => 'Buscar';

  @override
  String get clientAgentsRequestsFilterSearchHint =>
      'Nome do agente ou agent ID';

  @override
  String get clientAgentsRequestsFilterStatusLabel => 'Status da solicitação';

  @override
  String get clientAgentsRequestsFilterPendingLabel => 'Envio pendente';

  @override
  String clientAgentsRequestsFilterSummaryRequest(String label) {
    return 'Solicitação: $label';
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
      'Nenhuma solicitação corresponde aos filtros selecionados.';

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
      'Ajuste a consulta e aplique somente os recortes que fazem sentido para esta análise.';

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
  String get reportInlineFiltersSelectPeriod => 'Selecionar período';

  @override
  String get reportInlineFiltersSelectDate => 'Selecionar data';

  @override
  String get reportFiltersAppliedSectionTitle => 'Filtros aplicados';

  @override
  String get clientAgentsErrorLoadCatalog =>
      'Não foi possível carregar o catalogo de agentes.';

  @override
  String get clientAgentsErrorLoadCatalogAgent =>
      'Não foi possível carregar este agente do catalogo.';

  @override
  String get clientAgentsErrorLoadClientAccessStatus =>
      'Não foi possível ler o status da solicitação de acesso.';

  @override
  String get clientAgentsErrorLoadApproved =>
      'Não foi possível carregar os agentes aprovados para esta conta.';

  @override
  String get clientAgentsErrorLoadAgentDetail =>
      'Não foi possível carregar os dados do agente.';

  @override
  String get clientAgentsErrorProbeApproved =>
      'Não foi possível verificar se o agente já está ligado a esta conta.';

  @override
  String get clientAgentsErrorLoadAccessRequests =>
      'Não foi possível carregar o histórico de solicitações.';

  @override
  String get clientAgentsErrorRetryClientAccessRequest =>
      'Não foi possível reenviar esta solicitação de acesso.';

  @override
  String get clientAgentsErrorReadPending =>
      'Não foi possível carregar as ações pendentes de sincronização.';

  @override
  String get clientAgentsErrorQueueRequest =>
      'Não foi possível registrar a solicitação para sincronização.';

  @override
  String get clientAgentsErrorQueueRemove =>
      'Não foi possível registrar a remoção para sincronização.';

  @override
  String get clientAgentsErrorSyncAction =>
      'Não foi possível sincronizar a alteração do agente.';

  @override
  String get clientAgentsErrorSyncPending =>
      'Não foi possível sincronizar as ações pendentes de agentes.';

  @override
  String get clientAgentsErrorLoadManagedAgents =>
      'Não foi possível carregar os agentes administrados.';

  @override
  String get clientAgentsErrorLoadOwnerAccessRequests =>
      'Não foi possível carregar as solicitações de acesso para revisão.';

  @override
  String get clientAgentsErrorApproveOwnerAccessRequest =>
      'Não foi possível aprovar esta solicitação de acesso.';

  @override
  String get clientAgentsErrorRejectOwnerAccessRequest =>
      'Não foi possível rejeitar esta solicitação de acesso.';

  @override
  String get clientAgentsErrorLoadOwnerApprovedClients =>
      'Não foi possível carregar os clientes aprovados deste agente.';

  @override
  String get clientAgentsErrorRevokeOwnerClientAccess =>
      'Não foi possível revogar este acesso de cliente.';

  @override
  String get clientAgentsErrorGetClientAgentToken =>
      'Não foi possível ler o token do agente no servidor.';

  @override
  String get clientAgentsErrorSaveClientAgentToken =>
      'Não foi possível salvar o token do agente no servidor.';

  @override
  String get clientAgentsErrorRemoveClientAgentToken =>
      'Não foi possível remover o token do agente no servidor.';

  @override
  String get clientAgentsErrorAgentDocumentConflict =>
      'Este CPF/CNPJ ja está vinculado a outro agente no catalogo. Para alterar o vinculo, entre em contato com o suporte.';

  @override
  String get clientAgentsErrorAgentProfileCasMismatch =>
      'Outro dispositivo atualizou este agente. Recarregue a tela e reaplique suas alterações.';

  @override
  String get agentSqlErrorAuthenticationFailed =>
      'A autenticação para consultar este agente e inválida ou expirou.';

  @override
  String get agentSqlErrorPermissionDenied =>
      'Você não tem permissão para consultar estes dados neste agente.';

  @override
  String get agentSqlErrorTransportTimeout =>
      'O agente demorou mais do que o esperado para responder. Tente novamente.';

  @override
  String get agentSqlErrorNetworkError =>
      'Não foi possível alcancar o agente agora. Tente novamente.';

  @override
  String get agentSqlErrorRateLimited =>
      'Muitas tentativas de consulta foram feitas. Aguarde um instante e tente novamente.';

  @override
  String get agentSqlErrorExecutionFailed =>
      'Não foi possível executar a consulta.';

  @override
  String get agentSqlErrorTransactionFailed =>
      'Não foi possível concluir a transação da consulta.';

  @override
  String get agentSqlErrorConnectionPoolExhausted =>
      'O servidor esta ocupado para processar a consulta agora. Tente novamente em instantes.';

  @override
  String get agentSqlErrorResultTooLarge =>
      'A consulta retornou dados demais. Refine os filtros e tente novamente.';

  @override
  String get agentSqlErrorDatabaseConnectionFailed =>
      'Não foi possível conectar ao banco para executar a consulta.';

  @override
  String get agentSqlErrorQueryTimeout =>
      'A consulta demorou mais do que o esperado.';

  @override
  String get agentSqlErrorInvalidDatabaseConfig =>
      'A configuração de acesso ao banco deste agente esta inválida.';

  @override
  String get agentSqlErrorExecutionNotFound =>
      'A execução solicitada não foi encontrada.';

  @override
  String get agentSqlErrorExecutionCancelled => 'A consulta foi cancelada.';

  @override
  String get agentSqlErrorGeneric =>
      'Não foi possível concluir a consulta no agente.';

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
      'Mesmos wrappers dos relatorios: dropdown, multi-select e os mesmos date pickers da seção Form acima (FormBuilderField + AppFormBuilderDate*).';

  @override
  String formsDemoFormValidSnackbar(String refLabel, String rangeLabel) {
    return 'Formulário válido (demo fake). Ref: $refLabel. Período: $rangeLabel.';
  }

  @override
  String formsDemoFormBuilderValidSnackbar(
    String dateLabel,
    String rangeLabel,
  ) {
    return 'FormBuilder válido (demo fake). Data: $dateLabel. Período: $rangeLabel.';
  }

  @override
  String get datePickerPlaceholderSelectDate => 'Selecione uma data';

  @override
  String get dateRangePickerPlaceholderSelectPeriod => 'Selecione o período';

  @override
  String get datePickerSheetDefaultTitle => 'Selecionar data';

  @override
  String get dateRangePickerSheetDefaultTitle => 'Selecionar período';

  @override
  String get datePickerClearSelectionTooltip => 'Limpar seleção';

  @override
  String get datePickerSheetRemoveDate => 'Remover data';

  @override
  String get dateRangePickerSheetRemovePeriod => 'Remover período';

  @override
  String get datePickerSheetCloseTooltip => 'Fechar';

  @override
  String get datePickerSheetApply => 'Aplicar';

  @override
  String get datePickerSemanticsFallbackLabel => 'Data';

  @override
  String get dateRangePickerSemanticsFallbackLabel => 'Período';

  @override
  String get overviewLucratividadeTitle => 'Lucratividade por filial';

  @override
  String get overviewLucratividadeSubtitle =>
      'Receita, custo e margem no período selecionado (todas as filiais no escopo somadas).';

  @override
  String get overviewLucratividadeSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeSwitchMargin => 'Percentuais';

  @override
  String get overviewLucratividadePercentMetricCostShort => 'Custo %';

  @override
  String get overviewLucratividadePercentMetricGrossShort => 'Margem bruta';

  @override
  String get overviewLucratividadePercentMetricMarkupShort => 'Markup';

  @override
  String get overviewLucratividadePercentSeriesCostLabel =>
      'Percentual de custo';

  @override
  String get overviewLucratividadePercentSeriesGrossLabel =>
      'Margem de lucro bruto';

  @override
  String get overviewLucratividadePercentSeriesMarkupLabel =>
      'Markup sobre custo';

  @override
  String get overviewLucratividadePercentHelpCostBody =>
      'Custo / Venda × 100. Mostra qual parcela da receita corresponde ao custo de reposição.';

  @override
  String get overviewLucratividadePercentHelpGrossBody =>
      'Lucro / Venda × 100. Mostra qual parcela da receita permanece como lucro bruto.';

  @override
  String get overviewLucratividadePercentHelpMarkupBody =>
      'Lucro / Custo × 100. Mostra quanto o lucro representa em relação ao custo de reposição.';

  @override
  String get overviewLucratividadeMarkupNotApplicable => '—';

  @override
  String get overviewLucratividadePercentSemanticsCost =>
      'Percentual de custo sobre a venda.';

  @override
  String get overviewLucratividadePercentSemanticsGross =>
      'Margem de lucro bruto sobre a venda.';

  @override
  String get overviewLucratividadePercentSemanticsMarkup =>
      'Markup sobre o custo de reposição.';

  @override
  String get overviewLucratividadePercentIndicatorHeading =>
      'Indicador percentual';

  @override
  String get overviewLucratividadePercentIndicatorLabel => 'Indicador';

  @override
  String get overviewLucratividadePercentEmptyHelp =>
      'Sem dados para ilustrar este indicador.';

  @override
  String get overviewLucratividadeMarkupUndefinedTooltip =>
      'Markup não definido quando o custo de reposição é zero ou ausente.';

  @override
  String get overviewLucratividadePercentMetricCostTooltip =>
      'Parcela da receita correspondente ao custo de reposição (custo dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricGrossTooltip =>
      'Margem bruta sobre a venda (lucro dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricMarkupTooltip =>
      'Markup sobre o custo de reposição (lucro dividido pelo custo).';

  @override
  String get overviewLucratividadeMensalPercentChronologicalHint =>
      'Meses em ordem cronologica (sem ranking por valor).';

  @override
  String get overviewLucratividadeProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeCostSeriesLabel => 'Custo reposição';

  @override
  String get overviewLucratividadeMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLucratividadeEmpty =>
      'Sem dados de lucratividade para este período.';

  @override
  String get overviewLucratividadeMultiAgentHint =>
      'Nenhuma filial aprovada está disponível para carregar a lucratividade. Adicione ou conecte uma filial primeiro.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Carregando gráfico de lucratividade por filial…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Lucratividade mensal do produto';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Receita, custo de reposição e margem por mês (filial selecionada).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'Sem dados de lucratividade para este período.';

  @override
  String get overviewLucratividadeMensalMultiAgentHint =>
      'Selecione uma unica filial para visualizar a lucratividade mensal.';

  @override
  String get overviewLucratividadeMensalSwitchProfit => 'Lucro';

  @override
  String get overviewLucratividadeMensalSwitchRevenue => 'Receita';

  @override
  String get overviewLucratividadeMensalSwitchCost => 'Custo';

  @override
  String get overviewLucratividadeMensalSwitchMargin => 'Percentuais';

  @override
  String get overviewLucratividadeMensalProfitSeriesLabel => 'Lucro';

  @override
  String get overviewLucratividadeMensalRevenueSeriesLabel => 'Receita';

  @override
  String get overviewLucratividadeMensalCostSeriesLabel => 'Custo reposição';

  @override
  String get overviewLucratividadeMensalMarginSeriesLabel => 'Margem %';

  @override
  String get overviewLoadingLucratividadeMensalSemantics =>
      'Carregando gráfico de lucratividade mensal do produto…';

  @override
  String get salesHubTitle => 'Vendas';

  @override
  String get salesHubSubtitle =>
      'Acesse e gerencie informações comerciais por categoria.';

  @override
  String get shellNavSalesMonitoringLabel => 'Acompanhar vendas';

  @override
  String get shellNavSalesMonitoringSubtitle =>
      'Mapa e atualização por filtros';

  @override
  String get salesLiveMapTitle => 'Acompanhar vendas';

  @override
  String get salesLiveMapSubtitle =>
      'Mapa do Brasil com vendas por filial e atualização por filtros.';

  @override
  String get salesLiveMapSessionExpiredMessage =>
      'Sessao expirada. Entre novamente para consultar.';

  @override
  String get salesLiveMapAgentsLabel => 'Filiais';

  @override
  String get salesLiveMapPeriodLabel => 'Período';

  @override
  String get salesLiveMapMapLabel => 'Mapa';

  @override
  String get salesLiveMapParametersLabel => 'Parametros';

  @override
  String salesLiveMapParametersSummary(
    String origin,
    String finance,
    String preSale,
  ) {
    return '$origin | Financeiro $finance | Pre-venda $preSale';
  }

  @override
  String get salesLiveMapAgentsLoadingSummary => 'Carregando filiais';

  @override
  String get salesLiveMapAgentsNoneSummary => 'Sem filiais';

  @override
  String salesLiveMapAgentsAllWithTokenSummary(int count) {
    return 'Todas ($count)';
  }

  @override
  String salesLiveMapAgentsSelectedSummary(int count) {
    return '$count filial(is)';
  }

  @override
  String get salesLiveMapPeriodToday => 'Hoje';

  @override
  String get salesLiveMapPeriodLastSevenDays => 'Últimos 7 dias';

  @override
  String get salesLiveMapPeriodLastSevenDaysShort => '7 dias';

  @override
  String get salesLiveMapPeriodCurrentMonth => 'Mes atual';

  @override
  String get salesLiveMapPeriodCurrentMonthShort => 'Mes';

  @override
  String get salesLiveMapPeriodCustom => 'Personalizado';

  @override
  String get salesLiveMapMapPresetPoints => 'Pontos';

  @override
  String get salesLiveMapMapPresetBubbles => 'Bolhas';

  @override
  String get salesLiveMapMapPresetMunicipalities => 'Municípios';

  @override
  String get salesLiveMapMapPresetMunicipalitiesShort => 'Municípios';

  @override
  String get salesLiveMapMapPresetStateBubbles => 'Bolhas por UF';

  @override
  String get salesLiveMapMapPresetStateBubblesShort => 'UFs';

  @override
  String get salesLiveMapMapPresetStoreIcon => 'Icone loja';

  @override
  String get salesLiveMapMapPresetStoreIconShort => 'Loja';

  @override
  String get salesLiveMapLoadErrorTitle =>
      'Não foi possível carregar o acompanhamento';

  @override
  String get salesLiveMapLoadErrorRetryMessage =>
      'Tente atualizar a consulta novamente.';

  @override
  String get salesLiveMapMissingClientTokenSetupMessage =>
      'Nenhum agente selecionado possui token local para executar a consulta.';

  @override
  String get salesLiveMapEmptyNoSalesTitle => 'Sem vendas no período';

  @override
  String get salesLiveMapEmptyNoSalesMessage =>
      'A consulta foi executada, mas não encontrou vendas para os filtros atuais.';

  @override
  String get salesLiveMapEmptySelectionTitle => 'Seleção sem resultado';

  @override
  String get salesLiveMapEmptySelectionMessage =>
      'As filiais selecionadas não retornaram vendas neste período. Limpe a seleção para recarregar todas as filiais disponíveis.';

  @override
  String get salesLiveMapChartTitle => 'Vendas por filial no Brasil';

  @override
  String salesLiveMapChartSubtitlePending(String period) {
    return 'Período $period.';
  }

  @override
  String salesLiveMapChartSubtitleLoaded(
    String period,
    int mappedCount,
    int totalCount,
  ) {
    return 'Período $period. $mappedCount de $totalCount filiais posicionadas.';
  }

  @override
  String get salesLiveMapPartialTitle => 'Acompanhamento parcial';

  @override
  String salesLiveMapAgentQuerySummary(
    int plannedCount,
    int queriedCount,
    int salesCount,
    int noSalesCount,
  ) {
    return 'Filiais: $plannedCount planejada(s) | $queriedCount consultada(s) | $salesCount com vendas | $noSalesCount sem vendas';
  }

  @override
  String salesLiveMapPartialFailedAgents(int count) {
    return '$count filial(is) falharam na ultima consulta.';
  }

  @override
  String salesLiveMapPartialMissingTokenAgents(int count) {
    return '$count filial(is) sem client_token local.';
  }

  @override
  String salesLiveMapPartialOfflineAgents(int count) {
    return '$count filial(is) fora da presenca do hub.';
  }

  @override
  String salesLiveMapPartialRowCapReached(int count) {
    return '$count agente(s) atingiram o limite de linhas da consulta; o mapa pode estar incompleto.';
  }

  @override
  String salesLiveMapPartialMissingCoordinates(int count) {
    return '$count filial(is) sem coordenada resolvida.';
  }

  @override
  String salesLiveMapPartialNoSalesAgents(int count) {
    return '$count filial(is) sem vendas no período.';
  }

  @override
  String salesLiveMapPartialZeroedBranches(int count) {
    return '$count filial(is) exibidas com venda zerada.';
  }

  @override
  String salesLiveMapPartialUnavailableSalesBranches(int count) {
    return '$count filial(is) exibidas com venda indisponível por falha na consulta.';
  }

  @override
  String get salesLiveMapNoSalesAgentsTitle => 'Filiais sem vendas';

  @override
  String get salesLiveMapTechnicalDiagnosticsTitle => 'Diagnostico tecnico';

  @override
  String get salesLiveMapTechnicalDiagnosticsFilters => 'Filtros ativos';

  @override
  String get salesLiveMapTechnicalDiagnosticsQuery => 'Diagnostico da consulta';

  @override
  String get salesLiveMapFiltersTitle => 'Filtros de acompanhamento';

  @override
  String get salesLiveMapFiltersDescription =>
      'Escolha filiais, período e tipo visual do mapa.';

  @override
  String get salesLiveMapBranchesSectionTitle => 'Filiais';

  @override
  String get salesLiveMapBranchesSectionSubtitle =>
      'A lista aparece depois da primeira atualização do mapa.';

  @override
  String get salesLiveMapSelectAtLeastOneTokenBranch =>
      'Selecione ao menos uma filial com token local.';

  @override
  String get salesLiveMapNoApprovedAgents =>
      'Nenhuma filial aprovada disponível para consulta.';

  @override
  String get salesLiveMapBranchesLoadBeforeSelection =>
      'Atualize o mapa uma vez para listar as filiais disponíveis.';

  @override
  String get salesLiveMapSelectAllTokenBacked => 'Selecionar todas';

  @override
  String get salesLiveMapClearSelection => 'Desmarcar todas';

  @override
  String get salesLiveMapClearBranchSelectionAction =>
      'Limpar seleção de filiais';

  @override
  String get salesLiveMapClearSavedFiltersAction => 'Limpar filtros salvos';

  @override
  String get salesLiveMapMissingLocalToken => 'Sem token local';

  @override
  String get salesLiveMapCustomPeriodLabel => 'Período personalizado';

  @override
  String salesLiveMapCustomPeriodHelper(int maxDays) {
    return 'Limite de $maxDays dias por atualização.';
  }

  @override
  String get salesLiveMapCustomPeriodPickerTitle => 'Selecionar período';

  @override
  String get salesLiveMapMapTypeTitle => 'Tipo de mapa';

  @override
  String get salesLiveMapMapTypeSubtitle =>
      'Escolha como os pontos e totais devem aparecer.';

  @override
  String get salesLiveMapDetailLabel => 'Detalhamento';

  @override
  String get salesLiveMapDetailSubtitle =>
      'Escolha o nivel de agregação mostrado no mapa.';

  @override
  String get salesLiveMapDetailBranches => 'Filiais';

  @override
  String get salesLiveMapDetailMunicipalities => 'Municípios';

  @override
  String get salesLiveMapDetailStates => 'UFs';

  @override
  String get salesLiveMapVisualLabel => 'Visual';

  @override
  String get salesLiveMapVisualSubtitle =>
      'Escolha o estilo dos marcadores para filiais e municípios.';

  @override
  String get salesLiveMapVisualDot => 'Pontos';

  @override
  String get salesLiveMapVisualBubble => 'Bolhas';

  @override
  String get salesLiveMapVisualStoreIcon => 'Icone loja';

  @override
  String salesLiveMapDetailAutoMunicipalities(int threshold) {
    return 'Acima de $threshold filiais, municípios sao exibidos automáticamente para melhorar a leitura.';
  }

  @override
  String get salesLiveMapKpiRevenue => 'Receita total';

  @override
  String get salesLiveMapKpiSales => 'Vendas';

  @override
  String get salesLiveMapKpiBranchesOnMap => 'Filiais no mapa';

  @override
  String salesLiveMapKpiBranchesOnMapTooltip(
    int providedCount,
    int ibgeCount,
    int cepCount,
    int cityUfCount,
    int capitalUfCount,
    int stateUfCount,
    int missingCount,
  ) {
    return 'Geo: $providedCount informada | $ibgeCount IBGE | $cepCount CEP | $cityUfCount cidade/UF | $capitalUfCount capital/UF | $stateUfCount UF | $missingCount sem coordenada';
  }

  @override
  String get salesLiveMapKpiMunicipalitiesOnMap => 'Municípios no mapa';

  @override
  String get salesLiveMapKpiQueriedAgents => 'Filiais consultadas';

  @override
  String get salesBranchFilterLabel => 'FILIAIS';

  @override
  String get salesBranchFilterEmptyHint =>
      'Carregue o relatorio para listar as filiais.';

  @override
  String get salesBranchFilterSheetTitle => 'Selecionar filiais';

  @override
  String get salesBranchFilterSheetSearchHint => 'Buscar filiais…';

  @override
  String get salesBranchFilterNoSearchResults =>
      'Nenhuma filial corresponde à busca.';

  @override
  String get salesBranchFilterMissingClientTokenBanner =>
      'Filiais sem token de cliente neste dispositivo não executam consultas SQL. “Online” indica apenas ligação ao hub.';

  @override
  String get salesBranchPickerEmpty => 'Selecione uma filial';

  @override
  String get salesBranchRequiredTitle => 'Seleção de filial obrigatoria';

  @override
  String get salesBranchRequiredMessage =>
      'Selecione uma filial para visualizar essas informações.';

  @override
  String get salesAgentPickerLabel => 'Filial';

  @override
  String get salesAgentPickerEmpty => 'Selecione uma filial';

  @override
  String get salesAgentPickerSheetTitle => 'Selecione uma filial';

  @override
  String get salesAgentRequiredTitle => 'Seleção de filial obrigatoria';

  @override
  String get salesAgentRequiredMessage =>
      'Selecione uma filial para visualizar essas informações.';

  @override
  String get salesCardOpenAccountsTitle => 'Contas em Aberto';

  @override
  String get salesCardPaidAccountsTitle => 'Contas Pagas';

  @override
  String get salesCardPaymentHistoryTitle => 'Histórico de Pagamentos';

  @override
  String get salesCardNewPaymentTitle => 'Novo Pagamento';

  @override
  String get salesCardProdutoRankLucroTitle => 'Ranking de produtos';

  @override
  String get salesCardMonthlyPnlTitle => 'Resultado mensal';

  @override
  String get salesCardResumoTotalDiarioVendasTitle => 'Vendas diárias';

  @override
  String get salesAutoRefreshOff => 'Desligado';

  @override
  String get salesAutoRefreshTooltip => 'Atualização automática';

  @override
  String get salesAutoRefreshNow => 'Atualizar agora';

  @override
  String salesAutoRefreshLastUpdatedAt(String time) {
    return 'Atualizado $time';
  }

  @override
  String salesAutoRefreshNextIn(String time) {
    return 'Próximo em $time';
  }

  @override
  String salesAutoRefreshRetryIn(String time) {
    return 'Nova tentativa em $time';
  }

  @override
  String get salesAutoRefreshPaused => 'Atualização automática pausada';

  @override
  String get salesAutoRefreshPausedLoading =>
      'Atualização automática pausada durante a carga';

  @override
  String get salesAutoRefreshPausedMissingLocalToken =>
      'Atualização automática pausada: token local necessário';

  @override
  String get salesAutoRefreshPausedNoEligibleSelection =>
      'Atualização automática pausada: selecione uma filial válida';

  @override
  String get salesAutoRefreshPausedUnsupportedViewport =>
      'Atualização automática disponível no desktop';

  @override
  String get salesAutoRefreshPausedHidden =>
      'Atualização automática pausada enquanto a tela estiver oculta';

  @override
  String get salesDailyTotalsChartTitle => 'Vendas por dia';

  @override
  String get salesDailyTotalsChartTitleAmount => 'Faturamento diário';

  @override
  String get salesDailyTotalsChartSubtitle =>
      'Totais por dia civil na filial e no mês de referência selecionados.';

  @override
  String get salesDailyTotalsChartEmpty =>
      'Sem dados de vendas diárias para esta filial e mês.';

  @override
  String get salesDailyTotalsChartLoadFailed =>
      'Não foi possível carregar as vendas diárias desta filial. Tente novamente mais tarde.';

  @override
  String get salesDailyTotalsChartSemanticsCount =>
      'Gráfico de quantidade de vendas e faturamento diários da filial selecionada';

  @override
  String get salesDailyTotalsChartSemanticsAmount =>
      'Gráfico de faturamento diário e quantidade de vendas da filial selecionada';

  @override
  String get salesDailyTotalsChartScopeHint =>
      'Uma filial; os totais seguem o filtro de mês de referência.';

  @override
  String salesDailyTotalsChartTooltip(
    String date,
    String salesCount,
    String salesAmount,
  ) {
    return '$date: $salesCount vendas - $salesAmount';
  }

  @override
  String get salesDailyTotalsMetricSalesCountLabel => 'Vendas';

  @override
  String get salesDailyTotalsMetricSalesAmountLabel => 'Faturamento';

  @override
  String salesDailyTotalsChartSubtitleCustomRange(
    String startDate,
    String endDate,
  ) {
    return 'Totais por dia civil na filial, de $startDate a $endDate.';
  }

  @override
  String get salesDailyTotalsChartScopeHintCustomRange =>
      'Uma filial; os totais diários seguem o intervalo selecionado. Os gráficos mensais continuam usando o mês de referência.';

  @override
  String get salesDailyTotalsFilterSummaryLabel => 'Totais diários';

  @override
  String salesDailyTotalsFilterSummaryCustomRangeValue(
    String startDate,
    String endDate,
  ) {
    return '$startDate – $endDate';
  }

  @override
  String get salesDailyTotalsFilterDailyPeriodSectionTitle =>
      'Período dos totais diários';

  @override
  String get salesDailyTotalsFilterDailyPeriodSameMonthLabel =>
      'Mesmo mês de referência';

  @override
  String get salesDailyTotalsFilterDailyPeriodCustomRangeLabel =>
      'Intervalo customizado';

  @override
  String get salesDailyTotalsFilterDailyPeriodPickerLabel =>
      'Intervalo de datas de venda';

  @override
  String get salesDailyTotalsFilterDailyPeriodPickerTitle =>
      'Selecionar período';

  @override
  String salesDailyTotalsFilterDailyPeriodHelper(int maxDays) {
    return 'No máximo $maxDays dias corridos.';
  }

  @override
  String get salesDailyTotalsFilterMonthlyChartsAnchorHint =>
      'Os gráficos de resultado mensal usam sempre o mês de referência acima; só os totais diários usam o intervalo abaixo.';

  @override
  String get salesDailyTotalsFilterCustomRangeAnchorIndependenceBanner =>
      'Alterar o mês de referência atualiza só os gráficos mensais. Os totais diários seguem as datas de venda abaixo até você ajustar o intervalo ou voltar ao modo mesmo mês.';

  @override
  String salesDailyTotalsFilterRangeTooLongSnackbar(int maxDays) {
    return 'Escolha um período de no máximo $maxDays dias.';
  }

  @override
  String salesMonthlyPnlFullscreenDailyTotalsPeriodSuffix(
    String startDate,
    String endDate,
  ) {
    return 'Totais diários: $startDate–$endDate.';
  }

  @override
  String get salesMonthlyPnlPageSubtitle =>
      'Venda, lucro e custo da mercadoria por mês na filial selecionada. A janela termina no mes de referência.';

  @override
  String get salesMonthlyPnlFilterAnchorMonth => 'Mes de referência';

  @override
  String get salesMonthlyPnlChartTitle => 'Resultado mensal';

  @override
  String get salesMonthlyPnlChartSubtitle =>
      'Venda, lucro e custo da mercadoria por mês (filial selecionada).';

  @override
  String get salesMonthlyPnlSeriesSalesLabel => 'Vendas';

  @override
  String get salesMonthlyPnlSeriesProfitLabel => 'Lucro';

  @override
  String get salesMonthlyPnlSeriesCostLabel => 'Custo da mercadoria';

  @override
  String get salesMonthlyPnlEmpty => 'Sem dados mensais para este período.';

  @override
  String get salesMonthlyPnlLoadFailed =>
      'Não foi possível carregar o gráfico mensal. Tente novamente mais tarde.';

  @override
  String get salesMonthlyPnlChartSemantics =>
      'Gráfico do resultado mensal com venda, lucro e custo da mercadoria na filial selecionada';

  @override
  String get salesMonthlyPnlBarChartTitle => 'Comparativo mensal (barras)';

  @override
  String get salesMonthlyPnlBarChartSubtitle =>
      'As barras usam os mesmos totais mensais que o gráfico de linhas acima (venda, lucro e custo da mercadoria agregados — não médias por item). Os percentuais sao calculados a partir desses totais mensais.';

  @override
  String get salesMonthlyPnlBarDisplayValuesLabel => 'Valores';

  @override
  String get salesMonthlyPnlBarDisplayPercentLabel => 'Percentuais';

  @override
  String get salesMonthlyPnlBarDisplayValuesCompactLabel => 'Val.';

  @override
  String get salesMonthlyPnlBarDisplayPercentCompactLabel => '%';

  @override
  String salesMonthlyPnlFullscreenFilterSummary(
    String agentsLabel,
    String agentName,
    String anchorLabel,
    String anchorValue,
  ) {
    return '$agentsLabel: $agentName. $anchorLabel: $anchorValue.';
  }

  @override
  String get salesMonthlyPnlBarZerosOnlyMessage =>
      'Nada para plotar nesta vista na janela selecionada (todos os valores sao zero).';

  @override
  String get salesMonthlyPnlBarChartSemantics =>
      'Gráfico de barras agrupadas mensais de venda, lucro e custo da mercadoria';

  @override
  String salesMonthlyPnlBarSummarySemantics(
    String totalSales,
    String totalProfit,
    String totalCost,
    String topMonth,
    String topSales,
  ) {
    return 'Totais do período: $totalSales em vendas, $totalProfit de lucro, $totalCost de custo da mercadoria. Mes com maior venda: $topMonth ($topSales).';
  }

  @override
  String get salesProdutoRankLucroChartTitle => 'Top produtos';

  @override
  String get salesProdutoRankLucroFilterPeriod => 'Período';

  @override
  String get salesProdutoRankLucroFilterSortBy => 'Metrica';

  @override
  String get salesProdutoRankLucroSortQuantity => 'Quantidade vendida';

  @override
  String get salesProdutoRankLucroSortProfit => 'Lucro total';

  @override
  String get agentStatusPending => 'Pendente';

  @override
  String get agentStatusRejected => 'Rejeitado';

  @override
  String get agentStatusUnknown => 'Desconhecido';

  @override
  String get reportFiltersApplyButton => 'Aplicar';

  @override
  String get brazilStoreSalesMapCountryLabel => 'Brasil';

  @override
  String get brazilStoreSalesMapRegionNorth => 'Norte';

  @override
  String get brazilStoreSalesMapRegionNortheast => 'Nordeste';

  @override
  String get brazilStoreSalesMapRegionCenterWest => 'Centro-Oeste';

  @override
  String get brazilStoreSalesMapRegionSoutheast => 'Sudeste';

  @override
  String get brazilStoreSalesMapRegionSouth => 'Sul';

  @override
  String get brazilStoreSalesMapEmptyState => 'Sem lojas para exibir no mapa.';

  @override
  String get brazilStoreSalesMapPresetStandardLabel => 'Pontos';

  @override
  String get brazilStoreSalesMapPresetBubbleLabel => 'Bolhas';

  @override
  String get brazilStoreSalesMapPresetMunicipalityBubblesLabel => 'Municípios';

  @override
  String get brazilStoreSalesMapPresetStateBubblesLabel => 'Bolhas por UF';

  @override
  String get brazilStoreSalesMapPresetStoreIconLabel => 'Ícone loja';

  @override
  String get brazilStoreSalesMapPresetStandardTooltip =>
      'Exibe cada loja como ponto individual no mapa.';

  @override
  String get brazilStoreSalesMapPresetBubbleTooltip =>
      'Exibe lojas como bolhas proporcionais à métrica ativa.';

  @override
  String get brazilStoreSalesMapPresetMunicipalityBubblesTooltip =>
      'Agrupa lojas por município e exibe bolhas proporcionais à métrica ativa.';

  @override
  String get brazilStoreSalesMapPresetStateBubblesTooltip =>
      'Agrupa as lojas em bolhas posicionadas no centroide de cada UF.';

  @override
  String get brazilStoreSalesMapPresetStoreIconTooltip =>
      'Exibe cada loja com ícone operacional de unidade.';
}
