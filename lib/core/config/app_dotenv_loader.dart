import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads dotenv from bundled assets before `AppEnvironment` is read.
///
/// `EnvAssetPaths.bundledDefault` is required. Optional
/// `EnvAssetPaths.bundledLocal` is merged when present in the asset bundle
/// (add the file and list it under `flutter: assets:` in `pubspec.yaml`).
///
/// The merge step uses a small line parser (see `assets/env/.env.example`); for
/// `bundledDefault`, the full `flutter_dotenv` parser applies.
Future<void> loadAppDotenv() async {
  try {
    await dotenv.load(fileName: EnvAssetPaths.bundledDefault);
  } on Object catch (error, stackTrace) {
    AppLogger.error(
      'Failed to load ${EnvAssetPaths.bundledDefault}',
      context: const <String, Object?>{
        'component': 'loadAppDotenv',
      },
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
  await _mergeOptionalLocalEnv();
}

Future<void> _mergeOptionalLocalEnv() async {
  try {
    final content = await rootBundle.loadString(EnvAssetPaths.bundledLocal);
    final merged = _parseSimpleEnvLines(content);
    for (final entry in merged.entries) {
      dotenv.env[entry.key] = entry.value;
    }
  } on Object catch (error, stackTrace) {
    if (error is FlutterError) {
      if (kDebugMode) {
        AppLogger.debug(
          'Optional ${EnvAssetPaths.bundledLocal} not in asset bundle; '
          'merge skipped. Add the file and list it under flutter: assets: '
          'when using local overrides.',
          context: const <String, Object?>{
            'component': 'loadAppDotenv',
          },
        );
      }
      return;
    }
    AppLogger.warning(
      'Optional ${EnvAssetPaths.bundledLocal} merge failed',
      context: const <String, Object?>{
        'component': 'loadAppDotenv',
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Map<String, String> _parseSimpleEnvLines(String content) {
  final map = <String, String>{};
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final index = trimmed.indexOf('=');
    if (index <= 0) {
      continue;
    }
    final key = trimmed.substring(0, index).trim();
    if (key.isEmpty) {
      continue;
    }
    final value = trimmed.substring(index + 1).trim();
    map[key] = value;
  }
  return map;
}
