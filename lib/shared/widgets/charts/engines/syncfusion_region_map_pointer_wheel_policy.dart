import 'package:flutter/foundation.dart';

/// Platform rules for pointer-wheel zoom on Syncfusion region maps.
abstract final class SyncfusionRegionMapPointerWheelPolicy {
  static bool isEnabled({required bool zoomPanEnabled}) {
    if (!zoomPanEnabled) {
      return false;
    }
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
  }
}
