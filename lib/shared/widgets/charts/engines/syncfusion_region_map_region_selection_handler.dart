import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/foundation.dart';

/// Region tap / selection / auto-drill handling extracted from
/// `SyncfusionRegionMapChart` to keep the engine state class smaller.
class SyncfusionRegionMapRegionSelectionHandler<T> {
  const SyncfusionRegionMapRegionSelectionHandler({
    required this.items,
    required this.metric,
    required this.selectedRegionKey,
    required this.currentDrillLevel,
    required this.style,
    required this.onRegionTap,
    required this.onRegionTapEvent,
    required this.onSelectionChanged,
    required this.onDrillDownRequested,
  });

  final List<T> items;
  final AppMapMetric<T> metric;
  final String? selectedRegionKey;
  final AppMapDrillLevel currentDrillLevel;
  final AppRegionMapChartStyle style;
  final void Function(T item, String regionKey)? onRegionTap;
  final ValueChanged<AppMapRegionTapEvent<T>>? onRegionTapEvent;
  final ValueChanged<AppMapSelectionChangedEvent<T>>? onSelectionChanged;
  final ValueChanged<AppMapDrillDownEvent<T>>? onDrillDownRequested;

  void handle({
    required int index,
    required List<String> regionKeys,
    required List<String> regionLabels,
    required List<double> metricValues,
  }) {
    if (index < 0 || index >= items.length) {
      return;
    }

    final item = items[index];
    final regionKey = regionKeys[index];
    final regionLabel = regionLabels[index];
    final metricValue = metricValues[index];
    final previousRegionKey = selectedRegionKey;
    final previousIndex = previousRegionKey == null
        ? -1
        : regionKeys.indexOf(previousRegionKey);
    final previousItem = previousIndex >= 0 ? items[previousIndex] : null;

    if (regionKey == selectedRegionKey) {
      final nextDrill = _nextDrillLevel(currentDrillLevel);
      final canDrillFurther =
          style.enableAutoDrillOnTap &&
          nextDrill != null &&
          _shouldAutoDrillTo(nextDrill);
      if (!canDrillFurther) {
        onSelectionChanged?.call(
          AppMapSelectionChangedEvent<T>(
            previousRegionKey: previousRegionKey,
            currentRegionKey: null,
            previousItem: item,
            metricKey: metric.key,
            metricLabel: metric.label,
          ),
        );
        return;
      }
    }

    onRegionTap?.call(item, regionKey);
    onRegionTapEvent?.call(
      AppMapRegionTapEvent<T>(
        item: item,
        regionKey: regionKey,
        regionLabel: regionLabel,
        metricKey: metric.key,
        metricValue: metricValue,
        index: index,
      ),
    );
    onSelectionChanged?.call(
      AppMapSelectionChangedEvent<T>(
        previousRegionKey: previousRegionKey,
        currentRegionKey: regionKey,
        previousItem: previousItem,
        currentItem: item,
        metricKey: metric.key,
        metricLabel: metric.label,
      ),
    );

    if (style.enableAutoDrillOnTap) {
      final nextDrillLevel = _nextDrillLevel(currentDrillLevel);
      if (nextDrillLevel != null && _shouldAutoDrillTo(nextDrillLevel)) {
        onDrillDownRequested?.call(
          AppMapDrillDownEvent<T>(
            item: item,
            regionKey: regionKey,
            fromLevel: currentDrillLevel,
            toLevel: nextDrillLevel,
          ),
        );
      }
    }
  }

  AppMapDrillLevel? _nextDrillLevel(AppMapDrillLevel level) {
    return switch (level) {
      AppMapDrillLevel.region => AppMapDrillLevel.state,
      AppMapDrillLevel.state => AppMapDrillLevel.city,
      AppMapDrillLevel.city => AppMapDrillLevel.custom,
      AppMapDrillLevel.custom => null,
    };
  }

  bool _shouldAutoDrillTo(AppMapDrillLevel nextLevel) {
    final ceiling = style.autoDrillCeiling;
    if (ceiling == null) {
      return true;
    }
    return nextLevel.index <= ceiling.index;
  }
}
