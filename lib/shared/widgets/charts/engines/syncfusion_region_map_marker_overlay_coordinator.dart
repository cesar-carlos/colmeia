import 'package:flutter/scheduler.dart';

/// Manages deferred marker overlay readiness, remount generation bumps, and
/// lifecycle recovery scheduling for the Syncfusion region map surface.
class SyncfusionRegionMapMarkerOverlayCoordinator {
  bool markersOverlayReady = false;
  int markerOverlayMountGeneration = 0;

  int? _scheduleForSurfaceKey;
  int _scheduleGeneration = 0;

  void reset() {
    markersOverlayReady = false;
    markerOverlayMountGeneration = 0;
    cancelSchedule();
  }

  void cancelSchedule() {
    _scheduleForSurfaceKey = null;
    _scheduleGeneration++;
  }

  bool isScheduledFor(int mapSurfaceStableKey) {
    return _scheduleForSurfaceKey == mapSurfaceStableKey;
  }

  void recoverAfterHiddenLifecycle({
    required int? cachedMapSurfaceStableKey,
    required bool Function() mounted,
    required bool Function(int mapSurfaceStableKey) canCommit,
    required void Function() onOverlayReady,
  }) {
    reset();
    final surfaceKey = cachedMapSurfaceStableKey;
    if (surfaceKey != null) {
      scheduleReady(
        mapSurfaceStableKey: surfaceKey,
        mounted: mounted,
        canCommit: canCommit,
        onOverlayReady: onOverlayReady,
      );
    }
  }

  void scheduleReady({
    required int mapSurfaceStableKey,
    required bool Function() mounted,
    required bool Function(int mapSurfaceStableKey) canCommit,
    required void Function() onOverlayReady,
  }) {
    if (_scheduleForSurfaceKey == mapSurfaceStableKey) {
      return;
    }
    _scheduleForSurfaceKey = mapSurfaceStableKey;
    final scheduleGeneration = _scheduleGeneration;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted() || scheduleGeneration != _scheduleGeneration) {
        return;
      }
      if (!canCommit(mapSurfaceStableKey)) {
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted() ||
            scheduleGeneration != _scheduleGeneration ||
            markersOverlayReady) {
          return;
        }
        if (!canCommit(mapSurfaceStableKey)) {
          return;
        }
        markersOverlayReady = true;
        markerOverlayMountGeneration++;
        onOverlayReady();
      });
    });
  }
}
