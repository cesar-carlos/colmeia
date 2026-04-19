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

  /// No description provided for @shellNavSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get shellNavSalesLabel;

  /// No description provided for @shellNavSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders, revenue, and commercial KPIs'**
  String get shellNavSalesSubtitle;

  /// No description provided for @shellNavReturnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get shellNavReturnsLabel;

  /// No description provided for @shellNavReturnsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Returns, exchanges, and credit notes'**
  String get shellNavReturnsSubtitle;

  /// No description provided for @shellNavFinanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get shellNavFinanceLabel;

  /// No description provided for @shellNavFinanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cash flow, receivables, and payables'**
  String get shellNavFinanceSubtitle;

  /// No description provided for @shellNavPurchasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get shellNavPurchasesLabel;

  /// No description provided for @shellNavPurchasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers and purchase orders'**
  String get shellNavPurchasesSubtitle;

  /// No description provided for @shellNavInventoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get shellNavInventoryLabel;

  /// No description provided for @shellNavInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock levels and movements'**
  String get shellNavInventorySubtitle;

  /// No description provided for @shellPlaceholderUnderConstructionTitle.
  ///
  /// In en, this message translates to:
  /// **'Under construction'**
  String get shellPlaceholderUnderConstructionTitle;

  /// No description provided for @shellPlaceholderUnderConstructionBody.
  ///
  /// In en, this message translates to:
  /// **'This section will be available in a future update.'**
  String get shellPlaceholderUnderConstructionBody;

  /// No description provided for @shellAppBrandName.
  ///
  /// In en, this message translates to:
  /// **'Colmeia'**
  String get shellAppBrandName;

  /// No description provided for @shellOpenSettingsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get shellOpenSettingsSemantics;

  /// No description provided for @shellOpenProfileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open profile and account'**
  String get shellOpenProfileSemantics;

  /// No description provided for @shellNavSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get shellNavSignOut;

  /// No description provided for @shellNavSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get shellNavSigningOut;

  /// No description provided for @shellNavSignOutSemanticsLoading.
  ///
  /// In en, this message translates to:
  /// **'Ending session'**
  String get shellNavSignOutSemanticsLoading;

  /// No description provided for @shellSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get shellSignOutDialogTitle;

  /// No description provided for @shellSignOutDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get shellSignOutDialogConfirm;

  /// No description provided for @shellSignOutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your data.'**
  String get shellSignOutDialogMessage;

  /// No description provided for @shellNavMainSemantics.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get shellNavMainSemantics;

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

  /// No description provided for @userPermissionViewSales.
  ///
  /// In en, this message translates to:
  /// **'Sales (module access)'**
  String get userPermissionViewSales;

  /// No description provided for @userPermissionViewReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns (module access)'**
  String get userPermissionViewReturns;

  /// No description provided for @userPermissionViewFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance (module access)'**
  String get userPermissionViewFinance;

  /// No description provided for @userPermissionViewPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases (module access)'**
  String get userPermissionViewPurchases;

  /// No description provided for @userPermissionViewInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory (module access)'**
  String get userPermissionViewInventory;

  /// No description provided for @dashboardPartialAgentQueriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Incomplete overview data'**
  String get dashboardPartialAgentQueriesTitle;

  /// No description provided for @dashboardPartialAgentQueriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Some approved agents did not return data. Totals may be incomplete.'**
  String get dashboardPartialAgentQueriesMessage;

  /// No description provided for @dashboardMissingClientTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents without a saved client token'**
  String get dashboardMissingClientTokenTitle;

  /// No description provided for @dashboardMissingClientTokenMessage.
  ///
  /// In en, this message translates to:
  /// **'These approved agents were skipped because no local client token was saved. Add the token on the agent screen to include their data.'**
  String get dashboardMissingClientTokenMessage;

  /// No description provided for @overviewResumoUnknownPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method not specified'**
  String get overviewResumoUnknownPaymentMethod;

  /// No description provided for @overviewResumoUnknownUserName.
  ///
  /// In en, this message translates to:
  /// **'User not specified'**
  String get overviewResumoUnknownUserName;

  /// No description provided for @dashboardSetupRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Save a client token to load data'**
  String get dashboardSetupRequiredTitle;

  /// No description provided for @dashboardSetupRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'None of the approved agents has a client token saved on this device. Open agent management to save the token and enable overview queries.'**
  String get dashboardSetupRequiredMessage;

  /// No description provided for @dashboardViewAffectedAgentsList.
  ///
  /// In en, this message translates to:
  /// **'View list ({count})'**
  String dashboardViewAffectedAgentsList(int count);

  /// No description provided for @dashboardAffectedAgentsSheetTitlePartialFailure.
  ///
  /// In en, this message translates to:
  /// **'Agents that did not return data'**
  String get dashboardAffectedAgentsSheetTitlePartialFailure;

  /// No description provided for @dashboardAffectedAgentsSheetTitleMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Agents without a saved client token'**
  String get dashboardAffectedAgentsSheetTitleMissingToken;

  /// No description provided for @dashboardAffectedAgentsSheetTitleSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Approved agents without a client token on this device'**
  String get dashboardAffectedAgentsSheetTitleSetupRequired;

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

  /// No description provided for @dashboardHomeFiltersCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month'**
  String get dashboardHomeFiltersCurrentMonth;

  /// No description provided for @dashboardHomeFiltersPeriodLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get dashboardHomeFiltersPeriodLast30Days;

  /// No description provided for @dashboardHomeFiltersReferenceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dashboardHomeFiltersReferenceRangeLabel;

  /// No description provided for @dashboardHomeFiltersReferenceRangeHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Pick inclusive start and end — the range can span several months (up to {maxDays} days). Totals and rankings follow that span. The monthly trend still shows the 12 months ending in the last day’s month.'**
  String dashboardHomeFiltersReferenceRangeHelper(int maxDays);

  /// No description provided for @dashboardHomeFiltersReferenceRangePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get dashboardHomeFiltersReferenceRangePickerTitle;

  /// No description provided for @dashboardHomeFiltersYearMonthCustomDisplay.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dashboardHomeFiltersYearMonthCustomDisplay;

  /// No description provided for @dashboardHomeFiltersReferenceRangeMaxDurationSnackbar.
  ///
  /// In en, this message translates to:
  /// **'The selected range cannot exceed {maxDays} calendar days.'**
  String dashboardHomeFiltersReferenceRangeMaxDurationSnackbar(int maxDays);

  /// No description provided for @overviewPeriodTagCustomRangePrefix.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get overviewPeriodTagCustomRangePrefix;

  /// No description provided for @overviewAgentFilterAllAgentsSummary.
  ///
  /// In en, this message translates to:
  /// **'All agents ({count})'**
  String overviewAgentFilterAllAgentsSummary(int count);

  /// No description provided for @overviewAgentFilterSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} agents selected'**
  String overviewAgentFilterSelectedCount(int count);

  /// No description provided for @overviewAgentFilterRefineAction.
  ///
  /// In en, this message translates to:
  /// **'Refine selection'**
  String get overviewAgentFilterRefineAction;

  /// No description provided for @overviewAgentFilterEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get overviewAgentFilterEditAction;

  /// No description provided for @overviewAgentFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select agents'**
  String get overviewAgentFilterSheetTitle;

  /// No description provided for @overviewAgentFilterSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search agents…'**
  String get overviewAgentFilterSheetSearchHint;

  /// No description provided for @overviewAgentFilterSelectMatching.
  ///
  /// In en, this message translates to:
  /// **'Select all matching'**
  String get overviewAgentFilterSelectMatching;

  /// No description provided for @overviewAgentFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get overviewAgentFilterApply;

  /// No description provided for @overviewAgentFilterCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get overviewAgentFilterCancel;

  /// No description provided for @overviewAgentFilterNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No agents match your search.'**
  String get overviewAgentFilterNoSearchResults;

  /// No description provided for @overviewAgentFilterMissingClientTokenBanner.
  ///
  /// In en, this message translates to:
  /// **'Agents without a client token on this device cannot run SQL queries. “Online” only reflects hub connectivity.'**
  String get overviewAgentFilterMissingClientTokenBanner;

  /// No description provided for @overviewAgentFilterMissingClientTokenRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No client token on this device — SQL queries are skipped.'**
  String get overviewAgentFilterMissingClientTokenRowSubtitle;

  /// No description provided for @chartCategoryDonutEmptyForFilter.
  ///
  /// In en, this message translates to:
  /// **'No category data for this view.'**
  String get chartCategoryDonutEmptyForFilter;

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

  /// No description provided for @overviewAgentRankingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agent revenue in this period.'**
  String get overviewAgentRankingEmpty;

  /// No description provided for @overviewUserRankingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No operator revenue in this period.'**
  String get overviewUserRankingEmpty;

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

  /// No description provided for @overviewHomeAlertsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get overviewHomeAlertsSectionTitle;

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

  /// No description provided for @overviewLoadingMonthlyParcelsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading last 12 months chart…'**
  String get overviewLoadingMonthlyParcelsSemantics;

  /// Screen reader label while the weekday overview card is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading sales by weekday chart…'**
  String get overviewLoadingWeekdaySalesSemantics;

  /// No description provided for @overviewMonthlyParcelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get overviewMonthlyParcelsTitle;

  /// No description provided for @overviewMonthlyParcelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales count and parcel totals by month (all branches in scope).'**
  String get overviewMonthlyParcelsSubtitle;

  /// No description provided for @overviewMonthlyParcelsSalesSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get overviewMonthlyParcelsSalesSeriesLabel;

  /// No description provided for @overviewMonthlyParcelsAmountSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Parcel amount'**
  String get overviewMonthlyParcelsAmountSeriesLabel;

  /// No description provided for @overviewMonthlyParcelsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No monthly data for this period.'**
  String get overviewMonthlyParcelsEmpty;

  /// No description provided for @overviewMonthlyParcelsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the monthly chart. Try again later.'**
  String get overviewMonthlyParcelsLoadFailed;

  /// No description provided for @overviewMonthlyParcelsChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Last twelve months sales and parcel amount chart'**
  String get overviewMonthlyParcelsChartSemantics;

  /// No description provided for @overviewMonthlyParcelsSubtitleValueView.
  ///
  /// In en, this message translates to:
  /// **'Parcel totals and sales counts by month (all branches in scope).'**
  String get overviewMonthlyParcelsSubtitleValueView;

  /// No description provided for @overviewMonthlyParcelsSwitchSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get overviewMonthlyParcelsSwitchSalesLabel;

  /// No description provided for @overviewMonthlyParcelsSwitchValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Parcel value'**
  String get overviewMonthlyParcelsSwitchValueLabel;

  /// No description provided for @overviewMonthlyParcelsChartSemanticsValueView.
  ///
  /// In en, this message translates to:
  /// **'Last twelve months parcel amounts and sales counts chart'**
  String get overviewMonthlyParcelsChartSemanticsValueView;

  /// Card title when the weekday overview chart is plotting sales count.
  ///
  /// In en, this message translates to:
  /// **'Sales by weekday'**
  String get overviewWeekdaySalesTitle;

  /// Card title when the weekday overview chart is plotting parcel amount.
  ///
  /// In en, this message translates to:
  /// **'Revenue by weekday'**
  String get overviewWeekdayRevenueTitle;

  /// Shared subtitle for the weekday overview card, clarifying that all branches in scope are aggregated.
  ///
  /// In en, this message translates to:
  /// **'Weekday distribution in the selected period (all branches in scope).'**
  String get overviewWeekdaySalesSubtitle;

  /// Placeholder shown when the weekday overview chart has no data.
  ///
  /// In en, this message translates to:
  /// **'No weekday data for this period.'**
  String get overviewWeekdaySalesEmpty;

  /// Placeholder shown when the weekday overview chart query fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load the weekday chart. Try again later.'**
  String get overviewWeekdaySalesLoadFailed;

  /// Semantic label for the weekday overview chart when the primary metric is sales count.
  ///
  /// In en, this message translates to:
  /// **'Weekday sales count and parcel amount chart'**
  String get overviewWeekdaySalesChartSemantics;

  /// Semantic label for the weekday overview chart when the primary metric is parcel amount.
  ///
  /// In en, this message translates to:
  /// **'Weekday revenue and sales count chart'**
  String get overviewWeekdayRevenueChartSemantics;

  /// Additional semantic hint clarifying that the weekday chart aggregates all branches in scope.
  ///
  /// In en, this message translates to:
  /// **'Aggregated across all branches in the selected scope.'**
  String get overviewWeekdayChartScopeHint;

  /// Tooltip for one weekday bar showing sales count and parcel amount.
  ///
  /// In en, this message translates to:
  /// **'{weekday}: {salesCount} sales - {salesAmount}'**
  String overviewWeekdaySalesTooltip(
    String weekday,
    String salesCount,
    String salesAmount,
  );

  /// Segment label for plotting sales count in the weekday overview card.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get overviewWeekdayMetricSalesCountLabel;

  /// Segment label for plotting parcel amount in the weekday overview card.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get overviewWeekdayMetricSalesAmountLabel;

  /// Concise screen reader summary for the weekday overview chart when sales count is selected.
  ///
  /// In en, this message translates to:
  /// **'Total {totalSalesCount} sales and {totalSalesAmount} in the selected period. Highest day: {topWeekday} with {topSalesCount} sales.'**
  String overviewWeekdaySalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topSalesCount,
  );

  /// Concise screen reader summary for the weekday overview chart when parcel amount is selected.
  ///
  /// In en, this message translates to:
  /// **'Total {totalSalesAmount} and {totalSalesCount} sales in the selected period. Highest day: {topWeekday} with {topSalesAmount}.'**
  String overviewWeekdayRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topSalesAmount,
  );

  /// Localized label for weekday Sunday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get overviewWeekdaySunday;

  /// Localized label for weekday Monday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get overviewWeekdayMonday;

  /// Localized label for weekday Tuesday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get overviewWeekdayTuesday;

  /// Localized label for weekday Wednesday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get overviewWeekdayWednesday;

  /// Localized label for weekday Thursday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get overviewWeekdayThursday;

  /// Localized label for weekday Friday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get overviewWeekdayFriday;

  /// Localized label for weekday Saturday in the overview chart.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get overviewWeekdaySaturday;

  /// Card title when the per-user weekday overview chart plots sales count.
  ///
  /// In en, this message translates to:
  /// **'Sales by weekday and user'**
  String get overviewWeekdayUserSalesTitle;

  /// Card title when the per-user weekday overview chart plots parcel amount.
  ///
  /// In en, this message translates to:
  /// **'Revenue by weekday and user'**
  String get overviewWeekdayUserRevenueTitle;

  /// Subtitle for the per-user weekday overview card.
  ///
  /// In en, this message translates to:
  /// **'Weekdays on the horizontal axis; each colour is a user (see legend). Same period and branch scope as the dashboard.'**
  String get overviewWeekdayUserSalesSubtitle;

  /// Placeholder when the per-user weekday chart has no data.
  ///
  /// In en, this message translates to:
  /// **'No per-user weekday data for this period.'**
  String get overviewWeekdayUserSalesEmpty;

  /// Placeholder when the per-user weekday chart query fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load the per-user weekday chart. Try again later.'**
  String get overviewWeekdayUserSalesLoadFailed;

  /// Semantics label when the primary metric is sales count.
  ///
  /// In en, this message translates to:
  /// **'Weekday and user sales count and parcel amount chart'**
  String get overviewWeekdayUserSalesChartSemantics;

  /// Semantics label when the primary metric is parcel amount.
  ///
  /// In en, this message translates to:
  /// **'Weekday and user revenue and sales count chart'**
  String get overviewWeekdayUserRevenueChartSemantics;

  /// Semantic hint for the per-user weekday chart scope.
  ///
  /// In en, this message translates to:
  /// **'Aggregated across all branches in the selected scope.'**
  String get overviewWeekdayUserChartScopeHint;

  /// Legend and tooltip label for users combined when the grouped weekday chart exceeds the series limit.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get overviewWeekdayUserGroupedOthersLabel;

  /// Footnote when the grouped weekday-by-user chart merges extra users into an Others series.
  ///
  /// In en, this message translates to:
  /// **'Showing the {shown} users with the highest totals; additional users are summed under \"{othersLabel}\".'**
  String overviewWeekdayUserGroupedTruncationFootnote(
    int shown,
    String othersLabel,
  );

  /// Tooltip for one per-user weekday bar.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {userName}: {salesCount} sales - {salesAmount}'**
  String overviewWeekdayUserSalesTooltip(
    String weekday,
    String userName,
    String salesCount,
    String salesAmount,
  );

  /// Screen reader summary for per-user weekday chart when sales count is selected.
  ///
  /// In en, this message translates to:
  /// **'Total {totalSalesCount} sales and {totalSalesAmount} in the selected period. Highest bar: {topWeekday}, {topUserName} with {topSalesCount} sales.'**
  String overviewWeekdayUserSalesSummarySemantics(
    String totalSalesCount,
    String totalSalesAmount,
    String topWeekday,
    String topUserName,
    String topSalesCount,
  );

  /// Screen reader summary for per-user weekday chart when parcel amount is selected.
  ///
  /// In en, this message translates to:
  /// **'Total {totalSalesAmount} and {totalSalesCount} sales in the selected period. Highest bar: {topWeekday}, {topUserName} with {topSalesAmount}.'**
  String overviewWeekdayUserRevenueSummarySemantics(
    String totalSalesAmount,
    String totalSalesCount,
    String topWeekday,
    String topUserName,
    String topSalesAmount,
  );

  /// Screen reader label while the per-user weekday overview card is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading sales by weekday and user chart…'**
  String get overviewLoadingWeekdayUserSalesSemantics;

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

  /// No description provided for @overviewCategoryMixTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales by category'**
  String get overviewCategoryMixTitle;

  /// No description provided for @overviewCategoryMixDonutAnnualTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'ANNUAL TOTAL'**
  String get overviewCategoryMixDonutAnnualTotalLabel;

  /// No description provided for @overviewCategoryMixMoreOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get overviewCategoryMixMoreOptionsTooltip;

  /// No description provided for @overviewCategoryMixMenuComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Menu coming soon.'**
  String get overviewCategoryMixMenuComingSoon;

  /// No description provided for @appCategoryDonutCardLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading category chart…'**
  String get appCategoryDonutCardLoadingSemantics;

  /// No description provided for @appCategoryDonutCardEmptySemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, no data'**
  String appCategoryDonutCardEmptySemantics(String title);

  /// No description provided for @appCategoryDonutCardCategoriesSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {count} categories'**
  String appCategoryDonutCardCategoriesSemantics(String title, int count);

  /// No description provided for @appCategoryDonutChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Doughnut chart. {summary}'**
  String appCategoryDonutChartSemantics(String summary);

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

  /// Shown when every payment method has zero revenue for the period.
  ///
  /// In en, this message translates to:
  /// **'No payment method revenue in this period.'**
  String get overviewPaymentBarEmpty;

  /// No description provided for @overviewPaymentBarTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}'**
  String overviewPaymentBarTooltip(String label, String amount);

  /// No description provided for @overviewComparisonChartLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading comparison chart…'**
  String get overviewComparisonChartLoading;

  /// No description provided for @overviewComparisonBarHorizontalScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe horizontally to see all items.'**
  String get overviewComparisonBarHorizontalScrollHint;

  /// No description provided for @chartComparisonPlotFloorNotice.
  ///
  /// In en, this message translates to:
  /// **'Very small bars are drawn with a minimum height for readability. Values on labels are exact.'**
  String get chartComparisonPlotFloorNotice;

  /// No description provided for @chartComparisonExtremeValueSpreadNotice.
  ///
  /// In en, this message translates to:
  /// **'Some values differ by orders of magnitude; check units or aggregation if totals look wrong.'**
  String get chartComparisonExtremeValueSpreadNotice;

  /// No description provided for @chartComparisonLoadingDefault.
  ///
  /// In en, this message translates to:
  /// **'Loading comparison chart…'**
  String get chartComparisonLoadingDefault;

  /// No description provided for @chartComparisonEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'Nothing to compare right now.'**
  String get chartComparisonEmptyDefault;

  /// No description provided for @chartComparisonPanGestureHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe the chart sideways to see more categories.'**
  String get chartComparisonPanGestureHint;

  /// No description provided for @chartComboLoadingDefault.
  ///
  /// In en, this message translates to:
  /// **'Loading bar and line chart…'**
  String get chartComboLoadingDefault;

  /// No description provided for @chartComboEmptyDefault.
  ///
  /// In en, this message translates to:
  /// **'No combined data for this view.'**
  String get chartComboEmptyDefault;

  /// Footer hint when category-axis pan is enabled on bar+line combo charts.
  ///
  /// In en, this message translates to:
  /// **'Swipe sideways along the chart to see more periods.'**
  String get chartComboPanGestureHint;

  /// Screen reader summary when the combo chart uses horizontal pan on the category axis.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Bar and line chart, one category.} other{Bar and line chart, {count} categories.}} Swipe horizontally to see all.'**
  String chartComboPanChartA11y(int count);

  /// Screen reader summary when the comparison chart uses horizontal panning for categories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Bar chart, one category.} other{Bar chart, {count} categories.}} Swipe the chart horizontally to see all.'**
  String chartComparisonPanChartA11y(int count);

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
  /// **'Connection status unknown'**
  String get agentConnectionUnknown;

  /// No description provided for @clientAgentsRemoveAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove access'**
  String get clientAgentsRemoveAccess;

  /// No description provided for @clientAgentsApprovedBulkSelect.
  ///
  /// In en, this message translates to:
  /// **'Select for bulk removal'**
  String get clientAgentsApprovedBulkSelect;

  /// No description provided for @clientAgentsApprovedBulkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get clientAgentsApprovedBulkCancel;

  /// No description provided for @clientAgentsApprovedBulkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove selected ({count})'**
  String clientAgentsApprovedBulkRemove(int count);

  /// No description provided for @clientAgentsBulkRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue removal for multiple agents?'**
  String get clientAgentsBulkRemoveConfirmTitle;

  /// No description provided for @clientAgentsBulkRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Access removal for {count} agents will be prepared and sent on the next sync.'**
  String clientAgentsBulkRemoveConfirmMessage(int count);

  /// No description provided for @clientAgentsBulkRemoveConfirmBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get clientAgentsBulkRemoveConfirmBack;

  /// No description provided for @clientAgentsBulkRemoveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Queue removal'**
  String get clientAgentsBulkRemoveConfirmAction;

  /// No description provided for @clientAgentsApprovedBulkSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get clientAgentsApprovedBulkSelectAll;

  /// No description provided for @clientAgentsApprovedBulkClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clientAgentsApprovedBulkClearSelection;

  /// No description provided for @clientAgentsRequestAccessIntro1.
  ///
  /// In en, this message translates to:
  /// **'Use one or more rows to request access. Each row needs an agent UUID; add the client token when that agent requires it for SQL execution.'**
  String get clientAgentsRequestAccessIntro1;

  /// No description provided for @clientAgentsRequestAccessIntro2.
  ///
  /// In en, this message translates to:
  /// **'The agent ID must be provided by the agent owner or an external flow. When the request is approved, the agent will be released automatically for this account.'**
  String get clientAgentsRequestAccessIntro2;

  /// No description provided for @clientAgentsRequestAccessIntroToken.
  ///
  /// In en, this message translates to:
  /// **'The client token is cached on this device while approval is pending and pushed to the Colmeia server as soon as the agent is linked.'**
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
  /// **'Client token'**
  String get clientAgentsClientTokenLabel;

  /// No description provided for @clientAgentsClientTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — cached locally, pushed to the server after approval'**
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

  /// No description provided for @clientAgentsValidationTokenTooLong.
  ///
  /// In en, this message translates to:
  /// **'The client token must be {limit} characters or fewer. Shorten it for: {ids}.'**
  String clientAgentsValidationTokenTooLong(int limit, String ids);

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
  /// **'Unknown'**
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

  /// Compact label rendered on a disabled retry button while a Retry-After cooldown is active.
  ///
  /// In en, this message translates to:
  /// **'Retry in {seconds}s'**
  String appInlineErrorRetryCountdown(int seconds);

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

  /// No description provided for @clientAgentsRequestRelinkUpdatedSingle.
  ///
  /// In en, this message translates to:
  /// **'That agent is already approved on the server. Your agent list was updated.'**
  String get clientAgentsRequestRelinkUpdatedSingle;

  /// No description provided for @clientAgentsRequestRelinkUpdatedPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} agents were already approved on the server. Your agent list was updated.'**
  String clientAgentsRequestRelinkUpdatedPlural(int count);

  /// No description provided for @clientAgentsRequestRelinkAndQueued.
  ///
  /// In en, this message translates to:
  /// **'{relinkSummary}. {queueSummary}'**
  String clientAgentsRequestRelinkAndQueued(
    String relinkSummary,
    String queueSummary,
  );

  /// No description provided for @clientAgentsRelinkPendingNotCleared.
  ///
  /// In en, this message translates to:
  /// **'Could not clear local pending requests; they may retry on the next sync.'**
  String get clientAgentsRelinkPendingNotCleared;

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
  /// **'1 pending action finished syncing.'**
  String get clientAgentsSyncSuccessSingle;

  /// No description provided for @clientAgentsSyncSuccessPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} pending actions finished syncing.'**
  String clientAgentsSyncSuccessPlural(int count);

  /// No description provided for @clientAgentsSyncSuccessNoneCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync finished but no pending actions could be applied.'**
  String get clientAgentsSyncSuccessNoneCompleted;

  /// No description provided for @clientAgentsSyncRetryAfterCountdown.
  ///
  /// In en, this message translates to:
  /// **'The server asked us to wait. Try again in {seconds}s.'**
  String clientAgentsSyncRetryAfterCountdown(int seconds);

  /// No description provided for @clientAgentsRequestAccessRetryAfterCountdown.
  ///
  /// In en, this message translates to:
  /// **'Too many access requests. Try again in {seconds}s.'**
  String clientAgentsRequestAccessRetryAfterCountdown(int seconds);

  /// No description provided for @clientAgentsSyncSuccessSomeFailedSuffix.
  ///
  /// In en, this message translates to:
  /// **' {count} action(s) failed and remain queued to retry.'**
  String clientAgentsSyncSuccessSomeFailedSuffix(int count);

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

  /// No description provided for @clientAgentsSyncSuccessAlreadyApprovedSingle.
  ///
  /// In en, this message translates to:
  /// **' One agent was already approved on the server.'**
  String get clientAgentsSyncSuccessAlreadyApprovedSingle;

  /// No description provided for @clientAgentsSyncSuccessAlreadyApprovedPlural.
  ///
  /// In en, this message translates to:
  /// **' {count} agents were already approved on the server.'**
  String clientAgentsSyncSuccessAlreadyApprovedPlural(int count);

  /// No description provided for @clientAgentsSyncSuccessDebouncedSingle.
  ///
  /// In en, this message translates to:
  /// **' One request was refreshed recently (no new email).'**
  String get clientAgentsSyncSuccessDebouncedSingle;

  /// No description provided for @clientAgentsSyncSuccessDebouncedPlural.
  ///
  /// In en, this message translates to:
  /// **' {count} requests were refreshed recently (no new email).'**
  String clientAgentsSyncSuccessDebouncedPlural(int count);

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

  /// No description provided for @clientAgentDetailSectionServerToken.
  ///
  /// In en, this message translates to:
  /// **'Client token'**
  String get clientAgentDetailSectionServerToken;

  /// No description provided for @clientAgentDetailSectionServerTokenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stored on the Colmeia server and forwarded to the agent as `params.client_token` when this client runs SQL through the bridge. The token is also cached on this device so dashboards keep working briefly while offline.'**
  String get clientAgentDetailSectionServerTokenSubtitle;

  /// No description provided for @clientAgentDetailServerTokenSave.
  ///
  /// In en, this message translates to:
  /// **'Save token'**
  String get clientAgentDetailServerTokenSave;

  /// No description provided for @clientAgentDetailServerTokenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove token'**
  String get clientAgentDetailServerTokenRemove;

  /// No description provided for @clientAgentDetailServerTokenSaved.
  ///
  /// In en, this message translates to:
  /// **'Token saved on the server.'**
  String get clientAgentDetailServerTokenSaved;

  /// No description provided for @clientAgentDetailServerTokenRemoved.
  ///
  /// In en, this message translates to:
  /// **'Token removed from the server.'**
  String get clientAgentDetailServerTokenRemoved;

  /// No description provided for @clientAgentDetailServerTokenStatusConfigured.
  ///
  /// In en, this message translates to:
  /// **'A token is configured for this agent on the server.'**
  String get clientAgentDetailServerTokenStatusConfigured;

  /// No description provided for @clientAgentDetailServerTokenStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'No token configured on the server yet.'**
  String get clientAgentDetailServerTokenStatusMissing;

  /// No description provided for @clientAgentDetailServerTokenStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Token status not loaded yet — refresh the screen with internet access to confirm.'**
  String get clientAgentDetailServerTokenStatusUnknown;

  /// No description provided for @clientAgentDetailServerTokenLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the current token from the server. Showing the last value cached on this device, if any.'**
  String get clientAgentDetailServerTokenLoadError;

  /// No description provided for @clientAgentDetailRefreshFromAgent.
  ///
  /// In en, this message translates to:
  /// **'Refresh from agent'**
  String get clientAgentDetailRefreshFromAgent;

  /// No description provided for @clientAgentDetailRefreshFromAgentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile refreshed straight from the agent.'**
  String get clientAgentDetailRefreshFromAgentSuccess;

  /// No description provided for @clientAgentDetailRefreshFromAgentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This agent does not implement agent.getProfile via RPC.'**
  String get clientAgentDetailRefreshFromAgentUnsupported;

  /// No description provided for @clientAgentDetailRetryAfterCountdown.
  ///
  /// In en, this message translates to:
  /// **'The server asked us to wait. Try again in {seconds}s.'**
  String clientAgentDetailRetryAfterCountdown(int seconds);

  /// No description provided for @clientAgentDetailSectionPolicy.
  ///
  /// In en, this message translates to:
  /// **'Permissions of this token'**
  String get clientAgentDetailSectionPolicy;

  /// No description provided for @clientAgentDetailSectionPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resolved by the agent for the bearer token currently stored on the server. If the policy changes after a revocation or scope edit, refresh the screen.'**
  String get clientAgentDetailSectionPolicySubtitle;

  /// No description provided for @clientAgentDetailPolicyFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full access (all tables, views and permissions).'**
  String get clientAgentDetailPolicyFullAccess;

  /// No description provided for @clientAgentDetailPolicyAllTables.
  ///
  /// In en, this message translates to:
  /// **'Allowed on every table.'**
  String get clientAgentDetailPolicyAllTables;

  /// No description provided for @clientAgentDetailPolicyAllViews.
  ///
  /// In en, this message translates to:
  /// **'Allowed on every view.'**
  String get clientAgentDetailPolicyAllViews;

  /// No description provided for @clientAgentDetailPolicyAllPermissions.
  ///
  /// In en, this message translates to:
  /// **'Holds every permission flag.'**
  String get clientAgentDetailPolicyAllPermissions;

  /// No description provided for @clientAgentDetailPolicyTablesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed tables'**
  String get clientAgentDetailPolicyTablesLabel;

  /// No description provided for @clientAgentDetailPolicyViewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed views'**
  String get clientAgentDetailPolicyViewsLabel;

  /// No description provided for @clientAgentDetailPolicyPermissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get clientAgentDetailPolicyPermissionsLabel;

  /// No description provided for @clientAgentDetailPolicyRevoked.
  ///
  /// In en, this message translates to:
  /// **'This token is reported as revoked by the agent.'**
  String get clientAgentDetailPolicyRevoked;

  /// CTA shown next to the revoked-token banner; scrolls the token card into view and focuses its input.
  ///
  /// In en, this message translates to:
  /// **'Save new token'**
  String get clientAgentDetailPolicyRevokedSaveNewToken;

  /// No description provided for @clientAgentDetailPolicyUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This agent does not expose token policy introspection.'**
  String get clientAgentDetailPolicyUnsupported;

  /// No description provided for @clientAgentDetailPolicyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Agent did not return any rule for this token.'**
  String get clientAgentDetailPolicyEmpty;

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
  /// **'Unknown'**
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

  /// No description provided for @clientAgentsErrorProbeApproved.
  ///
  /// In en, this message translates to:
  /// **'Could not verify whether the agent is already linked for this account.'**
  String get clientAgentsErrorProbeApproved;

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

  /// No description provided for @clientAgentsErrorGetClientAgentToken.
  ///
  /// In en, this message translates to:
  /// **'Could not read the agent token from the server.'**
  String get clientAgentsErrorGetClientAgentToken;

  /// No description provided for @clientAgentsErrorSaveClientAgentToken.
  ///
  /// In en, this message translates to:
  /// **'Could not save the agent token on the server.'**
  String get clientAgentsErrorSaveClientAgentToken;

  /// No description provided for @clientAgentsErrorRemoveClientAgentToken.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the agent token on the server.'**
  String get clientAgentsErrorRemoveClientAgentToken;

  /// No description provided for @clientAgentsErrorAgentDocumentConflict.
  ///
  /// In en, this message translates to:
  /// **'This CNPJ/CPF is already linked to another agent in the catalog. To change the link, contact support.'**
  String get clientAgentsErrorAgentDocumentConflict;

  /// No description provided for @clientAgentsErrorAgentProfileCasMismatch.
  ///
  /// In en, this message translates to:
  /// **'Another device updated this agent in the meantime. Reload the screen and reapply your changes.'**
  String get clientAgentsErrorAgentProfileCasMismatch;

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

  /// No description provided for @formsDemoEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Forms'**
  String get formsDemoEyebrow;

  /// No description provided for @formsDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared fields'**
  String get formsDemoTitle;

  /// No description provided for @formsDemoIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Validation, enabled and disabled states, date pickers in Form, FormBuilder as in reports and groupings.'**
  String get formsDemoIntroSubtitle;

  /// No description provided for @formsDemoFieldLibraryOverline.
  ///
  /// In en, this message translates to:
  /// **'Field library'**
  String get formsDemoFieldLibraryOverline;

  /// No description provided for @formsDemoSharedFormControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared form controls'**
  String get formsDemoSharedFormControlsTitle;

  /// No description provided for @formsDemoPreviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get formsDemoPreviewBadge;

  /// No description provided for @formsDemoShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Base fields, selectors, and calendar wrappers in the same visual rhythm as the system.'**
  String get formsDemoShowcaseSubtitle;

  /// No description provided for @formsDemoFieldsEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Fields enabled'**
  String get formsDemoFieldsEnabledLabel;

  /// No description provided for @formsDemoShowcaseFieldsEnabledHelper.
  ///
  /// In en, this message translates to:
  /// **'Turns the entire example surface below on or off.'**
  String get formsDemoShowcaseFieldsEnabledHelper;

  /// No description provided for @formsDemoFormStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Form state'**
  String get formsDemoFormStateTitle;

  /// No description provided for @formsDemoFormStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to inspect disabled fields.'**
  String get formsDemoFormStateSubtitle;

  /// No description provided for @formsDemoFormStateFieldsEnabledHelper.
  ///
  /// In en, this message translates to:
  /// **'Applies the disabled state to every example below.'**
  String get formsDemoFormStateFieldsEnabledHelper;

  /// No description provided for @formsDemoTextEmailPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'AppTextField, email, and password'**
  String get formsDemoTextEmailPasswordTitle;

  /// No description provided for @formsDemoTextEmailPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fake data; submit runs validation.'**
  String get formsDemoTextEmailPasswordSubtitle;

  /// No description provided for @formsDemoFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get formsDemoFullNameLabel;

  /// No description provided for @formsDemoFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'As in registration'**
  String get formsDemoFullNameHint;

  /// No description provided for @formsDemoNameValidatorMinLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters.'**
  String get formsDemoNameValidatorMinLength;

  /// No description provided for @formsDemoCorporateEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get formsDemoCorporateEmailLabel;

  /// No description provided for @formsDemoPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get formsDemoPasswordLabel;

  /// No description provided for @formsDemoNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get formsDemoNotesLabel;

  /// No description provided for @formsDemoNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get formsDemoNotesHint;

  /// No description provided for @formsDemoDatePickersFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Date pickers in Form'**
  String get formsDemoDatePickersFormTitle;

  /// No description provided for @formsDemoDatePickersFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Native Form + FormField. Tap Apply in the sheet to confirm; closing without applying keeps the current value. Remove clears explicitly.'**
  String get formsDemoDatePickersFormSubtitle;

  /// No description provided for @formsDemoReferenceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference date'**
  String get formsDemoReferenceDateLabel;

  /// No description provided for @formsDemoReferenceDateHelper.
  ///
  /// In en, this message translates to:
  /// **'Opens in a bottom sheet with a styled calendar.'**
  String get formsDemoReferenceDateHelper;

  /// No description provided for @formsDemoSelectReferenceDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select reference date'**
  String get formsDemoSelectReferenceDateTitle;

  /// No description provided for @formsDemoReferenceDateRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select the reference date.'**
  String get formsDemoReferenceDateRequiredError;

  /// No description provided for @formsDemoAssessmentPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Desired capture period'**
  String get formsDemoAssessmentPeriodLabel;

  /// No description provided for @formsDemoAssessmentPeriodHelper.
  ///
  /// In en, this message translates to:
  /// **'Ideal for filters and analytical queries.'**
  String get formsDemoAssessmentPeriodHelper;

  /// No description provided for @formsDemoSelectPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get formsDemoSelectPeriodTitle;

  /// No description provided for @formsDemoAssessmentPeriodRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select the full period.'**
  String get formsDemoAssessmentPeriodRequiredError;

  /// No description provided for @formsDemoDateRangeMiddle.
  ///
  /// In en, this message translates to:
  /// **' to '**
  String get formsDemoDateRangeMiddle;

  /// No description provided for @formsDemoCheckboxTitle.
  ///
  /// In en, this message translates to:
  /// **'AppCheckboxField'**
  String get formsDemoCheckboxTitle;

  /// No description provided for @formsDemoCheckboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fictitious consent.'**
  String get formsDemoCheckboxSubtitle;

  /// No description provided for @formsDemoCheckboxLabel.
  ///
  /// In en, this message translates to:
  /// **'Receive a weekly summary by email'**
  String get formsDemoCheckboxLabel;

  /// No description provided for @formsDemoCheckboxHelper.
  ///
  /// In en, this message translates to:
  /// **'Sends alerts, summaries, and indicator updates.'**
  String get formsDemoCheckboxHelper;

  /// No description provided for @formsDemoRadioCompactTitle.
  ///
  /// In en, this message translates to:
  /// **'Compact AppRadioGroup'**
  String get formsDemoRadioCompactTitle;

  /// No description provided for @formsDemoRadioCompactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Single selection using the design system inline pattern.'**
  String get formsDemoRadioCompactSubtitle;

  /// No description provided for @formsDemoPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get formsDemoPeriodDaily;

  /// No description provided for @formsDemoPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get formsDemoPeriodMonthly;

  /// No description provided for @formsDemoPeriodQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get formsDemoPeriodQuarterly;

  /// No description provided for @formsDemoChoiceChipTitle.
  ///
  /// In en, this message translates to:
  /// **'AppChoiceChip'**
  String get formsDemoChoiceChipTitle;

  /// No description provided for @formsDemoChoiceChipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point-in-time chips for context, store, or scope.'**
  String get formsDemoChoiceChipSubtitle;

  /// No description provided for @formsDemoScopeHeadquarters.
  ///
  /// In en, this message translates to:
  /// **'Head office'**
  String get formsDemoScopeHeadquarters;

  /// No description provided for @formsDemoScopeStoreCenter.
  ///
  /// In en, this message translates to:
  /// **'Downtown store'**
  String get formsDemoScopeStoreCenter;

  /// No description provided for @formsDemoScopeStoreSouth.
  ///
  /// In en, this message translates to:
  /// **'South store'**
  String get formsDemoScopeStoreSouth;

  /// No description provided for @formsDemoDropdownMenusTitle.
  ///
  /// In en, this message translates to:
  /// **'Dropdown menus'**
  String get formsDemoDropdownMenusTitle;

  /// No description provided for @formsDemoDropdownMenusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Single-select and multi-select search in the same light/dark visual pattern as the references.'**
  String get formsDemoDropdownMenusSubtitle;

  /// No description provided for @formsDemoStandardSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard select'**
  String get formsDemoStandardSelectLabel;

  /// No description provided for @formsDemoSelectHiveNodeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Hive node…'**
  String get formsDemoSelectHiveNodeHint;

  /// No description provided for @formsDemoMultiSelectSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Multi-select search'**
  String get formsDemoMultiSelectSearchLabel;

  /// No description provided for @formsDemoHiveNodeAlphaCore.
  ///
  /// In en, this message translates to:
  /// **'Alpha Core'**
  String get formsDemoHiveNodeAlphaCore;

  /// No description provided for @formsDemoHiveNodeDeltaNode.
  ///
  /// In en, this message translates to:
  /// **'Delta Node'**
  String get formsDemoHiveNodeDeltaNode;

  /// No description provided for @formsDemoHiveNodeSigmaGrid.
  ///
  /// In en, this message translates to:
  /// **'Sigma Grid'**
  String get formsDemoHiveNodeSigmaGrid;

  /// No description provided for @formsDemoTagAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get formsDemoTagAnalytics;

  /// No description provided for @formsDemoTagCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get formsDemoTagCloud;

  /// No description provided for @formsDemoTagAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get formsDemoTagAutomation;

  /// No description provided for @formsDemoTagSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get formsDemoTagSecurity;

  /// No description provided for @formsDemoFormBuilderSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'FormBuilder with dropdowns and dates'**
  String get formsDemoFormBuilderSectionTitle;

  /// No description provided for @formsDemoFormBuilderSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same wrappers as reports: dropdown, multi-select, and the same date pickers as the Form section above (FormBuilderField + AppFormBuilderDate*).'**
  String get formsDemoFormBuilderSectionSubtitle;

  /// No description provided for @formsDemoFormBuilderNodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select node (FormBuilder)'**
  String get formsDemoFormBuilderNodeLabel;

  /// No description provided for @formsDemoFormBuilderNodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Single selection with the shared wrapper.'**
  String get formsDemoFormBuilderNodeHelper;

  /// No description provided for @formsDemoFormBuilderTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (FormBuilder)'**
  String get formsDemoFormBuilderTagsLabel;

  /// No description provided for @formsDemoFormBuilderTagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Inline search with removable chips.'**
  String get formsDemoFormBuilderTagsHelper;

  /// No description provided for @formsDemoFormBuilderDateRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required date (FormBuilder)'**
  String get formsDemoFormBuilderDateRequiredLabel;

  /// No description provided for @formsDemoFormBuilderDateRequiredHelper.
  ///
  /// In en, this message translates to:
  /// **'Validation with form_builder_validators.'**
  String get formsDemoFormBuilderDateRequiredHelper;

  /// No description provided for @formsDemoFormBuilderSelectDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select date (FormBuilder)'**
  String get formsDemoFormBuilderSelectDateTitle;

  /// No description provided for @formsDemoFormBuilderRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Period (FormBuilder)'**
  String get formsDemoFormBuilderRangeLabel;

  /// No description provided for @formsDemoFormBuilderRangeHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional in this demo.'**
  String get formsDemoFormBuilderRangeHelper;

  /// No description provided for @formsDemoFormBuilderSelectRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period (FormBuilder)'**
  String get formsDemoFormBuilderSelectRangeTitle;

  /// No description provided for @formsDemoValidateFormBuilderButton.
  ///
  /// In en, this message translates to:
  /// **'Validate FormBuilder'**
  String get formsDemoValidateFormBuilderButton;

  /// No description provided for @formsDemoValidateFormSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Validate submit (Form)'**
  String get formsDemoValidateFormSubmitButton;

  /// No description provided for @formsDemoFormValidSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Valid form (fake demo). Ref: {refLabel}. Period: {rangeLabel}.'**
  String formsDemoFormValidSnackbar(String refLabel, String rangeLabel);

  /// No description provided for @formsDemoFormBuilderValidSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Valid FormBuilder (fake demo). Date: {dateLabel}. Period: {rangeLabel}.'**
  String formsDemoFormBuilderValidSnackbar(String dateLabel, String rangeLabel);

  /// No description provided for @formsDemoLegendInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get formsDemoLegendInput;

  /// No description provided for @formsDemoLegendSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get formsDemoLegendSelection;

  /// No description provided for @formsDemoLegendDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get formsDemoLegendDate;

  /// No description provided for @formsDemoLegendFormBuilder.
  ///
  /// In en, this message translates to:
  /// **'FormBuilder'**
  String get formsDemoLegendFormBuilder;

  /// No description provided for @datePickerPlaceholderSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get datePickerPlaceholderSelectDate;

  /// No description provided for @dateRangePickerPlaceholderSelectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select the period'**
  String get dateRangePickerPlaceholderSelectPeriod;

  /// No description provided for @datePickerSheetDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get datePickerSheetDefaultTitle;

  /// No description provided for @dateRangePickerSheetDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get dateRangePickerSheetDefaultTitle;

  /// No description provided for @datePickerClearSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get datePickerClearSelectionTooltip;

  /// No description provided for @datePickerSheetRemoveDate.
  ///
  /// In en, this message translates to:
  /// **'Remove date'**
  String get datePickerSheetRemoveDate;

  /// No description provided for @dateRangePickerSheetRemovePeriod.
  ///
  /// In en, this message translates to:
  /// **'Remove period'**
  String get dateRangePickerSheetRemovePeriod;

  /// No description provided for @datePickerSheetCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get datePickerSheetCloseTooltip;

  /// No description provided for @datePickerSheetApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get datePickerSheetApply;

  /// No description provided for @datePickerSemanticsFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get datePickerSemanticsFallbackLabel;

  /// No description provided for @dateRangePickerSemanticsFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get dateRangePickerSemanticsFallbackLabel;

  /// No description provided for @areaTrendDemoIntroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Area charts'**
  String get areaTrendDemoIntroEyebrow;

  /// No description provided for @areaTrendDemoIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'AppAreaTrendChart'**
  String get areaTrendDemoIntroTitle;

  /// No description provided for @areaTrendDemoIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporal trend with filled area: gradient, markers, zoom, style variants, and structured per-series/point tap event.'**
  String get areaTrendDemoIntroSubtitle;

  /// No description provided for @areaTrendDemoShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporal trend with fill'**
  String get areaTrendDemoShowcaseTitle;

  /// No description provided for @areaTrendDemoShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Area chart for volume, growth, and comparisons over time, with good mass and intensity reading.'**
  String get areaTrendDemoShowcaseSubtitle;

  /// No description provided for @areaTrendDemoShowcaseBadge.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get areaTrendDemoShowcaseBadge;

  /// No description provided for @areaTrendDemoShowcaseHighlightTimeSeries.
  ///
  /// In en, this message translates to:
  /// **'Time series'**
  String get areaTrendDemoShowcaseHighlightTimeSeries;

  /// No description provided for @areaTrendDemoShowcaseHighlightGradientMarkers.
  ///
  /// In en, this message translates to:
  /// **'Gradient and markers'**
  String get areaTrendDemoShowcaseHighlightGradientMarkers;

  /// No description provided for @areaTrendDemoShowcaseHighlightMultiseries.
  ///
  /// In en, this message translates to:
  /// **'Multi-series'**
  String get areaTrendDemoShowcaseHighlightMultiseries;

  /// No description provided for @areaTrendDemoS01Title.
  ///
  /// In en, this message translates to:
  /// **'1. Weekly revenue'**
  String get areaTrendDemoS01Title;

  /// No description provided for @areaTrendDemoS01Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Area with gradient, formatted axis, tooltip, and tap.'**
  String get areaTrendDemoS01Subtitle;

  /// No description provided for @areaTrendDemoS02Title.
  ///
  /// In en, this message translates to:
  /// **'2. With point markers'**
  String get areaTrendDemoS02Title;

  /// No description provided for @areaTrendDemoS02Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Each point shows a visible marker.'**
  String get areaTrendDemoS02Subtitle;

  /// No description provided for @areaTrendDemoS03Title.
  ///
  /// In en, this message translates to:
  /// **'3. No gradient (solid area)'**
  String get areaTrendDemoS03Title;

  /// No description provided for @areaTrendDemoS03Subtitle.
  ///
  /// In en, this message translates to:
  /// **'showGradientFill: false for a flat fill.'**
  String get areaTrendDemoS03Subtitle;

  /// No description provided for @areaTrendDemoS04Title.
  ///
  /// In en, this message translates to:
  /// **'4. Orders by hour'**
  String get areaTrendDemoS04Title;

  /// No description provided for @areaTrendDemoS04Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Operational peak of the day — unit scale.'**
  String get areaTrendDemoS04Subtitle;

  /// No description provided for @areaTrendDemoS05Title.
  ///
  /// In en, this message translates to:
  /// **'5. Compact without shell'**
  String get areaTrendDemoS05Title;

  /// No description provided for @areaTrendDemoS05Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Compact preset, no axes and no inner shell.'**
  String get areaTrendDemoS05Subtitle;

  /// No description provided for @areaTrendDemoS06Title.
  ///
  /// In en, this message translates to:
  /// **'6. Loading state'**
  String get areaTrendDemoS06Title;

  /// No description provided for @areaTrendDemoS07Title.
  ///
  /// In en, this message translates to:
  /// **'7. Empty state'**
  String get areaTrendDemoS07Title;

  /// No description provided for @areaTrendDemoEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No data for the selected period.'**
  String get areaTrendDemoEmptyMessage;

  /// No description provided for @areaTrendDemoS08Title.
  ///
  /// In en, this message translates to:
  /// **'8. Multi-series (store comparison)'**
  String get areaTrendDemoS08Title;

  /// No description provided for @areaTrendDemoS08Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Three overlaid stores with automatic palette. Legend on.'**
  String get areaTrendDemoS08Subtitle;

  /// No description provided for @areaTrendDemoS09Title.
  ///
  /// In en, this message translates to:
  /// **'9. Multi-series with trackball'**
  String get areaTrendDemoS09Title;

  /// No description provided for @areaTrendDemoS09Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the area to see values for all series at the same X position.'**
  String get areaTrendDemoS09Subtitle;

  /// No description provided for @areaTrendDemoS10Title.
  ///
  /// In en, this message translates to:
  /// **'10. Colors per entry'**
  String get areaTrendDemoS10Title;

  /// No description provided for @areaTrendDemoS10Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom color per AppAreaTrendEntry.'**
  String get areaTrendDemoS10Subtitle;

  /// No description provided for @areaTrendDemoSeriesRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get areaTrendDemoSeriesRevenue;

  /// No description provided for @areaTrendDemoSeriesTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get areaTrendDemoSeriesTarget;

  /// No description provided for @areaTrendDemoStoreCenter.
  ///
  /// In en, this message translates to:
  /// **'Downtown'**
  String get areaTrendDemoStoreCenter;

  /// No description provided for @areaTrendDemoStoreNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get areaTrendDemoStoreNorth;

  /// No description provided for @areaTrendDemoStoreSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get areaTrendDemoStoreSouth;

  /// No description provided for @areaTrendDemoDefaultSeriesName.
  ///
  /// In en, this message translates to:
  /// **'primary series'**
  String get areaTrendDemoDefaultSeriesName;

  /// No description provided for @areaTrendDemoTapSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Area: {seriesLabel} • {pointLabel} = {valueLabel}'**
  String areaTrendDemoTapSnackbar(
    String seriesLabel,
    String pointLabel,
    String valueLabel,
  );

  /// No description provided for @areaTrendDemoA11ySection.
  ///
  /// In en, this message translates to:
  /// **'Chart demo {sectionIndex}: {sectionTitle}'**
  String areaTrendDemoA11ySection(int sectionIndex, String sectionTitle);
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
