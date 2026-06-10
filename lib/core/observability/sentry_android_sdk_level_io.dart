import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

final RegExp _androidApiLevelPattern = RegExp(r'API (\d+)');

String? resolveAndroidSdkApiLevelForSentry() {
  if (kIsWeb || !Platform.isAndroid) {
    return null;
  }

  return _androidApiLevelPattern.firstMatch(Platform.version)?.group(1);
}
