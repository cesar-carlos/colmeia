import 'dart:collection';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists per-agent `client_token` values locally (never sent to the Colmeia
/// backend). Keys are scoped by user id and agent id.
class LocalAgentClientTokenStore {
  LocalAgentClientTokenStore(this._secureStorage);

  static const String _keyPrefix = 'colmeia.agent_client_token.v1';

  /// Limits parallel secure-storage reads (same order of magnitude as SQL
  /// bridge concurrency in the dashboard).
  static const int _readManyConcurrency = 8;

  final FlutterSecureStorage _secureStorage;
  final Map<String, String> _fallbackStorage = HashMap<String, String>();

  String _storageKey({
    required String userId,
    required String agentId,
  }) {
    final u = userId.trim();
    final a = agentId.trim();
    return '$_keyPrefix|$u|$a';
  }

  Future<String?> read({
    required String userId,
    required String agentId,
  }) async {
    final key = _storageKey(userId: userId, agentId: agentId);
    try {
      final stored = await _secureStorage.read(key: key);
      if (stored == null) {
        return null;
      }
      final trimmed = stored.trim();
      return trimmed.isEmpty ? null : trimmed;
    } on MissingPluginException {
      final stored = _fallbackStorage[key];
      if (stored == null) {
        return null;
      }
      final trimmed = stored.trim();
      return trimmed.isEmpty ? null : trimmed;
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Secure storage read failed; treating token as absent',
        context: <String, Object?>{'storageKeyPrefix': _keyPrefix},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> write({
    required String userId,
    required String agentId,
    required String clientToken,
  }) async {
    final key = _storageKey(userId: userId, agentId: agentId);
    final trimmed = clientToken.trim();
    if (trimmed.isEmpty) {
      await delete(userId: userId, agentId: agentId);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: trimmed);
    } on MissingPluginException {
      _fallbackStorage[key] = trimmed;
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Secure storage write failed',
        context: <String, Object?>{'storageKeyPrefix': _keyPrefix},
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete({
    required String userId,
    required String agentId,
  }) async {
    final key = _storageKey(userId: userId, agentId: agentId);
    try {
      await _secureStorage.delete(key: key);
    } on MissingPluginException {
      _fallbackStorage.remove(key);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Secure storage delete failed',
        context: <String, Object?>{'storageKeyPrefix': _keyPrefix},
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Returns only agents that have a non-empty stored token.
  ///
  /// Keys are trimmed agent ids (same normalization as [read]). Reads run in
  /// parallel to reduce latency when many ids are requested (e.g. dashboard).
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    final uniqueIds = <String>{};
    for (final raw in agentIds) {
      final id = raw.trim();
      if (id.isNotEmpty) {
        uniqueIds.add(id);
      }
    }
    if (uniqueIds.isEmpty) {
      return <String, String>{};
    }
    final idList = uniqueIds.toList()..sort();
    final result = <String, String>{};
    for (var i = 0; i < idList.length; i += _readManyConcurrency) {
      final end = i + _readManyConcurrency > idList.length
          ? idList.length
          : i + _readManyConcurrency;
      final chunk = idList.sublist(i, end);
      final entries = await Future.wait(
        chunk.map((id) async {
          final token = await read(userId: userId, agentId: id);
          return MapEntry<String, String?>(id, token);
        }),
      );
      for (final e in entries) {
        final token = e.value;
        if (token != null && token.isNotEmpty) {
          result[e.key] = token;
        }
      }
    }
    return result;
  }
}
