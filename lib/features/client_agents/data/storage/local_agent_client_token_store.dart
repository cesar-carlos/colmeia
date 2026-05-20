import 'dart:collection';
import 'dart:convert';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalAgentClientTokenRecord {
  const LocalAgentClientTokenRecord({
    required this.token,
    required this.savedAt,
  });

  final String token;
  final DateTime? savedAt;

  bool isFresh({
    required Duration maxAge,
    DateTime? now,
  }) {
    final savedAt = this.savedAt;
    if (savedAt == null) {
      return false;
    }
    return (now ?? DateTime.now().toUtc()).difference(savedAt) <= maxAge;
  }
}

/// Persists per-agent `client_token` values locally (never sent to the Colmeia
/// backend). Keys are scoped by user id and agent id.
class LocalAgentClientTokenStore implements AgentClientTokenReader {
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
    final record = await readRecord(userId: userId, agentId: agentId);
    return record?.token;
  }

  Future<LocalAgentClientTokenRecord?> readRecord({
    required String userId,
    required String agentId,
  }) async {
    final key = _storageKey(userId: userId, agentId: agentId);
    try {
      return _decodeStoredRecord(await _secureStorage.read(key: key));
    } on MissingPluginException {
      return _decodeStoredRecord(_fallbackStorage[key]);
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
    final payload = jsonEncode(<String, Object?>{
      'token': trimmed,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
    });
    try {
      await _secureStorage.write(key: key, value: payload);
    } on MissingPluginException {
      _fallbackStorage[key] = payload;
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
  Future<Map<String, LocalAgentClientTokenRecord>> readManyRecords({
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
      return <String, LocalAgentClientTokenRecord>{};
    }
    final idList = uniqueIds.toList()..sort();
    final result = <String, LocalAgentClientTokenRecord>{};
    for (var i = 0; i < idList.length; i += _readManyConcurrency) {
      final end = i + _readManyConcurrency > idList.length
          ? idList.length
          : i + _readManyConcurrency;
      final chunk = idList.sublist(i, end);
      final entries = await Future.wait(
        chunk.map((id) async {
          final record = await readRecord(userId: userId, agentId: id);
          return MapEntry<String, LocalAgentClientTokenRecord?>(id, record);
        }),
      );
      for (final entry in entries) {
        final record = entry.value;
        if (record != null) {
          result[entry.key] = record;
        }
      }
    }
    return result;
  }

  @override
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    final records = await readManyRecords(userId: userId, agentIds: agentIds);
    return <String, String>{
      for (final entry in records.entries) entry.key: entry.value.token,
    };
  }

  LocalAgentClientTokenRecord? _decodeStoredRecord(String? rawStored) {
    final raw = rawStored?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final token = decoded['token']?.toString().trim();
        if (token == null || token.isEmpty) {
          return null;
        }
        final savedAt = DateTime.tryParse(
          decoded['savedAt']?.toString() ?? '',
        )?.toUtc();
        return LocalAgentClientTokenRecord(token: token, savedAt: savedAt);
      }
      if (decoded is String) {
        final token = decoded.trim();
        if (token.isEmpty) {
          return null;
        }
        return LocalAgentClientTokenRecord(token: token, savedAt: null);
      }
    } on FormatException {
      return LocalAgentClientTokenRecord(token: raw, savedAt: null);
    }
    return LocalAgentClientTokenRecord(token: raw, savedAt: null);
  }
}
