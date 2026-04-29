import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
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

  /// produto_rank_lucro card: date range encoded as epochs + metric key.
  static const Set<String> produtoRankLucroSortByAllowedValues = <String>{
    'qtdItensVendido',
    'totalValorLucro',
  };

  static const String produtoRankLucroCardId = 'produto_rank_lucro';

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

  Future<void> persistProdutoRankLucroFilters(Map<String, Object?> filters) async {
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
