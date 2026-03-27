import 'dart:convert';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/security/app_crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  SessionStorage(this._secureStorage);

  static const int _storageEnvelopeVersion = 1;
  static const String _digestKey = 'digest';
  static const String _payloadKey = 'payload';
  static const String _versionKey = 'version';

  final FlutterSecureStorage _secureStorage;
  final Map<String, String> _fallbackStorage = <String, String>{};

  Future<String?> read(String key) async {
    try {
      final storedValue = await _secureStorage.read(key: key);
      return _unwrapStoredValue(
        key: key,
        storedValue: storedValue,
      );
    } on MissingPluginException {
      AppLogger.warning(
        'Secure storage plugin unavailable on read',
        context: <String, Object?>{
          'storageKey': key,
        },
      );
      return _unwrapStoredValue(
        key: key,
        storedValue: _fallbackStorage[key],
      );
    }
  }

  Future<void> write({
    required String key,
    required String value,
  }) async {
    final encodedValue = _wrapStoredValue(value);

    try {
      await _secureStorage.write(key: key, value: encodedValue);
    } on MissingPluginException {
      AppLogger.warning(
        'Secure storage plugin unavailable on write',
        context: <String, Object?>{
          'storageKey': key,
        },
      );
      _fallbackStorage[key] = encodedValue;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } on MissingPluginException {
      AppLogger.warning(
        'Secure storage plugin unavailable on delete',
        context: <String, Object?>{
          'storageKey': key,
        },
      );
      _fallbackStorage.remove(key);
    }
  }

  String _wrapStoredValue(String value) {
    return jsonEncode(<String, Object?>{
      _versionKey: _storageEnvelopeVersion,
      _payloadKey: value,
      _digestKey: AppCrypto.hashSha256(value),
    });
  }

  String? _unwrapStoredValue({
    required String key,
    required String? storedValue,
  }) {
    const invalidStoredValueMessage =
        'Os dados salvos neste dispositivo estao invalidos. '
        'Entre novamente.';

    if (storedValue == null || storedValue.isEmpty) {
      return storedValue;
    }

    final envelope = _tryDecodeEnvelope(storedValue);
    if (envelope == null) {
      return storedValue;
    }

    final payload = envelope[_payloadKey];
    final digest = envelope[_digestKey];

    if (payload is! String || digest is! String) {
      AppLogger.error(
        'Stored value envelope is invalid',
        context: <String, Object?>{
          'storageKey': key,
        },
      );
      throw StorageFailure(
        message: 'Stored value envelope is invalid',
        userMessage: invalidStoredValueMessage,
        context: <String, Object?>{
          'operation': 'readSessionStorage',
          'storageKey': key,
        },
      );
    }

    final expectedDigest = AppCrypto.hashSha256(payload);
    if (!AppCrypto.secureEquals(expectedDigest, digest)) {
      AppLogger.error(
        'Stored value digest validation failed',
        context: <String, Object?>{
          'storageKey': key,
        },
      );
      throw StorageFailure(
        message: 'Stored value digest validation failed',
        userMessage: invalidStoredValueMessage,
        context: <String, Object?>{
          'operation': 'readSessionStorage',
          'storageKey': key,
        },
      );
    }

    return payload;
  }

  Map<String, dynamic>? _tryDecodeEnvelope(String value) {
    try {
      final decodedValue = jsonDecode(value);
      if (decodedValue is! Map<String, dynamic>) {
        return null;
      }

      final looksLikeEnvelope =
          decodedValue.containsKey(_versionKey) ||
          decodedValue.containsKey(_payloadKey) ||
          decodedValue.containsKey(_digestKey);

      return looksLikeEnvelope ? decodedValue : null;
    } on FormatException {
      return null;
    }
  }
}
