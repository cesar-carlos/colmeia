import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
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

  Future<void> persistMonthlyPnlAnchor(OverviewYearMonth anchor) async {
    final encoded = <String, Object?>{
      'anchor_year': anchor.year,
      'anchor_month': anchor.month,
    };
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$monthlyPnlCardId',
    );
    await store.persistJsonMap(
      suffix: 'filters',
      value: encoded,
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
