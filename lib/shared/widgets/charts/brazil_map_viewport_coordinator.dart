import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_zoom_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Input for pure preferred-viewport resolution (no side effects).
class BrazilMapPreferredViewportRequest {
  const BrazilMapPreferredViewportRequest({
    required this.userHasManualMapViewport,
    required this.cachedBindingKey,
    required this.regionBindingKey,
    required this.selectedStoreId,
    required this.selectedPoint,
    required this.shouldFocusCameraOnSelectedStore,
    required this.selectedStoreZoomLevel,
    required this.activeRegionKey,
  });

  final bool userHasManualMapViewport;
  final String? cachedBindingKey;
  final String regionBindingKey;
  final String? selectedStoreId;
  final AppBrazilStoreSalesPoint? selectedPoint;
  final bool shouldFocusCameraOnSelectedStore;
  final double selectedStoreZoomLevel;
  final String? activeRegionKey;
}

/// Pure preferred viewport policy for Syncfusion.
abstract final class BrazilMapPreferredViewportPolicy {
  static ({AppMapViewport? viewport, String? bindingKeyToRecord}) resolve(
    BrazilMapPreferredViewportRequest request,
  ) {
    if (request.userHasManualMapViewport) {
      return (viewport: null, bindingKeyToRecord: null);
    }

    final selectedPoint = request.selectedPoint;
    if (request.shouldFocusCameraOnSelectedStore && selectedPoint != null) {
      return (
        viewport: AppMapViewport(
          centerLatitude: selectedPoint.latitude,
          centerLongitude: selectedPoint.longitude,
          zoomLevel: request.selectedStoreZoomLevel,
        ),
        bindingKeyToRecord: null,
      );
    }

    if (request.selectedStoreId != null) {
      return (viewport: null, bindingKeyToRecord: null);
    }

    if (request.cachedBindingKey == request.regionBindingKey) {
      return (viewport: null, bindingKeyToRecord: null);
    }

    final regionKey = request.activeRegionKey;
    final viewport = regionKey == null
        ? AppBrazilMapStaticData.brazilViewport
        : AppBrazilMapStaticData.regionViewports[regionKey] ??
              AppBrazilMapStaticData.brazilViewport;

    return (
      viewport: viewport,
      bindingKeyToRecord: request.regionBindingKey,
    );
  }
}

/// Coordinates preferred viewport delivery, manual viewport tracking, and
/// viewport-driven clustering debounce for the Brazil store-sales map.
class BrazilMapViewportCoordinator {
  bool userHasManualMapViewport = false;
  String? cachedPreferredViewportBinding;
  AppMapViewport? cachedPreferredViewport;

  Timer? _viewportClusterDebounceTimer;
  double? _pendingViewportClusterZoomLevel;
  int _mapPointerDownCount = 0;
  bool _viewportClusterGestureActive = false;

  static const Duration touchViewportClusterDebounceDuration = Duration(
    milliseconds: 180,
  );
  static const Duration desktopViewportClusterDebounceDuration = Duration(
    milliseconds: 120,
  );

  void dispose() {
    cancelPendingViewportClusterSampling();
  }

  void invalidatePreferredViewport() {
    cachedPreferredViewportBinding = null;
    cachedPreferredViewport = null;
  }

  void resetManualViewport() {
    userHasManualMapViewport = false;
    invalidatePreferredViewport();
  }

  String regionBindingKey(String? activeRegionKey) =>
      activeRegionKey ?? '__brazil__';

  AppMapViewport resetTargetViewportForScope(String? activeRegionKey) {
    final regionKey = activeRegionKey;
    if (regionKey == null) {
      return AppBrazilMapStaticData.brazilViewport;
    }

    return AppBrazilMapStaticData.regionViewports[regionKey] ??
        AppBrazilMapStaticData.brazilViewport;
  }

  /// Resolves preferred viewport for build without mutating binding cache.
  /// Binding keys are recorded post-frame when a scope viewport is delivered.
  AppMapViewport? preferredViewportForBuild(
    BrazilMapPreferredViewportRequest request,
  ) {
    final result = BrazilMapPreferredViewportPolicy.resolve(request);
    final next = result.viewport;
    if (next == null) {
      cachedPreferredViewport = null;
      return null;
    }
    final cached = cachedPreferredViewport;
    if (cached == next) {
      return cached;
    }
    cachedPreferredViewport = next;
    final bindingKey = result.bindingKeyToRecord;
    if (bindingKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cachedPreferredViewportBinding = bindingKey;
      });
    }
    return next;
  }

  AppMapViewportChangedEvent? filterViewportChangedEvent(
    AppMapViewportChangedEvent event, {
    required bool blocksViewportDrivenClusteringOnWindows,
  }) {
    if (defaultTargetPlatform == TargetPlatform.windows &&
        blocksViewportDrivenClusteringOnWindows) {
      return null;
    }
    return event;
  }

  void cancelPendingViewportClusterSampling() {
    _viewportClusterDebounceTimer?.cancel();
    _viewportClusterDebounceTimer = null;
    _pendingViewportClusterZoomLevel = null;
    _mapPointerDownCount = 0;
    _viewportClusterGestureActive = false;
  }

  void handleMapPointerDown({required bool deferDuringGesture}) {
    if (!deferDuringGesture) {
      return;
    }
    _mapPointerDownCount++;
    if (_mapPointerDownCount == 1) {
      _viewportClusterGestureActive = true;
      _viewportClusterDebounceTimer?.cancel();
    }
  }

  void handleMapPointerUp({
    required bool deferDuringGesture,
    required void Function(double zoomLevel) onApplyClusterZoom,
  }) {
    if (!deferDuringGesture) {
      return;
    }
    if (_mapPointerDownCount <= 0) {
      return;
    }
    _mapPointerDownCount--;
    if (_mapPointerDownCount > 0) {
      return;
    }
    _viewportClusterGestureActive = false;
    _flushPendingViewportClusterZoomLevel(onApplyClusterZoom);
  }

  void _flushPendingViewportClusterZoomLevel(
    void Function(double zoomLevel) onApplyClusterZoom,
  ) {
    final pendingZoomLevel = _pendingViewportClusterZoomLevel;
    if (pendingZoomLevel == null) {
      return;
    }
    _pendingViewportClusterZoomLevel = null;
    onApplyClusterZoom(pendingZoomLevel);
  }

  static bool shouldDebounceTouchViewportClustering({
    required bool enableZoomPan,
  }) {
    if (!enableZoomPan) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => true,
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => false,
    };
  }

  void handleViewportChanged({
    required AppMapViewportChangedEvent event,
    required bool enableProximityCluster,
    required bool blocksViewportDrivenClustering,
    required bool enableZoomPan,
    required BrazilMapZoomController zoom,
    required void Function() onMarkManualViewport,
    required bool shouldClearStoreDetailOnUserViewportChange,
    required void Function() onClearStoreDetail,
    required void Function(double zoomLevel) onApplyClusterZoom,
    required int pointCount,
    required String? activeRegionKey,
  }) {
    if (event.source == AppMapViewportChangeSource.user &&
        !userHasManualMapViewport) {
      onMarkManualViewport();
    }

    if (event.source == AppMapViewportChangeSource.user &&
        shouldClearStoreDetailOnUserViewportChange) {
      onClearStoreDetail();
    }

    if (!enableProximityCluster) {
      return;
    }

    if (event.source == AppMapViewportChangeSource.programmatic) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      cancelPendingViewportClusterSampling();
      return;
    }

    if (blocksViewportDrivenClustering) {
      cancelPendingViewportClusterSampling();
      return;
    }

    final nextZoomLevel = event.viewport.zoomLevel;
    final debounceDuration = shouldDebounceTouchViewportClustering(
      enableZoomPan: enableZoomPan,
    )
        ? touchViewportClusterDebounceDuration
        : desktopViewportClusterDebounceDuration;

    _pendingViewportClusterZoomLevel = nextZoomLevel;
    if (_viewportClusterGestureActive) {
      _viewportClusterDebounceTimer?.cancel();
      return;
    }
    _viewportClusterDebounceTimer?.cancel();
    _viewportClusterDebounceTimer = Timer(
      debounceDuration,
      () {
        final pendingZoomLevel = _pendingViewportClusterZoomLevel;
        _pendingViewportClusterZoomLevel = null;
        if (pendingZoomLevel == null) {
          return;
        }
        _applyViewportClusterZoomLevel(
          pendingZoomLevel,
          blocksViewportDrivenClustering: blocksViewportDrivenClustering,
          zoom: zoom,
          onApplyClusterZoom: onApplyClusterZoom,
          pointCount: pointCount,
          activeRegionKey: activeRegionKey,
        );
      },
    );
  }

  void _applyViewportClusterZoomLevel(
    double nextZoomLevel, {
    required bool blocksViewportDrivenClustering,
    required BrazilMapZoomController zoom,
    required void Function(double zoomLevel) onApplyClusterZoom,
    required int pointCount,
    required String? activeRegionKey,
  }) {
    if (blocksViewportDrivenClustering) {
      return;
    }
    if (!zoom.shouldApplyViewportClusterSample(
      nextZoomLevel,
      blocksViewportDrivenClustering: blocksViewportDrivenClustering,
    )) {
      return;
    }

    onApplyClusterZoom(nextZoomLevel);
    if (kDebugMode || kProfileMode) {
      AppLogger.debug(
        'Brazil store sales map viewport changed',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'zoomLevel': nextZoomLevel,
          'pointCount': pointCount,
          'activeRegionKey': activeRegionKey,
        },
      );
    }
  }
}
