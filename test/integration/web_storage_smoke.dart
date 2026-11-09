import 'dart:convert';
import 'dart:js_interop';

import 'package:colmeia/core/cache/app_cache_store_factory.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/storage/app_secure_storage_factory.dart';
import 'package:colmeia/core/storage/session_storage.dart';
import 'package:flutter/widgets.dart';

@JS('colmeiaStorageSmoke')
external set _storageSmoke(JSFunction value);

/// Browser-only entry point for storage persistence and multi-tab smoke checks.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = await createAppCacheStore();
  final session = SessionStorage(createAppSecureStorage());
  _storageSmoke = ((JSString encoded) {
    Future<JSString> execute() async {
      final request = jsonDecode(encoded.toDart) as Map<String, dynamic>;
      final key = request['key'] as String? ?? 'storage_smoke';
      try {
        Object? result;
        switch (request['operation']) {
          case 'cacheRead':
            result = await cache.getString(key);
          case 'cacheWrite':
            await cache.putString(key: key, value: request['value'] as String);
          case 'cacheDelete':
            await cache.removeString(key);
          case 'cacheClear':
            await cache.clearAll();
          case 'sessionRead':
            result = await session.read(key);
          case 'sessionWrite':
            await session.write(key: key, value: request['value'] as String);
          case 'sessionDelete':
            await session.delete(key);
          default:
            throw ArgumentError('Unknown smoke operation');
        }
        return jsonEncode({'value': result}).toJS;
      } on StorageFailure {
        return jsonEncode({'error': 'StorageFailure'}).toJS;
      }
    }

    return execute().toJS;
  }).toJS;
}
