import 'package:colmeia/core/refresh/auto_refresh_option_set.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/features/sales/application/ports/sales_preferences_port.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

class SalesSessionService {
  SalesSessionService(this._preferences);

  final SalesPreferencesPort _preferences;

  static const Set<String> produtoRankLucroSortByAllowedValues =
      kSalesProdutoRankLucroSortByAllowedValues;

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

  DashboardYearMonth? restoreSalesChartReferenceMonth() {
    return _preferences.restoreSalesChartReferenceMonth();
  }

  Future<void> persistSalesChartReferenceMonth(DashboardYearMonth anchor) {
    return _preferences.persistSalesChartReferenceMonth(anchor);
  }

  bool restoreSalesDailyTotalsUseCustomRange() {
    return _preferences.restoreSalesDailyTotalsUseCustomRange();
  }

  DashboardDateRange? restoreSalesDailyTotalsDateRange() {
    return _preferences.restoreSalesDailyTotalsDateRange();
  }

  Future<void> persistSalesDailyTotalsDateRange({
    required bool useCustomRange,
    DashboardDateRange? range,
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

  AutoRefreshSnapshot restoreAutoRefreshSnapshot({
    required String cardId,
    required AutoRefreshOptionSet optionSet,
  }) {
    return _preferences.restoreAutoRefreshSnapshot(
      cardId: cardId,
      optionSet: optionSet,
    );
  }

  Future<void> persistAutoRefreshSnapshot({
    required String cardId,
    required AutoRefreshSnapshot snapshot,
  }) {
    return _preferences.persistAutoRefreshSnapshot(
      cardId: cardId,
      snapshot: snapshot,
    );
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

  Map<String, Object?> restoreRankingProdutosFaturamentoFilters() {
    return _preferences.restoreRankingProdutosFaturamentoFilters();
  }

  Future<void> persistRankingProdutosFaturamentoFilters(
    Map<String, Object?> filters,
  ) {
    return _preferences.persistRankingProdutosFaturamentoFilters(filters);
  }
}
