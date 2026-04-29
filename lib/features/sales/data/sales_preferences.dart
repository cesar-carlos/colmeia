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

  Future<void> persistCardFilters(
    String cardId,
    Map<String, Object?> filters,
  ) async {
    final sanitized = _sanitizeFilters(filters);
    final store = PersistedPageSessionStore(
      prefs: _prefs,
      namespace: 'colmeia_sales_card.$cardId',
    );
    await store.persistJsonMap(
      suffix: 'filters',
      value: sanitized,
    );
  }

  Map<String, Object?> _sanitizeFilters(Map<String, Object?> source) {
    return PersistedFilterMapCodec.sanitize((draft) {
      for (final key in source.keys) {
        draft.trimmedString(key: key, rawValue: source[key]);
      }
    });
  }
}
