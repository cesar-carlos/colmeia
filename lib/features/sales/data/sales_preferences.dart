import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/sales_daily_totals_range_policy.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesPreferences {
  SalesPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const String _selectedAgentIdKey = 'colmeia_sales_agent_id_v1';

  String? get selectedAgentId => _prefs.getString(_selectedAgentIdKey);

  Future<void> setSelectedAgentId(String? agentId) async {
    try {
      if (agentId == null) {
        await _prefs.remove(_selectedAgentIdKey);
        return;
      }
      await _prefs.setString(_selectedAgentIdKey, agentId);
    } on Object catch (e, st) {
      AppLogger.warning(
        'SalesPreferences.setSelectedAgentId failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Map<String, Object?> restoreCardFilters(String cardId) {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$cardId',
    );
    return store.restoreJsonMap(suffix: 'filters');
  }

  Future<void> persistCardFilters(
    String cardId,
    Map<String, Object?> filters,
  ) async {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$cardId',
    );
    await store.persistJsonMap(
      suffix: 'filters',
      value: filters,
    );
  }

  /// produto_rank_lucro card: date range encoded as epochs + metric key.
  static const Set<String> produtoRankLucroSortByAllowedValues = <String>{
    'qtdItensVendido',
    'totalValorLucro',
  };

  static const String produtoRankLucroCardId = 'produto_rank_lucro';

  static const String monthlyPnlCardId = 'monthly_pnl';
  static const String _legacyParcelasMensal12mCardId = 'parcelas_mensal_12m';

  static const int _anchorYearMin = 2000;
  static const int _anchorYearMax = 2100;

  /// Reference month shared by Sales monthly P&L and daily totals (same storage).
  OverviewYearMonth? restoreSalesChartReferenceMonth() =>
      restoreMonthlyPnlAnchor();

  /// Persists [anchor] for monthly P&L and daily totals charts.
  Future<void> persistSalesChartReferenceMonth(OverviewYearMonth anchor) =>
      persistMonthlyPnlAnchor(anchor);

  /// Restores [OverviewYearMonth] anchor for the monthly P&L chart,
  /// or null when nothing valid is stored.
  OverviewYearMonth? restoreMonthlyPnlAnchor() {
    final current = restoreCardFilters(monthlyPnlCardId);
    final raw = current.isNotEmpty
        ? current
        : restoreCardFilters(_legacyParcelasMensal12mCardId);
    final y = raw['anchor_year'];
    final m = raw['anchor_month'];
    if (y is! int || m is! int) {
      return null;
    }
    if (m < 1 || m > 12 || y < _anchorYearMin || y > _anchorYearMax) {
      return null;
    }
    return OverviewYearMonth(year: y, month: m);
  }

  static const String _dailyTotalsUseCustomRangeKey =
      'daily_totals_use_custom_range';
  static const String _dailyTotalsRangeStartMsKey =
      'daily_totals_range_start_ms';
  static const String _dailyTotalsRangeEndMsKey = 'daily_totals_range_end_ms';

  Future<void> persistMonthlyPnlAnchor(OverviewYearMonth anchor) async {
    final merged = Map<String, Object?>.from(
      restoreCardFilters(monthlyPnlCardId),
    );
    merged['anchor_year'] = anchor.year;
    merged['anchor_month'] = anchor.month;
    await persistCardFilters(monthlyPnlCardId, merged);
  }

  /// Optional inclusive date range for daily totals only (see filters sheet).
  /// When absent or the stored flag is false, callers use the anchor month.
  bool restoreSalesDailyTotalsUseCustomRange() {
    final raw = restoreCardFilters(monthlyPnlCardId);
    final v = raw[_dailyTotalsUseCustomRangeKey];
    return v == true;
  }

  OverviewDateRange? restoreSalesDailyTotalsDateRange() {
    final raw = restoreCardFilters(monthlyPnlCardId);
    if (raw[_dailyTotalsUseCustomRangeKey] != true) {
      return null;
    }
    final startMs = raw[_dailyTotalsRangeStartMsKey];
    final endMs = raw[_dailyTotalsRangeEndMsKey];
    if (startMs is! int || endMs is! int) {
      return null;
    }
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final range = OverviewDateRange.fromOrderedEndpoints(start, end);
    return SalesDailyTotalsRangePolicy.normalizedForSalesDailyTotalsPicker(
      range: range,
    );
  }

  Future<void> persistSalesDailyTotalsDateRange({
    required bool useCustomRange,
    OverviewDateRange? range,
  }) async {
    final merged = Map<String, Object?>.from(
      restoreCardFilters(monthlyPnlCardId),
    );
    OverviewDateRange? normalizedCustomForLog;
    if (!useCustomRange || range == null) {
      merged
        ..remove(_dailyTotalsUseCustomRangeKey)
        ..remove(_dailyTotalsRangeStartMsKey)
        ..remove(_dailyTotalsRangeEndMsKey);
    } else {
      final normalized =
          SalesDailyTotalsRangePolicy.normalizedForSalesDailyTotalsPicker(
            range: range,
          );
      normalizedCustomForLog = normalized;
      merged[_dailyTotalsUseCustomRangeKey] = true;
      merged[_dailyTotalsRangeStartMsKey] =
          normalized.startInclusive.millisecondsSinceEpoch;
      merged[_dailyTotalsRangeEndMsKey] =
          normalized.endInclusive.millisecondsSinceEpoch;
    }
    await persistCardFilters(monthlyPnlCardId, merged);
    if (normalizedCustomForLog != null) {
      AppLogger.info(
        'SalesPreferences.persistSalesDailyTotalsDateRange',
        context: <String, Object?>{
          'inclusive_day_count':
              normalizedCustomForLog.inclusiveCalendarDayCount,
        },
      );
    }
  }

  static const String _monthlyPnlBarChartSuffix = 'bar_chart';

  SalesMonthlyPnlBarChartPreferences restoreMonthlyPnlBarChartPreferences() {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$monthlyPnlCardId',
    );
    final raw = store.restoreJsonMap(suffix: _monthlyPnlBarChartSuffix);
    if (raw.isEmpty) {
      return SalesMonthlyPnlBarChartPreferences.defaults;
    }
    return SalesMonthlyPnlBarChartPreferences.fromRaw(raw);
  }

  Future<void> persistMonthlyPnlBarChartPreferences(
    SalesMonthlyPnlBarChartPreferences value,
  ) async {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$monthlyPnlCardId',
    );
    await store.persistJsonMap(
      suffix: _monthlyPnlBarChartSuffix,
      value: value.toJson(),
    );
  }

  /// Converts stored epochs into `'periodo': DateTimeRange` and sort key.
  Map<String, Object?> restoreProdutoRankLucroFilters() {
    final raw = restoreCardFilters(produtoRankLucroCardId);
    return PersistedFilterMapCodec.sanitize((draft) {
      draft
        ..dateRangeFromEpoch(
          targetKey: 'periodo',
          startEpochMs: raw['periodo_start_ms'],
          endEpochMs: raw['periodo_end_ms'],
        )
        ..stringIfAllowed(
          key: 'sortBy',
          rawValue: raw['sortBy'],
          allowedValues: produtoRankLucroSortByAllowedValues,
        );
    });
  }

  Future<void> persistProdutoRankLucroFilters(
    Map<String, Object?> filters,
  ) async {
    final encoded = PersistedFilterMapCodec.sanitize((draft) {
      draft
        ..dateRangeToEpoch(
          startEpochKey: 'periodo_start_ms',
          endEpochKey: 'periodo_end_ms',
          rawValue: filters['periodo'],
        )
        ..stringIfAllowed(
          key: 'sortBy',
          rawValue: filters['sortBy'],
          allowedValues: produtoRankLucroSortByAllowedValues,
        );
    });
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$produtoRankLucroCardId',
    );
    await store.persistJsonMap(
      suffix: 'filters',
      value: encoded,
    );
  }
}
