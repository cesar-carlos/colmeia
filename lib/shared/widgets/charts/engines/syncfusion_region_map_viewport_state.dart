import 'package:flutter/foundation.dart';

@immutable
class SyncfusionRegionMapViewportState {
  const SyncfusionRegionMapViewportState({
    required this.zoomLevel,
    this.centerLatitude,
    this.centerLongitude,
    this.userHasManualViewport = false,
    this.suppressProgrammaticViewportEvents = false,
  });

  final double zoomLevel;
  final double? centerLatitude;
  final double? centerLongitude;
  final bool userHasManualViewport;
  final bool suppressProgrammaticViewportEvents;

  SyncfusionRegionMapViewportState copyWith({
    double? zoomLevel,
    Object? centerLatitude = _syncfusionRegionMapViewportUnset,
    Object? centerLongitude = _syncfusionRegionMapViewportUnset,
    bool? userHasManualViewport,
    bool? suppressProgrammaticViewportEvents,
  }) {
    return SyncfusionRegionMapViewportState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      centerLatitude: identical(centerLatitude, _syncfusionRegionMapViewportUnset)
          ? this.centerLatitude
          : centerLatitude as double?,
      centerLongitude: identical(centerLongitude, _syncfusionRegionMapViewportUnset)
          ? this.centerLongitude
          : centerLongitude as double?,
      userHasManualViewport:
          userHasManualViewport ?? this.userHasManualViewport,
      suppressProgrammaticViewportEvents:
          suppressProgrammaticViewportEvents ??
          this.suppressProgrammaticViewportEvents,
    );
  }
}

const Object _syncfusionRegionMapViewportUnset = Object();
