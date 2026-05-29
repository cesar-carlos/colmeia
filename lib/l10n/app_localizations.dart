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

  /// No description provided for @shellSectionBreadcrumbSemantics.
  ///
  /// In en, this message translates to:
  /// **'Go to {sectionName} section home'**
  String shellSectionBreadcrumbSemantics(String sectionName);

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
  /// **'Some approved branches did not return data. Totals may be incomplete.'**
  String get dashboardPartialAgentQueriesMessage;

  /// No description provided for @dashboardMissingClientTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches without a saved client token'**
  String get dashboardMissingClientTokenTitle;

  /// No description provided for @dashboardMissingClientTokenMessage.
  ///
  /// In en, this message translates to:
  /// **'These approved branches were skipped because no local client token was saved. Add the token in branch management to include their data.'**
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
  /// **'None of the approved branches has a client token saved on this device. Open branch management to save the token and enable overview queries.'**
  String get dashboardSetupRequiredMessage;

  /// No description provided for @dashboardViewAffectedAgentsList.
  ///
  /// In en, this message translates to:
  /// **'View branches ({count})'**
  String dashboardViewAffectedAgentsList(int count);

  /// No description provided for @dashboardAffectedAgentsSheetTitlePartialFailure.
  ///
  /// In en, this message translates to:
  /// **'Branches that did not return data'**
  String get dashboardAffectedAgentsSheetTitlePartialFailure;

  /// No description provided for @dashboardAffectedAgentsSheetTitleMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Branches without a saved client token'**
  String get dashboardAffectedAgentsSheetTitleMissingToken;

  /// No description provided for @dashboardAffectedAgentsSheetTitleSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Approved branches without a client token on this device'**
  String get dashboardAffectedAgentsSheetTitleSetupRequired;

  /// No description provided for @dashboardAgentsOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches currently offline'**
  String get dashboardAgentsOfflineTitle;

  /// No description provided for @dashboardAgentsOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'These approved branches have a saved token but the hub reports them as disconnected. Ask the operator to reconnect them, then retry.'**
  String get dashboardAgentsOfflineMessage;

  /// No description provided for @dashboardAffectedAgentsSheetTitleOffline.
  ///
  /// In en, this message translates to:
  /// **'Branches reported offline by the hub'**
  String get dashboardAffectedAgentsSheetTitleOffline;

  /// No description provided for @dashboardMultiAgentAggregationTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple branches'**
  String get dashboardMultiAgentAggregationTitle;

  /// No description provided for @dashboardMultiAgentAggregationMessage.
  ///
  /// In en, this message translates to:
  /// **'This summary merges data from several approved branches. If their databases overlap, totals may be higher than a single source.'**
  String get dashboardMultiAgentAggregationMessage;

  /// No description provided for @overviewHomeAlertErrorDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'Error details'**
  String get overviewHomeAlertErrorDetailsButton;

  /// No description provided for @overviewHomeAlertDetailsCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get overviewHomeAlertDetailsCopiedSnackbar;

  /// No description provided for @overviewHomeAlertFailureSourcePaymentResumo.
  ///
  /// In en, this message translates to:
  /// **'Payment summary query'**
  String get overviewHomeAlertFailureSourcePaymentResumo;

  /// No description provided for @overviewHomeAlertFailureSourceLucratividadePeriod.
  ///
  /// In en, this message translates to:
  /// **'Profitability (period) query'**
  String get overviewHomeAlertFailureSourceLucratividadePeriod;

  /// No description provided for @overviewHomeAlertFailureSourceUserResumo.
  ///
  /// In en, this message translates to:
  /// **'Per-operator summary query'**
  String get overviewHomeAlertFailureSourceUserResumo;

  /// No description provided for @overviewHomeAlertFailureSourceMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months query'**
  String get overviewHomeAlertFailureSourceMonthlyTrend;

  /// No description provided for @overviewHomeAlertFailureSourceWeekdayTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales by weekday query'**
  String get overviewHomeAlertFailureSourceWeekdayTrend;

  /// No description provided for @overviewHomeAlertFailureSourceWeekdayUserTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekday by operator query'**
  String get overviewHomeAlertFailureSourceWeekdayUserTrend;

  /// No description provided for @overviewHomeAlertFailureSourceDailyTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily sales query'**
  String get overviewHomeAlertFailureSourceDailyTrend;

  /// No description provided for @overviewHomeAlertFailureSourceLucratividadeMensalTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly profitability query'**
  String get overviewHomeAlertFailureSourceLucratividadeMensalTrend;

  /// No description provided for @overviewHomeAlertDetailsUserLine.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get overviewHomeAlertDetailsUserLine;

  /// No description provided for @overviewHomeAlertDetailsTechnicalLine.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get overviewHomeAlertDetailsTechnicalLine;

  /// No description provided for @overviewHomeAlertDetailsNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic rows are available for this alert.'**
  String get overviewHomeAlertDetailsNoEntries;

  /// No description provided for @overviewHomeAlertDetailsStaleIntro.
  ///
  /// In en, this message translates to:
  /// **'These figures come from the last successful overview stored on this device.\n\n'**
  String get overviewHomeAlertDetailsStaleIntro;

  /// No description provided for @overviewHomeAlertErrorDetailsSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Opens a sheet with the full diagnostic text. You can select and copy it.'**
  String get overviewHomeAlertErrorDetailsSemanticsLabel;

  /// No description provided for @overviewHomeAlertDetailsCopySemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostic text to the clipboard'**
  String get overviewHomeAlertDetailsCopySemanticsLabel;

  /// No description provided for @overviewHomeAlertDetailsAgentSemanticSummary.
  ///
  /// In en, this message translates to:
  /// **'{agentName}, branch id {agentId}. {sourceLabel}. {userMessage}.'**
  String overviewHomeAlertDetailsAgentSemanticSummary(
    String agentName,
    String agentId,
    String sourceLabel,
    String userMessage,
  );

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

  /// No description provided for @dashboardHomeFiltersAgentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get dashboardHomeFiltersAgentsLabel;

  /// No description provided for @dashboardHomeFiltersAgentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Load the overview to list branches.'**
  String get dashboardHomeFiltersAgentsEmptyHint;

  /// No description provided for @dashboardHomeFiltersBranchesLabel.
  ///
  /// In en, this message translates to:
  /// **'BRANCHES'**
  String get dashboardHomeFiltersBranchesLabel;

  /// No description provided for @dashboardHomeFiltersBranchesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Load the overview to list branches.'**
  String get dashboardHomeFiltersBranchesEmptyHint;

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
  /// **'All branches ({count})'**
  String overviewAgentFilterAllAgentsSummary(int count);

  /// No description provided for @overviewHomeBranchFilterAllBranchesSummary.
  ///
  /// In en, this message translates to:
  /// **'All branches ({count})'**
  String overviewHomeBranchFilterAllBranchesSummary(int count);

  /// No description provided for @overviewAgentFilterSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} branches selected'**
  String overviewAgentFilterSelectedCount(int count);

  /// No description provided for @overviewHomeBranchFilterSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} branches selected'**
  String overviewHomeBranchFilterSelectedCount(int count);

  /// No description provided for @overviewAgentFilterRefineAction.
  ///
  /// In en, this message translates to:
  /// **'Refine branches'**
  String get overviewAgentFilterRefineAction;

  /// No description provided for @overviewAgentFilterEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get overviewAgentFilterEditAction;

  /// No description provided for @overviewAgentFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select branches'**
  String get overviewAgentFilterSheetTitle;

  /// No description provided for @overviewAgentFilterSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search branches…'**
  String get overviewAgentFilterSheetSearchHint;

  /// No description provided for @overviewHomeBranchFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select branches'**
  String get overviewHomeBranchFilterSheetTitle;

  /// No description provided for @overviewHomeBranchFilterSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search branches…'**
  String get overviewHomeBranchFilterSheetSearchHint;

  /// No description provided for @overviewHomeBranchFilterSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get overviewHomeBranchFilterSelectAll;

  /// No description provided for @overviewHomeBranchFilterSelectAllFullRoster.
  ///
  /// In en, this message translates to:
  /// **'Select all branches (full list)'**
  String get overviewHomeBranchFilterSelectAllFullRoster;

  /// No description provided for @overviewHomeBranchFilterDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get overviewHomeBranchFilterDeselectAll;

  /// No description provided for @overviewHomeBranchFilterSelectMatching.
  ///
  /// In en, this message translates to:
  /// **'Select all matching branches'**
  String get overviewHomeBranchFilterSelectMatching;

  /// No description provided for @overviewHomeBranchFilterDeselectMatching.
  ///
  /// In en, this message translates to:
  /// **'Deselect all matching branches'**
  String get overviewHomeBranchFilterDeselectMatching;

  /// No description provided for @overviewHomeBranchFilterSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{selectedCount} of {totalCount} branches selected'**
  String overviewHomeBranchFilterSelectionCount(
    int selectedCount,
    int totalCount,
  );

  /// No description provided for @overviewHomeBranchFilterApplyRequiresSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one branch to apply.'**
  String get overviewHomeBranchFilterApplyRequiresSelectionHint;

  /// No description provided for @overviewHomeBranchFilterSheetUseAllBranches.
  ///
  /// In en, this message translates to:
  /// **'Use all branches'**
  String get overviewHomeBranchFilterSheetUseAllBranches;

  /// No description provided for @overviewHomeBranchFilterApplyDisabledSemantics.
  ///
  /// In en, this message translates to:
  /// **'Apply. Disabled. Select at least one branch.'**
  String get overviewHomeBranchFilterApplyDisabledSemantics;

  /// No description provided for @overviewHomeBranchFilterRefineAction.
  ///
  /// In en, this message translates to:
  /// **'Refine branches'**
  String get overviewHomeBranchFilterRefineAction;

  /// No description provided for @overviewHomeBranchFilterEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get overviewHomeBranchFilterEditAction;

  /// No description provided for @overviewHomeBranchFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get overviewHomeBranchFilterApply;

  /// No description provided for @overviewHomeBranchFilterCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get overviewHomeBranchFilterCancel;

  /// No description provided for @overviewHomeBranchFilterMissingClientTokenRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No client token on this device for this branch — SQL queries are skipped.'**
  String get overviewHomeBranchFilterMissingClientTokenRowSubtitle;

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
  /// **'No branches match your search.'**
  String get overviewAgentFilterNoSearchResults;

  /// No description provided for @overviewHomeBranchFilterNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No branches match your search.'**
  String get overviewHomeBranchFilterNoSearchResults;

  /// No description provided for @overviewAgentFilterMissingClientTokenBanner.
  ///
  /// In en, this message translates to:
  /// **'Branches without a client token on this device cannot run SQL queries. “Online” only reflects hub connectivity.'**
  String get overviewAgentFilterMissingClientTokenBanner;

  /// No description provided for @overviewHomeBranchFilterMissingClientTokenBanner.
  ///
  /// In en, this message translates to:
  /// **'Branches without a client token on this device cannot run SQL queries. “Online” only reflects hub connectivity.'**
  String get overviewHomeBranchFilterMissingClientTokenBanner;

  /// No description provided for @overviewAgentFilterMissingClientTokenRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No client token on this device for this branch — SQL queries are skipped.'**
  String get overviewAgentFilterMissingClientTokenRowSubtitle;

  /// No description provided for @chartCategoryDonutEmptyForFilter.
  ///
  /// In en, this message translates to:
  /// **'No category data for this view.'**
  String get chartCategoryDonutEmptyForFilter;

  /// No description provided for @dashboardAgentRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking by branch'**
  String get dashboardAgentRankingTitle;

  /// No description provided for @dashboardAgentRankingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total revenue by branch in the period.'**
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
  /// **'No branch revenue in this period.'**
  String get overviewAgentRankingEmpty;

  /// No description provided for @overviewUserRankingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No operator revenue in this period.'**
  String get overviewUserRankingEmpty;

  /// No description provided for @overviewTopProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top products by sales'**
  String get overviewTopProductsTitle;

  /// No description provided for @overviewTopProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Per branch (not merged across databases). Up to {count} products.'**
  String overviewTopProductsSubtitle(int count);

  /// No description provided for @overviewTopProductsNoEligibleAgents.
  ///
  /// In en, this message translates to:
  /// **'No branches available for this chart. Save a client token on the branch or adjust the filter.'**
  String get overviewTopProductsNoEligibleAgents;

  /// No description provided for @overviewTopProductsInvalidPeriod.
  ///
  /// In en, this message translates to:
  /// **'The selected period is not valid for this chart.'**
  String get overviewTopProductsInvalidPeriod;

  /// No description provided for @overviewTopProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No product sales in this period for this branch.'**
  String get overviewTopProductsEmpty;

  /// No description provided for @overviewTopProductsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this chart. Try again later.'**
  String get overviewTopProductsLoadFailed;

  /// No description provided for @overviewTopProductsLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading top products chart…'**
  String get overviewTopProductsLoadingSemantics;

  /// No description provided for @overviewTopProductsTooltipLine.
  ///
  /// In en, this message translates to:
  /// **'{sales} sales · {items} items · {revenue} revenue · {cost} cost · {margin}% margin'**
  String overviewTopProductsTooltipLine(
    int sales,
    String items,
    String revenue,
    String cost,
    String margin,
  );

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
  /// **'Consolidated summary of approved branches (connected to the hub).'**
  String get overviewHomeSubtitle;

  /// Screen-reader label for the RefreshIndicator wrapping the overview home page.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh the overview'**
  String get overviewHomeRefreshSemanticsLabel;

  /// No description provided for @overviewHomeManageBranchesAction.
  ///
  /// In en, this message translates to:
  /// **'Branch management'**
  String get overviewHomeManageBranchesAction;

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

  /// Overview home chart title for daily sales totals.
  ///
  /// In en, this message translates to:
  /// **'Daily sales'**
  String get overviewDailySalesTitle;

  /// Subtitle clarifying scope for the daily sales chart.
  ///
  /// In en, this message translates to:
  /// **'Totals per calendar day in the selected period (aggregated across branches in scope).'**
  String get overviewDailySalesSubtitle;

  /// No description provided for @overviewDailySalesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No daily sales data for this period.'**
  String get overviewDailySalesEmpty;

  /// No description provided for @overviewDailySalesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the daily sales chart. Try again later.'**
  String get overviewDailySalesLoadFailed;

  /// No description provided for @overviewDailySalesChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Daily sales count and revenue trend chart'**
  String get overviewDailySalesChartSemantics;

  /// No description provided for @overviewDailySalesRevenueChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Daily revenue and sales count trend chart'**
  String get overviewDailySalesRevenueChartSemantics;

  /// No description provided for @overviewLoadingDailySalesSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading daily sales chart'**
  String get overviewLoadingDailySalesSemantics;

  /// Tooltip for one daily bar showing sales count and amount.
  ///
  /// In en, this message translates to:
  /// **'{date}: {salesCount} sales - {salesAmount}'**
  String overviewDailySalesTooltip(
    String date,
    String salesCount,
    String salesAmount,
  );

  /// Short weekday label (Monday) for overview charts: daily sales x-axis, weekday bars, tooltips — keep in sync across locales.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get overviewDailySalesAxisDowMon;

  /// No description provided for @overviewDailySalesAxisDowTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get overviewDailySalesAxisDowTue;

  /// No description provided for @overviewDailySalesAxisDowWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get overviewDailySalesAxisDowWed;

  /// No description provided for @overviewDailySalesAxisDowThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get overviewDailySalesAxisDowThu;

  /// No description provided for @overviewDailySalesAxisDowFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get overviewDailySalesAxisDowFri;

  /// No description provided for @overviewDailySalesAxisDowSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get overviewDailySalesAxisDowSat;

  /// No description provided for @overviewDailySalesAxisDowSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get overviewDailySalesAxisDowSun;

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

  /// Screen reader context for the overview operator ranking bar chart (revenue plus average ticket).
  ///
  /// In en, this message translates to:
  /// **'Each bar shows total revenue and average ticket for that operator.'**
  String get overviewUserRankingChartSemanticsExtra;

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

  /// Tooltip and semantics label for the chart fullscreen action button.
  ///
  /// In en, this message translates to:
  /// **'Open chart in fullscreen'**
  String get chartOpenFullscreenTooltip;

  /// Tooltip for the close action in the fullscreen chart scaffold.
  ///
  /// In en, this message translates to:
  /// **'Close fullscreen chart'**
  String get chartCloseFullscreenTooltip;

  /// Title shown when the fullscreen chart route is opened without a valid payload.
  ///
  /// In en, this message translates to:
  /// **'Chart unavailable'**
  String get chartFullscreenUnavailableTitle;

  /// Body shown when the fullscreen chart route is opened without a valid payload.
  ///
  /// In en, this message translates to:
  /// **'This chart could not be opened in fullscreen. Go back and try again.'**
  String get chartFullscreenUnavailableMessage;

  /// Short hint appended to fullscreen filter summary for charts that snapshot data (e.g. live map).
  ///
  /// In en, this message translates to:
  /// **'Map values reflect the data loaded when you opened fullscreen.'**
  String get chartFullscreenDataSnapshotHint;

  /// No description provided for @regionMapMetricGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get regionMapMetricGroupLabel;

  /// No description provided for @regionMapScopeGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get regionMapScopeGroupLabel;

  /// No description provided for @regionMapRootScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'All regions'**
  String get regionMapRootScopeLabel;

  /// No description provided for @regionMapLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading map…'**
  String get regionMapLoadingMessage;

  /// No description provided for @regionMapEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'No territorial data to show.'**
  String get regionMapEmptyStateMessage;

  /// No description provided for @regionMapMetricSelectorSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Map metric'**
  String get regionMapMetricSelectorSemanticsLabel;

  /// No description provided for @regionMapScopeSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Territorial scope'**
  String get regionMapScopeSemanticsLabel;

  /// No description provided for @regionMapDrillUpToRegionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to regions'**
  String get regionMapDrillUpToRegionsLabel;

  /// No description provided for @regionMapDrillUpToStatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to states'**
  String get regionMapDrillUpToStatesLabel;

  /// No description provided for @regionMapDrillUpToCitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to cities'**
  String get regionMapDrillUpToCitiesLabel;

  /// No description provided for @regionMapDrillUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get regionMapDrillUpLabel;

  /// No description provided for @regionMapDrillUpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Return to the previous map level'**
  String get regionMapDrillUpTooltip;

  /// No description provided for @regionMapViewFullScopeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show full map ({label})'**
  String regionMapViewFullScopeTooltip(String label);

  /// No description provided for @regionMapViewFullScopeSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Show full map {label}'**
  String regionMapViewFullScopeSemanticLabel(String label);

  /// No description provided for @regionMapFocusScopeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Focus on {label}'**
  String regionMapFocusScopeTooltip(String label);

  /// No description provided for @regionMapFocusScopeSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus on {label}'**
  String regionMapFocusScopeSemanticLabel(String label);

  /// No description provided for @brazilStoreSalesMapMetricGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get brazilStoreSalesMapMetricGroupLabel;

  /// No description provided for @brazilStoreSalesMapRegionGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get brazilStoreSalesMapRegionGroupLabel;

  /// No description provided for @brazilStoreSalesMapLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading Brazil map…'**
  String get brazilStoreSalesMapLoadingMessage;

  /// No description provided for @brazilStoreSalesMapMarkerSizeLegend.
  ///
  /// In en, this message translates to:
  /// **'Marker size'**
  String get brazilStoreSalesMapMarkerSizeLegend;

  /// No description provided for @brazilStoreSalesMapLegendRevenuePerState.
  ///
  /// In en, this message translates to:
  /// **'Revenue by state'**
  String get brazilStoreSalesMapLegendRevenuePerState;

  /// No description provided for @brazilStoreSalesMapLegendSalesPerState.
  ///
  /// In en, this message translates to:
  /// **'Sales by state'**
  String get brazilStoreSalesMapLegendSalesPerState;

  /// No description provided for @brazilStoreSalesMapShowBranchOnMapAction.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get brazilStoreSalesMapShowBranchOnMapAction;

  /// No description provided for @brazilStoreSalesMapUnpinBranchButton.
  ///
  /// In en, this message translates to:
  /// **'Unpin from map'**
  String get brazilStoreSalesMapUnpinBranchButton;

  /// No description provided for @brazilStoreSalesMapMetricRevenueShort.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get brazilStoreSalesMapMetricRevenueShort;

  /// No description provided for @brazilStoreSalesMapMetricSalesShort.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get brazilStoreSalesMapMetricSalesShort;

  /// No description provided for @brazilStoreSalesMapLegendButton.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get brazilStoreSalesMapLegendButton;

  /// No description provided for @brazilStoreSalesMapStateBucketTooltip.
  ///
  /// In en, this message translates to:
  /// **'{stateName} / {uf}\n{revenue} | {salesCount} sales | {storeCount} stores'**
  String brazilStoreSalesMapStateBucketTooltip(
    String stateName,
    String uf,
    String revenue,
    String salesCount,
    String storeCount,
  );

  /// No description provided for @brazilStoreSalesMapStateInlineTooltip.
  ///
  /// In en, this message translates to:
  /// **'{stateName} ({uf}) | {revenue} | {salesCount} sales | {storeCount} stores'**
  String brazilStoreSalesMapStateInlineTooltip(
    String stateName,
    String uf,
    String revenue,
    String salesCount,
    String storeCount,
  );

  /// No description provided for @brazilStoreSalesMapSemanticsStoreOnMap.
  ///
  /// In en, this message translates to:
  /// **'Store on map'**
  String get brazilStoreSalesMapSemanticsStoreOnMap;

  /// No description provided for @brazilStoreSalesMapSemanticsSalesLoadingSuffix.
  ///
  /// In en, this message translates to:
  /// **', sales loading'**
  String get brazilStoreSalesMapSemanticsSalesLoadingSuffix;

  /// No description provided for @brazilStoreSalesMapSemanticsSalesUnavailableSuffix.
  ///
  /// In en, this message translates to:
  /// **', sales unavailable'**
  String get brazilStoreSalesMapSemanticsSalesUnavailableSuffix;

  /// No description provided for @brazilStoreSalesMapSemanticsClusterStores.
  ///
  /// In en, this message translates to:
  /// **'{storeCount} stores in {cityLabel}, {revenue}, {salesCount} sales{salesStatusSuffix}'**
  String brazilStoreSalesMapSemanticsClusterStores(
    String storeCount,
    String cityLabel,
    String revenue,
    String salesCount,
    String salesStatusSuffix,
  );

  /// No description provided for @brazilStoreSalesMapSemanticsSingleStore.
  ///
  /// In en, this message translates to:
  /// **'{storeName}, {cityLabel}, {revenue}, {salesCount} sales{salesStatusSuffix}'**
  String brazilStoreSalesMapSemanticsSingleStore(
    String storeName,
    String cityLabel,
    String revenue,
    String salesCount,
    String salesStatusSuffix,
  );

  /// No description provided for @brazilStoreSalesMapSemanticsStateAggregate.
  ///
  /// In en, this message translates to:
  /// **'{stateName}, {revenue}, {salesCount} sales, {storeCount} stores'**
  String brazilStoreSalesMapSemanticsStateAggregate(
    String stateName,
    String revenue,
    String salesCount,
    String storeCount,
  );

  /// No description provided for @brazilStoreSalesMapDetailChipSales.
  ///
  /// In en, this message translates to:
  /// **'{count} sales'**
  String brazilStoreSalesMapDetailChipSales(String count);

  /// No description provided for @brazilStoreSalesMapDetailChipBranches.
  ///
  /// In en, this message translates to:
  /// **'{count} branches'**
  String brazilStoreSalesMapDetailChipBranches(String count);

  /// No description provided for @brazilStoreSalesMapStateSelectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{uf} selected'**
  String brazilStoreSalesMapStateSelectedSubtitle(String uf);

  /// No description provided for @brazilStoreSalesMapCarouselPosition.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String brazilStoreSalesMapCarouselPosition(String current, String total);

  /// No description provided for @brazilStoreSalesMapBranchDetailSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch details on the map'**
  String get brazilStoreSalesMapBranchDetailSemanticsLabel;

  /// No description provided for @brazilStoreSalesMapSalesLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading sales'**
  String get brazilStoreSalesMapSalesLoadingLabel;

  /// No description provided for @brazilStoreSalesMapDataQualityLead.
  ///
  /// In en, this message translates to:
  /// **'{count} stores not shown'**
  String brazilStoreSalesMapDataQualityLead(String count);

  /// No description provided for @brazilStoreSalesMapDataQualityInvalidCoords.
  ///
  /// In en, this message translates to:
  /// **'{count} with invalid coordinates'**
  String brazilStoreSalesMapDataQualityInvalidCoords(String count);

  /// No description provided for @brazilStoreSalesMapDataQualityUnknownUf.
  ///
  /// In en, this message translates to:
  /// **'{count} with unknown state code'**
  String brazilStoreSalesMapDataQualityUnknownUf(String count);

  /// No description provided for @brazilStoreSalesMapDataQualityOutsideClip.
  ///
  /// In en, this message translates to:
  /// **'{count} outside the map clip'**
  String brazilStoreSalesMapDataQualityOutsideClip(String count);

  /// No description provided for @salesLiveMapFilterBranchSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{city}/{uf} — Branch {agentName}'**
  String salesLiveMapFilterBranchSummaryLine(
    String city,
    String uf,
    String agentName,
  );

  /// No description provided for @salesLiveMapFilterBranchCodesLine.
  ///
  /// In en, this message translates to:
  /// **'Company: {codEmpresa}  Branch: {codFilial}'**
  String salesLiveMapFilterBranchCodesLine(String codEmpresa, String codFilial);

  /// No description provided for @brazilStoreSalesMapCloseBranchDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close details'**
  String get brazilStoreSalesMapCloseBranchDetailsTooltip;

  /// No description provided for @brazilStoreSalesMapBranchPinnedChip.
  ///
  /// In en, this message translates to:
  /// **'Pinned branch'**
  String get brazilStoreSalesMapBranchPinnedChip;

  /// No description provided for @brazilStoreSalesMapSalesUnavailableFallback.
  ///
  /// In en, this message translates to:
  /// **'Sales unavailable'**
  String get brazilStoreSalesMapSalesUnavailableFallback;

  /// No description provided for @brazilStoreSalesMapSelectBranchButton.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get brazilStoreSalesMapSelectBranchButton;

  /// No description provided for @brazilStoreSalesMapChooseBranchMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose branch'**
  String get brazilStoreSalesMapChooseBranchMenuTooltip;

  /// No description provided for @brazilStoreSalesMapBranchNavigationPreviousTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous branch'**
  String get brazilStoreSalesMapBranchNavigationPreviousTooltip;

  /// No description provided for @brazilStoreSalesMapBranchNavigationNextTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next branch'**
  String get brazilStoreSalesMapBranchNavigationNextTooltip;

  /// No description provided for @brazilStoreSalesMapMarkerGroupTotalTitle.
  ///
  /// In en, this message translates to:
  /// **'Location total'**
  String get brazilStoreSalesMapMarkerGroupTotalTitle;

  /// No description provided for @brazilStoreSalesMapDefaultBranchName.
  ///
  /// In en, this message translates to:
  /// **'Unnamed branch'**
  String get brazilStoreSalesMapDefaultBranchName;

  /// No description provided for @brazilStoreSalesMapSidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Visible branches'**
  String get brazilStoreSalesMapSidebarTitle;

  /// No description provided for @brazilStoreSalesMapSidebarSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 visible branch} other{{count} visible branches}} · {revenue}'**
  String brazilStoreSalesMapSidebarSummary(int count, String revenue);

  /// No description provided for @brazilStoreSalesMapSidebarCountSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 visible branch} other{{count} visible branches}}'**
  String brazilStoreSalesMapSidebarCountSummary(int count);

  /// No description provided for @brazilStoreSalesMapSidebarRevenueSummary.
  ///
  /// In en, this message translates to:
  /// **'Total in scope: {revenue}'**
  String brazilStoreSalesMapSidebarRevenueSummary(String revenue);

  /// No description provided for @brazilStoreSalesMapSidebarSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search branch or city'**
  String get brazilStoreSalesMapSidebarSearchPlaceholder;

  /// No description provided for @brazilStoreSalesMapSidebarSearchSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search branch or city in the map list'**
  String get brazilStoreSalesMapSidebarSearchSemanticsLabel;

  /// No description provided for @brazilStoreSalesMapSidebarEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No visible branches'**
  String get brazilStoreSalesMapSidebarEmptyStateTitle;

  /// No description provided for @brazilStoreSalesMapSidebarEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Adjust the map region or clear the active scope to list branches in this panel.'**
  String get brazilStoreSalesMapSidebarEmptyStateMessage;

  /// No description provided for @brazilStoreSalesMapSidebarSearchEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No branches found'**
  String get brazilStoreSalesMapSidebarSearchEmptyStateTitle;

  /// No description provided for @brazilStoreSalesMapSidebarSearchEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Adjust the search to find branches in this scope.'**
  String get brazilStoreSalesMapSidebarSearchEmptyStateMessage;

  /// No description provided for @brazilStoreSalesMapSidebarZeroSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'No sales in period'**
  String get brazilStoreSalesMapSidebarZeroSalesLabel;

  /// No description provided for @brazilStoreSalesMapSidebarCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide branch list'**
  String get brazilStoreSalesMapSidebarCollapseTooltip;

  /// No description provided for @brazilStoreSalesMapSidebarExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show branch list'**
  String get brazilStoreSalesMapSidebarExpandTooltip;

  /// No description provided for @brazilStoreSalesMapAgentChipWithName.
  ///
  /// In en, this message translates to:
  /// **'Branch {agentName}'**
  String brazilStoreSalesMapAgentChipWithName(String agentName);

  /// No description provided for @brazilStoreSalesMapIbgeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'IBGE {code}'**
  String brazilStoreSalesMapIbgeCodeLabel(String code);

  /// No description provided for @brazilStoreSalesMapLocationProvidedGeoPoint.
  ///
  /// In en, this message translates to:
  /// **'Branch coordinates'**
  String get brazilStoreSalesMapLocationProvidedGeoPoint;

  /// No description provided for @brazilStoreSalesMapLocationIbge.
  ///
  /// In en, this message translates to:
  /// **'IBGE geolocation'**
  String get brazilStoreSalesMapLocationIbge;

  /// No description provided for @brazilStoreSalesMapLocationCep.
  ///
  /// In en, this message translates to:
  /// **'ZIP code geolocation'**
  String get brazilStoreSalesMapLocationCep;

  /// No description provided for @brazilStoreSalesMapLocationCityUf.
  ///
  /// In en, this message translates to:
  /// **'City/state geolocation'**
  String get brazilStoreSalesMapLocationCityUf;

  /// No description provided for @brazilStoreSalesMapLocationCapitalUf.
  ///
  /// In en, this message translates to:
  /// **'State capital'**
  String get brazilStoreSalesMapLocationCapitalUf;

  /// No description provided for @brazilStoreSalesMapLocationStateUf.
  ///
  /// In en, this message translates to:
  /// **'State centroid'**
  String get brazilStoreSalesMapLocationStateUf;

  /// No description provided for @brazilStoreSalesMapLocationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Coordinate source not provided'**
  String get brazilStoreSalesMapLocationUnknown;

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
  /// **'No approved branch is available to load the overview.'**
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

  /// No description provided for @clientAgentsMaintenanceSubtitleOwner.
  ///
  /// In en, this message translates to:
  /// **'Use the tabs to manage your approved agents, retry client requests, and review access for agents you own.'**
  String get clientAgentsMaintenanceSubtitleOwner;

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

  /// No description provided for @clientAgentsTabOwnerRequests.
  ///
  /// In en, this message translates to:
  /// **'Review requests'**
  String get clientAgentsTabOwnerRequests;

  /// No description provided for @clientAgentsTabOwnerClients.
  ///
  /// In en, this message translates to:
  /// **'Approved clients'**
  String get clientAgentsTabOwnerClients;

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

  /// No description provided for @clientAgentsRetryRequestAction.
  ///
  /// In en, this message translates to:
  /// **'Retry request'**
  String get clientAgentsRetryRequestAction;

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

  /// No description provided for @clientAgentsRetryMissingRequestId.
  ///
  /// In en, this message translates to:
  /// **'This request cannot be retried because its identifier is unavailable.'**
  String get clientAgentsRetryMissingRequestId;

  /// No description provided for @clientAgentsRetrySuccess.
  ///
  /// In en, this message translates to:
  /// **'The request was retried. We will keep watching for approval updates.'**
  String get clientAgentsRetrySuccess;

  /// No description provided for @clientAgentsDiscardQueuedRequestAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get clientAgentsDiscardQueuedRequestAction;

  /// No description provided for @clientAgentsDiscardQueuedRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'The pending submission was removed. You can request access again when you want.'**
  String get clientAgentsDiscardQueuedRequestSuccess;

  /// No description provided for @clientAgentsDiscardQueuedRequestInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This submission cannot be removed from the queue in its current state.'**
  String get clientAgentsDiscardQueuedRequestInvalidState;

  /// No description provided for @clientAgentsOwnerActionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the owner action'**
  String get clientAgentsOwnerActionFailedTitle;

  /// No description provided for @clientAgentsOwnerRequestsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests to review'**
  String get clientAgentsOwnerRequestsLoadErrorTitle;

  /// No description provided for @clientAgentsOwnerRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No client requests need your review right now.'**
  String get clientAgentsOwnerRequestsEmpty;

  /// No description provided for @clientAgentsOwnerApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get clientAgentsOwnerApproveAction;

  /// No description provided for @clientAgentsOwnerRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get clientAgentsOwnerRejectAction;

  /// No description provided for @clientAgentsOwnerRequestsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your decision for this agent.'**
  String get clientAgentsOwnerRequestsStatusPending;

  /// No description provided for @clientAgentsOwnerRequestsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved and already available for the client.'**
  String get clientAgentsOwnerRequestsStatusApproved;

  /// No description provided for @clientAgentsOwnerRequestsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected during owner review.'**
  String get clientAgentsOwnerRequestsStatusRejected;

  /// No description provided for @clientAgentsOwnerRequestsStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired before a final review.'**
  String get clientAgentsOwnerRequestsStatusExpired;

  /// No description provided for @clientAgentsOwnerRequestsStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'The latest owner-review status is unavailable.'**
  String get clientAgentsOwnerRequestsStatusUnknown;

  /// No description provided for @clientAgentsOwnerApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'The access request was approved.'**
  String get clientAgentsOwnerApproveSuccess;

  /// No description provided for @clientAgentsOwnerRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'The access request was rejected.'**
  String get clientAgentsOwnerRejectSuccess;

  /// No description provided for @clientAgentsOwnerClientsEmptyAgents.
  ///
  /// In en, this message translates to:
  /// **'No managed agents are available for this account yet.'**
  String get clientAgentsOwnerClientsEmptyAgents;

  /// No description provided for @clientAgentsOwnerClientsAgentSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get clientAgentsOwnerClientsAgentSelectorLabel;

  /// No description provided for @clientAgentsOwnerClientsAgentSelectorHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an owned agent'**
  String get clientAgentsOwnerClientsAgentSelectorHint;

  /// No description provided for @clientAgentsOwnerClientsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load approved clients'**
  String get clientAgentsOwnerClientsLoadErrorTitle;

  /// No description provided for @clientAgentsOwnerClientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No approved clients are linked to this agent yet.'**
  String get clientAgentsOwnerClientsEmpty;

  /// No description provided for @clientAgentsOwnerClientsApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approved for this agent.'**
  String get clientAgentsOwnerClientsApprovedSubtitle;

  /// No description provided for @clientAgentsOwnerRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get clientAgentsOwnerRevokeAction;

  /// No description provided for @clientAgentsOwnerRevokeSuccess.
  ///
  /// In en, this message translates to:
  /// **'The client access was revoked.'**
  String get clientAgentsOwnerRevokeSuccess;

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

  /// Tooltip for copying a single identity field on the agent detail screen.
  ///
  /// In en, this message translates to:
  /// **'Copy {label} to the clipboard'**
  String clientAgentDetailCopyFieldTooltip(String label);

  /// No description provided for @clientAgentDetailCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get clientAgentDetailCopiedSnackbar;

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

  /// No description provided for @reportRowDetailDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportRowDetailDefaultTitle;

  /// No description provided for @reportLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get reportLoadErrorTitle;

  /// No description provided for @reportEmptyClearFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get reportEmptyClearFiltersAction;

  /// No description provided for @reportEmptyDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get reportEmptyDefaultMessage;

  /// No description provided for @reportLoadingFiltersSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading filters...'**
  String get reportLoadingFiltersSemantics;

  /// No description provided for @reportLoadingSummarySemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading summary...'**
  String get reportLoadingSummarySemantics;

  /// No description provided for @reportLoadingTableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading table...'**
  String get reportLoadingTableSemantics;

  /// No description provided for @reportLoadingPaginationSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading pagination...'**
  String get reportLoadingPaginationSemantics;

  /// No description provided for @reportToolbarLabel.
  ///
  /// In en, this message translates to:
  /// **'Table tools'**
  String get reportToolbarLabel;

  /// No description provided for @reportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get reportSearchHint;

  /// No description provided for @reportClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get reportClearSearchTooltip;

  /// No description provided for @reportSelectionPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String reportSelectionPill(int count);

  /// No description provided for @reportSelectionPillTooltip.
  ///
  /// In en, this message translates to:
  /// **'Selected rows in the grid'**
  String get reportSelectionPillTooltip;

  /// No description provided for @reportGroupedPill.
  ///
  /// In en, this message translates to:
  /// **'Grouped: {label}'**
  String reportGroupedPill(String label);

  /// No description provided for @reportGroupedPillTooltip.
  ///
  /// In en, this message translates to:
  /// **'Grouped by {label}'**
  String reportGroupedPillTooltip(String label);

  /// No description provided for @reportExpandGroupsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand groups'**
  String get reportExpandGroupsTooltip;

  /// No description provided for @reportCollapseGroupsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse groups'**
  String get reportCollapseGroupsTooltip;

  /// No description provided for @reportColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get reportColumnsLabel;

  /// No description provided for @reportColumnsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Visible columns'**
  String get reportColumnsTooltip;

  /// No description provided for @reportPrintLabel.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get reportPrintLabel;

  /// No description provided for @reportRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get reportRefreshTooltip;

  /// No description provided for @reportGroupLevelsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Control grouping levels'**
  String get reportGroupLevelsTooltip;

  /// No description provided for @reportExpandToLevel.
  ///
  /// In en, this message translates to:
  /// **'Expand to level {level}'**
  String reportExpandToLevel(int level);

  /// No description provided for @reportCollapseToLevel.
  ///
  /// In en, this message translates to:
  /// **'Collapse to level {level}'**
  String reportCollapseToLevel(int level);

  /// No description provided for @reportGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get reportGroupLabel;

  /// No description provided for @reportClearGroupingAction.
  ///
  /// In en, this message translates to:
  /// **'Clear grouping'**
  String get reportClearGroupingAction;

  /// No description provided for @reportDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get reportDensityCompact;

  /// No description provided for @reportDensityCompactTooltip.
  ///
  /// In en, this message translates to:
  /// **'Denser rows'**
  String get reportDensityCompactTooltip;

  /// No description provided for @reportDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get reportDensityComfortable;

  /// No description provided for @reportDensityComfortableTooltip.
  ///
  /// In en, this message translates to:
  /// **'Balance between readability and density'**
  String get reportDensityComfortableTooltip;

  /// No description provided for @reportDensityExpanded.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get reportDensityExpanded;

  /// No description provided for @reportDensityExpandedTooltip.
  ///
  /// In en, this message translates to:
  /// **'More vertical breathing room'**
  String get reportDensityExpandedTooltip;

  /// No description provided for @reportExportLabel.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get reportExportLabel;

  /// No description provided for @reportExportScopeCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'{format} of current page'**
  String reportExportScopeCurrentPage(String format);

  /// No description provided for @reportExportScopeAllPages.
  ///
  /// In en, this message translates to:
  /// **'{format} of all pages'**
  String reportExportScopeAllPages(String format);

  /// No description provided for @reportExportScopeSelection.
  ///
  /// In en, this message translates to:
  /// **'{format} of selection ({count})'**
  String reportExportScopeSelection(String format, int count);

  /// No description provided for @reportExportScopeCurrentPageWithFilters.
  ///
  /// In en, this message translates to:
  /// **'{format} of current page + filters'**
  String reportExportScopeCurrentPageWithFilters(String format);

  /// No description provided for @reportExportScopeAllPagesWithFilters.
  ///
  /// In en, this message translates to:
  /// **'{format} of all pages + filters'**
  String reportExportScopeAllPagesWithFilters(String format);

  /// No description provided for @reportExportScopeSelectionWithFilters.
  ///
  /// In en, this message translates to:
  /// **'{format} of selection + filters'**
  String reportExportScopeSelectionWithFilters(String format);

  /// No description provided for @reportFilterRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get reportFilterRequired;

  /// No description provided for @reportFilterOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get reportFilterOptional;

  /// No description provided for @reportFilterSelectOption.
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get reportFilterSelectOption;

  /// No description provided for @reportFilterRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportFilterRangeFrom;

  /// No description provided for @reportFilterRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportFilterRangeTo;

  /// No description provided for @reportFilterSearchTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get reportFilterSearchTagsHint;

  /// No description provided for @reportPaginationItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Items per page:'**
  String get reportPaginationItemsPerPage;

  /// No description provided for @reportPaginationPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get reportPaginationPrevious;

  /// No description provided for @reportPaginationNext.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get reportPaginationNext;

  /// No description provided for @reportPaginationPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String reportPaginationPageNumber(int page);

  /// No description provided for @appLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get appLoading;

  /// No description provided for @appLoadingDataSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get appLoadingDataSemantics;

  /// No description provided for @appRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appRefreshAction;

  /// No description provided for @dataStaleBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Data may be out of date.'**
  String get dataStaleBannerMessage;

  /// No description provided for @chartLoadingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Loading chart…'**
  String get chartLoadingGeneric;

  /// No description provided for @reportColumnChooserReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reportColumnChooserReset;

  /// No description provided for @reportColumnChooserCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportColumnChooserCancel;

  /// No description provided for @reportColumnChooserApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reportColumnChooserApply;

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

  /// No description provided for @clientAgentsErrorRetryClientAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not retry this access request.'**
  String get clientAgentsErrorRetryClientAccessRequest;

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

  /// No description provided for @clientAgentsErrorLoadManagedAgents.
  ///
  /// In en, this message translates to:
  /// **'Could not load managed agents.'**
  String get clientAgentsErrorLoadManagedAgents;

  /// No description provided for @clientAgentsErrorLoadOwnerAccessRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load client access requests for review.'**
  String get clientAgentsErrorLoadOwnerAccessRequests;

  /// No description provided for @clientAgentsErrorApproveOwnerAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not approve this access request.'**
  String get clientAgentsErrorApproveOwnerAccessRequest;

  /// No description provided for @clientAgentsErrorRejectOwnerAccessRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not reject this access request.'**
  String get clientAgentsErrorRejectOwnerAccessRequest;

  /// No description provided for @clientAgentsErrorLoadOwnerApprovedClients.
  ///
  /// In en, this message translates to:
  /// **'Could not load approved clients for this agent.'**
  String get clientAgentsErrorLoadOwnerApprovedClients;

  /// No description provided for @clientAgentsErrorRevokeOwnerClientAccess.
  ///
  /// In en, this message translates to:
  /// **'Could not revoke this client access.'**
  String get clientAgentsErrorRevokeOwnerClientAccess;

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

  /// No description provided for @overviewLucratividadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Profitability by branch'**
  String get overviewLucratividadeTitle;

  /// No description provided for @overviewLucratividadeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue, cost and margin for the selected period (all branches in scope combined).'**
  String get overviewLucratividadeSubtitle;

  /// No description provided for @overviewLucratividadeSwitchProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get overviewLucratividadeSwitchProfit;

  /// No description provided for @overviewLucratividadeSwitchRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get overviewLucratividadeSwitchRevenue;

  /// No description provided for @overviewLucratividadeSwitchCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get overviewLucratividadeSwitchCost;

  /// No description provided for @overviewLucratividadeSwitchMargin.
  ///
  /// In en, this message translates to:
  /// **'Percent metrics'**
  String get overviewLucratividadeSwitchMargin;

  /// No description provided for @overviewLucratividadePercentMetricCostShort.
  ///
  /// In en, this message translates to:
  /// **'Cost %'**
  String get overviewLucratividadePercentMetricCostShort;

  /// No description provided for @overviewLucratividadePercentMetricGrossShort.
  ///
  /// In en, this message translates to:
  /// **'Gross margin'**
  String get overviewLucratividadePercentMetricGrossShort;

  /// No description provided for @overviewLucratividadePercentMetricMarkupShort.
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get overviewLucratividadePercentMetricMarkupShort;

  /// No description provided for @overviewLucratividadePercentSeriesCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost on sales %'**
  String get overviewLucratividadePercentSeriesCostLabel;

  /// No description provided for @overviewLucratividadePercentSeriesGrossLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross margin %'**
  String get overviewLucratividadePercentSeriesGrossLabel;

  /// No description provided for @overviewLucratividadePercentSeriesMarkupLabel.
  ///
  /// In en, this message translates to:
  /// **'Markup on cost %'**
  String get overviewLucratividadePercentSeriesMarkupLabel;

  /// No description provided for @overviewLucratividadePercentHelpCostBody.
  ///
  /// In en, this message translates to:
  /// **'Cost / Sales × 100. Shows the share of revenue consumed by replacement cost.'**
  String get overviewLucratividadePercentHelpCostBody;

  /// No description provided for @overviewLucratividadePercentHelpGrossBody.
  ///
  /// In en, this message translates to:
  /// **'Profit / Sales × 100. Shows the share of revenue left as gross profit.'**
  String get overviewLucratividadePercentHelpGrossBody;

  /// No description provided for @overviewLucratividadePercentHelpMarkupBody.
  ///
  /// In en, this message translates to:
  /// **'Profit / Cost × 100. Shows profit relative to replacement cost.'**
  String get overviewLucratividadePercentHelpMarkupBody;

  /// No description provided for @overviewLucratividadeMarkupNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get overviewLucratividadeMarkupNotApplicable;

  /// No description provided for @overviewLucratividadePercentSemanticsCost.
  ///
  /// In en, this message translates to:
  /// **'Cost percentage on sales.'**
  String get overviewLucratividadePercentSemanticsCost;

  /// No description provided for @overviewLucratividadePercentSemanticsGross.
  ///
  /// In en, this message translates to:
  /// **'Gross margin percentage on sales.'**
  String get overviewLucratividadePercentSemanticsGross;

  /// No description provided for @overviewLucratividadePercentSemanticsMarkup.
  ///
  /// In en, this message translates to:
  /// **'Markup percentage on replacement cost.'**
  String get overviewLucratividadePercentSemanticsMarkup;

  /// No description provided for @overviewLucratividadePercentIndicatorHeading.
  ///
  /// In en, this message translates to:
  /// **'Percent indicator'**
  String get overviewLucratividadePercentIndicatorHeading;

  /// No description provided for @overviewLucratividadePercentIndicatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Indicator'**
  String get overviewLucratividadePercentIndicatorLabel;

  /// No description provided for @overviewLucratividadePercentEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'No data to illustrate this metric.'**
  String get overviewLucratividadePercentEmptyHelp;

  /// No description provided for @overviewLucratividadeMarkupUndefinedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Markup is undefined when replacement cost is missing or zero.'**
  String get overviewLucratividadeMarkupUndefinedTooltip;

  /// No description provided for @overviewLucratividadePercentMetricCostTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share of revenue that is replacement cost (cost divided by sales).'**
  String get overviewLucratividadePercentMetricCostTooltip;

  /// No description provided for @overviewLucratividadePercentMetricGrossTooltip.
  ///
  /// In en, this message translates to:
  /// **'Gross margin on sales (profit divided by sales).'**
  String get overviewLucratividadePercentMetricGrossTooltip;

  /// No description provided for @overviewLucratividadePercentMetricMarkupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Markup on replacement cost (profit divided by cost).'**
  String get overviewLucratividadePercentMetricMarkupTooltip;

  /// No description provided for @overviewLucratividadeMensalPercentChronologicalHint.
  ///
  /// In en, this message translates to:
  /// **'Months stay in chronological order (not ranked by value).'**
  String get overviewLucratividadeMensalPercentChronologicalHint;

  /// No description provided for @overviewLucratividadeProfitSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get overviewLucratividadeProfitSeriesLabel;

  /// No description provided for @overviewLucratividadeRevenueSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get overviewLucratividadeRevenueSeriesLabel;

  /// No description provided for @overviewLucratividadeCostSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Replacement cost'**
  String get overviewLucratividadeCostSeriesLabel;

  /// No description provided for @overviewLucratividadeMarginSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get overviewLucratividadeMarginSeriesLabel;

  /// No description provided for @overviewLucratividadeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profitability data for this period.'**
  String get overviewLucratividadeEmpty;

  /// No description provided for @overviewLucratividadeMultiAgentHint.
  ///
  /// In en, this message translates to:
  /// **'No approved branches are available to load profitability. Add or connect a branch first.'**
  String get overviewLucratividadeMultiAgentHint;

  /// No description provided for @overviewLoadingLucratividadeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading profitability by branch chart…'**
  String get overviewLoadingLucratividadeSemantics;

  /// No description provided for @overviewLucratividadeMensalTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly product profitability'**
  String get overviewLucratividadeMensalTitle;

  /// No description provided for @overviewLucratividadeMensalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue, replacement cost and margin per month (selected branch).'**
  String get overviewLucratividadeMensalSubtitle;

  /// No description provided for @overviewLucratividadeMensalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profitability data for this period.'**
  String get overviewLucratividadeMensalEmpty;

  /// No description provided for @overviewLucratividadeMensalMultiAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Select a single branch to view monthly profitability.'**
  String get overviewLucratividadeMensalMultiAgentHint;

  /// No description provided for @overviewLucratividadeMensalSwitchProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get overviewLucratividadeMensalSwitchProfit;

  /// No description provided for @overviewLucratividadeMensalSwitchRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get overviewLucratividadeMensalSwitchRevenue;

  /// No description provided for @overviewLucratividadeMensalSwitchCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get overviewLucratividadeMensalSwitchCost;

  /// No description provided for @overviewLucratividadeMensalSwitchMargin.
  ///
  /// In en, this message translates to:
  /// **'Percent metrics'**
  String get overviewLucratividadeMensalSwitchMargin;

  /// No description provided for @overviewLucratividadeMensalProfitSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get overviewLucratividadeMensalProfitSeriesLabel;

  /// No description provided for @overviewLucratividadeMensalRevenueSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get overviewLucratividadeMensalRevenueSeriesLabel;

  /// No description provided for @overviewLucratividadeMensalCostSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Replacement cost'**
  String get overviewLucratividadeMensalCostSeriesLabel;

  /// No description provided for @overviewLucratividadeMensalMarginSeriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get overviewLucratividadeMensalMarginSeriesLabel;

  /// No description provided for @overviewLoadingLucratividadeMensalSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading monthly product profitability chart…'**
  String get overviewLoadingLucratividadeMensalSemantics;

  /// No description provided for @salesHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesHubTitle;

  /// No description provided for @salesHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access and manage commercial information by category.'**
  String get salesHubSubtitle;

  /// No description provided for @shellNavSalesMonitoringLabel.
  ///
  /// In en, this message translates to:
  /// **'Track sales'**
  String get shellNavSalesMonitoringLabel;

  /// No description provided for @shellNavSalesMonitoringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map and filter-based refresh'**
  String get shellNavSalesMonitoringSubtitle;

  /// No description provided for @salesLiveMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Track sales'**
  String get salesLiveMapTitle;

  /// No description provided for @salesLiveMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Brazil map with sales by branch and filter-based refresh.'**
  String get salesLiveMapSubtitle;

  /// No description provided for @salesLiveMapSessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again to query.'**
  String get salesLiveMapSessionExpiredMessage;

  /// No description provided for @salesLiveMapAgentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get salesLiveMapAgentsLabel;

  /// No description provided for @salesLiveMapPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get salesLiveMapPeriodLabel;

  /// No description provided for @salesLiveMapMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get salesLiveMapMapLabel;

  /// No description provided for @salesLiveMapParametersLabel.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get salesLiveMapParametersLabel;

  /// No description provided for @salesLiveMapParametersSummary.
  ///
  /// In en, this message translates to:
  /// **'{origin} | Finance {finance} | Pre-sale {preSale}'**
  String salesLiveMapParametersSummary(
    String origin,
    String finance,
    String preSale,
  );

  /// No description provided for @salesLiveMapAgentsLoadingSummary.
  ///
  /// In en, this message translates to:
  /// **'Loading branches'**
  String get salesLiveMapAgentsLoadingSummary;

  /// No description provided for @salesLiveMapAgentsNoneSummary.
  ///
  /// In en, this message translates to:
  /// **'No branches'**
  String get salesLiveMapAgentsNoneSummary;

  /// No description provided for @salesLiveMapAgentsAllWithTokenSummary.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String salesLiveMapAgentsAllWithTokenSummary(int count);

  /// No description provided for @salesLiveMapAgentsSelectedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es)'**
  String salesLiveMapAgentsSelectedSummary(int count);

  /// No description provided for @salesLiveMapDateRangeFormat.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String salesLiveMapDateRangeFormat(String start, String end);

  /// No description provided for @salesLiveMapPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get salesLiveMapPeriodToday;

  /// No description provided for @salesLiveMapPeriodLastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get salesLiveMapPeriodLastSevenDays;

  /// No description provided for @salesLiveMapPeriodLastSevenDaysShort.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get salesLiveMapPeriodLastSevenDaysShort;

  /// No description provided for @salesLiveMapPeriodCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month'**
  String get salesLiveMapPeriodCurrentMonth;

  /// No description provided for @salesLiveMapPeriodCurrentMonthShort.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get salesLiveMapPeriodCurrentMonthShort;

  /// No description provided for @salesLiveMapPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get salesLiveMapPeriodCustom;

  /// No description provided for @salesLiveMapMapPresetPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get salesLiveMapMapPresetPoints;

  /// No description provided for @salesLiveMapMapPresetBubbles.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get salesLiveMapMapPresetBubbles;

  /// No description provided for @salesLiveMapMapPresetMunicipalities.
  ///
  /// In en, this message translates to:
  /// **'Municipalities'**
  String get salesLiveMapMapPresetMunicipalities;

  /// No description provided for @salesLiveMapMapPresetMunicipalitiesShort.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get salesLiveMapMapPresetMunicipalitiesShort;

  /// No description provided for @salesLiveMapMapPresetStateBubbles.
  ///
  /// In en, this message translates to:
  /// **'Bubbles by state'**
  String get salesLiveMapMapPresetStateBubbles;

  /// No description provided for @salesLiveMapMapPresetStateBubblesShort.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get salesLiveMapMapPresetStateBubblesShort;

  /// No description provided for @salesLiveMapMapPresetStoreIcon.
  ///
  /// In en, this message translates to:
  /// **'Store icon'**
  String get salesLiveMapMapPresetStoreIcon;

  /// No description provided for @salesLiveMapMapPresetStoreIconShort.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get salesLiveMapMapPresetStoreIconShort;

  /// No description provided for @salesLiveMapLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load sales tracking'**
  String get salesLiveMapLoadErrorTitle;

  /// No description provided for @salesLiveMapLoadErrorRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing the query again.'**
  String get salesLiveMapLoadErrorRetryMessage;

  /// No description provided for @salesLiveMapMissingClientTokenSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'No selected agent has a local token to execute the query.'**
  String get salesLiveMapMissingClientTokenSetupMessage;

  /// No description provided for @salesLiveMapEmptyNoSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales in period'**
  String get salesLiveMapEmptyNoSalesTitle;

  /// No description provided for @salesLiveMapEmptyNoSalesMessage.
  ///
  /// In en, this message translates to:
  /// **'The query ran, but did not find sales for the current filters.'**
  String get salesLiveMapEmptyNoSalesMessage;

  /// No description provided for @salesLiveMapEmptySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Selection has no result'**
  String get salesLiveMapEmptySelectionTitle;

  /// No description provided for @salesLiveMapEmptySelectionMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected branches did not return sales in this period. Clear the selection to reload all available branches.'**
  String get salesLiveMapEmptySelectionMessage;

  /// No description provided for @salesLiveMapChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales by branch in Brazil'**
  String get salesLiveMapChartTitle;

  /// No description provided for @salesLiveMapChartSubtitlePending.
  ///
  /// In en, this message translates to:
  /// **'Period {period}.'**
  String salesLiveMapChartSubtitlePending(String period);

  /// No description provided for @salesLiveMapChartSubtitleLoaded.
  ///
  /// In en, this message translates to:
  /// **'Period {period}. {mappedCount} of {totalCount} branches positioned.'**
  String salesLiveMapChartSubtitleLoaded(
    String period,
    int mappedCount,
    int totalCount,
  );

  /// No description provided for @salesLiveMapPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Partial tracking'**
  String get salesLiveMapPartialTitle;

  /// No description provided for @salesLiveMapAgentQuerySummary.
  ///
  /// In en, this message translates to:
  /// **'Branches: {plannedCount} planned | {queriedCount} queried | {salesCount} with sales | {noSalesCount} without sales'**
  String salesLiveMapAgentQuerySummary(
    int plannedCount,
    int queriedCount,
    int salesCount,
    int noSalesCount,
  );

  /// No description provided for @salesLiveMapPartialFailedAgents.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) failed in the last query.'**
  String salesLiveMapPartialFailedAgents(int count);

  /// No description provided for @salesLiveMapPartialMissingTokenAgents.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) without local client_token.'**
  String salesLiveMapPartialMissingTokenAgents(int count);

  /// No description provided for @salesLiveMapPartialOfflineAgents.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) outside hub presence.'**
  String salesLiveMapPartialOfflineAgents(int count);

  /// No description provided for @salesLiveMapPartialRowCapReached.
  ///
  /// In en, this message translates to:
  /// **'{count} agent(s) reached the query row limit; the map may be incomplete.'**
  String salesLiveMapPartialRowCapReached(int count);

  /// No description provided for @salesLiveMapPartialMissingCoordinates.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) without resolved coordinates.'**
  String salesLiveMapPartialMissingCoordinates(int count);

  /// No description provided for @salesLiveMapPartialNoSalesAgents.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) returned no sales in the period.'**
  String salesLiveMapPartialNoSalesAgents(int count);

  /// No description provided for @salesLiveMapPartialZeroedBranches.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) shown with zero sales.'**
  String salesLiveMapPartialZeroedBranches(int count);

  /// No description provided for @salesLiveMapPartialUnavailableSalesBranches.
  ///
  /// In en, this message translates to:
  /// **'{count} branch(es) shown with sales unavailable due to query failure.'**
  String salesLiveMapPartialUnavailableSalesBranches(int count);

  /// No description provided for @salesLiveMapNoSalesAgentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches without sales'**
  String get salesLiveMapNoSalesAgentsTitle;

  /// No description provided for @salesLiveMapTechnicalDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical diagnostics'**
  String get salesLiveMapTechnicalDiagnosticsTitle;

  /// No description provided for @salesLiveMapTechnicalDiagnosticsFilters.
  ///
  /// In en, this message translates to:
  /// **'Active filters'**
  String get salesLiveMapTechnicalDiagnosticsFilters;

  /// No description provided for @salesLiveMapTechnicalDiagnosticsQuery.
  ///
  /// In en, this message translates to:
  /// **'Query diagnostics'**
  String get salesLiveMapTechnicalDiagnosticsQuery;

  /// No description provided for @salesLiveMapFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking filters'**
  String get salesLiveMapFiltersTitle;

  /// No description provided for @salesLiveMapFiltersDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose branches, period, and map view type.'**
  String get salesLiveMapFiltersDescription;

  /// No description provided for @salesLiveMapBranchesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get salesLiveMapBranchesSectionTitle;

  /// No description provided for @salesLiveMapBranchesSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The list appears after the first map refresh.'**
  String get salesLiveMapBranchesSectionSubtitle;

  /// No description provided for @salesLiveMapSelectAtLeastOneTokenBranch.
  ///
  /// In en, this message translates to:
  /// **'Select at least one branch with a local token.'**
  String get salesLiveMapSelectAtLeastOneTokenBranch;

  /// No description provided for @salesLiveMapNoApprovedAgents.
  ///
  /// In en, this message translates to:
  /// **'No approved branch is available for query.'**
  String get salesLiveMapNoApprovedAgents;

  /// No description provided for @salesLiveMapBranchesLoadBeforeSelection.
  ///
  /// In en, this message translates to:
  /// **'Refresh the map once to list available branches.'**
  String get salesLiveMapBranchesLoadBeforeSelection;

  /// No description provided for @salesLiveMapSelectAllTokenBacked.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get salesLiveMapSelectAllTokenBacked;

  /// No description provided for @salesLiveMapClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get salesLiveMapClearSelection;

  /// No description provided for @salesLiveMapClearBranchSelectionAction.
  ///
  /// In en, this message translates to:
  /// **'Clear branch selection'**
  String get salesLiveMapClearBranchSelectionAction;

  /// No description provided for @salesLiveMapClearSavedFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Clear saved filters'**
  String get salesLiveMapClearSavedFiltersAction;

  /// No description provided for @salesLiveMapMissingLocalToken.
  ///
  /// In en, this message translates to:
  /// **'No local token'**
  String get salesLiveMapMissingLocalToken;

  /// No description provided for @salesLiveMapCustomPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom period'**
  String get salesLiveMapCustomPeriodLabel;

  /// No description provided for @salesLiveMapCustomPeriodHelper.
  ///
  /// In en, this message translates to:
  /// **'Limit of {maxDays} days per refresh.'**
  String salesLiveMapCustomPeriodHelper(int maxDays);

  /// No description provided for @salesLiveMapCustomPeriodPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get salesLiveMapCustomPeriodPickerTitle;

  /// No description provided for @salesLiveMapMapTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Map type'**
  String get salesLiveMapMapTypeTitle;

  /// No description provided for @salesLiveMapMapTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how points and totals should appear.'**
  String get salesLiveMapMapTypeSubtitle;

  /// No description provided for @salesLiveMapDetailLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get salesLiveMapDetailLabel;

  /// No description provided for @salesLiveMapDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the aggregation level shown on the map.'**
  String get salesLiveMapDetailSubtitle;

  /// No description provided for @salesLiveMapDetailBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get salesLiveMapDetailBranches;

  /// No description provided for @salesLiveMapDetailMunicipalities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get salesLiveMapDetailMunicipalities;

  /// No description provided for @salesLiveMapDetailStates.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get salesLiveMapDetailStates;

  /// No description provided for @salesLiveMapVisualLabel.
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get salesLiveMapVisualLabel;

  /// No description provided for @salesLiveMapVisualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the marker style for branch and city views.'**
  String get salesLiveMapVisualSubtitle;

  /// No description provided for @salesLiveMapVisualDot.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get salesLiveMapVisualDot;

  /// No description provided for @salesLiveMapVisualBubble.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get salesLiveMapVisualBubble;

  /// No description provided for @salesLiveMapVisualStoreIcon.
  ///
  /// In en, this message translates to:
  /// **'Store icon'**
  String get salesLiveMapVisualStoreIcon;

  /// No description provided for @salesLiveMapDetailAutoMunicipalities.
  ///
  /// In en, this message translates to:
  /// **'Above {threshold} branches, cities are shown automatically for readability.'**
  String salesLiveMapDetailAutoMunicipalities(int threshold);

  /// No description provided for @salesLiveMapKpiRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get salesLiveMapKpiRevenue;

  /// No description provided for @salesLiveMapKpiSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesLiveMapKpiSales;

  /// No description provided for @salesLiveMapKpiBranchesOnMap.
  ///
  /// In en, this message translates to:
  /// **'Branches on map'**
  String get salesLiveMapKpiBranchesOnMap;

  /// No description provided for @salesLiveMapKpiBranchesOnMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Geo: {providedCount} provided | {ibgeCount} IBGE | {cepCount} ZIP | {cityUfCount} city/state | {capitalUfCount} capital/state | {stateUfCount} state | {missingCount} without coordinates'**
  String salesLiveMapKpiBranchesOnMapTooltip(
    int providedCount,
    int ibgeCount,
    int cepCount,
    int cityUfCount,
    int capitalUfCount,
    int stateUfCount,
    int missingCount,
  );

  /// No description provided for @salesLiveMapKpiMunicipalitiesOnMap.
  ///
  /// In en, this message translates to:
  /// **'Cities on map'**
  String get salesLiveMapKpiMunicipalitiesOnMap;

  /// No description provided for @salesLiveMapKpiQueriedAgents.
  ///
  /// In en, this message translates to:
  /// **'Queried branches'**
  String get salesLiveMapKpiQueriedAgents;

  /// No description provided for @salesBranchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'BRANCHES'**
  String get salesBranchFilterLabel;

  /// No description provided for @salesBranchFilterEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Load the report to list branches.'**
  String get salesBranchFilterEmptyHint;

  /// No description provided for @salesBranchFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select branches'**
  String get salesBranchFilterSheetTitle;

  /// No description provided for @salesBranchFilterSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search branches…'**
  String get salesBranchFilterSheetSearchHint;

  /// No description provided for @salesBranchFilterNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No branches match your search.'**
  String get salesBranchFilterNoSearchResults;

  /// No description provided for @salesBranchFilterMissingClientTokenBanner.
  ///
  /// In en, this message translates to:
  /// **'Branches without a client token on this device cannot run SQL queries. “Online” only reflects hub connectivity.'**
  String get salesBranchFilterMissingClientTokenBanner;

  /// No description provided for @salesBranchPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get salesBranchPickerEmpty;

  /// No description provided for @salesBranchRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch selection required'**
  String get salesBranchRequiredTitle;

  /// No description provided for @salesBranchRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a branch to view this information.'**
  String get salesBranchRequiredMessage;

  /// No description provided for @salesAgentPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get salesAgentPickerLabel;

  /// No description provided for @salesAgentPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get salesAgentPickerEmpty;

  /// No description provided for @salesAgentPickerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get salesAgentPickerSheetTitle;

  /// No description provided for @salesAgentRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch selection required'**
  String get salesAgentRequiredTitle;

  /// No description provided for @salesAgentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a branch to view this information.'**
  String get salesAgentRequiredMessage;

  /// No description provided for @salesCardOpenAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Accounts'**
  String get salesCardOpenAccountsTitle;

  /// No description provided for @salesCardPaidAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid Accounts'**
  String get salesCardPaidAccountsTitle;

  /// No description provided for @salesCardPaymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get salesCardPaymentHistoryTitle;

  /// No description provided for @salesCardNewPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'New Payment'**
  String get salesCardNewPaymentTitle;

  /// No description provided for @salesCardProdutoRankLucroTitle.
  ///
  /// In en, this message translates to:
  /// **'Product ranking'**
  String get salesCardProdutoRankLucroTitle;

  /// No description provided for @salesCardMonthlyPnlTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly P&L'**
  String get salesCardMonthlyPnlTitle;

  /// No description provided for @salesCardResumoTotalDiarioVendasTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily sales totals'**
  String get salesCardResumoTotalDiarioVendasTitle;

  /// No description provided for @salesAutoRefreshOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get salesAutoRefreshOff;

  /// No description provided for @salesAutoRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh'**
  String get salesAutoRefreshTooltip;

  /// No description provided for @salesAutoRefreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get salesAutoRefreshNow;

  /// No description provided for @salesAutoRefreshLastUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String salesAutoRefreshLastUpdatedAt(String time);

  /// No description provided for @salesAutoRefreshNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next in {time}'**
  String salesAutoRefreshNextIn(String time);

  /// No description provided for @salesAutoRefreshRetryIn.
  ///
  /// In en, this message translates to:
  /// **'Retry in {time}'**
  String salesAutoRefreshRetryIn(String time);

  /// No description provided for @salesAutoRefreshPaused.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh paused'**
  String get salesAutoRefreshPaused;

  /// No description provided for @salesAutoRefreshPausedLoading.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh paused while loading'**
  String get salesAutoRefreshPausedLoading;

  /// No description provided for @salesAutoRefreshPausedMissingLocalToken.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh paused: local token required'**
  String get salesAutoRefreshPausedMissingLocalToken;

  /// No description provided for @salesAutoRefreshPausedNoEligibleSelection.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh paused: select an eligible branch'**
  String get salesAutoRefreshPausedNoEligibleSelection;

  /// No description provided for @salesAutoRefreshPausedUnsupportedViewport.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh available on desktop'**
  String get salesAutoRefreshPausedUnsupportedViewport;

  /// No description provided for @salesAutoRefreshPausedHidden.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh paused while this screen is hidden'**
  String get salesAutoRefreshPausedHidden;

  /// No description provided for @salesDailyTotalsChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily sales'**
  String get salesDailyTotalsChartTitle;

  /// No description provided for @salesDailyTotalsChartTitleAmount.
  ///
  /// In en, this message translates to:
  /// **'Daily revenue'**
  String get salesDailyTotalsChartTitleAmount;

  /// No description provided for @salesDailyTotalsChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Totals per calendar day for the selected branch and reference month.'**
  String get salesDailyTotalsChartSubtitle;

  /// No description provided for @salesDailyTotalsChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No daily sales data for this branch and month.'**
  String get salesDailyTotalsChartEmpty;

  /// No description provided for @salesDailyTotalsChartLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load daily sales for this branch. Try again later.'**
  String get salesDailyTotalsChartLoadFailed;

  /// No description provided for @salesDailyTotalsChartSemanticsCount.
  ///
  /// In en, this message translates to:
  /// **'Daily sales count and revenue chart for the selected branch'**
  String get salesDailyTotalsChartSemanticsCount;

  /// No description provided for @salesDailyTotalsChartSemanticsAmount.
  ///
  /// In en, this message translates to:
  /// **'Daily revenue and sales count chart for the selected branch'**
  String get salesDailyTotalsChartSemanticsAmount;

  /// No description provided for @salesDailyTotalsChartScopeHint.
  ///
  /// In en, this message translates to:
  /// **'Single branch; totals follow the reference month filter.'**
  String get salesDailyTotalsChartScopeHint;

  /// Tooltip for daily sales bars on the Sales daily totals screen.
  ///
  /// In en, this message translates to:
  /// **'{date}: {salesCount} sales - {salesAmount}'**
  String salesDailyTotalsChartTooltip(
    String date,
    String salesCount,
    String salesAmount,
  );

  /// No description provided for @salesDailyTotalsMetricSalesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesDailyTotalsMetricSalesCountLabel;

  /// No description provided for @salesDailyTotalsMetricSalesAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get salesDailyTotalsMetricSalesAmountLabel;

  /// No description provided for @salesDailyTotalsChartSubtitleCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Totals per calendar day for the selected branch from {startDate} through {endDate}.'**
  String salesDailyTotalsChartSubtitleCustomRange(
    String startDate,
    String endDate,
  );

  /// No description provided for @salesDailyTotalsChartScopeHintCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Single branch; daily totals follow the selected date range. Monthly charts still use the reference month.'**
  String get salesDailyTotalsChartScopeHintCustomRange;

  /// No description provided for @salesDailyTotalsFilterSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily totals'**
  String get salesDailyTotalsFilterSummaryLabel;

  /// No description provided for @salesDailyTotalsFilterSummaryCustomRangeValue.
  ///
  /// In en, this message translates to:
  /// **'{startDate} – {endDate}'**
  String salesDailyTotalsFilterSummaryCustomRangeValue(
    String startDate,
    String endDate,
  );

  /// No description provided for @salesDailyTotalsFilterDailyPeriodSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily totals period'**
  String get salesDailyTotalsFilterDailyPeriodSectionTitle;

  /// No description provided for @salesDailyTotalsFilterDailyPeriodSameMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Same as reference month'**
  String get salesDailyTotalsFilterDailyPeriodSameMonthLabel;

  /// No description provided for @salesDailyTotalsFilterDailyPeriodCustomRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get salesDailyTotalsFilterDailyPeriodCustomRangeLabel;

  /// No description provided for @salesDailyTotalsFilterDailyPeriodPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale date range'**
  String get salesDailyTotalsFilterDailyPeriodPickerLabel;

  /// No description provided for @salesDailyTotalsFilterDailyPeriodPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get salesDailyTotalsFilterDailyPeriodPickerTitle;

  /// No description provided for @salesDailyTotalsFilterDailyPeriodHelper.
  ///
  /// In en, this message translates to:
  /// **'At most {maxDays} calendar days.'**
  String salesDailyTotalsFilterDailyPeriodHelper(int maxDays);

  /// No description provided for @salesDailyTotalsFilterMonthlyChartsAnchorHint.
  ///
  /// In en, this message translates to:
  /// **'Monthly P&L charts always use the reference month above; only daily totals use the range below.'**
  String get salesDailyTotalsFilterMonthlyChartsAnchorHint;

  /// No description provided for @salesDailyTotalsFilterCustomRangeAnchorIndependenceBanner.
  ///
  /// In en, this message translates to:
  /// **'Changing the reference month updates monthly charts only. Daily totals follow the sale dates below until you change this range or switch to same month mode.'**
  String get salesDailyTotalsFilterCustomRangeAnchorIndependenceBanner;

  /// No description provided for @salesDailyTotalsFilterRangeTooLongSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Choose a period of at most {maxDays} days.'**
  String salesDailyTotalsFilterRangeTooLongSnackbar(int maxDays);

  /// No description provided for @salesMonthlyPnlFullscreenDailyTotalsPeriodSuffix.
  ///
  /// In en, this message translates to:
  /// **'Daily totals: {startDate}–{endDate}.'**
  String salesMonthlyPnlFullscreenDailyTotalsPeriodSuffix(
    String startDate,
    String endDate,
  );

  /// No description provided for @salesCardProdutoTendenciaTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales trend'**
  String get salesCardProdutoTendenciaTitle;

  /// No description provided for @salesCardProdutoTendenciaMediaMovelTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales trend (moving average)'**
  String get salesCardProdutoTendenciaMediaMovelTitle;

  /// No description provided for @salesMonthlyPnlPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales value, profit, and merchandise cost by month for the selected branch. The window ends in the reference month.'**
  String get salesMonthlyPnlPageSubtitle;

  /// No description provided for @salesMonthlyPnlFilterAnchorMonth.
  ///
  /// In en, this message translates to:
  /// **'Reference month'**
  String get salesMonthlyPnlFilterAnchorMonth;

  /// No description provided for @salesMonthlyPnlChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly P&L'**
  String get salesMonthlyPnlChartTitle;

  /// No description provided for @salesMonthlyPnlChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales value, profit, and merchandise cost by month (selected branch).'**
  String get salesMonthlyPnlChartSubtitle;

  /// No description provided for @salesMonthlyPnlSeriesSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesMonthlyPnlSeriesSalesLabel;

  /// No description provided for @salesMonthlyPnlSeriesProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get salesMonthlyPnlSeriesProfitLabel;

  /// No description provided for @salesMonthlyPnlSeriesCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Merchandise cost'**
  String get salesMonthlyPnlSeriesCostLabel;

  /// No description provided for @salesMonthlyPnlEmpty.
  ///
  /// In en, this message translates to:
  /// **'No monthly data for this period.'**
  String get salesMonthlyPnlEmpty;

  /// No description provided for @salesMonthlyPnlLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the monthly chart. Try again later.'**
  String get salesMonthlyPnlLoadFailed;

  /// No description provided for @salesMonthlyPnlChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Monthly P&L chart with sales value, profit, and merchandise cost for the selected branch'**
  String get salesMonthlyPnlChartSemantics;

  /// No description provided for @salesMonthlyPnlBarChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly comparison (bars)'**
  String get salesMonthlyPnlBarChartTitle;

  /// No description provided for @salesMonthlyPnlBarChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bars use the same monthly totals as the line chart above (aggregated sales, profit, and merchandise cost—not per-item averages). Percent metrics are computed from those monthly totals.'**
  String get salesMonthlyPnlBarChartSubtitle;

  /// No description provided for @salesMonthlyPnlBarDisplayValuesLabel.
  ///
  /// In en, this message translates to:
  /// **'Amounts'**
  String get salesMonthlyPnlBarDisplayValuesLabel;

  /// No description provided for @salesMonthlyPnlBarDisplayPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Percent metrics'**
  String get salesMonthlyPnlBarDisplayPercentLabel;

  /// No description provided for @salesMonthlyPnlBarDisplayValuesCompactLabel.
  ///
  /// In en, this message translates to:
  /// **'Amt'**
  String get salesMonthlyPnlBarDisplayValuesCompactLabel;

  /// No description provided for @salesMonthlyPnlBarDisplayPercentCompactLabel.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get salesMonthlyPnlBarDisplayPercentCompactLabel;

  /// No description provided for @salesMonthlyPnlFullscreenFilterSummary.
  ///
  /// In en, this message translates to:
  /// **'{agentsLabel}: {agentName}. {anchorLabel}: {anchorValue}.'**
  String salesMonthlyPnlFullscreenFilterSummary(
    String agentsLabel,
    String agentName,
    String anchorLabel,
    String anchorValue,
  );

  /// No description provided for @salesMonthlyPnlBarZerosOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing to plot for this view in the selected window (all values are zero).'**
  String get salesMonthlyPnlBarZerosOnlyMessage;

  /// No description provided for @salesMonthlyPnlBarChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Monthly grouped bar chart for sales, profit, and merchandise cost'**
  String get salesMonthlyPnlBarChartSemantics;

  /// No description provided for @salesMonthlyPnlBarSummarySemantics.
  ///
  /// In en, this message translates to:
  /// **'Period totals: {totalSales} sales, {totalProfit} profit, {totalCost} merchandise cost. Highest sales month: {topMonth} ({topSales}).'**
  String salesMonthlyPnlBarSummarySemantics(
    String totalSales,
    String totalProfit,
    String totalCost,
    String topMonth,
    String topSales,
  );

  /// No description provided for @salesProdutoRankLucroChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get salesProdutoRankLucroChartTitle;

  /// No description provided for @salesProdutoRankLucroFilterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get salesProdutoRankLucroFilterPeriod;

  /// No description provided for @salesProdutoRankLucroFilterSortBy.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get salesProdutoRankLucroFilterSortBy;

  /// No description provided for @salesProdutoRankLucroSortQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity sold'**
  String get salesProdutoRankLucroSortQuantity;

  /// No description provided for @salesProdutoRankLucroSortProfit.
  ///
  /// In en, this message translates to:
  /// **'Total profit'**
  String get salesProdutoRankLucroSortProfit;

  /// No description provided for @salesProdutoTendenciaPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Executive snapshot of product sales trend with summary, movers, and paged details.'**
  String get salesProdutoTendenciaPageSubtitle;

  /// No description provided for @salesProdutoTendenciaFilterCurrentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current period'**
  String get salesProdutoTendenciaFilterCurrentPeriod;

  /// No description provided for @salesProdutoTendenciaFilterPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get salesProdutoTendenciaFilterPreviousPeriod;

  /// No description provided for @salesProdutoTendenciaComparisonCurrentChip.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get salesProdutoTendenciaComparisonCurrentChip;

  /// No description provided for @salesProdutoTendenciaComparisonPreviousChip.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get salesProdutoTendenciaComparisonPreviousChip;

  /// No description provided for @salesProdutoTendenciaFilterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search term'**
  String get salesProdutoTendenciaFilterSearch;

  /// No description provided for @salesProdutoTendenciaFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Product, group, or brand'**
  String get salesProdutoTendenciaFilterSearchHint;

  /// No description provided for @salesProdutoTendenciaFilterClassification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get salesProdutoTendenciaFilterClassification;

  /// No description provided for @salesProdutoTendenciaFilterGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get salesProdutoTendenciaFilterGroup;

  /// No description provided for @salesProdutoTendenciaFilterBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get salesProdutoTendenciaFilterBrand;

  /// No description provided for @salesProdutoTendenciaFilterPageSize.
  ///
  /// In en, this message translates to:
  /// **'Rows per page'**
  String get salesProdutoTendenciaFilterPageSize;

  /// No description provided for @salesProdutoTendenciaFilterAllOption.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get salesProdutoTendenciaFilterAllOption;

  /// No description provided for @salesProdutoTendenciaFilterQuickPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested periods'**
  String get salesProdutoTendenciaFilterQuickPeriodsTitle;

  /// No description provided for @salesProdutoTendenciaFilterQuickPeriodsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a base window and the report will align the comparison for you.'**
  String get salesProdutoTendenciaFilterQuickPeriodsSubtitle;

  /// No description provided for @salesProdutoTendenciaFilterPresetCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month'**
  String get salesProdutoTendenciaFilterPresetCurrentMonth;

  /// No description provided for @salesProdutoTendenciaFilterPresetPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get salesProdutoTendenciaFilterPresetPreviousMonth;

  /// No description provided for @salesProdutoTendenciaFilterPresetLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get salesProdutoTendenciaFilterPresetLast7Days;

  /// No description provided for @salesProdutoTendenciaFilterPresetLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get salesProdutoTendenciaFilterPresetLast30Days;

  /// No description provided for @salesProdutoTendenciaFilterAutoAdjustPreviousAction.
  ///
  /// In en, this message translates to:
  /// **'Adjust previous period'**
  String get salesProdutoTendenciaFilterAutoAdjustPreviousAction;

  /// No description provided for @salesProdutoTendenciaFilterRuleHelperTitle.
  ///
  /// In en, this message translates to:
  /// **'Comparison rule'**
  String get salesProdutoTendenciaFilterRuleHelperTitle;

  /// No description provided for @salesProdutoTendenciaFilterRuleHelper.
  ///
  /// In en, this message translates to:
  /// **'Compare full months with full months, or custom periods with the same number of days.'**
  String get salesProdutoTendenciaFilterRuleHelper;

  /// No description provided for @salesProdutoTendenciaFilterApplyDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Comparison needs adjustment'**
  String get salesProdutoTendenciaFilterApplyDisabledTitle;

  /// No description provided for @salesProdutoTendenciaFilterApplyDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Update the periods above to enable the apply action.'**
  String get salesProdutoTendenciaFilterApplyDisabledHint;

  /// No description provided for @salesProdutoTendenciaFilterDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String salesProdutoTendenciaFilterDurationDays(int count);

  /// No description provided for @salesProdutoTendenciaFilterRangeKindFullMonth.
  ///
  /// In en, this message translates to:
  /// **'Full month'**
  String get salesProdutoTendenciaFilterRangeKindFullMonth;

  /// No description provided for @salesProdutoTendenciaFilterRangeKindCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom period'**
  String get salesProdutoTendenciaFilterRangeKindCustom;

  /// No description provided for @salesProdutoTendenciaFilterPeriodsOrderError.
  ///
  /// In en, this message translates to:
  /// **'The previous period must end before the current period starts.'**
  String get salesProdutoTendenciaFilterPeriodsOrderError;

  /// No description provided for @salesProdutoTendenciaFilterPeriodsEquivalentWindowError.
  ///
  /// In en, this message translates to:
  /// **'Use equivalent comparison windows: full month versus full month, or custom period versus custom period with the same number of days.'**
  String get salesProdutoTendenciaFilterPeriodsEquivalentWindowError;

  /// No description provided for @salesProdutoTendenciaSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Executive summary'**
  String get salesProdutoTendenciaSummaryTitle;

  /// No description provided for @salesProdutoTendenciaSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overview of product movement by trend classification.'**
  String get salesProdutoTendenciaSummarySubtitle;

  /// No description provided for @salesProdutoTendenciaSummaryByClassificacaoTitle.
  ///
  /// In en, this message translates to:
  /// **'Products by classification'**
  String get salesProdutoTendenciaSummaryByClassificacaoTitle;

  /// No description provided for @salesProdutoTendenciaSummaryByClassificacaoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution and impact in the loaded page.'**
  String get salesProdutoTendenciaSummaryByClassificacaoSubtitle;

  /// No description provided for @salesProdutoTendenciaTopMoversTitle.
  ///
  /// In en, this message translates to:
  /// **'Top movers'**
  String get salesProdutoTendenciaTopMoversTitle;

  /// No description provided for @salesProdutoTendenciaTopMoversSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highest growth and decline in the selected period.'**
  String get salesProdutoTendenciaTopMoversSubtitle;

  /// No description provided for @salesProdutoTendenciaTopGainersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 gainers'**
  String get salesProdutoTendenciaTopGainersTitle;

  /// No description provided for @salesProdutoTendenciaTopLosersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 losers'**
  String get salesProdutoTendenciaTopLosersTitle;

  /// No description provided for @salesProdutoTendenciaDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed rows'**
  String get salesProdutoTendenciaDetailsTitle;

  /// No description provided for @salesProdutoTendenciaDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paginated detail with product, classification, and group.'**
  String get salesProdutoTendenciaDetailsSubtitle;

  /// No description provided for @salesProdutoTendenciaDetailsHorizontalScrollCaption.
  ///
  /// In en, this message translates to:
  /// **'Swipe sideways to see all columns.'**
  String get salesProdutoTendenciaDetailsHorizontalScrollCaption;

  /// No description provided for @salesProdutoTendenciaFiltersAppliedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Filters applied. Refreshing data.'**
  String get salesProdutoTendenciaFiltersAppliedSnackbar;

  /// No description provided for @salesProdutoTendenciaLoadingTrendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading sales trend…'**
  String get salesProdutoTendenciaLoadingTrendSemantics;

  /// No description provided for @salesProdutoTendenciaDetailsEntityLabel.
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get salesProdutoTendenciaDetailsEntityLabel;

  /// No description provided for @salesProdutoTendenciaNoData.
  ///
  /// In en, this message translates to:
  /// **'No trend data for the selected filters.'**
  String get salesProdutoTendenciaNoData;

  /// No description provided for @salesProdutoTendenciaKpiGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing products'**
  String get salesProdutoTendenciaKpiGrowing;

  /// No description provided for @salesProdutoTendenciaKpiFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling products'**
  String get salesProdutoTendenciaKpiFalling;

  /// No description provided for @salesProdutoTendenciaKpiNewProducts.
  ///
  /// In en, this message translates to:
  /// **'New products'**
  String get salesProdutoTendenciaKpiNewProducts;

  /// No description provided for @salesProdutoTendenciaKpiStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped selling'**
  String get salesProdutoTendenciaKpiStopped;

  /// No description provided for @salesProdutoTendenciaKpiNetImpact.
  ///
  /// In en, this message translates to:
  /// **'Net impact (qty)'**
  String get salesProdutoTendenciaKpiNetImpact;

  /// No description provided for @salesProdutoTendenciaColProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get salesProdutoTendenciaColProduct;

  /// No description provided for @salesProdutoTendenciaColClassificacao.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get salesProdutoTendenciaColClassificacao;

  /// No description provided for @salesProdutoTendenciaColGrupo.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get salesProdutoTendenciaColGrupo;

  /// No description provided for @salesProdutoTendenciaColDiferenca.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get salesProdutoTendenciaColDiferenca;

  /// No description provided for @salesProdutoTendenciaColPercentual.
  ///
  /// In en, this message translates to:
  /// **'Trend %'**
  String get salesProdutoTendenciaColPercentual;

  /// No description provided for @salesProdutoTendenciaClassificacaoStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped selling'**
  String get salesProdutoTendenciaClassificacaoStopped;

  /// No description provided for @salesProdutoTendenciaClassificacaoNew.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get salesProdutoTendenciaClassificacaoNew;

  /// No description provided for @salesProdutoTendenciaClassificacaoGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get salesProdutoTendenciaClassificacaoGrowing;

  /// No description provided for @salesProdutoTendenciaClassificacaoFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get salesProdutoTendenciaClassificacaoFalling;

  /// No description provided for @salesProdutoTendenciaClassificacaoStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get salesProdutoTendenciaClassificacaoStable;

  /// No description provided for @salesProdutoTendenciaActiveFiltersSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No additional filters} one{1 additional filter} other{{count} additional filters}}'**
  String salesProdutoTendenciaActiveFiltersSummary(int count);

  /// No description provided for @salesProdutoTendenciaDetailsNotice.
  ///
  /// In en, this message translates to:
  /// **'Results may contain more rows. Use pagination to load next pages (current size: {pageSize}).'**
  String salesProdutoTendenciaDetailsNotice(String pageSize);

  /// No description provided for @salesProdutoTendenciaMediaMovelPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moving-average dashboard with classification summary and paged product detail.'**
  String get salesProdutoTendenciaMediaMovelPageSubtitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDias.
  ///
  /// In en, this message translates to:
  /// **'Window size'**
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDias;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint.
  ///
  /// In en, this message translates to:
  /// **'Number of days used in each moving average'**
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHint;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper.
  ///
  /// In en, this message translates to:
  /// **'Use the same window size for the current and previous averages.'**
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasHelper;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number of days greater than zero.'**
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasInvalid;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick windows'**
  String get salesProdutoTendenciaMediaMovelFilterQuantidadeDiasPresetsTitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Use at most {maxDays} days.'**
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasTooLarge(
    int maxDays,
  );

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(int count);

  /// No description provided for @salesProdutoTendenciaMediaMovelActiveFiltersSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No additional filters} one{1 additional filter} other{{count} additional filters}}'**
  String salesProdutoTendenciaMediaMovelActiveFiltersSummary(int count);

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Product or group'**
  String get salesProdutoTendenciaMediaMovelFilterSearchHint;

  /// No description provided for @salesProdutoTendenciaMediaMovelFiltersAppliedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Filters applied. Refreshing moving-average trend.'**
  String get salesProdutoTendenciaMediaMovelFiltersAppliedSnackbar;

  /// No description provided for @salesProdutoTendenciaMediaMovelSelectAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose one sales agent to load the moving-average sales trend.'**
  String get salesProdutoTendenciaMediaMovelSelectAgentHint;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Executive summary'**
  String get salesProdutoTendenciaMediaMovelSummaryTitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classification totals across the full filtered result.'**
  String get salesProdutoTendenciaMediaMovelSummarySubtitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary unavailable'**
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableTitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The summary could not be loaded, so the page is showing an estimate based on the current rows.'**
  String get salesProdutoTendenciaMediaMovelSummaryUnavailableMessage;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle.
  ///
  /// In en, this message translates to:
  /// **'Products by classification'**
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution of products across the full filtered result.'**
  String get salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryByImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Impact by classification'**
  String get salesProdutoTendenciaMediaMovelSummaryByImpactTitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Net quantity impact of each classification across the full filtered result.'**
  String get salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed rows'**
  String get salesProdutoTendenciaMediaMovelDetailsTitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paginated detail with product, averages, group, and trend classification.'**
  String get salesProdutoTendenciaMediaMovelDetailsSubtitle;

  /// No description provided for @salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption.
  ///
  /// In en, this message translates to:
  /// **'Swipe sideways to see all columns.'**
  String get salesProdutoTendenciaMediaMovelDetailsHorizontalScrollCaption;

  /// No description provided for @salesProdutoTendenciaMediaMovelDetailsEntityLabel.
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get salesProdutoTendenciaMediaMovelDetailsEntityLabel;

  /// No description provided for @salesProdutoTendenciaMediaMovelDetailsSortedBy.
  ///
  /// In en, this message translates to:
  /// **'Sorted by: {sortLabel}'**
  String salesProdutoTendenciaMediaMovelDetailsSortedBy(String sortLabel);

  /// No description provided for @salesProdutoTendenciaMediaMovelDetailsNotice.
  ///
  /// In en, this message translates to:
  /// **'Results may contain more rows. Use pagination to load next pages (current size: {pageSize}).'**
  String salesProdutoTendenciaMediaMovelDetailsNotice(String pageSize);

  /// No description provided for @salesProdutoTendenciaMediaMovelNoData.
  ///
  /// In en, this message translates to:
  /// **'No moving-average trend data for the selected filters.'**
  String get salesProdutoTendenciaMediaMovelNoData;

  /// No description provided for @salesProdutoTendenciaMediaMovelKpiGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing products'**
  String get salesProdutoTendenciaMediaMovelKpiGrowing;

  /// No description provided for @salesProdutoTendenciaMediaMovelKpiFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling products'**
  String get salesProdutoTendenciaMediaMovelKpiFalling;

  /// No description provided for @salesProdutoTendenciaMediaMovelKpiNewProducts.
  ///
  /// In en, this message translates to:
  /// **'New products'**
  String get salesProdutoTendenciaMediaMovelKpiNewProducts;

  /// No description provided for @salesProdutoTendenciaMediaMovelKpiStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped selling'**
  String get salesProdutoTendenciaMediaMovelKpiStopped;

  /// No description provided for @salesProdutoTendenciaMediaMovelKpiNetImpact.
  ///
  /// In en, this message translates to:
  /// **'Net impact (qty)'**
  String get salesProdutoTendenciaMediaMovelKpiNetImpact;

  /// No description provided for @salesProdutoTendenciaMediaMovelColProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get salesProdutoTendenciaMediaMovelColProduct;

  /// No description provided for @salesProdutoTendenciaMediaMovelColClassificacao.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get salesProdutoTendenciaMediaMovelColClassificacao;

  /// No description provided for @salesProdutoTendenciaMediaMovelColGrupo.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get salesProdutoTendenciaMediaMovelColGrupo;

  /// No description provided for @salesProdutoTendenciaMediaMovelColMediaAtual.
  ///
  /// In en, this message translates to:
  /// **'Current avg.'**
  String get salesProdutoTendenciaMediaMovelColMediaAtual;

  /// No description provided for @salesProdutoTendenciaMediaMovelColMediaAnterior.
  ///
  /// In en, this message translates to:
  /// **'Previous avg.'**
  String get salesProdutoTendenciaMediaMovelColMediaAnterior;

  /// No description provided for @salesProdutoTendenciaMediaMovelColDiferenca.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get salesProdutoTendenciaMediaMovelColDiferenca;

  /// No description provided for @salesProdutoTendenciaMediaMovelColPercentual.
  ///
  /// In en, this message translates to:
  /// **'Trend %'**
  String get salesProdutoTendenciaMediaMovelColPercentual;

  /// No description provided for @salesProdutoTendenciaMediaMovelFilterSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort rows by'**
  String get salesProdutoTendenciaMediaMovelFilterSortBy;

  /// No description provided for @salesProdutoTendenciaMediaMovelSortTrendPercent.
  ///
  /// In en, this message translates to:
  /// **'Trend percentage'**
  String get salesProdutoTendenciaMediaMovelSortTrendPercent;

  /// No description provided for @salesProdutoTendenciaMediaMovelSortDifference.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get salesProdutoTendenciaMediaMovelSortDifference;

  /// No description provided for @salesProdutoTendenciaMediaMovelSortProductName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get salesProdutoTendenciaMediaMovelSortProductName;

  /// No description provided for @salesProdutoTendenciaMediaMovelClassificacaoStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped selling'**
  String get salesProdutoTendenciaMediaMovelClassificacaoStopped;

  /// No description provided for @salesProdutoTendenciaMediaMovelClassificacaoNew.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get salesProdutoTendenciaMediaMovelClassificacaoNew;

  /// No description provided for @salesProdutoTendenciaMediaMovelClassificacaoGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get salesProdutoTendenciaMediaMovelClassificacaoGrowing;

  /// No description provided for @salesProdutoTendenciaMediaMovelClassificacaoFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get salesProdutoTendenciaMediaMovelClassificacaoFalling;

  /// No description provided for @salesProdutoTendenciaMediaMovelClassificacaoStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get salesProdutoTendenciaMediaMovelClassificacaoStable;

  /// No description provided for @agentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get agentStatusPending;

  /// No description provided for @agentStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get agentStatusRejected;

  /// No description provided for @agentStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get agentStatusUnknown;

  /// No description provided for @reportFiltersApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reportFiltersApplyButton;

  /// No description provided for @brazilStoreSalesMapCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get brazilStoreSalesMapCountryLabel;

  /// No description provided for @brazilStoreSalesMapRegionNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get brazilStoreSalesMapRegionNorth;

  /// No description provided for @brazilStoreSalesMapRegionNortheast.
  ///
  /// In en, this message translates to:
  /// **'Northeast'**
  String get brazilStoreSalesMapRegionNortheast;

  /// No description provided for @brazilStoreSalesMapRegionCenterWest.
  ///
  /// In en, this message translates to:
  /// **'Center-West'**
  String get brazilStoreSalesMapRegionCenterWest;

  /// No description provided for @brazilStoreSalesMapRegionSoutheast.
  ///
  /// In en, this message translates to:
  /// **'Southeast'**
  String get brazilStoreSalesMapRegionSoutheast;

  /// No description provided for @brazilStoreSalesMapRegionSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get brazilStoreSalesMapRegionSouth;

  /// No description provided for @brazilStoreSalesMapEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No stores to show on the map.'**
  String get brazilStoreSalesMapEmptyState;

  /// No description provided for @brazilStoreSalesMapPresetStandardLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get brazilStoreSalesMapPresetStandardLabel;

  /// No description provided for @brazilStoreSalesMapPresetBubbleLabel.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get brazilStoreSalesMapPresetBubbleLabel;

  /// No description provided for @brazilStoreSalesMapPresetMunicipalityBubblesLabel.
  ///
  /// In en, this message translates to:
  /// **'Municipalities'**
  String get brazilStoreSalesMapPresetMunicipalityBubblesLabel;

  /// No description provided for @brazilStoreSalesMapPresetStateBubblesLabel.
  ///
  /// In en, this message translates to:
  /// **'State bubbles'**
  String get brazilStoreSalesMapPresetStateBubblesLabel;

  /// No description provided for @brazilStoreSalesMapPresetStoreIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Store icon'**
  String get brazilStoreSalesMapPresetStoreIconLabel;

  /// No description provided for @brazilStoreSalesMapPresetStandardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shows each store as an individual point on the map.'**
  String get brazilStoreSalesMapPresetStandardTooltip;

  /// No description provided for @brazilStoreSalesMapPresetBubbleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shows stores as bubbles proportional to the active metric.'**
  String get brazilStoreSalesMapPresetBubbleTooltip;

  /// No description provided for @brazilStoreSalesMapPresetMunicipalityBubblesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Groups stores by municipality and shows bubbles proportional to the active metric.'**
  String get brazilStoreSalesMapPresetMunicipalityBubblesTooltip;

  /// No description provided for @brazilStoreSalesMapPresetStateBubblesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Groups stores into bubbles positioned at each state centroid.'**
  String get brazilStoreSalesMapPresetStateBubblesTooltip;

  /// No description provided for @brazilStoreSalesMapPresetStoreIconTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shows each store with an operational store icon.'**
  String get brazilStoreSalesMapPresetStoreIconTooltip;

  /// No description provided for @authLoginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginWelcomeTitle;

  /// No description provided for @authLoginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access Colmeia.'**
  String get authLoginWelcomeSubtitle;

  /// No description provided for @authLoginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'User or e-mail'**
  String get authLoginEmailLabel;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authLoginPasswordLabel;

  /// No description provided for @authLoginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the password'**
  String get authLoginPasswordRequired;

  /// No description provided for @authLoginForgotPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get authLoginForgotPasswordShort;

  /// No description provided for @authLoginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get authLoginRememberMe;

  /// No description provided for @authLoginNewHerePrefix.
  ///
  /// In en, this message translates to:
  /// **'New here?  '**
  String get authLoginNewHerePrefix;

  /// No description provided for @authLoginRequestAccessAction.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get authLoginRequestAccessAction;

  /// No description provided for @authLoginSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginSubmitButton;

  /// No description provided for @authLoginRestoringSession.
  ///
  /// In en, this message translates to:
  /// **'Restoring session…'**
  String get authLoginRestoringSession;

  /// No description provided for @authLoginCheckRegistrationStatus.
  ///
  /// In en, this message translates to:
  /// **'Check registration status'**
  String get authLoginCheckRegistrationStatus;

  /// No description provided for @authLoginForgotPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password'**
  String get authLoginForgotPasswordAction;

  /// No description provided for @authLoginLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading: {label}'**
  String authLoginLoadingSemantics(String label);

  /// No description provided for @authEmailFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the e-mail'**
  String get authEmailFieldRequired;

  /// No description provided for @authEmailFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid e-mail.'**
  String get authEmailFieldInvalid;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create client account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your registration will be pending approval from the designated owner. Once approved, you will be able to sign in.'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterOwnerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner e-mail'**
  String get authRegisterOwnerEmailLabel;

  /// No description provided for @authRegisterOwnerEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the owner e-mail.'**
  String get authRegisterOwnerEmailRequired;

  /// No description provided for @authRegisterFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get authRegisterFirstNameLabel;

  /// No description provided for @authRegisterFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name.'**
  String get authRegisterFirstNameRequired;

  /// No description provided for @authRegisterLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get authRegisterLastNameLabel;

  /// No description provided for @authRegisterLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name.'**
  String get authRegisterLastNameRequired;

  /// No description provided for @authRegisterAccountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Account e-mail'**
  String get authRegisterAccountEmailLabel;

  /// No description provided for @authRegisterAccountEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the account e-mail.'**
  String get authRegisterAccountEmailRequired;

  /// No description provided for @authRegisterMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile (optional)'**
  String get authRegisterMobileLabel;

  /// No description provided for @authRegisterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authRegisterPasswordLabel;

  /// No description provided for @authRegisterConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authRegisterConfirmPasswordLabel;

  /// No description provided for @authRegisterSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Request registration'**
  String get authRegisterSubmitButton;

  /// No description provided for @authRegisterBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authRegisterBackToLogin;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {minLength} characters.'**
  String authPasswordTooShort(int minLength);

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authPasswordsMismatch;
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
