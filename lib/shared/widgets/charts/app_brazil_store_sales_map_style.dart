import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_enums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension AppBrazilStoreSalesMapPresetX on AppBrazilStoreSalesMapPreset {
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

@immutable
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
    this.selectedMarkerDetailPlacement =
        AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay,
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
    this.emptyStateMessage = defaultEmptyStateMessage,
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

  static const String defaultEmptyStateMessage =
      'Sem lojas para exibir no mapa.';
  static const Object _unset = Object();

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
  final AppBrazilStoreSalesSelectedMarkerDetailPlacement
  selectedMarkerDetailPlacement;
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
    AppBrazilStoreSalesSelectedMarkerDetailPlacement?
    selectedMarkerDetailPlacement,
    AppBrazilStoreSalesStateLabelMode? stateLabelMode,
    bool? showDataQualityNotice,
    bool? autoFocusSelectedStore,
    double? selectedStoreZoomLevel,
    int? clusterCoordinatePrecision,
    int? maxClusterTooltipStores,
    double? markerMinSize,
    double? markerMaxSize,
    Object? lowValueColor = _unset,
    Object? highValueColor = _unset,
    Object? markerColor = _unset,
    Object? markerStrokeColor = _unset,
    Object? selectedMarkerColor = _unset,
    Object? selectedMarkerStrokeColor = _unset,
    Object? legendNumberFormat = _unset,
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
      selectedMarkerDetailPlacement:
          selectedMarkerDetailPlacement ?? this.selectedMarkerDetailPlacement,
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
      lowValueColor: identical(lowValueColor, _unset)
          ? this.lowValueColor
          : lowValueColor as Color?,
      highValueColor: identical(highValueColor, _unset)
          ? this.highValueColor
          : highValueColor as Color?,
      markerColor: identical(markerColor, _unset)
          ? this.markerColor
          : markerColor as Color?,
      markerStrokeColor: identical(markerStrokeColor, _unset)
          ? this.markerStrokeColor
          : markerStrokeColor as Color?,
      selectedMarkerColor: identical(selectedMarkerColor, _unset)
          ? this.selectedMarkerColor
          : selectedMarkerColor as Color?,
      selectedMarkerStrokeColor: identical(selectedMarkerStrokeColor, _unset)
          ? this.selectedMarkerStrokeColor
          : selectedMarkerStrokeColor as Color?,
      legendNumberFormat: identical(legendNumberFormat, _unset)
          ? this.legendNumberFormat
          : legendNumberFormat as NumberFormat?,
      emptyStateMessage: emptyStateMessage ?? this.emptyStateMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppBrazilStoreSalesMapStyle &&
        height == other.height &&
        includeEmptyStates == other.includeEmptyStates &&
        showLegend == other.showLegend &&
        showTooltip == other.showTooltip &&
        enableZoomPan == other.enableZoomPan &&
        showDataLabels == other.showDataLabels &&
        showMetricSelector == other.showMetricSelector &&
        showRegionFilter == other.showRegionFilter &&
        showMarkerScaleLegend == other.showMarkerScaleLegend &&
        showStoreDetail == other.showStoreDetail &&
        highlightSelectedState == other.highlightSelectedState &&
        collapseSameCoordinateMarkers == other.collapseSameCoordinateMarkers &&
        enableProximityCluster == other.enableProximityCluster &&
        proximityClusterDistanceDegrees ==
            other.proximityClusterDistanceDegrees &&
        markerVisual == other.markerVisual &&
        markerAggregation == other.markerAggregation &&
        selectedMarkerDetailPlacement == other.selectedMarkerDetailPlacement &&
        stateLabelMode == other.stateLabelMode &&
        showDataQualityNotice == other.showDataQualityNotice &&
        autoFocusSelectedStore == other.autoFocusSelectedStore &&
        selectedStoreZoomLevel == other.selectedStoreZoomLevel &&
        clusterCoordinatePrecision == other.clusterCoordinatePrecision &&
        maxClusterTooltipStores == other.maxClusterTooltipStores &&
        markerMinSize == other.markerMinSize &&
        markerMaxSize == other.markerMaxSize &&
        lowValueColor == other.lowValueColor &&
        highValueColor == other.highValueColor &&
        markerColor == other.markerColor &&
        markerStrokeColor == other.markerStrokeColor &&
        selectedMarkerColor == other.selectedMarkerColor &&
        selectedMarkerStrokeColor == other.selectedMarkerStrokeColor &&
        legendNumberFormat == other.legendNumberFormat &&
        emptyStateMessage == other.emptyStateMessage;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    height,
    includeEmptyStates,
    showLegend,
    showTooltip,
    enableZoomPan,
    showDataLabels,
    showMetricSelector,
    showRegionFilter,
    showMarkerScaleLegend,
    showStoreDetail,
    highlightSelectedState,
    collapseSameCoordinateMarkers,
    enableProximityCluster,
    proximityClusterDistanceDegrees,
    markerVisual,
    markerAggregation,
    selectedMarkerDetailPlacement,
    stateLabelMode,
    showDataQualityNotice,
    autoFocusSelectedStore,
    selectedStoreZoomLevel,
    clusterCoordinatePrecision,
    maxClusterTooltipStores,
    markerMinSize,
    markerMaxSize,
    lowValueColor,
    highValueColor,
    markerColor,
    markerStrokeColor,
    selectedMarkerColor,
    selectedMarkerStrokeColor,
    legendNumberFormat,
    emptyStateMessage,
  ]);
}
