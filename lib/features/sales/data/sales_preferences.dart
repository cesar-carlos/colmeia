import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_option_set.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/features/sales/application/ports/sales_preferences_port.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref_codec.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/sales_daily_totals_range_policy.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesPreferences implements SalesPreferencesPort {
  SalesPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const String _selectedAgentIdKey = 'colmeia_sales_agent_id_v1';

  @override
  String? get selectedAgentId => _prefs.getString(_selectedAgentIdKey);

  @override
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

  @override
  Map<String, Object?> restoreCardFilters(String cardId) {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$cardId',
    );
    return store.restoreJsonMap(suffix: 'filters');
  }

  @override
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
  static const String produtoRankLucroCardId = 'produto_rank_lucro';

  static const String salesDailyTotalsCardId = 'daily_totals';
  static const String monthlyPnlCardId = 'monthly_pnl';
  static const String _legacyParcelasMensal12mCardId = 'parcelas_mensal_12m';
  static const String salesLiveMapCardId = 'sales_live_map';
  static const String _autoRefreshSuffix = 'auto_refresh';
  static const Map<String, Object?> _disabledAutoRefreshSnapshot =
      <String, Object?>{};

  static const int _anchorYearMin = 2000;
  static const int _anchorYearMax = 2100;

  /// Reference month shared by Sales monthly P&L and daily totals (same storage).
  @override
  DashboardYearMonth? restoreSalesChartReferenceMonth() =>
      restoreMonthlyPnlAnchor();

  /// Persists [anchor] for monthly P&L and daily totals charts.
  @override
  Future<void> persistSalesChartReferenceMonth(DashboardYearMonth anchor) =>
      persistMonthlyPnlAnchor(anchor);

  /// Restores [DashboardYearMonth] anchor for the monthly P&L chart,
  /// or null when nothing valid is stored.
  DashboardYearMonth? restoreMonthlyPnlAnchor() {
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
    return DashboardYearMonth(year: y, month: m);
  }

  static const String _dailyTotalsUseCustomRangeKey =
      'daily_totals_use_custom_range';
  static const String _dailyTotalsRangeStartMsKey =
      'daily_totals_range_start_ms';
  static const String _dailyTotalsRangeEndMsKey = 'daily_totals_range_end_ms';

  Future<void> persistMonthlyPnlAnchor(DashboardYearMonth anchor) async {
    final merged = Map<String, Object?>.from(
      restoreCardFilters(monthlyPnlCardId),
    );
    merged['anchor_year'] = anchor.year;
    merged['anchor_month'] = anchor.month;
    await persistCardFilters(monthlyPnlCardId, merged);
  }

  /// Optional inclusive date range for daily totals only (see filters sheet).
  /// When absent or the stored flag is false, callers use the anchor month.
  @override
  bool restoreSalesDailyTotalsUseCustomRange() {
    final raw = restoreCardFilters(monthlyPnlCardId);
    final v = raw[_dailyTotalsUseCustomRangeKey];
    return v == true;
  }

  @override
  DashboardDateRange? restoreSalesDailyTotalsDateRange() {
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
    final range = DashboardDateRange.fromOrderedEndpoints(start, end);
    return SalesDailyTotalsRangePolicy.normalizedForSalesDailyTotalsPicker(
      range: range,
    );
  }

  @override
  Future<void> persistSalesDailyTotalsDateRange({
    required bool useCustomRange,
    DashboardDateRange? range,
  }) async {
    final merged = Map<String, Object?>.from(
      restoreCardFilters(monthlyPnlCardId),
    );
    DashboardDateRange? normalizedCustomForLog;
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

  @override
  SalesLiveMapFilter restoreSalesLiveMapFilter() {
    final raw = restoreCardFilters(salesLiveMapCardId);
    final mode = _salesLiveMapPeriodModeFromRaw(raw['period_mode']);
    final selectedAgentIds = _salesLiveMapSelectedAgentIdsFromRaw(
      raw['selected_agent_ids'],
    );
    final selectedBranchIds = _salesLiveMapSelectedBranchRefsFromRaw(
      raw['selected_branch_ids'],
    );
    final customDateRange = _salesLiveMapCustomRangeFromRaw(
      startMs: raw['custom_range_start_ms'],
      endMs: raw['custom_range_end_ms'],
    );

    return SalesLiveMapFilter(
      selectedAgentIds: selectedAgentIds,
      selectedBranchIds: selectedBranchIds,
      periodMode: mode,
      customDateRange: customDateRange,
      detailLevel: _salesLiveMapDetailFromRaw(
        raw['map_detail'],
        legacyPreset: raw['map_preset'],
      ),
      markerVisual: _salesLiveMapMarkerVisualFromRaw(
        raw['map_visual'],
        legacyPreset: raw['map_preset'],
      ),
      metric: _salesLiveMapMetricFromRaw(raw['metric']),
    );
  }

  @override
  Future<void> persistSalesLiveMapFilter(SalesLiveMapFilter filter) async {
    final encoded = <String, Object?>{
      'period_mode': filter.periodMode.name,
      'map_detail': filter.detailLevel.name,
      'map_visual': filter.markerVisual.name,
    };

    final selected = filter.selectedAgentIds;
    if (selected != null && selected.isNotEmpty) {
      encoded['selected_agent_ids'] = (List<String>.from(selected)..sort());
    }
    final selectedBranches = filter.selectedBranchIds;
    if (selectedBranches != null && selectedBranches.isNotEmpty) {
      encoded['selected_branch_ids'] =
          selectedBranches
              .map(SalesLiveMapBranchRefCodec.encode)
              .toList(growable: false)
            ..sort();
    }
    encoded['metric'] = filter.metric.name;

    final customRange = filter.customDateRange;
    if (filter.periodMode == SalesLiveMapPeriodMode.customRange &&
        customRange != null) {
      encoded['custom_range_start_ms'] =
          customRange.startInclusive.millisecondsSinceEpoch;
      encoded['custom_range_end_ms'] =
          customRange.endInclusive.millisecondsSinceEpoch;
    }

    await persistCardFilters(salesLiveMapCardId, encoded);
  }

  @override
  AutoRefreshSnapshot restoreAutoRefreshSnapshot({
    required String cardId,
    required AutoRefreshOptionSet optionSet,
  }) {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$cardId',
    );
    final raw = store.restoreJsonMap(suffix: _autoRefreshSuffix);
    final option = _autoRefreshOptionFromRaw(
      raw['option_id'] ?? raw['interval'],
      optionSet,
    );
    final refreshedAtMs = raw['last_successful_refresh_at_ms'];
    final nextDueAtMs = raw['next_due_at_ms'];
    final remainingDelayMs = raw['remaining_delay_ms'];
    final failureStreakRaw = raw['failure_streak'];
    final lastSuccessfulRefreshAt = refreshedAtMs is int
        ? DateTime.fromMillisecondsSinceEpoch(refreshedAtMs)
        : null;
    final nextDueAt = nextDueAtMs is int
        ? DateTime.fromMillisecondsSinceEpoch(nextDueAtMs)
        : null;
    final remainingDelay = remainingDelayMs is int && remainingDelayMs >= 0
        ? Duration(milliseconds: remainingDelayMs)
        : null;
    final failureStreak = failureStreakRaw is int && failureStreakRaw >= 0
        ? failureStreakRaw
        : 0;
    return AutoRefreshSnapshot(
      option: option,
      lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
      nextDueAt: nextDueAt,
      remainingDelay: remainingDelay,
      failureStreak: failureStreak,
    );
  }

  @override
  Future<void> persistAutoRefreshSnapshot({
    required String cardId,
    required AutoRefreshSnapshot snapshot,
  }) async {
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$cardId',
    );
    final option = snapshot.option;
    if (option == null) {
      await store.persistJsonMap(
        suffix: _autoRefreshSuffix,
        value: _disabledAutoRefreshSnapshot,
      );
      return;
    }
    await store.persistJsonMap(
      suffix: _autoRefreshSuffix,
      value: <String, Object?>{
        'option_id': option.id,
        if (snapshot.lastSuccessfulRefreshAt != null)
          'last_successful_refresh_at_ms':
              snapshot.lastSuccessfulRefreshAt!.millisecondsSinceEpoch,
        if (snapshot.nextDueAt != null)
          'next_due_at_ms': snapshot.nextDueAt!.millisecondsSinceEpoch,
        if (snapshot.remainingDelay != null)
          'remaining_delay_ms': snapshot.remainingDelay!.inMilliseconds,
        if (snapshot.failureStreak > 0)
          'failure_streak': snapshot.failureStreak,
      },
    );
  }

  static const String _monthlyPnlBarChartSuffix = 'bar_chart';

  @override
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

  @override
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
  @override
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
          allowedValues: kSalesProdutoRankLucroSortByAllowedValues,
        );
    });
  }

  @override
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
          allowedValues: kSalesProdutoRankLucroSortByAllowedValues,
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

  static SalesLiveMapPeriodMode _salesLiveMapPeriodModeFromRaw(Object? raw) {
    if (raw is String) {
      for (final mode in SalesLiveMapPeriodMode.values) {
        if (mode.name == raw) {
          return mode;
        }
      }
    }
    return SalesLiveMapPeriodMode.today;
  }

  static SalesLiveMapMapDetail _salesLiveMapDetailFromRaw(
    Object? raw, {
    Object? legacyPreset,
  }) {
    if (raw is String) {
      for (final detail in SalesLiveMapMapDetail.values) {
        if (detail.name == raw) {
          return detail;
        }
      }
    }

    return switch (_salesLiveMapMapPresetFromRaw(legacyPreset)) {
      SalesLiveMapMapPreset.municipalities =>
        SalesLiveMapMapDetail.municipalities,
      SalesLiveMapMapPreset.stateBubbles => SalesLiveMapMapDetail.states,
      SalesLiveMapMapPreset.standard ||
      SalesLiveMapMapPreset.bubble ||
      SalesLiveMapMapPreset.storeIcon => SalesLiveMapMapDetail.branches,
    };
  }

  static SalesLiveMapMarkerVisual _salesLiveMapMarkerVisualFromRaw(
    Object? raw, {
    Object? legacyPreset,
  }) {
    if (raw is String) {
      for (final visual in SalesLiveMapMarkerVisual.values) {
        if (visual.name == raw) {
          return visual;
        }
      }
    }

    return switch (_salesLiveMapMapPresetFromRaw(legacyPreset)) {
      SalesLiveMapMapPreset.bubble ||
      SalesLiveMapMapPreset.municipalities ||
      SalesLiveMapMapPreset.stateBubbles => SalesLiveMapMarkerVisual.bubble,
      SalesLiveMapMapPreset.storeIcon => SalesLiveMapMarkerVisual.storeIcon,
      SalesLiveMapMapPreset.standard => SalesLiveMapMarkerVisual.dot,
    };
  }

  static SalesLiveMapMapPreset _salesLiveMapMapPresetFromRaw(Object? raw) {
    if (raw is String) {
      for (final preset in SalesLiveMapMapPreset.values) {
        if (preset.name == raw) {
          return preset;
        }
      }
    }
    return SalesLiveMapMapPreset.standard;
  }

  static SalesLiveMapMetric _salesLiveMapMetricFromRaw(Object? raw) {
    if (raw is String) {
      for (final metric in SalesLiveMapMetric.values) {
        if (metric.name == raw) {
          return metric;
        }
      }
    }
    return SalesLiveMapMetric.revenue;
  }

  static Set<String>? _salesLiveMapSelectedAgentIdsFromRaw(Object? raw) {
    if (raw is! List) {
      return null;
    }

    final ids = <String>{};
    for (final item in raw) {
      if (item is! String) {
        continue;
      }
      final id = item.trim();
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }

    return ids.isEmpty ? null : Set<String>.unmodifiable(ids);
  }

  static Set<SalesLiveMapBranchRef>? _salesLiveMapSelectedBranchRefsFromRaw(
    Object? raw,
  ) {
    if (raw is! List) {
      return null;
    }

    final refs = <SalesLiveMapBranchRef>{};
    for (final item in raw) {
      if (item is! String) {
        continue;
      }
      try {
        refs.add(SalesLiveMapBranchRef.fromStorageKey(item));
      } on FormatException {
        continue;
      }
    }

    return refs.isEmpty ? null : Set<SalesLiveMapBranchRef>.unmodifiable(refs);
  }

  static DashboardDateRange? _salesLiveMapCustomRangeFromRaw({
    required Object? startMs,
    required Object? endMs,
  }) {
    if (startMs is! int || endMs is! int) {
      return null;
    }
    final range = DashboardDateRange.fromOrderedEndpoints(
      DateTime.fromMillisecondsSinceEpoch(startMs),
      DateTime.fromMillisecondsSinceEpoch(endMs),
    );
    return range.clampedToMaxInclusiveCalendarDays(
      kSalesLiveMapMaxCustomRangeInclusiveDays,
    );
  }

  static AutoRefreshOption? _autoRefreshOptionFromRaw(
    Object? raw,
    AutoRefreshOptionSet optionSet,
  ) {
    if (raw is! String) {
      return null;
    }
    return optionSet.byId(raw);
  }
}
