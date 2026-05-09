import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AppBrazilStoreSalesMapMetric {
  revenue,
  salesCount,
}

enum AppBrazilStoreSalesMarkerVisual {
  dot,
  bubble,
  storeIcon,
}

enum AppBrazilStoreSalesStateLabelMode {
  uf,
  stateName,
  responsive,
}

enum AppBrazilStoreSalesMarkerAggregation {
  stores,
  municipalities,
  states,
  storesAndStates,
}

enum AppBrazilStoreSalesMapPreset {
  standard,
  bubble,
  municipalityBubbles,
  stateBubbles,
  storeIcon,
}

extension AppBrazilStoreSalesMapPresetX on AppBrazilStoreSalesMapPreset {
  String get label => switch (this) {
    AppBrazilStoreSalesMapPreset.standard => 'Pontos',
    AppBrazilStoreSalesMapPreset.bubble => 'Bolhas',
    AppBrazilStoreSalesMapPreset.municipalityBubbles => 'Municipios',
    AppBrazilStoreSalesMapPreset.stateBubbles => 'Bolhas por UF',
    AppBrazilStoreSalesMapPreset.storeIcon => 'Icone loja',
  };

  String get tooltip => switch (this) {
    AppBrazilStoreSalesMapPreset.standard =>
      'Exibe cada loja como ponto individual no mapa.',
    AppBrazilStoreSalesMapPreset.bubble =>
      'Exibe lojas como bolhas proporcionais a metrica ativa.',
    AppBrazilStoreSalesMapPreset.municipalityBubbles =>
      'Agrupa lojas por municipio e exibe bolhas proporcionais a metrica ativa.',
    AppBrazilStoreSalesMapPreset.stateBubbles =>
      'Agrupa as lojas em bolhas posicionadas no centro de cada UF.',
    AppBrazilStoreSalesMapPreset.storeIcon =>
      'Exibe cada loja com icone operacional de unidade.',
  };

  AppBrazilStoreSalesMapStyle style({
    double height = 480,
    bool showStoreDetail = true,
    bool showMarkerScaleLegend = true,
    bool enableProximityCluster = false,
  }) => switch (this) {
    AppBrazilStoreSalesMapPreset.standard =>
      AppBrazilStoreSalesMapStyle.standard(
        height: height,
        showStoreDetail: showStoreDetail,
        showMarkerScaleLegend: showMarkerScaleLegend,
        enableProximityCluster: enableProximityCluster,
      ),
    AppBrazilStoreSalesMapPreset.bubble => AppBrazilStoreSalesMapStyle.bubble(
      height: height,
      showStoreDetail: showStoreDetail,
      showMarkerScaleLegend: showMarkerScaleLegend,
      enableProximityCluster: enableProximityCluster,
    ),
    AppBrazilStoreSalesMapPreset.municipalityBubbles =>
      AppBrazilStoreSalesMapStyle.municipalityBubbles(
        height: height,
        showStoreDetail: showStoreDetail,
        showMarkerScaleLegend: showMarkerScaleLegend,
      ),
    AppBrazilStoreSalesMapPreset.stateBubbles =>
      AppBrazilStoreSalesMapStyle.stateBubbles(
        height: height,
        showMarkerScaleLegend: showMarkerScaleLegend,
      ),
    AppBrazilStoreSalesMapPreset.storeIcon =>
      AppBrazilStoreSalesMapStyle.storeIcon(
        height: height,
        showStoreDetail: showStoreDetail,
        showMarkerScaleLegend: showMarkerScaleLegend,
        enableProximityCluster: enableProximityCluster,
      ),
  };
}

extension AppBrazilStoreSalesMapMetricX on AppBrazilStoreSalesMapMetric {
  String get key => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => 'revenue',
    AppBrazilStoreSalesMapMetric.salesCount => 'salesCount',
  };

  String get label => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => 'Receita',
    AppBrazilStoreSalesMapMetric.salesCount => 'Vendas',
  };

  num valueForPoint(AppBrazilStoreSalesPoint point) => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => point.salesAmount,
    AppBrazilStoreSalesMapMetric.salesCount => point.salesCount,
  };

  num valueForBucket(AppBrazilStoreSalesStateBucket bucket) => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => bucket.salesAmount,
    AppBrazilStoreSalesMapMetric.salesCount => bucket.salesCount,
  };
}

class AppBrazilStoreSalesPoint {
  const AppBrazilStoreSalesPoint({
    required this.id,
    required this.name,
    required this.uf,
    required this.latitude,
    required this.longitude,
    required this.salesAmount,
    required this.salesCount,
    this.municipalityCode,
    this.city,
    this.subtitle,
    this.payload,
  });

  final String id;
  final String name;
  final String uf;
  final double latitude;
  final double longitude;
  final double salesAmount;
  final int salesCount;
  final String? municipalityCode;
  final String? city;
  final String? subtitle;
  final Object? payload;
}

class AppBrazilStoreSalesStateBucket {
  const AppBrazilStoreSalesStateBucket({
    required this.uf,
    required this.stateName,
    required this.regionKey,
    required this.regionName,
    required this.salesAmount,
    required this.salesCount,
    required this.storeCount,
  });

  final String uf;
  final String stateName;
  final String regionKey;
  final String regionName;
  final double salesAmount;
  final int salesCount;
  final int storeCount;
}

class AppBrazilStoreSalesMapStyle {
  const AppBrazilStoreSalesMapStyle({
    this.height = 480,
    this.includeEmptyStates = true,
    this.showLegend = true,
    this.showTooltip = true,
    this.enableZoomPan = true,
    this.showDataLabels = true,
    this.showMetricSelector = true,
    this.showRegionFilter = true,
    this.showMarkerScaleLegend = true,
    this.showStoreDetail = true,
    this.highlightSelectedState = true,
    this.collapseSameCoordinateMarkers = true,
    this.enableProximityCluster = false,
    this.proximityClusterDistanceDegrees = 0.45,
    this.markerVisual = AppBrazilStoreSalesMarkerVisual.dot,
    this.markerAggregation = AppBrazilStoreSalesMarkerAggregation.stores,
    this.stateLabelMode = AppBrazilStoreSalesStateLabelMode.uf,
    this.showDataQualityNotice = true,
    this.autoFocusSelectedStore = true,
    this.selectedStoreZoomLevel = 4.2,
    this.clusterCoordinatePrecision = 4,
    this.maxClusterTooltipStores = 5,
    this.markerMinSize = 10,
    this.markerMaxSize = 24,
    this.lowValueColor,
    this.highValueColor,
    this.markerColor,
    this.markerStrokeColor,
    this.selectedMarkerColor,
    this.selectedMarkerStrokeColor,
    this.legendNumberFormat,
    this.emptyStateMessage = 'Sem lojas para exibir no mapa.',
  });

  const AppBrazilStoreSalesMapStyle.standard({
    double height = 480,
    bool showStoreDetail = true,
    bool showMarkerScaleLegend = true,
    bool enableProximityCluster = false,
  }) : this(
         height: height,
         showStoreDetail: showStoreDetail,
         showMarkerScaleLegend: showMarkerScaleLegend,
         enableProximityCluster: enableProximityCluster,
         markerVisual: AppBrazilStoreSalesMarkerVisual.dot,
         markerAggregation: AppBrazilStoreSalesMarkerAggregation.stores,
         stateLabelMode: AppBrazilStoreSalesStateLabelMode.responsive,
       );

  const AppBrazilStoreSalesMapStyle.bubble({
    double height = 480,
    bool showStoreDetail = true,
    bool showMarkerScaleLegend = true,
    AppBrazilStoreSalesMarkerAggregation markerAggregation =
        AppBrazilStoreSalesMarkerAggregation.stores,
    bool enableProximityCluster = false,
  }) : this(
         height: height,
         showStoreDetail: showStoreDetail,
         showMarkerScaleLegend: showMarkerScaleLegend,
         enableProximityCluster: enableProximityCluster,
         markerVisual: AppBrazilStoreSalesMarkerVisual.bubble,
         markerAggregation: markerAggregation,
         stateLabelMode: AppBrazilStoreSalesStateLabelMode.responsive,
         markerMinSize: 34,
         markerMaxSize: 78,
       );

  const AppBrazilStoreSalesMapStyle.municipalityBubbles({
    double height = 480,
    bool showStoreDetail = true,
    bool showMarkerScaleLegend = true,
  }) : this(
         height: height,
         showStoreDetail: showStoreDetail,
         showMarkerScaleLegend: showMarkerScaleLegend,
         markerVisual: AppBrazilStoreSalesMarkerVisual.bubble,
         markerAggregation: AppBrazilStoreSalesMarkerAggregation.municipalities,
         stateLabelMode: AppBrazilStoreSalesStateLabelMode.responsive,
         markerMinSize: 34,
         markerMaxSize: 82,
         maxClusterTooltipStores: 8,
       );

  const AppBrazilStoreSalesMapStyle.storeIcon({
    double height = 480,
    bool showStoreDetail = true,
    bool showMarkerScaleLegend = true,
    bool enableProximityCluster = false,
  }) : this(
         height: height,
         showStoreDetail: showStoreDetail,
         showMarkerScaleLegend: showMarkerScaleLegend,
         enableProximityCluster: enableProximityCluster,
         markerVisual: AppBrazilStoreSalesMarkerVisual.storeIcon,
         markerAggregation: AppBrazilStoreSalesMarkerAggregation.stores,
         stateLabelMode: AppBrazilStoreSalesStateLabelMode.responsive,
         markerMinSize: 24,
         markerMaxSize: 34,
       );

  const AppBrazilStoreSalesMapStyle.stateBubbles({
    double height = 480,
    bool showMarkerScaleLegend = true,
  }) : this(
         height: height,
         markerVisual: AppBrazilStoreSalesMarkerVisual.bubble,
         markerAggregation: AppBrazilStoreSalesMarkerAggregation.states,
         stateLabelMode: AppBrazilStoreSalesStateLabelMode.responsive,
         showStoreDetail: false,
         showMarkerScaleLegend: showMarkerScaleLegend,
         markerMinSize: 30,
         markerMaxSize: 76,
       );

  final double height;
  final bool includeEmptyStates;
  final bool showLegend;
  final bool showTooltip;
  final bool enableZoomPan;
  final bool showDataLabels;
  final bool showMetricSelector;
  final bool showRegionFilter;
  final bool showMarkerScaleLegend;
  final bool showStoreDetail;
  final bool highlightSelectedState;
  final bool collapseSameCoordinateMarkers;
  final bool enableProximityCluster;
  final double proximityClusterDistanceDegrees;
  final AppBrazilStoreSalesMarkerVisual markerVisual;
  final AppBrazilStoreSalesMarkerAggregation markerAggregation;
  final AppBrazilStoreSalesStateLabelMode stateLabelMode;
  final bool showDataQualityNotice;
  final bool autoFocusSelectedStore;
  final double selectedStoreZoomLevel;
  final int clusterCoordinatePrecision;
  final int maxClusterTooltipStores;
  final double markerMinSize;
  final double markerMaxSize;
  final Color? lowValueColor;
  final Color? highValueColor;
  final Color? markerColor;
  final Color? markerStrokeColor;
  final Color? selectedMarkerColor;
  final Color? selectedMarkerStrokeColor;
  final NumberFormat? legendNumberFormat;
  final String emptyStateMessage;

  AppBrazilStoreSalesMapStyle copyWith({
    double? height,
    bool? includeEmptyStates,
    bool? showLegend,
    bool? showTooltip,
    bool? enableZoomPan,
    bool? showDataLabels,
    bool? showMetricSelector,
    bool? showRegionFilter,
    bool? showMarkerScaleLegend,
    bool? showStoreDetail,
    bool? highlightSelectedState,
    bool? collapseSameCoordinateMarkers,
    bool? enableProximityCluster,
    double? proximityClusterDistanceDegrees,
    AppBrazilStoreSalesMarkerVisual? markerVisual,
    AppBrazilStoreSalesMarkerAggregation? markerAggregation,
    AppBrazilStoreSalesStateLabelMode? stateLabelMode,
    bool? showDataQualityNotice,
    bool? autoFocusSelectedStore,
    double? selectedStoreZoomLevel,
    int? clusterCoordinatePrecision,
    int? maxClusterTooltipStores,
    double? markerMinSize,
    double? markerMaxSize,
    Color? lowValueColor,
    Color? highValueColor,
    Color? markerColor,
    Color? markerStrokeColor,
    Color? selectedMarkerColor,
    Color? selectedMarkerStrokeColor,
    NumberFormat? legendNumberFormat,
    String? emptyStateMessage,
  }) {
    return AppBrazilStoreSalesMapStyle(
      height: height ?? this.height,
      includeEmptyStates: includeEmptyStates ?? this.includeEmptyStates,
      showLegend: showLegend ?? this.showLegend,
      showTooltip: showTooltip ?? this.showTooltip,
      enableZoomPan: enableZoomPan ?? this.enableZoomPan,
      showDataLabels: showDataLabels ?? this.showDataLabels,
      showMetricSelector: showMetricSelector ?? this.showMetricSelector,
      showRegionFilter: showRegionFilter ?? this.showRegionFilter,
      showMarkerScaleLegend:
          showMarkerScaleLegend ?? this.showMarkerScaleLegend,
      showStoreDetail: showStoreDetail ?? this.showStoreDetail,
      highlightSelectedState:
          highlightSelectedState ?? this.highlightSelectedState,
      collapseSameCoordinateMarkers:
          collapseSameCoordinateMarkers ?? this.collapseSameCoordinateMarkers,
      enableProximityCluster:
          enableProximityCluster ?? this.enableProximityCluster,
      proximityClusterDistanceDegrees:
          proximityClusterDistanceDegrees ??
          this.proximityClusterDistanceDegrees,
      markerVisual: markerVisual ?? this.markerVisual,
      markerAggregation: markerAggregation ?? this.markerAggregation,
      stateLabelMode: stateLabelMode ?? this.stateLabelMode,
      showDataQualityNotice:
          showDataQualityNotice ?? this.showDataQualityNotice,
      autoFocusSelectedStore:
          autoFocusSelectedStore ?? this.autoFocusSelectedStore,
      selectedStoreZoomLevel:
          selectedStoreZoomLevel ?? this.selectedStoreZoomLevel,
      clusterCoordinatePrecision:
          clusterCoordinatePrecision ?? this.clusterCoordinatePrecision,
      maxClusterTooltipStores:
          maxClusterTooltipStores ?? this.maxClusterTooltipStores,
      markerMinSize: markerMinSize ?? this.markerMinSize,
      markerMaxSize: markerMaxSize ?? this.markerMaxSize,
      lowValueColor: lowValueColor ?? this.lowValueColor,
      highValueColor: highValueColor ?? this.highValueColor,
      markerColor: markerColor ?? this.markerColor,
      markerStrokeColor: markerStrokeColor ?? this.markerStrokeColor,
      selectedMarkerColor: selectedMarkerColor ?? this.selectedMarkerColor,
      selectedMarkerStrokeColor:
          selectedMarkerStrokeColor ?? this.selectedMarkerStrokeColor,
      legendNumberFormat: legendNumberFormat ?? this.legendNumberFormat,
      emptyStateMessage: emptyStateMessage ?? this.emptyStateMessage,
    );
  }
}

@immutable
class AppBrazilStoreSalesMapDiagnostics {
  const AppBrazilStoreSalesMapDiagnostics({
    required this.totalPointCount,
    required this.validPointCount,
    required this.invalidCoordinateCount,
    required this.unknownUfCount,
    required this.filteredByRegionCount,
  });

  final int totalPointCount;
  final int validPointCount;
  final int invalidCoordinateCount;
  final int unknownUfCount;
  final int filteredByRegionCount;

  int get discardedPointCount =>
      invalidCoordinateCount + unknownUfCount + filteredByRegionCount;

  bool get hasDiscardedPoints => discardedPointCount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppBrazilStoreSalesMapDiagnostics &&
        totalPointCount == other.totalPointCount &&
        validPointCount == other.validPointCount &&
        invalidCoordinateCount == other.invalidCoordinateCount &&
        unknownUfCount == other.unknownUfCount &&
        filteredByRegionCount == other.filteredByRegionCount;
  }

  @override
  int get hashCode => Object.hash(
    totalPointCount,
    validPointCount,
    invalidCoordinateCount,
    unknownUfCount,
    filteredByRegionCount,
  );
}

class AppBrazilStoreSalesStateBubble {
  const AppBrazilStoreSalesStateBubble({
    required this.bucket,
  });

  final AppBrazilStoreSalesStateBucket bucket;
}

class AppBrazilStoreSalesPointTapEvent {
  const AppBrazilStoreSalesPointTapEvent({
    required this.point,
    required this.index,
    required this.metric,
  });

  final AppBrazilStoreSalesPoint point;
  final int index;
  final AppBrazilStoreSalesMapMetric metric;
}

class AppBrazilStoreSalesPointClusterTapEvent {
  const AppBrazilStoreSalesPointClusterTapEvent({
    required this.points,
    required this.index,
    required this.metric,
    required this.latitude,
    required this.longitude,
    required this.salesAmount,
    required this.salesCount,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final int index;
  final AppBrazilStoreSalesMapMetric metric;
  final double latitude;
  final double longitude;
  final double salesAmount;
  final int salesCount;
}
