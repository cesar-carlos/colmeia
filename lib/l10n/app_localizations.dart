import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @shellNavDashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get shellNavDashboardLabel;

  /// No description provided for @shellNavDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Operational summary and KPIs'**
  String get shellNavDashboardSubtitle;

  /// No description provided for @shellNavAgentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get shellNavAgentsLabel;

  /// No description provided for @shellNavAgentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data sources and access'**
  String get shellNavAgentsSubtitle;

  /// No description provided for @shellNavSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get shellNavSettingsLabel;

  /// No description provided for @shellNavSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account and preferences'**
  String get shellNavSettingsSubtitle;

  /// No description provided for @userPermissionViewDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get userPermissionViewDashboard;

  /// No description provided for @userPermissionManageAgents.
  ///
  /// In en, this message translates to:
  /// **'Agent management'**
  String get userPermissionManageAgents;

  /// No description provided for @dashboardPartialAgentQueriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Incomplete overview data'**
  String get dashboardPartialAgentQueriesTitle;

  /// No description provided for @dashboardPartialAgentQueriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Some approved agents did not return data ({agents}). Totals may be incomplete.'**
  String dashboardPartialAgentQueriesMessage(String agents);

  /// No description provided for @dashboardMissingClientTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents without a saved client token'**
  String get dashboardMissingClientTokenTitle;

  /// No description provided for @dashboardMissingClientTokenMessage.
  ///
  /// In en, this message translates to:
  /// **'These approved agents were skipped because no local client token was saved ({agents}). Add the token on the agent screen to include their data.'**
  String dashboardMissingClientTokenMessage(String agents);

  /// No description provided for @dashboardSetupRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup required before loading data'**
  String get dashboardSetupRequiredTitle;

  /// No description provided for @dashboardSetupRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'None of the approved agents has a client token saved on this device ({agents}). Open agent management to save the token and enable overview queries.'**
  String dashboardSetupRequiredMessage(String agents);

  /// No description provided for @dashboardMultiAgentAggregationTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple agents'**
  String get dashboardMultiAgentAggregationTitle;

  /// No description provided for @dashboardMultiAgentAggregationMessage.
  ///
  /// In en, this message translates to:
  /// **'This summary merges data from several approved agents. If their databases overlap, totals may be higher than a single source.'**
  String get dashboardMultiAgentAggregationMessage;

  /// No description provided for @dashboardPaymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary by payment method'**
  String get dashboardPaymentSummaryTitle;

  /// No description provided for @dashboardPaymentSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales, average ticket, and share of revenue by method.'**
  String get dashboardPaymentSummarySubtitle;

  /// No description provided for @dashboardPaymentSummaryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No payment methods'**
  String get dashboardPaymentSummaryEmptyTitle;

  /// No description provided for @dashboardPaymentSummaryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no payment method breakdown for this period.'**
  String get dashboardPaymentSummaryEmptyMessage;

  /// No description provided for @dashboardPaymentSummaryHeaderRevenueAbbr.
  ///
  /// In en, this message translates to:
  /// **'REV.'**
  String get dashboardPaymentSummaryHeaderRevenueAbbr;

  /// No description provided for @dashboardPaymentSummaryTooltipRevenueAbbr.
  ///
  /// In en, this message translates to:
  /// **'Revenue in the selected period'**
  String get dashboardPaymentSummaryTooltipRevenueAbbr;

  /// No description provided for @dashboardPaymentSummaryHeaderParticipationAbbr.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get dashboardPaymentSummaryHeaderParticipationAbbr;

  /// No description provided for @dashboardPaymentSummaryTooltipParticipationAbbr.
  ///
  /// In en, this message translates to:
  /// **'Share of total revenue (percent)'**
  String get dashboardPaymentSummaryTooltipParticipationAbbr;

  /// No description provided for @dashboardPaymentSummaryHeaderSales.
  ///
  /// In en, this message translates to:
  /// **'SALES'**
  String get dashboardPaymentSummaryHeaderSales;

  /// No description provided for @dashboardPaymentSummaryHeaderAvgTicket.
  ///
  /// In en, this message translates to:
  /// **'AVG.\nTICKET'**
  String get dashboardPaymentSummaryHeaderAvgTicket;

  /// No description provided for @dashboardPaymentSummaryLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading payment method summary…'**
  String get dashboardPaymentSummaryLoadingSemantics;

  /// No description provided for @dashboardHomeFiltersAgentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get dashboardHomeFiltersAgentsLabel;

  /// No description provided for @dashboardHomeFiltersAgentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Load the overview to list agents.'**
  String get dashboardHomeFiltersAgentsEmptyHint;

  /// No description provided for @dashboardHomeFiltersYearMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'YEAR / MONTH'**
  String get dashboardHomeFiltersYearMonthLabel;

  /// No description provided for @dashboardHomeFiltersPeriodLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get dashboardHomeFiltersPeriodLast30Days;

  /// No description provided for @dashboardAgentRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking by agent'**
  String get dashboardAgentRankingTitle;

  /// No description provided for @dashboardAgentRankingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total revenue by agent in the period.'**
  String get dashboardAgentRankingSubtitle;

  /// No description provided for @dashboardUserRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking by operator'**
  String get dashboardUserRankingTitle;

  /// No description provided for @dashboardUserRankingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue by operator in the period.'**
  String get dashboardUserRankingSubtitle;

  /// No description provided for @overviewDefaultGreetingName.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get overviewDefaultGreetingName;

  /// No description provided for @overviewGreetingEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String overviewGreetingEyebrow(String name);

  /// No description provided for @overviewHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consolidated summary of approved agents (all connected branches).'**
  String get overviewHomeSubtitle;

  /// No description provided for @overviewLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the overview'**
  String get overviewLoadErrorTitle;

  /// No description provided for @overviewStaleCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Data saved on this device'**
  String get overviewStaleCacheTitle;

  /// No description provided for @overviewStaleCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh right now. The numbers below reflect the last summary fetched successfully.'**
  String get overviewStaleCacheMessage;

  /// No description provided for @overviewLoadingPaymentKpisSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading payment KPIs…'**
  String get overviewLoadingPaymentKpisSemantics;

  /// No description provided for @overviewLoadingPaymentMixSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading payment method mix…'**
  String get overviewLoadingPaymentMixSemantics;

  /// No description provided for @overviewLoadingPaymentBarSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading revenue by payment method…'**
  String get overviewLoadingPaymentBarSemantics;

  /// No description provided for @overviewLoadingRankingsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading rankings…'**
  String get overviewLoadingRankingsSemantics;

  /// No description provided for @overviewKpiTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get overviewKpiTotalRevenue;

  /// No description provided for @overviewKpiSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get overviewKpiSales;

  /// No description provided for @overviewKpiAvgTicket.
  ///
  /// In en, this message translates to:
  /// **'Average ticket'**
  String get overviewKpiAvgTicket;

  /// No description provided for @overviewKpiPaymentMethodCount.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get overviewKpiPaymentMethodCount;

  /// No description provided for @overviewPaymentMixTitle.
  ///
  /// In en, this message translates to:
  /// **'Mix by payment method'**
  String get overviewPaymentMixTitle;

  /// No description provided for @overviewPaymentMixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Percentage share of revenue in the period.'**
  String get overviewPaymentMixSubtitle;

  /// No description provided for @overviewPaymentMixDonutTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get overviewPaymentMixDonutTotalLabel;

  /// No description provided for @overviewPaymentBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue by payment method'**
  String get overviewPaymentBarTitle;

  /// No description provided for @overviewPaymentBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total amount accumulated in the period.'**
  String get overviewPaymentBarSubtitle;

  /// No description provided for @overviewPaymentBarTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}'**
  String overviewPaymentBarTooltip(String label, String amount);

  /// No description provided for @overviewSemanticsPaymentMethodRow.
  ///
  /// In en, this message translates to:
  /// **'Payment method {label}'**
  String overviewSemanticsPaymentMethodRow(String label);

  /// No description provided for @overviewSemanticsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue {amount}'**
  String overviewSemanticsRevenue(String amount);

  /// No description provided for @overviewSemanticsSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Sales {count}'**
  String overviewSemanticsSalesCount(String count);

  /// No description provided for @overviewSemanticsAvgTicket.
  ///
  /// In en, this message translates to:
  /// **'Average ticket {amount}'**
  String overviewSemanticsAvgTicket(String amount);

  /// No description provided for @overviewSemanticsSharePercent.
  ///
  /// In en, this message translates to:
  /// **'{value} percent'**
  String overviewSemanticsSharePercent(String value);

  /// No description provided for @overviewNoApprovedAgentsUserMessage.
  ///
  /// In en, this message translates to:
  /// **'No approved agent is available to load the overview.'**
  String get overviewNoApprovedAgentsUserMessage;

  /// No description provided for @overviewLoadFailedUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the overview.'**
  String get overviewLoadFailedUserMessage;

  /// No description provided for @overviewSaveClientTokenForAgentUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Save this agent\'s client token to query their data.'**
  String get overviewSaveClientTokenForAgentUserMessage;

  /// No description provided for @clientAgentsDataSourcesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get clientAgentsDataSourcesEyebrow;

  /// No description provided for @clientAgentsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent management'**
  String get clientAgentsPageTitle;

  /// No description provided for @clientAgentsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your approved agents, request new access, and follow the status of your requests.'**
  String get clientAgentsPageSubtitle;

  /// No description provided for @clientAgentsPendingActionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action to send} other{{count} actions to send}}'**
  String clientAgentsPendingActionsCount(int count);

  /// No description provided for @clientAgentsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get clientAgentsRefresh;

  /// No description provided for @clientAgentsSubmitRequests.
  ///
  /// In en, this message translates to:
  /// **'Send requests'**
  String get clientAgentsSubmitRequests;

  /// No description provided for @clientAgentsActionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action'**
  String get clientAgentsActionFailedTitle;

  /// No description provided for @clientAgentsMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent maintenance'**
  String get clientAgentsMaintenanceTitle;

  /// No description provided for @clientAgentsMaintenanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the tabs to see approved agents, request new access, and follow your request history.'**
  String get clientAgentsMaintenanceSubtitle;

  /// No description provided for @clientAgentsTabMyAgents.
  ///
  /// In en, this message translates to:
  /// **'My agents'**
  String get clientAgentsTabMyAgents;

  /// No description provided for @clientAgentsTabRequestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get clientAgentsTabRequestAccess;

  /// No description provided for @clientAgentsTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get clientAgentsTabRequests;

  /// No description provided for @clientAgentsLoadApprovedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load your agents'**
  String get clientAgentsLoadApprovedErrorTitle;

  /// No description provided for @clientAgentsEmptyApproved.
  ///
  /// In en, this message translates to:
  /// **'No approved agents yet. Request access in the \"{tabLabel}\" tab.'**
  String clientAgentsEmptyApproved(String tabLabel);

  /// No description provided for @clientAgentsNoTradeName.
  ///
  /// In en, this message translates to:
  /// **'No trade name'**
  String get clientAgentsNoTradeName;

  /// No description provided for @agentCatalogInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get agentCatalogInactive;

  /// No description provided for @agentCatalogActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get agentCatalogActive;

  /// No description provided for @agentConnectionOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get agentConnectionOnline;

  /// No description provided for @agentConnectionOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get agentConnectionOffline;

  /// No description provided for @agentConnectionUnknown.
  ///
  /// In en, this message translates to:
  /// **'operational status unavailable'**
  String get agentConnectionUnknown;

  /// No description provided for @clientAgentsRemoveAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove access'**
  String get clientAgentsRemoveAccess;

  /// No description provided for @clientAgentsRequestAccessIntro1.
  ///
  /// In en, this message translates to:
  /// **'Use one or more rows to request access. Each row needs an agent UUID; add the local client token when that agent requires it for SQL execution.'**
  String get clientAgentsRequestAccessIntro1;

  /// No description provided for @clientAgentsRequestAccessIntro2.
  ///
  /// In en, this message translates to:
  /// **'The agent ID must be provided by the agent owner or an external flow. When the request is approved, the agent will be released automatically for this account.'**
  String get clientAgentsRequestAccessIntro2;

  /// No description provided for @clientAgentsRequestAccessIntroToken.
  ///
  /// In en, this message translates to:
  /// **'The client token is saved only on this device (encrypted) and is not sent when you submit the access request.'**
  String get clientAgentsRequestAccessIntroToken;

  /// No description provided for @clientAgentsRequestAccessAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add agent row'**
  String get clientAgentsRequestAccessAddRow;

  /// No description provided for @clientAgentsRequestAccessRemoveRow.
  ///
  /// In en, this message translates to:
  /// **'Remove row'**
  String get clientAgentsRequestAccessRemoveRow;

  /// No description provided for @clientAgentsRequestAccessRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent {index}'**
  String clientAgentsRequestAccessRowTitle(int index);

  /// No description provided for @clientAgentsClientTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Client token (local)'**
  String get clientAgentsClientTokenLabel;

  /// No description provided for @clientAgentsClientTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — stored only on this device'**
  String get clientAgentsClientTokenHint;

  /// No description provided for @clientAgentsClientTokenShow.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get clientAgentsClientTokenShow;

  /// No description provided for @clientAgentsClientTokenHide.
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get clientAgentsClientTokenHide;

  /// No description provided for @clientAgentsAgentIdsLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent ID'**
  String get clientAgentsAgentIdsLabel;

  /// No description provided for @clientAgentsRequestAccessCta.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get clientAgentsRequestAccessCta;

  /// No description provided for @clientAgentsValidationNeedOneValidId.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one valid agent ID to continue.'**
  String get clientAgentsValidationNeedOneValidId;

  /// No description provided for @clientAgentsValidationInvalidIds.
  ///
  /// In en, this message translates to:
  /// **'The following agent IDs are invalid: {ids}.'**
  String clientAgentsValidationInvalidIds(String ids);

  /// No description provided for @clientAgentsDuplicatedIdsNote.
  ///
  /// In en, this message translates to:
  /// **'Duplicate IDs were ignored automatically: {ids}.'**
  String clientAgentsDuplicatedIdsNote(String ids);

  /// No description provided for @clientAgentsLoadRequestsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests'**
  String get clientAgentsLoadRequestsErrorTitle;

  /// No description provided for @clientAgentsLoadPendingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load pending submissions'**
  String get clientAgentsLoadPendingErrorTitle;

  /// No description provided for @clientAgentsNoRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests at the moment.'**
  String get clientAgentsNoRequestsYet;

  /// No description provided for @clientAgentsRequestStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get clientAgentsRequestStatusPending;

  /// No description provided for @clientAgentsRequestStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get clientAgentsRequestStatusApproved;

  /// No description provided for @clientAgentsRequestStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get clientAgentsRequestStatusRejected;

  /// No description provided for @clientAgentsRequestStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get clientAgentsRequestStatusExpired;

  /// No description provided for @clientAgentsRequestStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get clientAgentsRequestStatusUnknown;

  /// No description provided for @clientAgentsRequestDescPending.
  ///
  /// In en, this message translates to:
  /// **'Under review by the agent owner.'**
  String get clientAgentsRequestDescPending;

  /// No description provided for @clientAgentsRequestDescApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved and available for this account.'**
  String get clientAgentsRequestDescApproved;

  /// No description provided for @clientAgentsRequestDescRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved by the agent owner.'**
  String get clientAgentsRequestDescRejected;

  /// No description provided for @clientAgentsRequestDescExpired.
  ///
  /// In en, this message translates to:
  /// **'The request expired. Submit again if needed.'**
  String get clientAgentsRequestDescExpired;

  /// No description provided for @clientAgentsRequestDescUnknown.
  ///
  /// In en, this message translates to:
  /// **'The status of this request is not available yet.'**
  String get clientAgentsRequestDescUnknown;

  /// No description provided for @clientAgentsPendingDescQueued.
  ///
  /// In en, this message translates to:
  /// **'Ready to send.'**
  String get clientAgentsPendingDescQueued;

  /// No description provided for @clientAgentsPendingDescSyncing.
  ///
  /// In en, this message translates to:
  /// **'Sending now.'**
  String get clientAgentsPendingDescSyncing;

  /// No description provided for @clientAgentsPendingDescFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Try again.'**
  String get clientAgentsPendingDescFailed;

  /// No description provided for @clientAgentsPendingDescSynced.
  ///
  /// In en, this message translates to:
  /// **'Sent.'**
  String get clientAgentsPendingDescSynced;

  /// No description provided for @clientAgentsPendingChipRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get clientAgentsPendingChipRequest;

  /// No description provided for @clientAgentsPendingChipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get clientAgentsPendingChipRemove;

  /// No description provided for @clientAgentsPendingChipQueued.
  ///
  /// In en, this message translates to:
  /// **'ready to send'**
  String get clientAgentsPendingChipQueued;

  /// No description provided for @clientAgentsPendingChipSyncing.
  ///
  /// In en, this message translates to:
  /// **'sending'**
  String get clientAgentsPendingChipSyncing;

  /// No description provided for @clientAgentsPendingChipFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get clientAgentsPendingChipFailed;

  /// No description provided for @clientAgentsPendingChipSynced.
  ///
  /// In en, this message translates to:
  /// **'sent'**
  String get clientAgentsPendingChipSynced;

  /// No description provided for @clientAgentsPendingSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending send: {agentId}'**
  String clientAgentsPendingSendTitle(String agentId);

  /// No description provided for @clientAgentsSessionUnavailableLoad.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable to load agents.'**
  String get clientAgentsSessionUnavailableLoad;

  /// No description provided for @clientAgentsSessionUnavailableRequest.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable to request access.'**
  String get clientAgentsSessionUnavailableRequest;

  /// No description provided for @clientAgentsSessionUnavailableRemove.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable to remove access.'**
  String get clientAgentsSessionUnavailableRemove;

  /// No description provided for @clientAgentsSessionUnavailableSync.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable to sync pending items.'**
  String get clientAgentsSessionUnavailableSync;

  /// No description provided for @clientAgentDetailSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable to load the agent.'**
  String get clientAgentDetailSessionUnavailable;

  /// No description provided for @appInlineErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get appInlineErrorRetry;

  /// No description provided for @clientAgentsNoLocalPendingToSync.
  ///
  /// In en, this message translates to:
  /// **'There are no local pending items to sync.'**
  String get clientAgentsNoLocalPendingToSync;

  /// No description provided for @clientAgentsRequestBlockedFallback.
  ///
  /// In en, this message translates to:
  /// **'Could not register the requested access request.'**
  String get clientAgentsRequestBlockedFallback;

  /// No description provided for @clientAgentsRequestBlockedIntro.
  ///
  /// In en, this message translates to:
  /// **'No new agents can be requested with the IDs provided. {details}'**
  String clientAgentsRequestBlockedIntro(String details);

  /// No description provided for @clientAgentsRequestBlockedAlreadyApproved.
  ///
  /// In en, this message translates to:
  /// **'Already approved: {ids}.'**
  String clientAgentsRequestBlockedAlreadyApproved(String ids);

  /// No description provided for @clientAgentsRequestBlockedAlreadyReview.
  ///
  /// In en, this message translates to:
  /// **'Already under review: {ids}.'**
  String clientAgentsRequestBlockedAlreadyReview(String ids);

  /// No description provided for @clientAgentsRequestBlockedAlreadyQueued.
  ///
  /// In en, this message translates to:
  /// **'Already queued for sending: {ids}.'**
  String clientAgentsRequestBlockedAlreadyQueued(String ids);

  /// No description provided for @clientAgentsRequestQueuedWatchingSingle.
  ///
  /// In en, this message translates to:
  /// **'Request submitted. We will track approval automatically.'**
  String get clientAgentsRequestQueuedWatchingSingle;

  /// No description provided for @clientAgentsRequestQueuedWatchingPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} requests submitted. We will track approvals automatically.'**
  String clientAgentsRequestQueuedWatchingPlural(int count);

  /// No description provided for @clientAgentsRequestQueuedIgnoredSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} IDs were ignored because they were already approved or under review.'**
  String clientAgentsRequestQueuedIgnoredSuffix(int count);

  /// No description provided for @clientAgentsRemoveBlockedFallback.
  ///
  /// In en, this message translates to:
  /// **'Could not register the requested removal.'**
  String get clientAgentsRemoveBlockedFallback;

  /// No description provided for @clientAgentsRemoveBlockedIntro.
  ///
  /// In en, this message translates to:
  /// **'No new agents can be removed with the IDs provided. {details}'**
  String clientAgentsRemoveBlockedIntro(String details);

  /// No description provided for @clientAgentsRemoveBlockedNotApproved.
  ///
  /// In en, this message translates to:
  /// **'No approved access: {ids}.'**
  String clientAgentsRemoveBlockedNotApproved(String ids);

  /// No description provided for @clientAgentsRemoveBlockedAlreadyQueued.
  ///
  /// In en, this message translates to:
  /// **'Removal already queued for sending: {ids}.'**
  String clientAgentsRemoveBlockedAlreadyQueued(String ids);

  /// No description provided for @clientAgentsRemoveQueuedSingle.
  ///
  /// In en, this message translates to:
  /// **'Access removal prepared and queued for sync.'**
  String get clientAgentsRemoveQueuedSingle;

  /// No description provided for @clientAgentsRemoveQueuedPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} access removals prepared and queued for sync.'**
  String clientAgentsRemoveQueuedPlural(int count);

  /// No description provided for @clientAgentsRemoveQueuedIgnoredSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} IDs were ignored.'**
  String clientAgentsRemoveQueuedIgnoredSuffix(int count);

  /// No description provided for @clientAgentsSyncSuccessSingle.
  ///
  /// In en, this message translates to:
  /// **'1 request was sent for review.'**
  String get clientAgentsSyncSuccessSingle;

  /// No description provided for @clientAgentsSyncSuccessPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} requests were sent for review.'**
  String clientAgentsSyncSuccessPlural(int count);

  /// No description provided for @clientAgentsSyncSuccessAutoSuffix.
  ///
  /// In en, this message translates to:
  /// **' It was sent automatically.'**
  String get clientAgentsSyncSuccessAutoSuffix;

  /// No description provided for @clientAgentsSyncSuccessManualSuffix.
  ///
  /// In en, this message translates to:
  /// **' The screen was refreshed with the latest status.'**
  String get clientAgentsSyncSuccessManualSuffix;

  /// No description provided for @clientAgentsSyncSuccessPollingSuffix.
  ///
  /// In en, this message translates to:
  /// **' We will track approval automatically.'**
  String get clientAgentsSyncSuccessPollingSuffix;

  /// No description provided for @clientAgentsPollApprovedSingle.
  ///
  /// In en, this message translates to:
  /// **'Access approved. The agent is already available under \"{tabLabel}\".'**
  String clientAgentsPollApprovedSingle(String tabLabel);

  /// No description provided for @clientAgentsPollApprovedPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} accesses were approved. The agents are already available under \"{tabLabel}\".'**
  String clientAgentsPollApprovedPlural(int count, String tabLabel);

  /// No description provided for @clientAgentsPollDeniedSingle.
  ///
  /// In en, this message translates to:
  /// **'1 request was closed without approval.'**
  String get clientAgentsPollDeniedSingle;

  /// No description provided for @clientAgentsPollDeniedPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} requests were closed without approval.'**
  String clientAgentsPollDeniedPlural(int count);

  /// No description provided for @clientAgentsPollTimeoutSingle.
  ///
  /// In en, this message translates to:
  /// **'1 request is still under review. Refresh this screen later to check the result.'**
  String get clientAgentsPollTimeoutSingle;

  /// No description provided for @clientAgentsPollTimeoutPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} requests are still under review and you can refresh this screen later to check the result.'**
  String clientAgentsPollTimeoutPlural(int count);

  /// No description provided for @clientAgentsPollRemainingSingle.
  ///
  /// In en, this message translates to:
  /// **'There is still 1 request under review.'**
  String get clientAgentsPollRemainingSingle;

  /// No description provided for @clientAgentsPollRemainingPlural.
  ///
  /// In en, this message translates to:
  /// **'There are still {count} requests under review.'**
  String clientAgentsPollRemainingPlural(int count);

  /// No description provided for @clientAgentDetailEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get clientAgentDetailEyebrow;

  /// No description provided for @clientAgentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get clientAgentDetailTitle;

  /// No description provided for @clientAgentDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed information for the agent approved for this account.'**
  String get clientAgentDetailSubtitle;

  /// No description provided for @clientAgentDetailLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the agent'**
  String get clientAgentDetailLoadErrorTitle;

  /// No description provided for @clientAgentFieldTradeName.
  ///
  /// In en, this message translates to:
  /// **'Trade name'**
  String get clientAgentFieldTradeName;

  /// No description provided for @clientAgentFieldDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get clientAgentFieldDocument;

  /// No description provided for @clientAgentFieldCnpjCpf.
  ///
  /// In en, this message translates to:
  /// **'CNPJ/CPF'**
  String get clientAgentFieldCnpjCpf;

  /// No description provided for @clientAgentFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientAgentFieldEmail;

  /// No description provided for @clientAgentFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get clientAgentFieldPhone;

  /// No description provided for @clientAgentFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get clientAgentFieldCity;

  /// No description provided for @clientAgentValueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get clientAgentValueNotAvailable;

  /// No description provided for @clientAgentAddressNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Address not provided'**
  String get clientAgentAddressNotProvided;

  /// No description provided for @clientAgentDetailSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientAgentDetailSectionContact;

  /// No description provided for @clientAgentDetailSectionAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get clientAgentDetailSectionAddress;

  /// No description provided for @clientAgentDetailSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get clientAgentDetailSectionNotes;

  /// No description provided for @clientAgentDetailSectionRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get clientAgentDetailSectionRecord;

  /// No description provided for @clientAgentDetailSectionLocalToken.
  ///
  /// In en, this message translates to:
  /// **'Local client token'**
  String get clientAgentDetailSectionLocalToken;

  /// No description provided for @clientAgentDetailSectionLocalTokenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used only on this device for SQL queries (for example in the overview). Never sent to Colmeia servers.'**
  String get clientAgentDetailSectionLocalTokenSubtitle;

  /// No description provided for @clientAgentDetailLocalTokenSave.
  ///
  /// In en, this message translates to:
  /// **'Save token'**
  String get clientAgentDetailLocalTokenSave;

  /// No description provided for @clientAgentDetailLocalTokenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove token'**
  String get clientAgentDetailLocalTokenRemove;

  /// No description provided for @clientAgentDetailLocalTokenSaved.
  ///
  /// In en, this message translates to:
  /// **'Token saved on this device.'**
  String get clientAgentDetailLocalTokenSaved;

  /// No description provided for @clientAgentDetailLocalTokenRemoved.
  ///
  /// In en, this message translates to:
  /// **'Token removed from this device.'**
  String get clientAgentDetailLocalTokenRemoved;

  /// No description provided for @clientAgentDetailSectionEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Catalog profile'**
  String get clientAgentDetailSectionEditProfile;

  /// No description provided for @clientAgentDetailSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get clientAgentDetailSaveProfile;

  /// No description provided for @clientAgentDetailProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved on the server.'**
  String get clientAgentDetailProfileSaved;

  /// No description provided for @clientAgentDetailProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Legal name is required.'**
  String get clientAgentDetailProfileNameRequired;

  /// No description provided for @clientAgentFieldLegalName.
  ///
  /// In en, this message translates to:
  /// **'Legal name'**
  String get clientAgentFieldLegalName;

  /// No description provided for @clientAgentFieldNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get clientAgentFieldNumber;

  /// No description provided for @clientAgentFieldId.
  ///
  /// In en, this message translates to:
  /// **'Agent ID'**
  String get clientAgentFieldId;

  /// No description provided for @clientAgentFieldDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get clientAgentFieldDocumentType;

  /// No description provided for @clientAgentFieldMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get clientAgentFieldMobile;

  /// No description provided for @clientAgentFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get clientAgentFieldStatus;

  /// No description provided for @clientAgentFieldConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get clientAgentFieldConnection;

  /// No description provided for @clientAgentFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get clientAgentFieldNotes;

  /// No description provided for @clientAgentFieldObservation.
  ///
  /// In en, this message translates to:
  /// **'Observation'**
  String get clientAgentFieldObservation;

  /// No description provided for @clientAgentFieldStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get clientAgentFieldStreet;

  /// No description provided for @clientAgentFieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get clientAgentFieldDistrict;

  /// No description provided for @clientAgentFieldPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get clientAgentFieldPostalCode;

  /// No description provided for @clientAgentFieldState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get clientAgentFieldState;

  /// No description provided for @clientAgentFieldCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get clientAgentFieldCreatedAt;

  /// No description provided for @clientAgentFieldUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get clientAgentFieldUpdatedAt;

  /// No description provided for @clientAgentFieldProfileUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get clientAgentFieldProfileUpdatedAt;

  /// No description provided for @clientAgentsFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent filters'**
  String get clientAgentsFilterSheetTitle;

  /// No description provided for @clientAgentsFilterSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search agent'**
  String get clientAgentsFilterSearchLabel;

  /// No description provided for @clientAgentsFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, agentId, or trade name'**
  String get clientAgentsFilterSearchHint;

  /// No description provided for @clientAgentsFilterConnectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get clientAgentsFilterConnectionLabel;

  /// No description provided for @clientAgentsFilterConnectionOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get clientAgentsFilterConnectionOnline;

  /// No description provided for @clientAgentsFilterConnectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get clientAgentsFilterConnectionOffline;

  /// No description provided for @clientAgentsFilterConnectionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get clientAgentsFilterConnectionUnknown;

  /// No description provided for @clientAgentsFilterCatalogLabel.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get clientAgentsFilterCatalogLabel;

  /// No description provided for @clientAgentsFilterCatalogActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get clientAgentsFilterCatalogActive;

  /// No description provided for @clientAgentsFilterCatalogInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get clientAgentsFilterCatalogInactive;

  /// No description provided for @clientAgentsFilterSummarySearch.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String clientAgentsFilterSummarySearch(String query);

  /// No description provided for @clientAgentsFilterSummaryConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection: {label}'**
  String clientAgentsFilterSummaryConnection(String label);

  /// No description provided for @clientAgentsFilterSummaryCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog: {label}'**
  String clientAgentsFilterSummaryCatalog(String label);

  /// No description provided for @clientAgentsEmptyFilteredApproved.
  ///
  /// In en, this message translates to:
  /// **'No agents match the selected filters.'**
  String get clientAgentsEmptyFilteredApproved;

  /// No description provided for @clientAgentsRequestsFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Request filters'**
  String get clientAgentsRequestsFilterSheetTitle;

  /// No description provided for @clientAgentsRequestsFilterSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get clientAgentsRequestsFilterSearchLabel;

  /// No description provided for @clientAgentsRequestsFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Agent name or agent ID'**
  String get clientAgentsRequestsFilterSearchHint;

  /// No description provided for @clientAgentsRequestsFilterStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Request status'**
  String get clientAgentsRequestsFilterStatusLabel;

  /// No description provided for @clientAgentsRequestsFilterPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Queued action'**
  String get clientAgentsRequestsFilterPendingLabel;

  /// No description provided for @clientAgentsRequestsFilterSummaryRequest.
  ///
  /// In en, this message translates to:
  /// **'Request: {label}'**
  String clientAgentsRequestsFilterSummaryRequest(String label);

  /// No description provided for @clientAgentsRequestsFilterSummaryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending: {label}'**
  String clientAgentsRequestsFilterSummaryPending(String label);

  /// No description provided for @clientAgentsFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get clientAgentsFiltersTooltip;

  /// No description provided for @clientAgentsFiltersTooltipActive.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count} active)'**
  String clientAgentsFiltersTooltipActive(int count);

  /// No description provided for @clientAgentsEmptyFilteredRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests match the selected filters.'**
  String get clientAgentsEmptyFilteredRequests;

  /// No description provided for @clientAgentsPendingFilterQueued.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get clientAgentsPendingFilterQueued;

  /// No description provided for @clientAgentsPendingFilterSyncing.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get clientAgentsPendingFilterSyncing;

  /// No description provided for @clientAgentsPendingFilterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get clientAgentsPendingFilterFailed;

  /// No description provided for @clientAgentsPendingFilterSynced.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get clientAgentsPendingFilterSynced;

  /// No description provided for @reportFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportFiltersTitle;

  /// No description provided for @reportFiltersTitleWithContext.
  ///
  /// In en, this message translates to:
  /// **'Filters - {title}'**
  String reportFiltersTitleWithContext(String title);

  /// No description provided for @reportFiltersDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust the query and apply only the slices that make sense for this analysis.'**
  String get reportFiltersDescription;

  /// No description provided for @reportFiltersFieldCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 field} other{{count} fields}}'**
  String reportFiltersFieldCount(int count);

  /// No description provided for @reportFiltersRequiredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 required} other{{count} required}}'**
  String reportFiltersRequiredCount(int count);

  /// No description provided for @reportFiltersActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active} other{{count} active}}'**
  String reportFiltersActiveCount(int count);

  /// No description provided for @reportFiltersClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reportFiltersClearAction;

  /// No description provided for @reportFiltersApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get reportFiltersApplyAction;

  /// No description provided for @reportFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportFiltersButton;

  /// No description provided for @reportFiltersButtonActive.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count} active)'**
  String reportFiltersButtonActive(int count);

  /// No description provided for @reportFiltersClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reportFiltersClearTooltip;

  /// No description provided for @reportFiltersClearAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get reportFiltersClearAllTooltip;

  /// No description provided for @reportFiltersAdvancedButton.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get reportFiltersAdvancedButton;

  /// No description provided for @reportInlineFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Filter...'**
  String get reportInlineFiltersHint;

  /// No description provided for @reportInlineFiltersAllOption.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportInlineFiltersAllOption;

  /// No description provided for @reportInlineFiltersSelectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get reportInlineFiltersSelectPeriod;

  /// No description provided for @reportInlineFiltersSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get reportInlineFiltersSelectDate;

  /// No description provided for @reportFiltersAppliedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Applied filters'**
  String get reportFiltersAppliedSectionTitle;

  /// No description provided for @clientAgentsErrorLoadCatalog.
  ///
  /// In en, this message translates to:
  /// **'Could not load the agent catalog.'**
  String get clientAgentsErrorLoadCatalog;

  /// No description provided for @clientAgentsErrorLoadCatalogAgent.
  ///
  /// In en, this message translates to:
  /// **'Could not load this catalog agent.'**
  String get clientAgentsErrorLoadCatalogAgent;

  /// No description provided for @clientAgentsErrorLoadClientAccessStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not read the access request status.'**
  String get clientAgentsErrorLoadClientAccessStatus;

  /// No description provided for @clientAgentsErrorLoadApproved.
  ///
  /// In en, this message translates to:
  /// **'Could not load approved agents for this account.'**
  String get clientAgentsErrorLoadApproved;

  /// No description provided for @clientAgentsErrorLoadAgentDetail.
  ///
  /// In en, this message translates to:
  /// **'Could not load agent details.'**
  String get clientAgentsErrorLoadAgentDetail;

  /// No description provided for @clientAgentsErrorLoadAccessRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load request history.'**
  String get clientAgentsErrorLoadAccessRequests;

  /// No description provided for @clientAgentsErrorReadPending.
  ///
  /// In en, this message translates to:
  /// **'Could not load pending submissions to sync.'**
  String get clientAgentsErrorReadPending;

  /// No description provided for @clientAgentsErrorQueueRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not queue the access request for sync.'**
  String get clientAgentsErrorQueueRequest;

  /// No description provided for @clientAgentsErrorQueueRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not queue the removal for sync.'**
  String get clientAgentsErrorQueueRemove;

  /// No description provided for @clientAgentsErrorSyncAction.
  ///
  /// In en, this message translates to:
  /// **'Could not sync the change for this agent.'**
  String get clientAgentsErrorSyncAction;

  /// No description provided for @clientAgentsErrorSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Could not sync pending agent actions.'**
  String get clientAgentsErrorSyncPending;

  /// No description provided for @clientAgentsErrorAgentDocumentConflict.
  ///
  /// In en, this message translates to:
  /// **'This CNPJ/CPF is already linked to another agent in the catalog. To change the link, contact support.'**
  String get clientAgentsErrorAgentDocumentConflict;

  /// No description provided for @agentSqlErrorAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication is required to query this agent.'**
  String get agentSqlErrorAuthenticationFailed;

  /// No description provided for @agentSqlErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to query this data on this agent.'**
  String get agentSqlErrorPermissionDenied;

  /// No description provided for @agentSqlErrorTransportTimeout.
  ///
  /// In en, this message translates to:
  /// **'The agent took too long to respond. Please try again.'**
  String get agentSqlErrorTransportTimeout;

  /// No description provided for @agentSqlErrorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the agent right now. Please try again.'**
  String get agentSqlErrorNetworkError;

  /// No description provided for @agentSqlErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many query attempts were made. Please wait a moment and try again.'**
  String get agentSqlErrorRateLimited;

  /// No description provided for @agentSqlErrorValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'The query is invalid.'**
  String get agentSqlErrorValidationFailed;

  /// No description provided for @agentSqlErrorExecutionFailed.
  ///
  /// In en, this message translates to:
  /// **'The query could not be executed.'**
  String get agentSqlErrorExecutionFailed;

  /// No description provided for @agentSqlErrorTransactionFailed.
  ///
  /// In en, this message translates to:
  /// **'The query transaction could not be completed.'**
  String get agentSqlErrorTransactionFailed;

  /// No description provided for @agentSqlErrorConnectionPoolExhausted.
  ///
  /// In en, this message translates to:
  /// **'The server is busy processing queries. Please try again shortly.'**
  String get agentSqlErrorConnectionPoolExhausted;

  /// No description provided for @agentSqlErrorResultTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The query returned too much data. Narrow filters and try again.'**
  String get agentSqlErrorResultTooLarge;

  /// No description provided for @agentSqlErrorDatabaseConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the database to run the query.'**
  String get agentSqlErrorDatabaseConnectionFailed;

  /// No description provided for @agentSqlErrorQueryTimeout.
  ///
  /// In en, this message translates to:
  /// **'The query took longer than expected.'**
  String get agentSqlErrorQueryTimeout;

  /// No description provided for @agentSqlErrorInvalidDatabaseConfig.
  ///
  /// In en, this message translates to:
  /// **'This agent\'s database access configuration is invalid.'**
  String get agentSqlErrorInvalidDatabaseConfig;

  /// No description provided for @agentSqlErrorExecutionNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested execution was not found.'**
  String get agentSqlErrorExecutionNotFound;

  /// No description provided for @agentSqlErrorExecutionCancelled.
  ///
  /// In en, this message translates to:
  /// **'The query was cancelled.'**
  String get agentSqlErrorExecutionCancelled;

  /// No description provided for @agentSqlErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The query could not be completed on the agent.'**
  String get agentSqlErrorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
