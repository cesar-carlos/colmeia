import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Platform-appropriate share icon for chart header actions.
IconData chartShareActionIcon() {
  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
    return Icons.ios_share;
  }
  return Icons.share;
}
