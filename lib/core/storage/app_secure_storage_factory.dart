import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-appropriate secure storage for OAuth-style tokens.
///
/// On Android and iOS, tokens are stored with the platform secure enclave /
/// Keystore behavior provided by the plugin.
///
/// On web, the plugin persists encrypted blobs in browser storage using the
/// given [WebOptions]; this is not equivalent to a hardware-backed keystore.
/// Session invalidation and rotation remain enforced by the backend; the app
/// must treat refresh/access tokens as secrets and avoid logging them.
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
