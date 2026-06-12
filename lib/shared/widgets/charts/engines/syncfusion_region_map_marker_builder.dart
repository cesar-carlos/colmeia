import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// Builds Syncfusion [MapMarker] widgets with platform-aware tap targets.
abstract final class SyncfusionRegionMapMarkerBuilder {
  static MapMarker build({
    required BuildContext mapBuilderContext,
    required AppMapPoint point,
    required int index,
    required AppMapMarkerStyle defaultMarkerStyle,
    required Color defaultColor,
    required Color defaultStrokeColor,
    required Widget Function(BuildContext context, AppMapPoint point, int index)?
    markerBuilder,
    required ValueChanged<AppMapPointTapEvent>? onPointTap,
  }) {
    final effectiveStyle = point.style ?? defaultMarkerStyle;
    final fallbackChild = SyncfusionRegionMapMarkerShape(
      style: effectiveStyle,
      defaultColor: defaultColor,
      defaultStrokeColor: defaultStrokeColor,
    );
    final builtChild =
        markerBuilder?.call(mapBuilderContext, point, index) ?? fallbackChild;
    final tapWrappedChild = onPointTap == null
        ? builtChild
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPointTap(
              AppMapPointTapEvent(point: point, index: index),
            ),
            child: builtChild,
          );
    final visualSize = effectiveStyle.size;
    const minTapSize = 48.0;
    final isMobilePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final markerSize = isMobilePlatform
        ? math.max(minTapSize, visualSize)
        : visualSize;
    final markerChild =
        isMobilePlatform && markerSize > visualSize
        ? SizedBox(
            width: markerSize,
            height: markerSize,
            child: Center(child: tapWrappedChild),
          )
        : tapWrappedChild;
    return MapMarker(
      latitude: point.latitude,
      longitude: point.longitude,
      size: Size.square(markerSize),
      child: markerChild,
    );
  }
}
