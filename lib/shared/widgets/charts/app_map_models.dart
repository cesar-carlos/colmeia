import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

/// Drill granularity for territorial maps (query, chart, and drill events).
enum AppMapDrillLevel {
  region,
  state,
  city,
  custom,
}

/// Origin of a viewport change notification.
enum AppMapViewportChangeSource {
  /// User pinched, panned, or used zoom controls.
  user,

  /// Map moved programmatically (animation or direct camera set).
  programmatic,
}

/// Current viewport information emitted by interactive map widgets.
@immutable
class AppMapViewport {
  const AppMapViewport({
    required this.zoomLevel,
    this.centerLatitude,
    this.centerLongitude,
    this.bounds,
  });

  final double zoomLevel;
  final double? centerLatitude;
  final double? centerLongitude;
  final AppMapViewportBounds? bounds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppMapViewport &&
        zoomLevel == other.zoomLevel &&
        centerLatitude == other.centerLatitude &&
        centerLongitude == other.centerLongitude &&
        bounds == other.bounds;
  }

  @override
  int get hashCode => Object.hash(
    zoomLevel,
    centerLatitude,
    centerLongitude,
    bounds,
  );
}

/// Geographic bounds represented in latitude/longitude coordinates.
@immutable
class AppMapViewportBounds {
  const AppMapViewportBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  final double north;
  final double south;
  final double east;
  final double west;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppMapViewportBounds &&
        north == other.north &&
        south == other.south &&
        east == other.east &&
        west == other.west;
  }

  @override
  int get hashCode => Object.hash(north, south, east, west);
}

/// Structured payload emitted when the user taps a map region.
@immutable
class AppMapRegionTapEvent<T> {
  const AppMapRegionTapEvent({
    required this.item,
    required this.regionKey,
    required this.regionLabel,
    required this.metricKey,
    required this.metricValue,
    required this.index,
  });

  final T item;
  final String regionKey;
  final String regionLabel;
  final String metricKey;
  final num metricValue;
  final int index;
}

/// Structured payload emitted when map selection changes.
@immutable
class AppMapSelectionChangedEvent<T> {
  const AppMapSelectionChangedEvent({
    required this.previousRegionKey,
    required this.currentRegionKey,
    this.previousItem,
    this.currentItem,
    this.metricKey,
    this.metricLabel,
  });

  final String? previousRegionKey;
  final String? currentRegionKey;
  final T? previousItem;
  final T? currentItem;

  /// Active metric when the selection changed (if provided by the chart).
  final String? metricKey;

  /// Display label for [metricKey], when available.
  final String? metricLabel;
}

/// Structured payload emitted when the active map metric changes.
@immutable
class AppMapMetricChangedEvent {
  const AppMapMetricChangedEvent({
    required this.metricKey,
    required this.previousMetricKey,
  });

  final String metricKey;
  final String? previousMetricKey;
}

/// Scope option exposed to let the user navigate the current map context.
@immutable
class AppMapScopeOption {
  const AppMapScopeOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

/// Emitted when the user changes the territorial scope chip.
@immutable
class AppMapScopeChangedEvent {
  const AppMapScopeChangedEvent({
    required this.previousScopeKey,
    required this.currentScopeKey,
  });

  final String? previousScopeKey;
  final String? currentScopeKey;
}

/// Structured payload emitted when the user requests drill-down navigation.
@immutable
class AppMapDrillDownEvent<T> {
  const AppMapDrillDownEvent({
    required this.item,
    required this.regionKey,
    required this.fromLevel,
    required this.toLevel,
  });

  final T item;
  final String regionKey;
  final AppMapDrillLevel fromLevel;
  final AppMapDrillLevel toLevel;
}

/// Structured payload emitted when the user requests drill-up navigation.
@immutable
class AppMapDrillUpEvent {
  const AppMapDrillUpEvent({
    required this.fromLevel,
    required this.toLevel,
  });

  final AppMapDrillLevel fromLevel;
  final AppMapDrillLevel toLevel;
}

/// Structured payload emitted whenever map viewport changes.
@immutable
class AppMapViewportChangedEvent {
  const AppMapViewportChangedEvent({
    required this.viewport,
    this.source = AppMapViewportChangeSource.user,
  });

  final AppMapViewport viewport;

  /// Whether the change came from user interaction or programmatic updates.
  final AppMapViewportChangeSource source;
}

/// Available marker icon shapes for [AppMapPoint].
enum AppMapMarkerIcon { circle, diamond, triangle, rectangle }

/// Visual style applied to map markers when no per-point override is provided.
@immutable
class AppMapMarkerStyle {
  const AppMapMarkerStyle({
    this.iconType = AppMapMarkerIcon.circle,
    this.size = 14,
    this.color,
    this.strokeColor,
    this.strokeWidth = 1.5,
  });

  final AppMapMarkerIcon iconType;
  final double size;

  /// When `null`, the chart uses the active theme's primary color.
  final Color? color;

  /// When `null`, the chart uses the active theme's surface color so the
  /// marker stays readable over both colored regions and empty areas.
  final Color? strokeColor;

  final double strokeWidth;

  AppMapMarkerStyle copyWith({
    AppMapMarkerIcon? iconType,
    double? size,
    Color? color,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    return AppMapMarkerStyle(
      iconType: iconType ?? this.iconType,
      size: size ?? this.size,
      color: color ?? this.color,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// A geographic point overlay rendered on top of region shapes.
///
/// `payload` is intentionally `Object?` to keep the chart and snapshot
/// generics clean (`AppRegionMapChart<T>` stays mono-generic). Consumers
/// cast inside their `onPointTap` handler when they need the typed value.
@immutable
class AppMapPoint {
  const AppMapPoint({
    required this.latitude,
    required this.longitude,
    this.payload,
    this.label,
    this.tooltip,
    this.style,
  }) : assert(
         latitude >= -90 && latitude <= 90,
         'latitude must be in [-90, 90]',
       ),
       assert(
         longitude >= -180 && longitude <= 180,
         'longitude must be in [-180, 180]',
       );

  final double latitude;
  final double longitude;

  /// Original domain object (e.g. a Store, Agent, Event). Cast on tap.
  final Object? payload;

  /// Optional short text shown beside or under the marker (engine-dependent).
  final String? label;

  /// Tooltip text when the user hovers/taps. When `null`, falls back to
  /// [label]; when both are `null`, no tooltip is shown.
  final String? tooltip;

  /// Per-point visual override; `null` uses the chart's default style.
  final AppMapMarkerStyle? style;
}

/// Structured payload emitted when the user taps a map point marker.
@immutable
class AppMapPointTapEvent {
  const AppMapPointTapEvent({required this.point, required this.index});

  final AppMapPoint point;
  final int index;
}
