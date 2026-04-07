import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small helper to persist page/session state snapshots in SharedPreferences.
class PersistedPageSessionStore {
  PersistedPageSessionStore({
    required SharedPreferences prefs,
    required String namespace,
  }) : _prefs = prefs,
       _namespace = namespace;

  final SharedPreferences _prefs;
  final String _namespace;

  String _key(String suffix) => '$_namespace.$suffix';

  int restoreTabIndex({
    required String suffix,
    required int fallbackIndex,
    required int maxTabIndex,
  }) {
    final saved = _prefs.getInt(_key(suffix));
    if (saved == null || saved < 0 || saved > maxTabIndex) {
      return fallbackIndex;
    }
    return saved;
  }

  Future<void> persistTabIndex({
    required String suffix,
    required int tabIndex,
  }) async {
    await _prefs.setInt(_key(suffix), tabIndex);
  }

  String restoreText({
    required String suffix,
    String fallback = '',
  }) {
    return _prefs.getString(_key(suffix)) ?? fallback;
  }

  Future<void> persistText({
    required String suffix,
    required String value,
    bool removeWhenBlank = true,
  }) async {
    if (removeWhenBlank && value.trim().isEmpty) {
      await _prefs.remove(_key(suffix));
      return;
    }
    await _prefs.setString(_key(suffix), value);
  }

  Map<String, Object?> restoreJsonMap({
    required String suffix,
  }) {
    final raw = _prefs.getString(_key(suffix));
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, Object?>{};
      }
      return Map<String, Object?>.from(decoded);
    } on FormatException {
      return <String, Object?>{};
    }
  }

  Future<void> persistJsonMap({
    required String suffix,
    required Map<String, Object?> value,
    bool removeWhenEmpty = true,
  }) async {
    if (removeWhenEmpty && value.isEmpty) {
      await _prefs.remove(_key(suffix));
      return;
    }
    await _prefs.setString(_key(suffix), jsonEncode(value));
  }
}
