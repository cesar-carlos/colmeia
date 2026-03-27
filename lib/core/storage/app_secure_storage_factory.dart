import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-appropriate secure storage. On web, [FlutterSecureStorage] uses the
/// browser storage implementation from the plugin (not OS keychain).
FlutterSecureStorage createAppSecureStorage() {
  if (kIsWeb) {
    return const FlutterSecureStorage(
      webOptions: WebOptions(
        dbName: 'colmeia_secure',
        publicKey: 'colmeia_web_storage',
      ),
    );
  }
  return const FlutterSecureStorage();
}
