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
      'Filiais que nao retornaram dados';

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
      'Este resumo agrega dados de varias filiais aprovadas. Se houver sobreposicao entre bases, os totais podem ficar acima de uma unica fonte.';

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
  String get dashboardHomeFiltersAgentsLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visao geral para listar as filiais.';

  @override
  String get dashboardHomeFiltersBranchesLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersBranchesEmptyHint =>
      'Carregue a visao geral para listar as filiais.';

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
      'Faturamento total por filial no periodo.';

  @override
  String get dashboardUserRankingTitle => 'Ranking por operador';

  @override
  String get dashboardUserRankingSubtitle =>
      'Faturamento por operador no periodo.';

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
  String get chartFullscreenDataSnapshotHint =>
      'Os valores do mapa refletem os dados carregados ao abrir a tela cheia.';

  @override
  String get brazilStoreSalesMapMetricGroupLabel => 'Metrica';

  @override
  String get brazilStoreSalesMapRegionGroupLabel => 'Regiao';

  @override
  String get brazilStoreSalesMapLoadingMessage => 'Carregando mapa do Brasil…';

  @override
  String get brazilStoreSalesMapMarkerSizeLegend => 'Tamanho do ponto';

  @override
  String get brazilStoreSalesMapLegendRevenuePerState => 'Receita por UF';

  @override
  String get brazilStoreSalesMapLegendSalesPerState => 'Vendas por UF';

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
      'Nenhuma filial aprovada esta disponivel para carregar a visao geral.';

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
  String get overviewLucratividadeTitle => 'Lucratividade por filial';

  @override
  String get overviewLucratividadeSubtitle =>
      'Receita, custo e margem no periodo selecionado (todas as filiais no escopo somadas).';

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
      'Custo / Venda × 100. Mostra qual parcela da receita corresponde ao custo de reposicao.';

  @override
  String get overviewLucratividadePercentHelpGrossBody =>
      'Lucro / Venda × 100. Mostra qual parcela da receita permanece como lucro bruto.';

  @override
  String get overviewLucratividadePercentHelpMarkupBody =>
      'Lucro / Custo × 100. Mostra quanto o lucro representa em relacao ao custo de reposicao.';

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
      'Markup sobre o custo de reposicao.';

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
      'Markup nao definido quando o custo de reposicao e zero ou ausente.';

  @override
  String get overviewLucratividadePercentMetricCostTooltip =>
      'Parcela da receita correspondente ao custo de reposicao (custo dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricGrossTooltip =>
      'Margem bruta sobre a venda (lucro dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricMarkupTooltip =>
      'Markup sobre o custo de reposicao (lucro dividido pelo custo).';

  @override
  String get overviewLucratividadeMensalPercentChronologicalHint =>
      'Meses em ordem cronologica (sem ranking por valor).';

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
      'Nenhuma filial aprovada esta disponivel para carregar a lucratividade. Adicione ou conecte uma filial primeiro.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Carregando grafico de lucratividade por filial…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Lucratividade mensal do produto';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Receita, custo de reposicao e margem por mes (filial selecionada).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'Sem dados de lucratividade para este periodo.';

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
      'Acesse e gerencie informações comerciais por categoria.';

  @override
  String get shellNavSalesMonitoringLabel => 'Acompanhar vendas';

  @override
  String get shellNavSalesMonitoringSubtitle =>
      'Mapa e atualizacao por filtros';

  @override
  String get salesLiveMapTitle => 'Acompanhar vendas';

  @override
  String get salesLiveMapSubtitle =>
      'Mapa do Brasil com vendas por filial e atualizacao por filtros.';

  @override
  String get salesLiveMapSessionExpiredMessage =>
      'Sessao expirada. Entre novamente para consultar.';

  @override
  String get salesLiveMapAgentsLabel => 'Filiais';

  @override
  String get salesLiveMapPeriodLabel => 'Periodo';

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
  String get salesLiveMapPeriodLastSevenDays => 'Ultimos 7 dias';

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
  String get salesLiveMapMapPresetMunicipalities => 'Municipios';

  @override
  String get salesLiveMapMapPresetMunicipalitiesShort => 'Municipios';

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
      'Nao foi possivel carregar o acompanhamento';

  @override
  String get salesLiveMapLoadErrorRetryMessage =>
      'Tente atualizar a consulta novamente.';

  @override
  String get salesLiveMapMissingClientTokenSetupMessage =>
      'Nenhum agente selecionado possui token local para executar a consulta.';

  @override
  String get salesLiveMapChartTitle => 'Vendas por filial no Brasil';

  @override
  String salesLiveMapChartSubtitlePending(String period) {
    return 'Periodo $period.';
  }

  @override
  String salesLiveMapChartSubtitleLoaded(
    String period,
    int mappedCount,
    int totalCount,
  ) {
    return 'Periodo $period. $mappedCount de $totalCount filiais posicionadas.';
  }

  @override
  String get salesLiveMapPartialTitle => 'Acompanhamento parcial';

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
  String get salesLiveMapFiltersTitle => 'Filtros de acompanhamento';

  @override
  String get salesLiveMapFiltersDescription =>
      'Escolha filiais, periodo e tipo visual do mapa.';

  @override
  String get salesLiveMapBranchesSectionTitle => 'Filiais';

  @override
  String get salesLiveMapBranchesSectionSubtitle =>
      'A lista aparece depois da primeira atualizacao do mapa.';

  @override
  String get salesLiveMapSelectAtLeastOneTokenBranch =>
      'Selecione ao menos uma filial com token local.';

  @override
  String get salesLiveMapNoApprovedAgents =>
      'Nenhuma filial aprovada disponivel para consulta.';

  @override
  String get salesLiveMapBranchesLoadBeforeSelection =>
      'Atualize o mapa uma vez para listar as filiais disponiveis.';

  @override
  String get salesLiveMapSelectAllTokenBacked => 'Selecionar todas';

  @override
  String get salesLiveMapClearSelection => 'Desmarcar todas';

  @override
  String get salesLiveMapMissingLocalToken => 'Sem token local';

  @override
  String get salesLiveMapCustomPeriodLabel => 'Periodo personalizado';

  @override
  String salesLiveMapCustomPeriodHelper(int maxDays) {
    return 'Limite de $maxDays dias por atualizacao.';
  }

  @override
  String get salesLiveMapCustomPeriodPickerTitle => 'Selecionar periodo';

  @override
  String get salesLiveMapMapTypeTitle => 'Tipo de mapa';

  @override
  String get salesLiveMapMapTypeSubtitle =>
      'Escolha como os pontos e totais devem aparecer.';

  @override
  String get salesLiveMapDetailLabel => 'Detalhamento';

  @override
  String get salesLiveMapDetailSubtitle =>
      'Escolha o nivel de agregacao mostrado no mapa.';

  @override
  String get salesLiveMapDetailBranches => 'Filiais';

  @override
  String get salesLiveMapDetailMunicipalities => 'Municipios';

  @override
  String get salesLiveMapDetailStates => 'UFs';

  @override
  String get salesLiveMapVisualLabel => 'Visual';

  @override
  String get salesLiveMapVisualSubtitle =>
      'Escolha o estilo dos marcadores para filiais e municipios.';

  @override
  String get salesLiveMapVisualDot => 'Pontos';

  @override
  String get salesLiveMapVisualBubble => 'Bolhas';

  @override
  String get salesLiveMapVisualStoreIcon => 'Icone loja';

  @override
  String salesLiveMapDetailAutoMunicipalities(int threshold) {
    return 'Acima de $threshold filiais, municipios sao exibidos automaticamente para melhorar a leitura.';
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
  String get salesLiveMapKpiMunicipalitiesOnMap => 'Municipios no mapa';

  @override
  String get salesLiveMapKpiQueriedAgents => 'Agentes consultados';

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
      'Filiais sem token de cliente neste dispositivo nao executam consultas SQL. “Online” indica apenas ligacao ao hub.';

  @override
  String get salesBranchPickerEmpty => 'Selecione uma filial';

  @override
  String get salesBranchRequiredTitle => 'Selecao de filial obrigatoria';

  @override
  String get salesBranchRequiredMessage =>
      'Selecione uma filial para visualizar essas informacoes.';

  @override
  String get salesAgentPickerLabel => 'Filial';

  @override
  String get salesAgentPickerEmpty => 'Selecione uma filial';

  @override
  String get salesAgentPickerSheetTitle => 'Selecione uma filial';

  @override
  String get salesAgentRequiredTitle => 'Selecao de filial obrigatoria';

  @override
  String get salesAgentRequiredMessage =>
      'Selecione uma filial para visualizar essas informacoes.';

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
  String get salesCardResumoTotalDiarioVendasTitle => 'Vendas diárias';

  @override
  String get salesAutoRefreshOff => 'Desligado';

  @override
  String get salesAutoRefreshTooltip => 'Atualizacao automatica';

  @override
  String get salesAutoRefreshNow => 'Atualizar agora';

  @override
  String salesAutoRefreshLastUpdatedAt(String time) {
    return 'Atualizado $time';
  }

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
  String get salesCardProdutoTendenciaTitle => 'Tendência de vendas';

  @override
  String get salesCardProdutoTendenciaMediaMovelTitle =>
      'Tendência de vendas (média móvel)';

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
  String get salesMonthlyPnlBarChartTitle => 'Comparativo mensal (barras)';

  @override
  String get salesMonthlyPnlBarChartSubtitle =>
      'As barras usam os mesmos totais mensais que o grafico de linhas acima (venda, lucro e custo da mercadoria agregados — nao medias por item). Os percentuais sao calculados a partir desses totais mensais.';

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
      'Grafico de barras agrupadas mensais de venda, lucro e custo da mercadoria';

  @override
  String salesMonthlyPnlBarSummarySemantics(
    String totalSales,
    String totalProfit,
    String totalCost,
    String topMonth,
    String topSales,
  ) {
    return 'Totais do periodo: $totalSales em vendas, $totalProfit de lucro, $totalCost de custo da mercadoria. Mes com maior venda: $topMonth ($topSales).';
  }

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
      'Visao executiva da tendencia de venda por produto com resumo, destaques e detalhe paginado.';

  @override
  String get salesProdutoTendenciaFilterCurrentPeriod => 'Periodo atual';

  @override
  String get salesProdutoTendenciaFilterPreviousPeriod => 'Periodo anterior';

  @override
  String get salesProdutoTendenciaComparisonCurrentChip => 'Atual';

  @override
  String get salesProdutoTendenciaComparisonPreviousChip => 'Anterior';

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
  String get salesProdutoTendenciaFilterQuickPeriodsTitle =>
      'Periodos sugeridos';

  @override
  String get salesProdutoTendenciaFilterQuickPeriodsSubtitle =>
      'Escolha uma janela base e o relatorio alinha a comparacao automaticamente.';

  @override
  String get salesProdutoTendenciaFilterPresetCurrentMonth => 'Mes atual';

  @override
  String get salesProdutoTendenciaFilterPresetPreviousMonth => 'Mes anterior';

  @override
  String get salesProdutoTendenciaFilterPresetLast7Days => 'Ultimos 7 dias';

  @override
  String get salesProdutoTendenciaFilterPresetLast30Days => 'Ultimos 30 dias';

  @override
  String get salesProdutoTendenciaFilterAutoAdjustPreviousAction =>
      'Ajustar periodo anterior';

  @override
  String get salesProdutoTendenciaFilterRuleHelperTitle =>
      'Regra da comparacao';

  @override
  String get salesProdutoTendenciaFilterRuleHelper =>
      'Compare mes completo com mes completo, ou periodos personalizados com a mesma quantidade de dias.';

  @override
  String get salesProdutoTendenciaFilterApplyDisabledTitle =>
      'A comparacao precisa de ajuste';

  @override
  String get salesProdutoTendenciaFilterApplyDisabledHint =>
      'Atualize os periodos acima para habilitar a aplicacao dos filtros.';

  @override
  String salesProdutoTendenciaFilterDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get salesProdutoTendenciaFilterRangeKindFullMonth => 'Mes completo';

  @override
  String get salesProdutoTendenciaFilterRangeKindCustom =>
      'Periodo personalizado';

  @override
  String get salesProdutoTendenciaFilterPeriodsOrderError =>
      'O periodo anterior precisa terminar antes do inicio do periodo atual.';

  @override
  String get salesProdutoTendenciaFilterPeriodsEquivalentWindowError =>
      'Use janelas equivalentes na comparacao: mes completo contra mes completo, ou periodo personalizado contra periodo personalizado com a mesma quantidade de dias.';

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
  String get salesProdutoTendenciaTopMoversTitle => 'Principais movimentacoes';

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
      'Lista paginada com produto, classificacao e grupo.';

  @override
  String get salesProdutoTendenciaDetailsHorizontalScrollCaption =>
      'Deslize para o lado para ver todas as colunas.';

  @override
  String get salesProdutoTendenciaFiltersAppliedSnackbar =>
      'Filtros aplicados. Atualizando dados.';

  @override
  String get salesProdutoTendenciaLoadingTrendSemantics =>
      'Carregando tendencia de vendas…';

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
      other: '$count filtros adicionais',
      one: '1 filtro adicional',
      zero: 'Sem filtros adicionais',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaDetailsNotice(String pageSize) {
    return 'Pode haver mais linhas no resultado. Use a paginacao para carregar as proximas paginas (tamanho atual: $pageSize).';
  }

  @override
  String get salesProdutoTendenciaMediaMovelPageSubtitle =>
      'Painel de media movel com resumo por classificacao e detalhe paginado por produto.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDias =>
      'Janela de dias';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint =>
      'Quantidade de dias usada em cada media movel';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper =>
      'Use a mesma janela para comparar a media atual com a anterior.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid =>
      'Informe uma quantidade de dias valida e maior que zero.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle =>
      'Janelas rapidas';

  @override
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge(
    int maxDays,
  ) {
    return 'Use no maximo $maxDays dias.';
  }

  @override
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaMediaMovelActiveFiltersSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros adicionais',
      one: '1 filtro adicional',
      zero: 'Sem filtros adicionais',
    );
    return '$_temp0';
  }

  @override
  String get salesProdutoTendenciaMediaMovelFilterSearchHint =>
      'Produto ou grupo';

  @override
  String get salesProdutoTendenciaMediaMovelFiltersAppliedSnackbar =>
      'Filtros aplicados. Atualizando a tendencia por media movel.';

  @override
  String get salesProdutoTendenciaMediaMovelSelectAgentHint =>
      'Escolha um agente de vendas para carregar a tendencia de vendas por media movel.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryTitle => 'Resumo executivo';

  @override
  String get salesProdutoTendenciaMediaMovelSummarySubtitle =>
      'Totais por classificacao em todo o resultado filtrado.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableTitle =>
      'Resumo indisponivel';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableMessage =>
      'Nao foi possivel carregar o resumo, entao a pagina esta mostrando uma estimativa baseada nas linhas atuais.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle =>
      'Produtos por classificacao';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle =>
      'Distribuicao dos produtos em todo o resultado filtrado.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByImpactTitle =>
      'Impacto por classificacao';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle =>
      'Impacto liquido em quantidade de cada classificacao em todo o resultado filtrado.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsTitle => 'Detalhes';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsSubtitle =>
      'Lista paginada com produto, medias, grupo e classificacao de tendencia.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption =>
      'Deslize para o lado para ver todas as colunas.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsEntityLabel => 'linhas';

  @override
  String salesProdutoTendenciaMediaMovelDetailsSortedBy(String sortLabel) {
    return 'Ordenado por: $sortLabel';
  }

  @override
  String salesProdutoTendenciaMediaMovelDetailsNotice(String pageSize) {
    return 'Pode haver mais linhas no resultado. Use a paginacao para carregar as proximas paginas (tamanho atual: $pageSize).';
  }

  @override
  String get salesProdutoTendenciaMediaMovelNoData =>
      'Sem dados de tendencia por media movel para os filtros selecionados.';

  @override
  String get salesProdutoTendenciaMediaMovelKpiGrowing => 'Produtos crescendo';

  @override
  String get salesProdutoTendenciaMediaMovelKpiFalling => 'Produtos caindo';

  @override
  String get salesProdutoTendenciaMediaMovelKpiNewProducts => 'Produtos novos';

  @override
  String get salesProdutoTendenciaMediaMovelKpiStopped => 'Parou de vender';

  @override
  String get salesProdutoTendenciaMediaMovelKpiNetImpact =>
      'Impacto liquido (qtd)';

  @override
  String get salesProdutoTendenciaMediaMovelColProduct => 'Produto';

  @override
  String get salesProdutoTendenciaMediaMovelColClassificacao => 'Classificacao';

  @override
  String get salesProdutoTendenciaMediaMovelColGrupo => 'Grupo';

  @override
  String get salesProdutoTendenciaMediaMovelColMediaAtual => 'Media atual';

  @override
  String get salesProdutoTendenciaMediaMovelColMediaAnterior =>
      'Media anterior';

  @override
  String get salesProdutoTendenciaMediaMovelColDiferenca => 'Diferenca';

  @override
  String get salesProdutoTendenciaMediaMovelColPercentual => 'Tendencia %';

  @override
  String get salesProdutoTendenciaMediaMovelFilterSortBy =>
      'Ordenar linhas por';

  @override
  String get salesProdutoTendenciaMediaMovelSortTrendPercent =>
      'Percentual de tendencia';

  @override
  String get salesProdutoTendenciaMediaMovelSortDifference => 'Diferenca';

  @override
  String get salesProdutoTendenciaMediaMovelSortProductName =>
      'Nome do produto';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoStopped =>
      'Parou de vender';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoNew => 'Novo produto';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoGrowing => 'Crescendo';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoFalling => 'Caindo';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoStable => 'Estavel';

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
      'Filiais que nao retornaram dados';

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
      'Este resumo agrega dados de varias filiais aprovadas. Se houver sobreposicao entre bases, os totais podem ficar acima de uma unica fonte.';

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
  String get dashboardHomeFiltersAgentsLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Carregue a visao geral para listar as filiais.';

  @override
  String get dashboardHomeFiltersBranchesLabel => 'FILIAIS';

  @override
  String get dashboardHomeFiltersBranchesEmptyHint =>
      'Carregue a visao geral para listar as filiais.';

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
      'Faturamento total por filial no periodo.';

  @override
  String get dashboardUserRankingTitle => 'Ranking por operador';

  @override
  String get dashboardUserRankingSubtitle =>
      'Faturamento por operador no periodo.';

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
  String get chartFullscreenDataSnapshotHint =>
      'Os valores do mapa refletem os dados carregados ao abrir a tela cheia.';

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
      'Nenhuma filial aprovada esta disponivel para carregar a visao geral.';

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
  String get overviewLucratividadeTitle => 'Lucratividade por filial';

  @override
  String get overviewLucratividadeSubtitle =>
      'Receita, custo e margem no periodo selecionado (todas as filiais no escopo somadas).';

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
      'Custo / Venda × 100. Mostra qual parcela da receita corresponde ao custo de reposicao.';

  @override
  String get overviewLucratividadePercentHelpGrossBody =>
      'Lucro / Venda × 100. Mostra qual parcela da receita permanece como lucro bruto.';

  @override
  String get overviewLucratividadePercentHelpMarkupBody =>
      'Lucro / Custo × 100. Mostra quanto o lucro representa em relacao ao custo de reposicao.';

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
      'Markup sobre o custo de reposicao.';

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
      'Markup nao definido quando o custo de reposicao e zero ou ausente.';

  @override
  String get overviewLucratividadePercentMetricCostTooltip =>
      'Parcela da receita correspondente ao custo de reposicao (custo dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricGrossTooltip =>
      'Margem bruta sobre a venda (lucro dividido pela venda).';

  @override
  String get overviewLucratividadePercentMetricMarkupTooltip =>
      'Markup sobre o custo de reposicao (lucro dividido pelo custo).';

  @override
  String get overviewLucratividadeMensalPercentChronologicalHint =>
      'Meses em ordem cronologica (sem ranking por valor).';

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
      'Nenhuma filial aprovada esta disponivel para carregar a lucratividade. Adicione ou conecte uma filial primeiro.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Carregando grafico de lucratividade por filial…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Lucratividade mensal do produto';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Receita, custo de reposicao e margem por mes (filial selecionada).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'Sem dados de lucratividade para este periodo.';

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
      'Acesse e gerencie informações comerciais por categoria.';

  @override
  String get shellNavSalesMonitoringLabel => 'Acompanhar vendas';

  @override
  String get shellNavSalesMonitoringSubtitle =>
      'Mapa e atualizacao por filtros';

  @override
  String get salesLiveMapTitle => 'Acompanhar vendas';

  @override
  String get salesLiveMapSubtitle =>
      'Mapa do Brasil com vendas por filial e atualizacao por filtros.';

  @override
  String get salesLiveMapSessionExpiredMessage =>
      'Sessao expirada. Entre novamente para consultar.';

  @override
  String get salesLiveMapAgentsLabel => 'Filiais';

  @override
  String get salesLiveMapPeriodLabel => 'Periodo';

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
  String get salesLiveMapPeriodLastSevenDays => 'Ultimos 7 dias';

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
  String get salesLiveMapMapPresetMunicipalities => 'Municipios';

  @override
  String get salesLiveMapMapPresetMunicipalitiesShort => 'Municipios';

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
      'Nao foi possivel carregar o acompanhamento';

  @override
  String get salesLiveMapLoadErrorRetryMessage =>
      'Tente atualizar a consulta novamente.';

  @override
  String get salesLiveMapMissingClientTokenSetupMessage =>
      'Nenhum agente selecionado possui token local para executar a consulta.';

  @override
  String get salesLiveMapChartTitle => 'Vendas por filial no Brasil';

  @override
  String salesLiveMapChartSubtitlePending(String period) {
    return 'Periodo $period.';
  }

  @override
  String salesLiveMapChartSubtitleLoaded(
    String period,
    int mappedCount,
    int totalCount,
  ) {
    return 'Periodo $period. $mappedCount de $totalCount filiais posicionadas.';
  }

  @override
  String get salesLiveMapPartialTitle => 'Acompanhamento parcial';

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
  String get salesLiveMapFiltersTitle => 'Filtros de acompanhamento';

  @override
  String get salesLiveMapFiltersDescription =>
      'Escolha filiais, periodo e tipo visual do mapa.';

  @override
  String get salesLiveMapBranchesSectionTitle => 'Filiais';

  @override
  String get salesLiveMapBranchesSectionSubtitle =>
      'A lista aparece depois da primeira atualizacao do mapa.';

  @override
  String get salesLiveMapSelectAtLeastOneTokenBranch =>
      'Selecione ao menos uma filial com token local.';

  @override
  String get salesLiveMapNoApprovedAgents =>
      'Nenhuma filial aprovada disponivel para consulta.';

  @override
  String get salesLiveMapBranchesLoadBeforeSelection =>
      'Atualize o mapa uma vez para listar as filiais disponiveis.';

  @override
  String get salesLiveMapSelectAllTokenBacked => 'Selecionar todas';

  @override
  String get salesLiveMapClearSelection => 'Desmarcar todas';

  @override
  String get salesLiveMapMissingLocalToken => 'Sem token local';

  @override
  String get salesLiveMapCustomPeriodLabel => 'Periodo personalizado';

  @override
  String salesLiveMapCustomPeriodHelper(int maxDays) {
    return 'Limite de $maxDays dias por atualizacao.';
  }

  @override
  String get salesLiveMapCustomPeriodPickerTitle => 'Selecionar periodo';

  @override
  String get salesLiveMapMapTypeTitle => 'Tipo de mapa';

  @override
  String get salesLiveMapMapTypeSubtitle =>
      'Escolha como os pontos e totais devem aparecer.';

  @override
  String get salesLiveMapDetailLabel => 'Detalhamento';

  @override
  String get salesLiveMapDetailSubtitle =>
      'Escolha o nivel de agregacao mostrado no mapa.';

  @override
  String get salesLiveMapDetailBranches => 'Filiais';

  @override
  String get salesLiveMapDetailMunicipalities => 'Municipios';

  @override
  String get salesLiveMapDetailStates => 'UFs';

  @override
  String get salesLiveMapVisualLabel => 'Visual';

  @override
  String get salesLiveMapVisualSubtitle =>
      'Escolha o estilo dos marcadores para filiais e municipios.';

  @override
  String get salesLiveMapVisualDot => 'Pontos';

  @override
  String get salesLiveMapVisualBubble => 'Bolhas';

  @override
  String get salesLiveMapVisualStoreIcon => 'Icone loja';

  @override
  String salesLiveMapDetailAutoMunicipalities(int threshold) {
    return 'Acima de $threshold filiais, municipios sao exibidos automaticamente para melhorar a leitura.';
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
  String get salesLiveMapKpiMunicipalitiesOnMap => 'Municipios no mapa';

  @override
  String get salesLiveMapKpiQueriedAgents => 'Agentes consultados';

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
      'Filiais sem token de cliente neste dispositivo nao executam consultas SQL. “Online” indica apenas ligacao ao hub.';

  @override
  String get salesBranchPickerEmpty => 'Selecione uma filial';

  @override
  String get salesBranchRequiredTitle => 'Selecao de filial obrigatoria';

  @override
  String get salesBranchRequiredMessage =>
      'Selecione uma filial para visualizar essas informacoes.';

  @override
  String get salesAgentPickerLabel => 'Filial';

  @override
  String get salesAgentPickerEmpty => 'Selecione uma filial';

  @override
  String get salesAgentPickerSheetTitle => 'Selecione uma filial';

  @override
  String get salesAgentRequiredTitle => 'Selecao de filial obrigatoria';

  @override
  String get salesAgentRequiredMessage =>
      'Selecione uma filial para visualizar essas informacoes.';

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
  String get salesCardResumoTotalDiarioVendasTitle => 'Vendas diárias';

  @override
  String get salesAutoRefreshOff => 'Desligado';

  @override
  String get salesAutoRefreshTooltip => 'Atualizacao automatica';

  @override
  String get salesAutoRefreshNow => 'Atualizar agora';

  @override
  String salesAutoRefreshLastUpdatedAt(String time) {
    return 'Atualizado $time';
  }

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
  String get salesCardProdutoTendenciaTitle => 'Tendência de vendas';

  @override
  String get salesCardProdutoTendenciaMediaMovelTitle =>
      'Tendência de vendas (média móvel)';

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
  String get salesMonthlyPnlBarChartTitle => 'Comparativo mensal (barras)';

  @override
  String get salesMonthlyPnlBarChartSubtitle =>
      'As barras usam os mesmos totais mensais que o grafico de linhas acima (venda, lucro e custo da mercadoria agregados — nao medias por item). Os percentuais sao calculados a partir desses totais mensais.';

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
      'Grafico de barras agrupadas mensais de venda, lucro e custo da mercadoria';

  @override
  String salesMonthlyPnlBarSummarySemantics(
    String totalSales,
    String totalProfit,
    String totalCost,
    String topMonth,
    String topSales,
  ) {
    return 'Totais do periodo: $totalSales em vendas, $totalProfit de lucro, $totalCost de custo da mercadoria. Mes com maior venda: $topMonth ($topSales).';
  }

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
      'Visao executiva da tendencia de venda por produto com resumo, destaques e detalhe paginado.';

  @override
  String get salesProdutoTendenciaFilterCurrentPeriod => 'Periodo atual';

  @override
  String get salesProdutoTendenciaFilterPreviousPeriod => 'Periodo anterior';

  @override
  String get salesProdutoTendenciaComparisonCurrentChip => 'Atual';

  @override
  String get salesProdutoTendenciaComparisonPreviousChip => 'Anterior';

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
  String get salesProdutoTendenciaFilterQuickPeriodsTitle =>
      'Periodos sugeridos';

  @override
  String get salesProdutoTendenciaFilterQuickPeriodsSubtitle =>
      'Escolha uma janela base e o relatorio alinha a comparacao automaticamente.';

  @override
  String get salesProdutoTendenciaFilterPresetCurrentMonth => 'Mes atual';

  @override
  String get salesProdutoTendenciaFilterPresetPreviousMonth => 'Mes anterior';

  @override
  String get salesProdutoTendenciaFilterPresetLast7Days => 'Ultimos 7 dias';

  @override
  String get salesProdutoTendenciaFilterPresetLast30Days => 'Ultimos 30 dias';

  @override
  String get salesProdutoTendenciaFilterAutoAdjustPreviousAction =>
      'Ajustar periodo anterior';

  @override
  String get salesProdutoTendenciaFilterRuleHelperTitle =>
      'Regra da comparacao';

  @override
  String get salesProdutoTendenciaFilterRuleHelper =>
      'Compare mes completo com mes completo, ou periodos personalizados com a mesma quantidade de dias.';

  @override
  String get salesProdutoTendenciaFilterApplyDisabledTitle =>
      'A comparacao precisa de ajuste';

  @override
  String get salesProdutoTendenciaFilterApplyDisabledHint =>
      'Atualize os periodos acima para habilitar a aplicacao dos filtros.';

  @override
  String salesProdutoTendenciaFilterDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get salesProdutoTendenciaFilterRangeKindFullMonth => 'Mes completo';

  @override
  String get salesProdutoTendenciaFilterRangeKindCustom =>
      'Periodo personalizado';

  @override
  String get salesProdutoTendenciaFilterPeriodsOrderError =>
      'O periodo anterior precisa terminar antes do inicio do periodo atual.';

  @override
  String get salesProdutoTendenciaFilterPeriodsEquivalentWindowError =>
      'Use janelas equivalentes na comparacao: mes completo contra mes completo, ou periodo personalizado contra periodo personalizado com a mesma quantidade de dias.';

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
  String get salesProdutoTendenciaTopMoversTitle => 'Principais movimentacoes';

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
      'Lista paginada com produto, classificacao e grupo.';

  @override
  String get salesProdutoTendenciaDetailsHorizontalScrollCaption =>
      'Deslize para o lado para ver todas as colunas.';

  @override
  String get salesProdutoTendenciaFiltersAppliedSnackbar =>
      'Filtros aplicados. Atualizando dados.';

  @override
  String get salesProdutoTendenciaLoadingTrendSemantics =>
      'Carregando tendencia de vendas…';

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
      other: '$count filtros adicionais',
      one: '1 filtro adicional',
      zero: 'Sem filtros adicionais',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaDetailsNotice(String pageSize) {
    return 'Pode haver mais linhas no resultado. Use a paginacao para carregar as proximas paginas (tamanho atual: $pageSize).';
  }

  @override
  String get salesProdutoTendenciaMediaMovelPageSubtitle =>
      'Painel de media movel com resumo por classificacao e detalhe paginado por produto.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDias =>
      'Janela de dias';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint =>
      'Quantidade de dias usada em cada media movel';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper =>
      'Use a mesma janela para comparar a media atual com a anterior.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid =>
      'Informe uma quantidade de dias valida e maior que zero.';

  @override
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle =>
      'Janelas rapidas';

  @override
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge(
    int maxDays,
  ) {
    return 'Use no maximo $maxDays dias.';
  }

  @override
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String salesProdutoTendenciaMediaMovelActiveFiltersSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros adicionais',
      one: '1 filtro adicional',
      zero: 'Sem filtros adicionais',
    );
    return '$_temp0';
  }

  @override
  String get salesProdutoTendenciaMediaMovelFilterSearchHint =>
      'Produto ou grupo';

  @override
  String get salesProdutoTendenciaMediaMovelFiltersAppliedSnackbar =>
      'Filtros aplicados. Atualizando a tendencia por media movel.';

  @override
  String get salesProdutoTendenciaMediaMovelSelectAgentHint =>
      'Escolha um agente de vendas para carregar a tendencia de vendas por media movel.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryTitle => 'Resumo executivo';

  @override
  String get salesProdutoTendenciaMediaMovelSummarySubtitle =>
      'Totais por classificacao em todo o resultado filtrado.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableTitle =>
      'Resumo indisponivel';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableMessage =>
      'Nao foi possivel carregar o resumo, entao a pagina esta mostrando uma estimativa baseada nas linhas atuais.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle =>
      'Produtos por classificacao';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle =>
      'Distribuicao dos produtos em todo o resultado filtrado.';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByImpactTitle =>
      'Impacto por classificacao';

  @override
  String get salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle =>
      'Impacto liquido em quantidade de cada classificacao em todo o resultado filtrado.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsTitle => 'Detalhes';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsSubtitle =>
      'Lista paginada com produto, medias, grupo e classificacao de tendencia.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption =>
      'Deslize para o lado para ver todas as colunas.';

  @override
  String get salesProdutoTendenciaMediaMovelDetailsEntityLabel => 'linhas';

  @override
  String salesProdutoTendenciaMediaMovelDetailsSortedBy(String sortLabel) {
    return 'Ordenado por: $sortLabel';
  }

  @override
  String salesProdutoTendenciaMediaMovelDetailsNotice(String pageSize) {
    return 'Pode haver mais linhas no resultado. Use a paginacao para carregar as proximas paginas (tamanho atual: $pageSize).';
  }

  @override
  String get salesProdutoTendenciaMediaMovelNoData =>
      'Sem dados de tendencia por media movel para os filtros selecionados.';

  @override
  String get salesProdutoTendenciaMediaMovelKpiGrowing => 'Produtos crescendo';

  @override
  String get salesProdutoTendenciaMediaMovelKpiFalling => 'Produtos caindo';

  @override
  String get salesProdutoTendenciaMediaMovelKpiNewProducts => 'Produtos novos';

  @override
  String get salesProdutoTendenciaMediaMovelKpiStopped => 'Parou de vender';

  @override
  String get salesProdutoTendenciaMediaMovelKpiNetImpact =>
      'Impacto liquido (qtd)';

  @override
  String get salesProdutoTendenciaMediaMovelColProduct => 'Produto';

  @override
  String get salesProdutoTendenciaMediaMovelColClassificacao => 'Classificacao';

  @override
  String get salesProdutoTendenciaMediaMovelColGrupo => 'Grupo';

  @override
  String get salesProdutoTendenciaMediaMovelColMediaAtual => 'Media atual';

  @override
  String get salesProdutoTendenciaMediaMovelColMediaAnterior =>
      'Media anterior';

  @override
  String get salesProdutoTendenciaMediaMovelColDiferenca => 'Diferenca';

  @override
  String get salesProdutoTendenciaMediaMovelColPercentual => 'Tendencia %';

  @override
  String get salesProdutoTendenciaMediaMovelFilterSortBy =>
      'Ordenar linhas por';

  @override
  String get salesProdutoTendenciaMediaMovelSortTrendPercent =>
      'Percentual de tendencia';

  @override
  String get salesProdutoTendenciaMediaMovelSortDifference => 'Diferenca';

  @override
  String get salesProdutoTendenciaMediaMovelSortProductName =>
      'Nome do produto';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoStopped =>
      'Parou de vender';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoNew => 'Novo produto';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoGrowing => 'Crescendo';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoFalling => 'Caindo';

  @override
  String get salesProdutoTendenciaMediaMovelClassificacaoStable => 'Estavel';

  @override
  String get agentStatusPending => 'Pendente';

  @override
  String get agentStatusRejected => 'Rejeitado';

  @override
  String get agentStatusUnknown => 'Desconhecido';

  @override
  String get reportFiltersApplyButton => 'Aplicar';
}
