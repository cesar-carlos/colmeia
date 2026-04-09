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
  String get userPermissionViewDashboard => 'Overview';

  @override
  String get userPermissionManageAgents => 'Agent management';

  @override
  String get dashboardPartialAgentQueriesTitle => 'Incomplete overview data';

  @override
  String dashboardPartialAgentQueriesMessage(String agents) {
    return 'Some approved agents did not return data ($agents). Totals may be incomplete.';
  }

  @override
  String get dashboardMissingClientTokenTitle =>
      'Agents without a saved client token';

  @override
  String dashboardMissingClientTokenMessage(String agents) {
    return 'These approved agents were skipped because no local client token was saved ($agents). Add the token on the agent screen to include their data.';
  }

  @override
  String get dashboardSetupRequiredTitle =>
      'Setup required before loading data';

  @override
  String dashboardSetupRequiredMessage(String agents) {
    return 'None of the approved agents has a client token saved on this device ($agents). Open agent management to save the token and enable overview queries.';
  }

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
  String get dashboardPaymentSummaryLoadingSemantics =>
      'Loading payment method summary…';

  @override
  String get dashboardHomeFiltersAgentsLabel => 'Agents';

  @override
  String get dashboardHomeFiltersAgentsEmptyHint =>
      'Load the overview to list agents.';

  @override
  String get dashboardHomeFiltersYearMonthLabel => 'YEAR / MONTH';

  @override
  String get dashboardHomeFiltersPeriodLast30Days => 'Last 30 days';

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
  String get overviewDefaultGreetingName => 'Manager';

  @override
  String overviewGreetingEyebrow(String name) {
    return 'Hello, $name';
  }

  @override
  String get overviewHomeSubtitle =>
      'Consolidated summary of approved agents (all connected branches).';

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
  String get overviewPaymentBarTitle => 'Revenue by payment method';

  @override
  String get overviewPaymentBarSubtitle =>
      'Total amount accumulated in the period.';

  @override
  String overviewPaymentBarTooltip(String label, String amount) {
    return '$label: $amount';
  }

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
  String get overviewSaveClientTokenForAgentUserMessage =>
      'Save this agent\'s client token to query their data.';

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
  String get clientAgentsTabMyAgents => 'My agents';

  @override
  String get clientAgentsTabRequestAccess => 'Request access';

  @override
  String get clientAgentsTabRequests => 'Requests';

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
  String get agentConnectionUnknown => 'operational status unavailable';

  @override
  String get clientAgentsRemoveAccess => 'Remove access';

  @override
  String get clientAgentsRequestAccessIntro1 =>
      'Use one or more rows to request access. Each row needs an agent UUID; add the local client token when that agent requires it for SQL execution.';

  @override
  String get clientAgentsRequestAccessIntro2 =>
      'The agent ID must be provided by the agent owner or an external flow. When the request is approved, the agent will be released automatically for this account.';

  @override
  String get clientAgentsRequestAccessIntroToken =>
      'The client token is saved only on this device (encrypted) and is not sent when you submit the access request.';

  @override
  String get clientAgentsRequestAccessAddRow => 'Add agent row';

  @override
  String get clientAgentsRequestAccessRemoveRow => 'Remove row';

  @override
  String clientAgentsRequestAccessRowTitle(int index) {
    return 'Agent $index';
  }

  @override
  String get clientAgentsClientTokenLabel => 'Client token (local)';

  @override
  String get clientAgentsClientTokenHint =>
      'Optional — stored only on this device';

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
  String get clientAgentsRequestStatusUnknown => 'Status unavailable';

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
  String get clientAgentDetailSessionUnavailable =>
      'Session unavailable to load the agent.';

  @override
  String get appInlineErrorRetry => 'Try again';

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
  String get clientAgentsSyncSuccessSingle => '1 request was sent for review.';

  @override
  String clientAgentsSyncSuccessPlural(int count) {
    return '$count requests were sent for review.';
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
  String get clientAgentAddressNotProvided => 'Address not provided';

  @override
  String get clientAgentDetailSectionContact => 'Contact';

  @override
  String get clientAgentDetailSectionAddress => 'Address';

  @override
  String get clientAgentDetailSectionNotes => 'Notes';

  @override
  String get clientAgentDetailSectionRecord => 'Record';

  @override
  String get clientAgentDetailSectionLocalToken => 'Local client token';

  @override
  String get clientAgentDetailSectionLocalTokenSubtitle =>
      'Used only on this device for SQL queries (for example in the overview). Never sent to Colmeia servers.';

  @override
  String get clientAgentDetailLocalTokenSave => 'Save token';

  @override
  String get clientAgentDetailLocalTokenRemove => 'Remove token';

  @override
  String get clientAgentDetailLocalTokenSaved => 'Token saved on this device.';

  @override
  String get clientAgentDetailLocalTokenRemoved =>
      'Token removed from this device.';

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
  String get clientAgentsFilterConnectionUnknown => 'Unavailable';

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
  String get clientAgentsErrorLoadAccessRequests =>
      'Could not load request history.';

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
}
