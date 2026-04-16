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
  String get dashboardHomeFiltersCurrentMonth => 'Current month';

  @override
  String get dashboardHomeFiltersPeriodLast30Days => 'Last 30 days';

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
  String get overviewComparisonChartLoading => 'Loading comparison chart…';

  @override
  String get overviewComparisonBarHorizontalScrollHint =>
      'Swipe horizontally to see all items.';

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
  String get clientAgentsErrorAgentDocumentConflict =>
      'This CNPJ/CPF is already linked to another agent in the catalog. To change the link, contact support.';

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
  String get formsDemoEyebrow => 'Forms';

  @override
  String get formsDemoTitle => 'Shared fields';

  @override
  String get formsDemoIntroSubtitle =>
      'Validation, enabled and disabled states, date pickers in Form, FormBuilder as in reports and groupings.';

  @override
  String get formsDemoFieldLibraryOverline => 'Field library';

  @override
  String get formsDemoSharedFormControlsTitle => 'Shared form controls';

  @override
  String get formsDemoPreviewBadge => 'Preview';

  @override
  String get formsDemoShowcaseSubtitle =>
      'Base fields, selectors, and calendar wrappers in the same visual rhythm as the system.';

  @override
  String get formsDemoFieldsEnabledLabel => 'Fields enabled';

  @override
  String get formsDemoShowcaseFieldsEnabledHelper =>
      'Turns the entire example surface below on or off.';

  @override
  String get formsDemoFormStateTitle => 'Form state';

  @override
  String get formsDemoFormStateSubtitle =>
      'Turn off to inspect disabled fields.';

  @override
  String get formsDemoFormStateFieldsEnabledHelper =>
      'Applies the disabled state to every example below.';

  @override
  String get formsDemoTextEmailPasswordTitle =>
      'AppTextField, email, and password';

  @override
  String get formsDemoTextEmailPasswordSubtitle =>
      'Fake data; submit runs validation.';

  @override
  String get formsDemoFullNameLabel => 'Full name';

  @override
  String get formsDemoFullNameHint => 'As in registration';

  @override
  String get formsDemoNameValidatorMinLength => 'Enter at least 3 characters.';

  @override
  String get formsDemoCorporateEmailLabel => 'Work email';

  @override
  String get formsDemoPasswordLabel => 'Password';

  @override
  String get formsDemoNotesLabel => 'Notes';

  @override
  String get formsDemoNotesHint => 'Optional';

  @override
  String get formsDemoDatePickersFormTitle => 'Date pickers in Form';

  @override
  String get formsDemoDatePickersFormSubtitle =>
      'Validation on submit; clear the field and validate to see the error. Range with explicit dates in the demo.';

  @override
  String get formsDemoReferenceDateLabel => 'Reference date';

  @override
  String get formsDemoReferenceDateHelper =>
      'Opens in a bottom sheet with a styled calendar.';

  @override
  String get formsDemoSelectReferenceDateTitle => 'Select reference date';

  @override
  String get formsDemoReferenceDateRequiredError =>
      'Select the reference date.';

  @override
  String get formsDemoAssessmentPeriodLabel => 'Desired capture period';

  @override
  String get formsDemoAssessmentPeriodHelper =>
      'Ideal for filters and analytical queries.';

  @override
  String get formsDemoSelectPeriodTitle => 'Select period';

  @override
  String get formsDemoAssessmentPeriodRequiredError =>
      'Select the full period.';

  @override
  String get formsDemoDateRangeMiddle => ' to ';

  @override
  String get formsDemoCheckboxTitle => 'AppCheckboxField';

  @override
  String get formsDemoCheckboxSubtitle => 'Fictitious consent.';

  @override
  String get formsDemoCheckboxLabel => 'Receive a weekly summary by email';

  @override
  String get formsDemoCheckboxHelper =>
      'Sends alerts, summaries, and indicator updates.';

  @override
  String get formsDemoRadioCompactTitle => 'Compact AppRadioGroup';

  @override
  String get formsDemoRadioCompactSubtitle =>
      'Single selection using the design system inline pattern.';

  @override
  String get formsDemoPeriodDaily => 'Daily';

  @override
  String get formsDemoPeriodMonthly => 'Monthly';

  @override
  String get formsDemoPeriodQuarterly => 'Quarterly';

  @override
  String get formsDemoChoiceChipTitle => 'AppChoiceChip';

  @override
  String get formsDemoChoiceChipSubtitle =>
      'Point-in-time chips for context, store, or scope.';

  @override
  String get formsDemoScopeHeadquarters => 'Head office';

  @override
  String get formsDemoScopeStoreCenter => 'Downtown store';

  @override
  String get formsDemoScopeStoreSouth => 'South store';

  @override
  String get formsDemoDropdownMenusTitle => 'Dropdown menus';

  @override
  String get formsDemoDropdownMenusSubtitle =>
      'Single-select and multi-select search in the same light/dark visual pattern as the references.';

  @override
  String get formsDemoStandardSelectLabel => 'Standard select';

  @override
  String get formsDemoSelectHiveNodeHint => 'Select Hive node…';

  @override
  String get formsDemoMultiSelectSearchLabel => 'Multi-select search';

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
      'FormBuilder with dropdowns and dates';

  @override
  String get formsDemoFormBuilderSectionSubtitle =>
      'Same wrappers used in parameterized reports, now with the shared dropdown.';

  @override
  String get formsDemoFormBuilderNodeLabel => 'Select node (FormBuilder)';

  @override
  String get formsDemoFormBuilderNodeHelper =>
      'Single selection with the shared wrapper.';

  @override
  String get formsDemoFormBuilderTagsLabel => 'Tags (FormBuilder)';

  @override
  String get formsDemoFormBuilderTagsHelper =>
      'Inline search with removable chips.';

  @override
  String get formsDemoFormBuilderDateRequiredLabel =>
      'Required date (FormBuilder)';

  @override
  String get formsDemoFormBuilderDateRequiredHelper =>
      'Validation with form_builder_validators.';

  @override
  String get formsDemoFormBuilderSelectDateTitle => 'Select date (FormBuilder)';

  @override
  String get formsDemoFormBuilderRangeLabel => 'Period (FormBuilder)';

  @override
  String get formsDemoFormBuilderRangeHelper => 'Optional in this demo.';

  @override
  String get formsDemoFormBuilderSelectRangeTitle =>
      'Select period (FormBuilder)';

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
  String get formsDemoLegendInput => 'Input';

  @override
  String get formsDemoLegendSelection => 'Selection';

  @override
  String get formsDemoLegendDate => 'Date';

  @override
  String get formsDemoLegendFormBuilder => 'FormBuilder';

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
  String get areaTrendDemoIntroEyebrow => 'Area charts';

  @override
  String get areaTrendDemoIntroTitle => 'AppAreaTrendChart';

  @override
  String get areaTrendDemoIntroSubtitle =>
      'Temporal trend with filled area: gradient, markers, zoom, style variants, and structured per-series/point tap event.';

  @override
  String get areaTrendDemoShowcaseTitle => 'Temporal trend with fill';

  @override
  String get areaTrendDemoShowcaseSubtitle =>
      'Area chart for volume, growth, and comparisons over time, with good mass and intensity reading.';

  @override
  String get areaTrendDemoShowcaseBadge => 'Trend';

  @override
  String get areaTrendDemoShowcaseHighlightTimeSeries => 'Time series';

  @override
  String get areaTrendDemoShowcaseHighlightGradientMarkers =>
      'Gradient and markers';

  @override
  String get areaTrendDemoShowcaseHighlightMultiseries => 'Multi-series';

  @override
  String get areaTrendDemoS01Title => '1. Weekly revenue';

  @override
  String get areaTrendDemoS01Subtitle =>
      'Area with gradient, formatted axis, tooltip, and tap.';

  @override
  String get areaTrendDemoS02Title => '2. With point markers';

  @override
  String get areaTrendDemoS02Subtitle => 'Each point shows a visible marker.';

  @override
  String get areaTrendDemoS03Title => '3. No gradient (solid area)';

  @override
  String get areaTrendDemoS03Subtitle =>
      'showGradientFill: false for a flat fill.';

  @override
  String get areaTrendDemoS04Title => '4. Orders by hour';

  @override
  String get areaTrendDemoS04Subtitle =>
      'Operational peak of the day — unit scale.';

  @override
  String get areaTrendDemoS05Title => '5. Compact without shell';

  @override
  String get areaTrendDemoS05Subtitle =>
      'Compact preset, no axes and no inner shell.';

  @override
  String get areaTrendDemoS06Title => '6. Loading state';

  @override
  String get areaTrendDemoS07Title => '7. Empty state';

  @override
  String get areaTrendDemoEmptyMessage => 'No data for the selected period.';

  @override
  String get areaTrendDemoS08Title => '8. Multi-series (store comparison)';

  @override
  String get areaTrendDemoS08Subtitle =>
      'Three overlaid stores with automatic palette. Legend on.';

  @override
  String get areaTrendDemoS09Title => '9. Multi-series with trackball';

  @override
  String get areaTrendDemoS09Subtitle =>
      'Tap the area to see values for all series at the same X position.';

  @override
  String get areaTrendDemoS10Title => '10. Colors per entry';

  @override
  String get areaTrendDemoS10Subtitle => 'Custom color per AppAreaTrendEntry.';

  @override
  String get areaTrendDemoSeriesRevenue => 'Revenue';

  @override
  String get areaTrendDemoSeriesTarget => 'Target';

  @override
  String get areaTrendDemoStoreCenter => 'Downtown';

  @override
  String get areaTrendDemoStoreNorth => 'North';

  @override
  String get areaTrendDemoStoreSouth => 'South';

  @override
  String get areaTrendDemoDefaultSeriesName => 'primary series';

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
    return 'Chart demo $sectionIndex: $sectionTitle';
  }
}
