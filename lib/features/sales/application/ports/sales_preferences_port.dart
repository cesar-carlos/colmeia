import 'package:colmeia/core/refresh/auto_refresh_option_set.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Allowed sort-by keys for the produto_rank_lucro card filters.
const Set<String> kSalesProdutoRankLucroSortByAllowedValues = <String>{
  'qtdItensVendido',
  'totalValorLucro',
};

/// Persistence port consumed by `SalesSessionService` and the sales feature.
///
/// Defines the contract for reading and writing user-scoped sales
/// preferences. Concrete implementations live in the data layer; the use
/// cases and session service depend on this abstraction so the application
/// layer never imports data directly.
abstract class SalesPreferencesPort {
  String? get selectedAgentId;

  Future<void> setSelectedAgentId(String? agentId);

  Map<String, Object?> restoreCardFilters(String cardId);

  Future<void> persistCardFilters(
    String cardId,
    Map<String, Object?> filters,
  );

  DashboardYearMonth? restoreSalesChartReferenceMonth();

  Future<void> persistSalesChartReferenceMonth(DashboardYearMonth anchor);

  bool restoreSalesDailyTotalsUseCustomRange();

  DashboardDateRange? restoreSalesDailyTotalsDateRange();

  Future<void> persistSalesDailyTotalsDateRange({
    required bool useCustomRange,
    DashboardDateRange? range,
  });

  SalesLiveMapFilter restoreSalesLiveMapFilter();

  Future<void> persistSalesLiveMapFilter(SalesLiveMapFilter filter);

  AutoRefreshSnapshot restoreAutoRefreshSnapshot({
    required String cardId,
    required AutoRefreshOptionSet optionSet,
  });

  Future<void> persistAutoRefreshSnapshot({
    required String cardId,
    required AutoRefreshSnapshot snapshot,
  });

  SalesMonthlyPnlBarChartPreferences restoreMonthlyPnlBarChartPreferences();

  Future<void> persistMonthlyPnlBarChartPreferences(
    SalesMonthlyPnlBarChartPreferences value,
  );

  Map<String, Object?> restoreProdutoRankLucroFilters();

  Future<void> persistProdutoRankLucroFilters(Map<String, Object?> filters);

  Map<String, Object?> restoreRankingProdutosFaturamentoFilters();

  Future<void> persistRankingProdutosFaturamentoFilters(
    Map<String, Object?> filters,
  );
}
