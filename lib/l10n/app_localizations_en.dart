// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get shellNavDashboardLabel => 'Overview';

  @override
  String get shellNavDashboardSubtitle => 'Operational summary and KPIs';

  @override
  String get shellNavAgentsLabel => 'Agents';

  @override
  String get shellNavAgentsSubtitle => 'Data sources and access';

  @override
  String get shellNavSettingsLabel => 'Profile';

  @override
  String get shellNavSettingsSubtitle => 'Account and preferences';

  @override
  String get shellNavSalesLabel => 'Sales';

  @override
  String get shellNavSalesSubtitle => 'Orders, revenue, and commercial KPIs';

  @override
  String get shellNavReturnsLabel => 'Returns';

  @override
  String get shellNavReturnsSubtitle => 'Returns, exchanges, and credit notes';

  @override
  String get shellNavFinanceLabel => 'Finance';

  @override
  String get shellNavFinanceSubtitle => 'Cash flow, receivables, and payables';

  @override
  String get shellNavPurchasesLabel => 'Purchases';

  @override
  String get shellNavPurchasesSubtitle => 'Suppliers and purchase orders';

  @override
  String get shellNavInventoryLabel => 'Inventory';

  @override
  String get shellNavInventorySubtitle => 'Stock levels and movements';

  @override
  String get shellPlaceholderUnderConstructionTitle => 'Under construction';

  @override
  String get shellPlaceholderUnderConstructionBody =>
      'This section will be available in a future update.';

  @override
  String get shellAppBrandName => 'Colmeia';

  @override
  String get shellOpenSettingsSemantics => 'Open settings';

  @override
  String get shellOpenProfileSemantics => 'Open profile and account';

  @override
  String get shellNavSignOut => 'Sign out';

  @override
  String get shellNavSigningOut => 'Signing out...';

  @override
  String get shellNavSignOutSemanticsLoading => 'Ending session';

  @override
  String get shellSignOutDialogTitle => 'Sign out?';

  @override
  String get shellSignOutDialogConfirm => 'Sign out';

  @override
  String get shellSignOutDialogMessage =>
      'You will need to sign in again to access your data.';

  @override
  String get shellNavMainSemantics => 'Main navigation';

  @override
  String get userPermissionViewDashboard => 'Overview';

  @override
  String get userPermissionManageAgents => 'Agent management';

  @override
  String get userPermissionViewSales => 'Sales (module access)';

  @override
  String get userPermissionViewReturns => 'Returns (module access)';

  @override
  String get userPermissionViewFinance => 'Finance (module access)';

  @override
  String get userPermissionViewPurchases => 'Purchases (module access)';

  @override
  String get userPermissionViewInventory => 'Inventory (module access)';

  @override
  String get dashboardPartialAgentQueriesTitle => 'Incomplete overview data';

  @override
  String get dashboardPartialAgentQueriesMessage =>
      'Some approved agents did not return data. Totals may be incomplete.';

  @override
  String get dashboardMissingClientTokenTitle =>
      'Agents without a saved client token';

  @override
  String get dashboardMissingClientTokenMessage =>
      'These approved agents were skipped because no local client token was saved. Add the token on the agent screen to include their data.';

  @override
  String get overviewResumoUnknownPaymentMethod =>
      'Payment method not specified';

  @override
  String get overviewResumoUnknownUserName => 'User not specified';

  @override
  String get dashboardSetupRequiredTitle => 'Save a client token to load data';

  @override
  String get dashboardSetupRequiredMessage =>
      'None of the approved agents has a client token saved on this device. Open agent management to save the token and enable overview queries.';

  @override
  String dashboardViewAffectedAgentsList(int count) {
    return 'View list ($count)';
  }

  @override
  String get dashboardAffectedAgentsSheetTitlePartialFailure =>
      'Agents that did not return data';

  @override
  String get dashboardAffectedAgentsSheetTitleMissingToken =>
      'Agents without a saved client token';

  @override
  String get dashboardAffectedAgentsSheetTitleSetupRequired =>
      'Approved agents without a client token on this device';

  @override
  String get dashboardAgentsOfflineTitle => 'Agents currently offline';

  @override
  String get dashboardAgentsOfflineMessage =>
      'These approved agents have a saved token but the hub reports them as disconnected. Ask the agent operator to reconnect them, then retry.';

  @override
  String get dashboardAffectedAgentsSheetTitleOffline =>
      'Agents reported offline by the hub';

  @override
  String get dashboardMultiAgentAggregationTitle => 'Multiple agents';

  @override
  String get dashboardMultiAgentAggregationMessage =>
      'This summary merges data from several approved agents. If their databases overlap, totals may be higher than a single source.';

  @override
  String get dashboardPaymentSummaryTitle => 'Summary by payment method';

  @override
  String get dashboardPaymentSummarySubtitle =>
      'Sales, average ticket, and share of revenue by method.';

  @override
  String get dashboardPaymentSummaryEmptyTitle => 'No payment methods';

  @override
  String get dashboardPaymentSummaryEmptyMessage =>
      'There is no payment method breakdown for this period.';

  @override
  String get dashboardPaymentSummaryHeaderRevenueAbbr => 'REV.';

  @override
  String get dashboardPaymentSummaryTooltipRevenueAbbr =>
      'Revenue in the selected period';

  @override
  String get dashboardPaymentSummaryHeaderParticipationAbbr => 'SHARE';

  @override
  String get dashboardPaymentSummaryTooltipParticipationAbbr =>
      'Share of total revenue (percent)';

  @override
  String get dashboardPaymentSummaryHeaderSales => 'SALES';

  @override
  String get dashboardPaymentSummaryHeaderAvgTicket => 'AVG.\nTICKET';

  @override
  String get dashboardHomeFiltersAgentsLabel => 'Agents';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Load the overview to list agents.';

  @override
  String get dashboardHomeFiltersYearMonthLabel => 'YEAR / MONTH';

  @override
  String get dashboardHomeFiltersCurrentMonth => 'Current month';

  @override
  String get dashboardHomeFiltersReferenceRangeLabel => 'Date range';

  @override
  String dashboardHomeFiltersReferenceRangeHelper(int maxDays) {
    return 'Optional. Pick inclusive start and end — the range can span several months (up to $maxDays days). Totals and rankings follow that span. The monthly trend still shows the 12 months ending in the last day’s month.';
  }

  @override
  String get dashboardHomeFiltersReferenceRangePickerTitle => 'Select period';

  @override
  String get dashboardHomeFiltersYearMonthCustomDisplay => 'Custom';

  @override
  String dashboardHomeFiltersReferenceRangeMaxDurationSnackbar(int maxDays) {
    return 'The selected range cannot exceed $maxDays calendar days.';
  }

  @override
  String get overviewPeriodTagCustomRangePrefix => 'Period';

  @override
  String overviewAgentFilterAllAgentsSummary(int count) {
    return 'All agents ($count)';
  }

  @override
  String overviewAgentFilterSelectedCount(int count) {
    return '$count agents selected';
  }

  @override
  String get overviewAgentFilterRefineAction => 'Refine selection';

  @override
  String get overviewAgentFilterEditAction => 'Edit';

  @override
  String get overviewAgentFilterSheetTitle => 'Select agents';

  @override
  String get overviewAgentFilterSheetSearchHint => 'Search agents…';

  @override
  String get overviewAgentFilterSelectMatching => 'Select all matching';

  @override
  String get overviewAgentFilterApply => 'Apply';

  @override
  String get overviewAgentFilterCancel => 'Cancel';

  @override
  String get overviewAgentFilterNoSearchResults =>
      'No agents match your search.';

  @override
  String get overviewAgentFilterMissingClientTokenBanner =>
      'Agents without a client token on this device cannot run SQL queries. “Online” only reflects hub connectivity.';

  @override
  String get overviewAgentFilterMissingClientTokenRowSubtitle =>
      'No client token on this device — SQL queries are skipped.';

  @override
  String get chartCategoryDonutEmptyForFilter =>
      'No category data for this view.';

  @override
  String get dashboardAgentRankingTitle => 'Ranking by agent';

  @override
  String get dashboardAgentRankingSubtitle =>
      'Total revenue by agent in the period.';

  @override
  String get dashboardUserRankingTitle => 'Ranking by operator';

  @override
  String get dashboardUserRankingSubtitle =>
      'Revenue by operator in the period.';

  @override
  String get overviewAgentRankingEmpty => 'No agent revenue in this period.';

  @override
  String get overviewUserRankingEmpty => 'No operator revenue in this period.';

  @override
  String get overviewTopProductsTitle => 'Top products by sales';

  @override
  String overviewTopProductsSubtitle(int count) {
    return 'Per agent (not merged across databases). Up to $count products.';
  }

  @override
  String get overviewTopProductsNoEligibleAgents =>
      'No agents available for this chart. Save a client token on the agent or adjust the filter.';

  @override
  String get overviewTopProductsInvalidPeriod =>
      'The selected period is not valid for this chart.';

  @override
  String get overviewTopProductsEmpty =>
      'No product sales in this period for this agent.';

  @override
  String get overviewTopProductsLoadFailed =>
      'Could not load this chart. Try again later.';

  @override
  String get overviewTopProductsLoadingSemantics =>
      'Loading top products chart…';

  @override
  String overviewTopProductsTooltipLine(
    int sales,
    String items,
    String revenue,
    String cost,
    String margin,
  ) {
    return '$sales sales · $items items · $revenue revenue · $cost cost · $margin% margin';
  }

  @override
  String get overviewDefaultGreetingName => 'Manager';

  @override
  String overviewGreetingEyebrow(String name) {
    return 'Hello, $name';
  }

  @override
  String get overviewHomeSubtitle =>
      'Consolidated summary of approved agents (all connected branches).';

  @override
  String get overviewHomeAlertsSectionTitle => 'Notices';

  @override
  String get overviewLoadErrorTitle => 'Unable to load the overview';

  @override
  String get overviewStaleCacheTitle => 'Data saved on this device';

  @override
  String get overviewStaleCacheMessage =>
      'Could not refresh right now. The numbers below reflect the last summary fetched successfully.';

  @override
  String get overviewLoadingPaymentKpisSemantics => 'Loading payment KPIs…';

  @override
  String get overviewLoadingPaymentMixSemantics =>
      'Loading payment method mix…';

  @override
  String get overviewLoadingPaymentBarSemantics =>
      'Loading revenue by payment method…';

  @override
  String get overviewLoadingRankingsSemantics => 'Loading rankings…';

  @override
  String get overviewLoadingMonthlyParcelsSemantics =>
      'Loading last 12 months chart…';

  @override
  String get overviewLoadingWeekdaySalesSemantics =>
      'Loading sales by weekday chart…';

  @override
  String get overviewMonthlyParcelsTitle => 'Last 12 months';

  @override
  String get overviewMonthlyParcelsSubtitle =>
      'Sales count and parcel totals by month (all branches in scope).';

  @override
  String get overviewMonthlyParcelsSalesSeriesLabel => 'Sales';

  @override
  String get overviewMonthlyParcelsAmountSeriesLabel => 'Parcel amount';

  @override
  String get overviewMonthlyParcelsEmpty => 'No monthly data for this period.';

  @override
  String get overviewMonthlyParcelsLoadFailed =>
      'Could not load the monthly chart. Try again later.';

  @override
  String get overviewMonthlyParcelsChartSemantics =>
      'Last twelve months sales and parcel amount chart';

  @override
  String get overviewMonthlyParcelsSubtitleValueView =>
      'Parcel totals and sales counts by month (all branches in scope).';

  @override
  String get overviewMonthlyParcelsSwitchSalesLabel => 'Sales';

  @override
  String get overviewMonthlyParcelsSwitchValueLabel => 'Parcel value';

  @override
  String get overviewMonthlyParcelsChartSemanticsValueView =>
      'Last twelve months parcel amounts and sales counts chart';

  @override
  String get overviewWeekdaySalesTitle => 'Sales by weekday';

  @override
  String get overviewWeekdayRevenueTitle => 'Revenue by weekday';

  @override
  String get overviewWeekdaySalesSubtitle =>
      'Weekday distribution in the selected period (all branches in scope).';

  @override
  String get overviewWeekdaySalesEmpty => 'No weekday data for this period.';

  @override
  String get overviewWeekdaySalesLoadFailed =>
      'Could not load the weekday chart. Try again later.';

  @override
  String get overviewWeekdaySalesChartSemantics =>
      'Weekday sales count and parcel amount chart';

  @override
  String get overviewWeekdayRevenueChartSemantics =>
      'Weekday revenue and sales count chart';

  @override
  String get overviewWeekdayChartScopeHint =>
      'Aggregated across all branches in the selected scope.';

  @override
  String overviewWeekdaySalesTooltip(
    String weekday,
    String salesCount,
    String salesAmount,
  ) {
    return '$weekday: $salesCount sales - $salesAmount';
  }

  @override
  String get overviewWeekdayMetricSalesCountLabel => 'Sales';

  @override
  String get overviewWeekdayMetricSalesAmountLabel => 'Revenue';

  @override
  String overviewWeekdaySalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topSalesCount,
  ) {
    return 'Total $totalSalesCount sales and $totalSalesAmount in the selected period. Highest day: $topWeekday with $topSalesCount sales.';
  }

  @override
  String overviewWeekdayRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topSalesAmount,
  ) {
    return 'Total $totalSalesAmount and $totalSalesCount sales in the selected period. Highest day: $topWeekday with $topSalesAmount.';
  }

  @override
  String get overviewWeekdaySunday => 'Sunday';

  @override
  String get overviewWeekdayMonday => 'Monday';

  @override
  String get overviewWeekdayTuesday => 'Tuesday';

  @override
  String get overviewWeekdayWednesday => 'Wednesday';

  @override
  String get overviewWeekdayThursday => 'Thursday';

  @override
  String get overviewWeekdayFriday => 'Friday';

  @override
  String get overviewWeekdaySaturday => 'Saturday';

  @override
  String get overviewWeekdayUserSalesTitle => 'Sales by weekday and user';

  @override
  String get overviewWeekdayUserRevenueTitle => 'Revenue by weekday and user';

  @override
  String get overviewWeekdayUserSalesSubtitle =>
      'Weekdays on the horizontal axis; each colour is a user (see legend). Same period and branch scope as the dashboard.';

  @override
  String get overviewWeekdayUserSalesEmpty =>
      'No per-user weekday data for this period.';

  @override
  String get overviewWeekdayUserSalesLoadFailed =>
      'Could not load the per-user weekday chart. Try again later.';

  @override
  String get overviewWeekdayUserSalesChartSemantics =>
      'Weekday and user sales count and parcel amount chart';

  @override
  String get overviewWeekdayUserRevenueChartSemantics =>
      'Weekday and user revenue and sales count chart';

  @override
  String get overviewWeekdayUserChartScopeHint =>
      'Aggregated across all branches in the selected scope.';

  @override
  String get overviewWeekdayUserGroupedOthersLabel => 'Others';

  @override
  String overviewWeekdayUserGroupedTruncationFootnote(
    int shown,
    String othersLabel,
  ) {
    return 'Showing the $shown users with the highest totals; additional users are summed under \"$othersLabel\".';
  }

  @override
  String overviewWeekdayUserSalesTooltip(
    String weekday,
    String userName,
    String salesCount,
    String salesAmount,
  ) {
    return '$weekday, $userName: $salesCount sales - $salesAmount';
  }

  @override
  String overviewWeekdayUserSalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topUserName,
    String topSalesCount,
  ) {
    return 'Total $totalSalesCount sales and $totalSalesAmount in the selected period. Highest bar: $topWeekday, $topUserName with $topSalesCount sales.';
  }

  @override
  String overviewWeekdayUserRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topUserName,
    String topSalesAmount,
  ) {
    return 'Total $totalSalesAmount and $totalSalesCount sales in the selected period. Highest bar: $topWeekday, $topUserName with $topSalesAmount.';
  }

  @override
  String get overviewLoadingWeekdayUserSalesSemantics =>
      'Loading sales by weekday and user chart…';

  @override
  String get overviewKpiTotalRevenue => 'Total revenue';

  @override
  String get overviewKpiSales => 'Sales';

  @override
  String get overviewKpiAvgTicket => 'Average ticket';

  @override
  String get overviewKpiPaymentMethodCount => 'Payment methods';

  @override
  String get overviewPaymentMixTitle => 'Mix by payment method';

  @override
  String get overviewPaymentMixSubtitle =>
      'Percentage share of revenue in the period.';

  @override
  String get overviewPaymentMixDonutTotalLabel => 'TOTAL';

  @override
  String get overviewCategoryMixTitle => 'Sales by category';

  @override
  String get overviewCategoryMixDonutAnnualTotalLabel => 'ANNUAL TOTAL';

  @override
  String get overviewCategoryMixMoreOptionsTooltip => 'More options';

  @override
  String get overviewCategoryMixMenuComingSoon => 'Menu coming soon.';

  @override
  String get appCategoryDonutCardLoadingSemantics => 'Loading category chart…';

  @override
  String appCategoryDonutCardEmptySemantics(String title) {
    return '$title, no data';
  }

  @override
  String appCategoryDonutCardCategoriesSemantics(String title, int count) {
    return '$title, $count categories';
  }

  @override
  String appCategoryDonutChartSemantics(String summary) {
    return 'Doughnut chart. $summary';
  }

  @override
  String get overviewPaymentBarTitle => 'Revenue by payment method';

  @override
  String get overviewPaymentBarSubtitle =>
      'Total amount accumulated in the period.';

  @override
  String get overviewPaymentBarEmpty =>
      'No payment method revenue in this period.';

  @override
  String overviewPaymentBarTooltip(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get overviewComparisonChartLoading => 'Loading comparison chart…';

  @override
  String get overviewComparisonBarHorizontalScrollHint =>
      'Swipe horizontally to see all items.';

  @override
  String get chartComparisonPlotFloorNotice =>
      'Very small bars are drawn with a minimum height for readability. Values on labels are exact.';

  @override
  String get chartComparisonExtremeValueSpreadNotice =>
      'Some values differ by orders of magnitude; check units or aggregation if totals look wrong.';

  @override
  String get chartComparisonLoadingDefault => 'Loading comparison chart…';

  @override
  String get chartComparisonEmptyDefault => 'Nothing to compare right now.';

  @override
  String get chartComparisonPanGestureHint =>
      'Swipe the chart sideways to see more categories.';

  @override
  String get chartComboLoadingDefault => 'Loading bar and line chart…';

  @override
  String get chartComboEmptyDefault => 'No combined data for this view.';

  @override
  String get chartOpenFullscreenTooltip => 'Open chart in fullscreen';

  @override
  String get chartCloseFullscreenTooltip => 'Close fullscreen chart';

  @override
  String get chartFullscreenUnavailableTitle => 'Chart unavailable';

  @override
  String get chartFullscreenUnavailableMessage =>
      'This chart could not be opened in fullscreen. Go back and try again.';

  @override
  String overviewSemanticsPaymentMethodRow(String label) {
    return 'Payment method $label';
  }

  @override
  String overviewSemanticsRevenue(String amount) {
    return 'Revenue $amount';
  }

  @override
  String overviewSemanticsSalesCount(String count) {
    return 'Sales $count';
  }

  @override
  String overviewSemanticsAvgTicket(String amount) {
    return 'Average ticket $amount';
  }

  @override
  String overviewSemanticsSharePercent(String value) {
    return '$value percent';
  }

  @override
  String get overviewNoApprovedAgentsUserMessage =>
      'No approved agent is available to load the overview.';

  @override
  String get overviewLoadFailedUserMessage => 'Unable to load the overview.';

  @override
  String get clientAgentsDataSourcesEyebrow => 'Data sources';

  @override
  String get clientAgentsPageTitle => 'Agent management';

  @override
  String get clientAgentsPageSubtitle =>
      'Track your approved agents, request new access, and follow the status of your requests.';

  @override
  String clientAgentsPendingActionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions to send',
      one: '1 action to send',
    );
    return '$_temp0';
  }

  @override
  String get clientAgentsRefresh => 'Refresh';

  @override
  String get clientAgentsSubmitRequests => 'Send requests';

  @override
  String get clientAgentsActionFailedTitle => 'Could not complete the action';

  @override
  String get clientAgentsMaintenanceTitle => 'Agent maintenance';

  @override
  String get clientAgentsMaintenanceSubtitle =>
      'Use the tabs to see approved agents, request new access, and follow your request history.';

  @override
  String get clientAgentsMaintenanceSubtitleOwner =>
      'Use the tabs to manage your approved agents, retry client requests, and review access for agents you own.';

  @override
  String get clientAgentsTabMyAgents => 'My agents';

  @override
  String get clientAgentsTabRequestAccess => 'Request access';

  @override
  String get clientAgentsTabRequests => 'Requests';

  @override
  String get clientAgentsTabOwnerRequests => 'Review requests';

  @override
  String get clientAgentsTabOwnerClients => 'Approved clients';

  @override
  String get clientAgentsLoadApprovedErrorTitle => 'Could not load your agents';

  @override
  String clientAgentsEmptyApproved(String tabLabel) {
    return 'No approved agents yet. Request access in the \"$tabLabel\" tab.';
  }

  @override
  String get clientAgentsNoTradeName => 'No trade name';

  @override
  String get agentCatalogInactive => 'inactive';

  @override
  String get agentCatalogActive => 'active';

  @override
  String get agentConnectionOnline => 'online';

  @override
  String get agentConnectionOffline => 'offline';

  @override
  String get agentConnectionUnknown => 'Connection status unknown';

  @override
  String get clientAgentsRemoveAccess => 'Remove access';

  @override
  String get clientAgentsApprovedBulkSelect => 'Select for bulk removal';

  @override
  String get clientAgentsApprovedBulkCancel => 'Cancel selection';

  @override
  String clientAgentsApprovedBulkRemove(int count) {
    return 'Remove selected ($count)';
  }

  @override
  String get clientAgentsBulkRemoveConfirmTitle =>
      'Queue removal for multiple agents?';

  @override
  String clientAgentsBulkRemoveConfirmMessage(int count) {
    return 'Access removal for $count agents will be prepared and sent on the next sync.';
  }

  @override
  String get clientAgentsBulkRemoveConfirmBack => 'Back';

  @override
  String get clientAgentsBulkRemoveConfirmAction => 'Queue removal';

  @override
  String get clientAgentsApprovedBulkSelectAll => 'Select all';

  @override
  String get clientAgentsApprovedBulkClearSelection => 'Clear selection';

  @override
  String get clientAgentsRequestAccessIntro1 =>
      'Use one or more rows to request access. Each row needs an agent UUID; add the client token when that agent requires it for SQL execution.';

  @override
  String get clientAgentsRequestAccessIntro2 =>
      'The agent ID must be provided by the agent owner or an external flow. When the request is approved, the agent will be released automatically for this account.';

  @override
  String get clientAgentsRequestAccessIntroToken =>
      'The client token is cached on this device while approval is pending and pushed to the Colmeia server as soon as the agent is linked.';

  @override
  String get clientAgentsRequestAccessAddRow => 'Add agent row';

  @override
  String get clientAgentsRequestAccessRemoveRow => 'Remove row';

  @override
  String clientAgentsRequestAccessRowTitle(int index) {
    return 'Agent $index';
  }

  @override
  String get clientAgentsClientTokenLabel => 'Client token';

  @override
  String get clientAgentsClientTokenHint =>
      'Optional — cached locally, pushed to the server after approval';

  @override
  String get clientAgentsClientTokenShow => 'Show token';

  @override
  String get clientAgentsClientTokenHide => 'Hide token';

  @override
  String get clientAgentsAgentIdsLabel => 'Agent ID';

  @override
  String get clientAgentsRequestAccessCta => 'Request access';

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
    return 'Duplicate IDs were ignored automatically: $ids.';
  }

  @override
  String get clientAgentsLoadRequestsErrorTitle => 'Could not load requests';

  @override
  String get clientAgentsLoadPendingErrorTitle =>
      'Could not load pending submissions';

  @override
  String get clientAgentsNoRequestsYet => 'No requests at the moment.';

  @override
  String get clientAgentsRequestStatusPending => 'Pending';

  @override
  String get clientAgentsRequestStatusApproved => 'Approved';

  @override
  String get clientAgentsRequestStatusRejected => 'Rejected';

  @override
  String get clientAgentsRequestStatusExpired => 'Expired';

  @override
  String get clientAgentsRequestStatusUnknown => 'Unknown';

  @override
  String get clientAgentsRequestDescPending =>
      'Under review by the agent owner.';

  @override
  String get clientAgentsRequestDescApproved =>
      'Approved and available for this account.';

  @override
  String get clientAgentsRequestDescRejected =>
      'Not approved by the agent owner.';

  @override
  String get clientAgentsRequestDescExpired =>
      'The request expired. Submit again if needed.';

  @override
  String get clientAgentsRequestDescUnknown =>
      'The status of this request is not available yet.';

  @override
  String get clientAgentsRetryRequestAction => 'Retry request';

  @override
  String get clientAgentsPendingDescQueued => 'Ready to send.';

  @override
  String get clientAgentsPendingDescSyncing => 'Sending now.';

  @override
  String get clientAgentsPendingDescFailed => 'Could not send. Try again.';

  @override
  String get clientAgentsPendingDescSynced => 'Sent.';

  @override
  String get clientAgentsPendingChipRequest => 'Request';

  @override
  String get clientAgentsPendingChipRemove => 'Remove';

  @override
  String get clientAgentsPendingChipQueued => 'ready to send';

  @override
  String get clientAgentsPendingChipSyncing => 'sending';

  @override
  String get clientAgentsPendingChipFailed => 'failed';

  @override
  String get clientAgentsPendingChipSynced => 'sent';

  @override
  String clientAgentsPendingSendTitle(String agentId) {
    return 'Pending send: $agentId';
  }

  @override
  String get clientAgentsSessionUnavailableLoad =>
      'Session unavailable to load agents.';

  @override
  String get clientAgentsSessionUnavailableRequest =>
      'Session unavailable to request access.';

  @override
  String get clientAgentsSessionUnavailableRemove =>
      'Session unavailable to remove access.';

  @override
  String get clientAgentsSessionUnavailableSync =>
      'Session unavailable to sync pending items.';

  @override
  String get clientAgentsRetryMissingRequestId =>
      'This request cannot be retried because its identifier is unavailable.';

  @override
  String get clientAgentsRetrySuccess =>
      'The request was retried. We will keep watching for approval updates.';

  @override
  String get clientAgentsDiscardQueuedRequestAction => 'Remove from queue';

  @override
  String get clientAgentsDiscardQueuedRequestSuccess =>
      'The pending submission was removed. You can request access again when you want.';

  @override
  String get clientAgentsDiscardQueuedRequestInvalidState =>
      'This submission cannot be removed from the queue in its current state.';

  @override
  String get clientAgentsOwnerActionFailedTitle =>
      'Could not complete the owner action';

  @override
  String get clientAgentsOwnerRequestsLoadErrorTitle =>
      'Could not load requests to review';

  @override
  String get clientAgentsOwnerRequestsEmpty =>
      'No client requests need your review right now.';

  @override
  String get clientAgentsOwnerApproveAction => 'Approve';

  @override
  String get clientAgentsOwnerRejectAction => 'Reject';

  @override
  String get clientAgentsOwnerRequestsStatusPending =>
      'Awaiting your decision for this agent.';

  @override
  String get clientAgentsOwnerRequestsStatusApproved =>
      'Approved and already available for the client.';

  @override
  String get clientAgentsOwnerRequestsStatusRejected =>
      'Rejected during owner review.';

  @override
  String get clientAgentsOwnerRequestsStatusExpired =>
      'Expired before a final review.';

  @override
  String get clientAgentsOwnerRequestsStatusUnknown =>
      'The latest owner-review status is unavailable.';

  @override
  String get clientAgentsOwnerApproveSuccess =>
      'The access request was approved.';

  @override
  String get clientAgentsOwnerRejectSuccess =>
      'The access request was rejected.';

  @override
  String get clientAgentsOwnerClientsEmptyAgents =>
      'No managed agents are available for this account yet.';

  @override
  String get clientAgentsOwnerClientsAgentSelectorLabel => 'Agent';

  @override
  String get clientAgentsOwnerClientsAgentSelectorHint =>
      'Choose an owned agent';

  @override
  String get clientAgentsOwnerClientsLoadErrorTitle =>
      'Could not load approved clients';

  @override
  String get clientAgentsOwnerClientsEmpty =>
      'No approved clients are linked to this agent yet.';

  @override
  String get clientAgentsOwnerClientsApprovedSubtitle =>
      'Approved for this agent.';

  @override
  String get clientAgentsOwnerRevokeAction => 'Revoke access';

  @override
  String get clientAgentsOwnerRevokeSuccess => 'The client access was revoked.';

  @override
  String get clientAgentDetailSessionUnavailable =>
      'Session unavailable to load the agent.';

  @override
  String get appInlineErrorRetry => 'Try again';

  @override
  String appInlineErrorRetryCountdown(int seconds) {
    return 'Retry in ${seconds}s';
  }

  @override
  String get clientAgentsNoLocalPendingToSync =>
      'There are no local pending items to sync.';

  @override
  String get clientAgentsRequestBlockedFallback =>
      'Could not register the requested access request.';

  @override
  String clientAgentsRequestBlockedIntro(String details) {
    return 'No new agents can be requested with the IDs provided. $details';
  }

  @override
  String clientAgentsRequestBlockedAlreadyApproved(String ids) {
    return 'Already approved: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyReview(String ids) {
    return 'Already under review: $ids.';
  }

  @override
  String clientAgentsRequestBlockedAlreadyQueued(String ids) {
    return 'Already queued for sending: $ids.';
  }

  @override
  String get clientAgentsRequestQueuedWatchingSingle =>
      'Request submitted. We will track approval automatically.';

  @override
  String clientAgentsRequestQueuedWatchingPlural(int count) {
    return '$count requests submitted. We will track approvals automatically.';
  }

  @override
  String clientAgentsRequestQueuedIgnoredSuffix(int count) {
    return '$count IDs were ignored because they were already approved or under review.';
  }

  @override
  String get clientAgentsRequestRelinkUpdatedSingle =>
      'That agent is already approved on the server. Your agent list was updated.';

  @override
  String clientAgentsRequestRelinkUpdatedPlural(int count) {
    return '$count agents were already approved on the server. Your agent list was updated.';
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
      'Could not clear local pending requests; they may retry on the next sync.';

  @override
  String get clientAgentsRemoveBlockedFallback =>
      'Could not register the requested removal.';

  @override
  String clientAgentsRemoveBlockedIntro(String details) {
    return 'No new agents can be removed with the IDs provided. $details';
  }

  @override
  String clientAgentsRemoveBlockedNotApproved(String ids) {
    return 'No approved access: $ids.';
  }

  @override
  String clientAgentsRemoveBlockedAlreadyQueued(String ids) {
    return 'Removal already queued for sending: $ids.';
  }

  @override
  String get clientAgentsRemoveQueuedSingle =>
      'Access removal prepared and queued for sync.';

  @override
  String clientAgentsRemoveQueuedPlural(int count) {
    return '$count access removals prepared and queued for sync.';
  }

  @override
  String clientAgentsRemoveQueuedIgnoredSuffix(int count) {
    return '$count IDs were ignored.';
  }

  @override
  String get clientAgentsSyncSuccessSingle =>
      '1 pending action finished syncing.';

  @override
  String clientAgentsSyncSuccessPlural(int count) {
    return '$count pending actions finished syncing.';
  }

  @override
  String get clientAgentsSyncSuccessNoneCompleted =>
      'Sync finished but no pending actions could be applied.';

  @override
  String clientAgentsSyncRetryAfterCountdown(int seconds) {
    return 'The server asked us to wait. Try again in ${seconds}s.';
  }

  @override
  String clientAgentsRequestAccessRetryAfterCountdown(int seconds) {
    return 'Too many access requests. Try again in ${seconds}s.';
  }

  @override
  String clientAgentsSyncSuccessSomeFailedSuffix(int count) {
    return ' $count action(s) failed and remain queued to retry.';
  }

  @override
  String get clientAgentsSyncSuccessAutoSuffix => ' It was sent automatically.';

  @override
  String get clientAgentsSyncSuccessManualSuffix =>
      ' The screen was refreshed with the latest status.';

  @override
  String get clientAgentsSyncSuccessPollingSuffix =>
      ' We will track approval automatically.';

  @override
  String get clientAgentsSyncSuccessAlreadyApprovedSingle =>
      ' One agent was already approved on the server.';

  @override
  String clientAgentsSyncSuccessAlreadyApprovedPlural(int count) {
    return ' $count agents were already approved on the server.';
  }

  @override
  String get clientAgentsSyncSuccessDebouncedSingle =>
      ' One request was refreshed recently (no new email).';

  @override
  String clientAgentsSyncSuccessDebouncedPlural(int count) {
    return ' $count requests were refreshed recently (no new email).';
  }

  @override
  String clientAgentsPollApprovedSingle(String tabLabel) {
    return 'Access approved. The agent is already available under \"$tabLabel\".';
  }

  @override
  String clientAgentsPollApprovedPlural(int count, String tabLabel) {
    return '$count accesses were approved. The agents are already available under \"$tabLabel\".';
  }

  @override
  String get clientAgentsPollDeniedSingle =>
      '1 request was closed without approval.';

  @override
  String clientAgentsPollDeniedPlural(int count) {
    return '$count requests were closed without approval.';
  }

  @override
  String get clientAgentsPollTimeoutSingle =>
      '1 request is still under review. Refresh this screen later to check the result.';

  @override
  String clientAgentsPollTimeoutPlural(int count) {
    return '$count requests are still under review and you can refresh this screen later to check the result.';
  }

  @override
  String get clientAgentsPollRemainingSingle =>
      'There is still 1 request under review.';

  @override
  String clientAgentsPollRemainingPlural(int count) {
    return 'There are still $count requests under review.';
  }

  @override
  String get clientAgentDetailEyebrow => 'Detail';

  @override
  String get clientAgentDetailTitle => 'Agent';

  @override
  String get clientAgentDetailSubtitle =>
      'Detailed information for the agent approved for this account.';

  @override
  String get clientAgentDetailLoadErrorTitle => 'Could not load the agent';

  @override
  String get clientAgentFieldTradeName => 'Trade name';

  @override
  String get clientAgentFieldDocument => 'Document';

  @override
  String get clientAgentFieldCnpjCpf => 'CNPJ/CPF';

  @override
  String get clientAgentFieldEmail => 'Email';

  @override
  String get clientAgentFieldPhone => 'Phone';

  @override
  String get clientAgentFieldCity => 'City';

  @override
  String get clientAgentValueNotAvailable => 'N/A';

  @override
  String get clientAgentDetailSectionContact => 'Contact';

  @override
  String get clientAgentDetailSectionAddress => 'Address';

  @override
  String get clientAgentDetailSectionNotes => 'Notes';

  @override
  String get clientAgentDetailSectionRecord => 'Record';

  @override
  String get clientAgentDetailSectionServerToken => 'Client token';

  @override
  String get clientAgentDetailSectionServerTokenSubtitle =>
      'Stored on the Colmeia server and forwarded to the agent as `params.client_token` when this client runs SQL through the bridge. The token is also cached on this device so dashboards keep working briefly while offline.';

  @override
  String get clientAgentDetailServerTokenSave => 'Save token';

  @override
  String get clientAgentDetailServerTokenRemove => 'Remove token';

  @override
  String get clientAgentDetailServerTokenSaved => 'Token saved on the server.';

  @override
  String get clientAgentDetailServerTokenRemoved =>
      'Token removed from the server.';

  @override
  String get clientAgentDetailServerTokenStatusConfigured =>
      'A token is configured for this agent on the server.';

  @override
  String get clientAgentDetailServerTokenStatusMissing =>
      'No token configured on the server yet.';

  @override
  String get clientAgentDetailServerTokenStatusUnknown =>
      'Token status not loaded yet — refresh the screen with internet access to confirm.';

  @override
  String get clientAgentDetailRefreshFromAgent => 'Refresh from agent';

  @override
  String get clientAgentDetailRefreshFromAgentSuccess =>
      'Profile refreshed straight from the agent.';

  @override
  String get clientAgentDetailRefreshFromAgentUnsupported =>
      'This agent does not implement agent.getProfile via RPC.';

  @override
  String clientAgentDetailRetryAfterCountdown(int seconds) {
    return 'The server asked us to wait. Try again in ${seconds}s.';
  }

  @override
  String get clientAgentDetailSectionPolicy => 'Permissions of this token';

  @override
  String get clientAgentDetailSectionPolicySubtitle =>
      'Resolved by the agent for the bearer token currently stored on the server. If the policy changes after a revocation or scope edit, refresh the screen.';

  @override
  String get clientAgentDetailPolicyFullAccess =>
      'Full access (all tables, views and permissions).';

  @override
  String get clientAgentDetailPolicyAllTables => 'Allowed on every table.';

  @override
  String get clientAgentDetailPolicyAllViews => 'Allowed on every view.';

  @override
  String get clientAgentDetailPolicyAllPermissions =>
      'Holds every permission flag.';

  @override
  String get clientAgentDetailPolicyTablesLabel => 'Allowed tables';

  @override
  String get clientAgentDetailPolicyViewsLabel => 'Allowed views';

  @override
  String get clientAgentDetailPolicyPermissionsLabel => 'Permissions';

  @override
  String get clientAgentDetailPolicyRevoked =>
      'This token is reported as revoked by the agent.';

  @override
  String get clientAgentDetailPolicyRevokedSaveNewToken => 'Save new token';

  @override
  String get clientAgentDetailPolicyUnsupported =>
      'This agent does not expose token policy introspection.';

  @override
  String get clientAgentDetailPolicyEmpty =>
      'Agent did not return any rule for this token.';

  @override
  String get clientAgentDetailSectionEditProfile => 'Catalog profile';

  @override
  String get clientAgentDetailSaveProfile => 'Save profile';

  @override
  String get clientAgentDetailProfileSaved => 'Profile saved on the server.';

  @override
  String get clientAgentDetailProfileNameRequired => 'Legal name is required.';

  @override
  String get clientAgentFieldLegalName => 'Legal name';

  @override
  String get clientAgentFieldNumber => 'Number';

  @override
  String get clientAgentFieldId => 'Agent ID';

  @override
  String get clientAgentFieldDocumentType => 'Type';

  @override
  String get clientAgentFieldMobile => 'Mobile';

  @override
  String get clientAgentFieldStatus => 'Status';

  @override
  String get clientAgentFieldConnection => 'Connection';

  @override
  String get clientAgentFieldNotes => 'Notes';

  @override
  String get clientAgentFieldObservation => 'Observation';

  @override
  String get clientAgentFieldStreet => 'Street';

  @override
  String get clientAgentFieldDistrict => 'District';

  @override
  String get clientAgentFieldPostalCode => 'Postal code';

  @override
  String get clientAgentFieldState => 'State';

  @override
  String get clientAgentFieldCreatedAt => 'Since';

  @override
  String get clientAgentFieldUpdatedAt => 'Updated';

  @override
  String get clientAgentFieldProfileUpdatedAt => 'Profile updated';

  @override
  String get clientAgentsFilterSheetTitle => 'Agent filters';

  @override
  String get clientAgentsFilterSearchLabel => 'Search agent';

  @override
  String get clientAgentsFilterSearchHint => 'Name, agentId, or trade name';

  @override
  String get clientAgentsFilterConnectionLabel => 'Connection';

  @override
  String get clientAgentsFilterConnectionOnline => 'Online';

  @override
  String get clientAgentsFilterConnectionOffline => 'Offline';

  @override
  String get clientAgentsFilterConnectionUnknown => 'Unknown';

  @override
  String get clientAgentsFilterCatalogLabel => 'Catalog';

  @override
  String get clientAgentsFilterCatalogActive => 'Active';

  @override
  String get clientAgentsFilterCatalogInactive => 'Inactive';

  @override
  String clientAgentsFilterSummarySearch(String query) {
    return 'Search: $query';
  }

  @override
  String clientAgentsFilterSummaryConnection(String label) {
    return 'Connection: $label';
  }

  @override
  String clientAgentsFilterSummaryCatalog(String label) {
    return 'Catalog: $label';
  }

  @override
  String get clientAgentsEmptyFilteredApproved =>
      'No agents match the selected filters.';

  @override
  String get clientAgentsRequestsFilterSheetTitle => 'Request filters';

  @override
  String get clientAgentsRequestsFilterSearchLabel => 'Search';

  @override
  String get clientAgentsRequestsFilterSearchHint => 'Agent name or agent ID';

  @override
  String get clientAgentsRequestsFilterStatusLabel => 'Request status';

  @override
  String get clientAgentsRequestsFilterPendingLabel => 'Queued action';

  @override
  String clientAgentsRequestsFilterSummaryRequest(String label) {
    return 'Request: $label';
  }

  @override
  String clientAgentsRequestsFilterSummaryPending(String label) {
    return 'Pending: $label';
  }

  @override
  String get clientAgentsFiltersTooltip => 'Filters';

  @override
  String clientAgentsFiltersTooltipActive(int count) {
    return 'Filters ($count active)';
  }

  @override
  String get clientAgentsEmptyFilteredRequests =>
      'No requests match the selected filters.';

  @override
  String get clientAgentsPendingFilterQueued => 'Ready to send';

  @override
  String get clientAgentsPendingFilterSyncing => 'Sending…';

  @override
  String get clientAgentsPendingFilterFailed => 'Failed';

  @override
  String get clientAgentsPendingFilterSynced => 'Sent';

  @override
  String get reportFiltersTitle => 'Filters';

  @override
  String reportFiltersTitleWithContext(String title) {
    return 'Filters - $title';
  }

  @override
  String get reportFiltersDescription =>
      'Adjust the query and apply only the slices that make sense for this analysis.';

  @override
  String reportFiltersFieldCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields',
      one: '1 field',
    );
    return '$_temp0';
  }

  @override
  String reportFiltersRequiredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count required',
      one: '1 required',
    );
    return '$_temp0';
  }

  @override
  String reportFiltersActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '1 active',
    );
    return '$_temp0';
  }

  @override
  String get reportFiltersClearAction => 'Clear';

  @override
  String get reportFiltersApplyAction => 'Apply filters';

  @override
  String get reportFiltersButton => 'Filters';

  @override
  String reportFiltersButtonActive(int count) {
    return 'Filters ($count active)';
  }

  @override
  String get reportFiltersClearTooltip => 'Clear';

  @override
  String get reportFiltersClearAllTooltip => 'Clear filters';

  @override
  String get reportFiltersAdvancedButton => 'Advanced filters';

  @override
  String get reportInlineFiltersHint => 'Filter...';

  @override
  String get reportInlineFiltersAllOption => 'All';

  @override
  String get reportInlineFiltersSelectPeriod => 'Select period';

  @override
  String get reportInlineFiltersSelectDate => 'Select date';

  @override
  String get reportFiltersAppliedSectionTitle => 'Applied filters';

  @override
  String get clientAgentsErrorLoadCatalog =>
      'Could not load the agent catalog.';

  @override
  String get clientAgentsErrorLoadCatalogAgent =>
      'Could not load this catalog agent.';

  @override
  String get clientAgentsErrorLoadClientAccessStatus =>
      'Could not read the access request status.';

  @override
  String get clientAgentsErrorLoadApproved =>
      'Could not load approved agents for this account.';

  @override
  String get clientAgentsErrorLoadAgentDetail =>
      'Could not load agent details.';

  @override
  String get clientAgentsErrorProbeApproved =>
      'Could not verify whether the agent is already linked for this account.';

  @override
  String get clientAgentsErrorLoadAccessRequests =>
      'Could not load request history.';

  @override
  String get clientAgentsErrorRetryClientAccessRequest =>
      'Could not retry this access request.';

  @override
  String get clientAgentsErrorReadPending =>
      'Could not load pending submissions to sync.';

  @override
  String get clientAgentsErrorQueueRequest =>
      'Could not queue the access request for sync.';

  @override
  String get clientAgentsErrorQueueRemove =>
      'Could not queue the removal for sync.';

  @override
  String get clientAgentsErrorSyncAction =>
      'Could not sync the change for this agent.';

  @override
  String get clientAgentsErrorSyncPending =>
      'Could not sync pending agent actions.';

  @override
  String get clientAgentsErrorLoadManagedAgents =>
      'Could not load managed agents.';

  @override
  String get clientAgentsErrorLoadOwnerAccessRequests =>
      'Could not load client access requests for review.';

  @override
  String get clientAgentsErrorApproveOwnerAccessRequest =>
      'Could not approve this access request.';

  @override
  String get clientAgentsErrorRejectOwnerAccessRequest =>
      'Could not reject this access request.';

  @override
  String get clientAgentsErrorLoadOwnerApprovedClients =>
      'Could not load approved clients for this agent.';

  @override
  String get clientAgentsErrorRevokeOwnerClientAccess =>
      'Could not revoke this client access.';

  @override
  String get clientAgentsErrorGetClientAgentToken =>
      'Could not read the agent token from the server.';

  @override
  String get clientAgentsErrorSaveClientAgentToken =>
      'Could not save the agent token on the server.';

  @override
  String get clientAgentsErrorRemoveClientAgentToken =>
      'Could not remove the agent token on the server.';

  @override
  String get clientAgentsErrorAgentDocumentConflict =>
      'This CNPJ/CPF is already linked to another agent in the catalog. To change the link, contact support.';

  @override
  String get clientAgentsErrorAgentProfileCasMismatch =>
      'Another device updated this agent in the meantime. Reload the screen and reapply your changes.';

  @override
  String get agentSqlErrorAuthenticationFailed =>
      'Authentication is required to query this agent.';

  @override
  String get agentSqlErrorPermissionDenied =>
      'You do not have permission to query this data on this agent.';

  @override
  String get agentSqlErrorTransportTimeout =>
      'The agent took too long to respond. Please try again.';

  @override
  String get agentSqlErrorNetworkError =>
      'Could not reach the agent right now. Please try again.';

  @override
  String get agentSqlErrorRateLimited =>
      'Too many query attempts were made. Please wait a moment and try again.';

  @override
  String get agentSqlErrorValidationFailed => 'The query is invalid.';

  @override
  String get agentSqlErrorExecutionFailed => 'The query could not be executed.';

  @override
  String get agentSqlErrorTransactionFailed =>
      'The query transaction could not be completed.';

  @override
  String get agentSqlErrorConnectionPoolExhausted =>
      'The server is busy processing queries. Please try again shortly.';

  @override
  String get agentSqlErrorResultTooLarge =>
      'The query returned too much data. Narrow filters and try again.';

  @override
  String get agentSqlErrorDatabaseConnectionFailed =>
      'Could not connect to the database to run the query.';

  @override
  String get agentSqlErrorQueryTimeout =>
      'The query took longer than expected.';

  @override
  String get agentSqlErrorInvalidDatabaseConfig =>
      'This agent\'s database access configuration is invalid.';

  @override
  String get agentSqlErrorExecutionNotFound =>
      'The requested execution was not found.';

  @override
  String get agentSqlErrorExecutionCancelled => 'The query was cancelled.';

  @override
  String get agentSqlErrorGeneric =>
      'The query could not be completed on the agent.';

  @override
  String get formsDemoDatePickersFormTitle => 'Date pickers in Form';

  @override
  String get formsDemoDatePickersFormSubtitle =>
      'Native Form + FormField. Tap Apply in the sheet to confirm; closing without applying keeps the current value. Remove clears explicitly.';

  @override
  String get formsDemoFormBuilderSectionTitle =>
      'FormBuilder with dropdowns and dates';

  @override
  String get formsDemoFormBuilderSectionSubtitle =>
      'Same wrappers as reports: dropdown, multi-select, and the same date pickers as the Form section above (FormBuilderField + AppFormBuilderDate*).';

  @override
  String get formsDemoValidateFormBuilderButton => 'Validate FormBuilder';

  @override
  String get formsDemoValidateFormSubmitButton => 'Validate submit (Form)';

  @override
  String formsDemoFormValidSnackbar(String refLabel, String rangeLabel) {
    return 'Valid form (fake demo). Ref: $refLabel. Period: $rangeLabel.';
  }

  @override
  String formsDemoFormBuilderValidSnackbar(
    String dateLabel,
    String rangeLabel,
  ) {
    return 'Valid FormBuilder (fake demo). Date: $dateLabel. Period: $rangeLabel.';
  }

  @override
  String get datePickerPlaceholderSelectDate => 'Select a date';

  @override
  String get dateRangePickerPlaceholderSelectPeriod => 'Select the period';

  @override
  String get datePickerSheetDefaultTitle => 'Select date';

  @override
  String get dateRangePickerSheetDefaultTitle => 'Select period';

  @override
  String get datePickerClearSelectionTooltip => 'Clear selection';

  @override
  String get datePickerSheetRemoveDate => 'Remove date';

  @override
  String get dateRangePickerSheetRemovePeriod => 'Remove period';

  @override
  String get datePickerSheetCloseTooltip => 'Close';

  @override
  String get datePickerSheetApply => 'Apply';

  @override
  String get datePickerSemanticsFallbackLabel => 'Date';

  @override
  String get dateRangePickerSemanticsFallbackLabel => 'Period';

  @override
  String get overviewLucratividadeTitle => 'Profitability by agent';

  @override
  String get overviewLucratividadeSubtitle =>
      'Revenue, cost and margin for the selected period, per agent (all branches combined).';

  @override
  String get overviewLucratividadeSwitchProfit => 'Profit';

  @override
  String get overviewLucratividadeSwitchRevenue => 'Revenue';

  @override
  String get overviewLucratividadeSwitchCost => 'Cost';

  @override
  String get overviewLucratividadeSwitchMargin => 'Margin %';

  @override
  String get overviewLucratividadeProfitSeriesLabel => 'Profit';

  @override
  String get overviewLucratividadeRevenueSeriesLabel => 'Revenue';

  @override
  String get overviewLucratividadeCostSeriesLabel => 'Replacement cost';

  @override
  String get overviewLucratividadeMarginSeriesLabel => 'Margin %';

  @override
  String get overviewLucratividadeEmpty =>
      'No profitability data for this period.';

  @override
  String get overviewLucratividadeMultiAgentHint =>
      'No approved agents are available to load profitability. Add or connect an agent first.';

  @override
  String get overviewLoadingLucratividadeSemantics =>
      'Loading profitability by branch chart…';

  @override
  String get overviewLucratividadeMensalTitle =>
      'Monthly product profitability';

  @override
  String get overviewLucratividadeMensalSubtitle =>
      'Revenue, replacement cost and margin per month (selected agent).';

  @override
  String get overviewLucratividadeMensalEmpty =>
      'No profitability data for this period.';

  @override
  String get overviewLucratividadeMensalMultiAgentHint =>
      'Select a single agent to view monthly profitability.';

  @override
  String get overviewLucratividadeMensalSwitchProfit => 'Profit';

  @override
  String get overviewLucratividadeMensalSwitchRevenue => 'Revenue';

  @override
  String get overviewLucratividadeMensalSwitchCost => 'Cost';

  @override
  String get overviewLucratividadeMensalSwitchMargin => 'Margin %';

  @override
  String get overviewLucratividadeMensalProfitSeriesLabel => 'Profit';

  @override
  String get overviewLucratividadeMensalRevenueSeriesLabel => 'Revenue';

  @override
  String get overviewLucratividadeMensalCostSeriesLabel => 'Replacement cost';

  @override
  String get overviewLucratividadeMensalMarginSeriesLabel => 'Margin %';

  @override
  String get overviewLoadingLucratividadeMensalSemantics =>
      'Loading monthly product profitability chart…';

  @override
  String get salesHubTitle => 'Sales';

  @override
  String get salesHubSubtitle =>
      'Access and manage commercial information by category.';

  @override
  String get salesAgentPickerLabel => 'Agent';

  @override
  String get salesAgentPickerEmpty => 'Select an agent';

  @override
  String get salesAgentPickerSheetTitle => 'Select an agent';

  @override
  String get salesAgentRequiredTitle => 'Agent selection required';

  @override
  String get salesAgentRequiredMessage =>
      'Select an agent to view this information.';

  @override
  String get salesCardOpenAccountsTitle => 'Open Accounts';

  @override
  String get salesCardPaidAccountsTitle => 'Paid Accounts';

  @override
  String get salesCardPaymentHistoryTitle => 'Payment History';

  @override
  String get salesCardNewPaymentTitle => 'New Payment';

  @override
  String get salesCardProdutoRankLucroTitle => 'Product ranking';

  @override
  String get salesCardMonthlyPnlTitle => 'Monthly P&L';

  @override
  String get salesCardProdutoTendenciaTitle => 'Sales trend';

  @override
  String get salesCardProdutoTendenciaMediaMovelTitle =>
      'Sales trend (moving average)';

  @override
  String get salesMonthlyPnlPageSubtitle =>
      'Sales value, profit, and merchandise cost by month for the selected branch. The window ends in the reference month.';

  @override
  String get salesMonthlyPnlFilterAnchorMonth => 'Reference month';

  @override
  String get salesMonthlyPnlChartTitle => 'Monthly P&L';

  @override
  String get salesMonthlyPnlChartSubtitle =>
      'Sales value, profit, and merchandise cost by month (selected branch).';

  @override
  String get salesMonthlyPnlSeriesSalesLabel => 'Sales';

  @override
  String get salesMonthlyPnlSeriesProfitLabel => 'Profit';

  @override
  String get salesMonthlyPnlSeriesCostLabel => 'Merchandise cost';

  @override
  String get salesMonthlyPnlEmpty => 'No monthly data for this period.';

  @override
  String get salesMonthlyPnlLoadFailed =>
      'Could not load the monthly chart. Try again later.';

  @override
  String get salesMonthlyPnlChartSemantics =>
      'Monthly P&L chart with sales value, profit, and merchandise cost for the selected branch';

  @override
  String get salesProdutoRankLucroChartTitle => 'Top products';

  @override
  String get salesProdutoRankLucroFilterPeriod => 'Period';

  @override
  String get salesProdutoRankLucroFilterSortBy => 'Metric';

  @override
  String get salesProdutoRankLucroSortQuantity => 'Quantity sold';

  @override
  String get salesProdutoRankLucroSortProfit => 'Total profit';

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
      'Paginated detail with product, classification, group, and brand.';

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
  String get salesProdutoTendenciaColMarca => 'Brand';

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
      'Paginated detail with product, averages, group, brand, and trend classification.';

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
  String get salesProdutoTendenciaMediaMovelColMarca => 'Brand';

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
  String get agentStatusPending => 'Pending';

  @override
  String get agentStatusRejected => 'Rejected';

  @override
  String get agentStatusUnknown => 'Unknown';

  @override
  String get reportFiltersApplyButton => 'Apply';
}
