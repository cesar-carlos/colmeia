import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_auto_refresh_preference.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';

class SalesSessionService {
  SalesSessionService(this._preferences);

  final SalesPreferences _preferences;

  static const Set<String> produtoRankLucroSortByAllowedValues =
      SalesPreferences.produtoRankLucroSortByAllowedValues;

  String? get selectedAgentId => _preferences.selectedAgentId;

  Future<void> setSelectedAgentId(String? agentId) {
    return _preferences.setSelectedAgentId(agentId);
  }

  Map<String, Object?> restoreCardFilters(String cardId) {
    return _preferences.restoreCardFilters(cardId);
  }

  Future<void> persistCardFilters(
    String cardId,
    Map<String, Object?> filters,
  ) {
    return _preferences.persistCardFilters(cardId, filters);
  }

  OverviewYearMonth? restoreSalesChartReferenceMonth() {
    return _preferences.restoreSalesChartReferenceMonth();
  }

  Future<void> persistSalesChartReferenceMonth(OverviewYearMonth anchor) {
    return _preferences.persistSalesChartReferenceMonth(anchor);
  }

  bool restoreSalesDailyTotalsUseCustomRange() {
    return _preferences.restoreSalesDailyTotalsUseCustomRange();
  }

  OverviewDateRange? restoreSalesDailyTotalsDateRange() {
    return _preferences.restoreSalesDailyTotalsDateRange();
  }

  Future<void> persistSalesDailyTotalsDateRange({
    required bool useCustomRange,
    OverviewDateRange? range,
  }) {
    return _preferences.persistSalesDailyTotalsDateRange(
      useCustomRange: useCustomRange,
      range: range,
    );
  }

  SalesLiveMapFilter restoreSalesLiveMapFilter() {
    return _preferences.restoreSalesLiveMapFilter();
  }

  Future<void> persistSalesLiveMapFilter(SalesLiveMapFilter filter) {
    return _preferences.persistSalesLiveMapFilter(filter);
  }

  SalesAutoRefreshPreference restoreSalesLiveMapAutoRefreshPreference() {
    return _preferences.restoreSalesLiveMapAutoRefreshPreference();
  }

  Future<void> persistSalesLiveMapAutoRefreshPreference(
    SalesAutoRefreshPreference preference,
  ) {
    return _preferences.persistSalesLiveMapAutoRefreshPreference(preference);
  }

  SalesMonthlyPnlBarChartPreferences restoreMonthlyPnlBarChartPreferences() {
    return _preferences.restoreMonthlyPnlBarChartPreferences();
  }

  Future<void> persistMonthlyPnlBarChartPreferences(
    SalesMonthlyPnlBarChartPreferences value,
  ) {
    return _preferences.persistMonthlyPnlBarChartPreferences(value);
  }

  Map<String, Object?> restoreProdutoRankLucroFilters() {
    return _preferences.restoreProdutoRankLucroFilters();
  }

  Future<void> persistProdutoRankLucroFilters(
    Map<String, Object?> filters,
  ) {
    return _preferences.persistProdutoRankLucroFilters(filters);
  }
}
