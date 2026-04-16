class AppChartPoint {
  const AppChartPoint({
    required this.label,
    required this.value,
    this.plottedValue,
  });

  final String label;

  /// True metric for labels, tooltips, and tap payloads.
  final num value;

  /// Optional Y used only for column height in charts that apply a readability
  /// floor. When null, [value] is used for layout as well.
  final num? plottedValue;
}

class AppChartSeries {
  const AppChartSeries({
    required this.id,
    required this.points,
  });

  final String id;
  final List<AppChartPoint> points;
}

/// Structured payload emitted when the user taps an item-based chart element
/// (segment, bar, scatter point, etc.) in generic charts parameterized by [T].
///
/// All generic chart widgets expose both a simple callback
/// `void Function(T item, int index)?` and a typed
/// `ValueChanged<AppChartItemTapEvent<T>>?` that carries the same data in a
/// single structured object — mirrors the pattern established by
/// AppComparisonBarPointTapEvent.
class AppChartItemTapEvent<T> {
  const AppChartItemTapEvent({
    required this.item,
    required this.index,
  });

  final T item;
  final int index;
}

/// Structured payload for matrix/grid-like charts such as heatmaps.
class AppChartMatrixTapEvent<T> {
  const AppChartMatrixTapEvent({
    required this.item,
    required this.xIndex,
    required this.yIndex,
  });

  final T item;
  final int xIndex;
  final int yIndex;
}

/// Structured payload for category-based charts where the tapped category can
/// optionally be resolved back to a matching point and series entry.
class AppChartCategoryPointTapEvent<E> {
  const AppChartCategoryPointTapEvent({
    required this.category,
    required this.categoryIndex,
    this.point,
    this.entry,
    this.entryIndex,
  });

  final String category;
  final int categoryIndex;
  final AppChartPoint? point;
  final E? entry;
  final int? entryIndex;
}

/// Structured payload for cartesian charts that expose both the tapped point
/// and its parent series entry.
class AppChartSeriesPointTapEvent<E> {
  const AppChartSeriesPointTapEvent({
    required this.entry,
    required this.seriesIndex,
    required this.point,
    required this.pointIndex,
  });

  final E entry;
  final int seriesIndex;
  final AppChartPoint point;
  final int pointIndex;
}
