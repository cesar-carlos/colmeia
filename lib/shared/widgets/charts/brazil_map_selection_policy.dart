import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

typedef BrazilMapPointLookup = AppBrazilStoreSalesPoint? Function(String id);

/// Marker/region highlight state that can update without rebuilding the map tile.
class BrazilMapMarkerSelection {
  const BrazilMapMarkerSelection({
    this.selectedStoreId,
    this.previewedStoreId,
    this.shapeHighlightRegionKey,
  });

  final String? selectedStoreId;
  final String? previewedStoreId;

  /// UF highlight for the shape layer; only changes on explicit region taps
  /// when store selection does not link region highlight.
  final String? shapeHighlightRegionKey;

  BrazilMapMarkerSelection copyWith({
    String? selectedStoreId,
    String? previewedStoreId,
    String? shapeHighlightRegionKey,
    bool clearSelectedStoreId = false,
    bool clearPreviewedStoreId = false,
    bool clearShapeHighlightRegionKey = false,
  }) {
    return BrazilMapMarkerSelection(
      selectedStoreId: clearSelectedStoreId
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      previewedStoreId: clearPreviewedStoreId
          ? null
          : (previewedStoreId ?? this.previewedStoreId),
      shapeHighlightRegionKey: clearShapeHighlightRegionKey
          ? null
          : (shapeHighlightRegionKey ?? this.shapeHighlightRegionKey),
    );
  }
}

/// Centralizes marker, cluster and region selection for the Brazil store-sales map.
class BrazilMapSelectionPolicy {
  String? internalSelectedStoreId;
  String? dismissedControlledSelectedStoreId;
  String? internalSelectedStateKey;
  bool focusCameraOnSelectedStore = false;

  String? resolveSelectedStoreId(String? controlledSelectedStoreId) {
    if (controlledSelectedStoreId != null &&
        controlledSelectedStoreId != dismissedControlledSelectedStoreId) {
      return controlledSelectedStoreId;
    }
    return internalSelectedStoreId;
  }

  bool blocksViewportDrivenClustering(String? controlledSelectedStoreId) =>
      resolveSelectedStoreId(controlledSelectedStoreId) != null;

  bool shouldFocusCameraOnSelectedStore({
    required String? controlledSelectedStoreId,
    required bool autoFocusSelectedStore,
  }) =>
      autoFocusSelectedStore &&
      focusCameraOnSelectedStore &&
      resolveSelectedStoreId(controlledSelectedStoreId) != null;

  /// Returns true when a region tap would only repeat the active UF highlight
  /// while a store is already selected (common during programmatic camera focus).
  bool shouldSkipRedundantRegionTap({
    required String regionKey,
    required bool preserveStoreSelection,
    required String? controlledSelectedStoreId,
  }) {
    if (!preserveStoreSelection ||
        resolveSelectedStoreId(controlledSelectedStoreId) == null) {
      return false;
    }

    final normalizedRegion =
        AppBrazilStoreSalesMapData.normalizeUf(regionKey);
    return internalSelectedStateKey == normalizedRegion;
  }

  bool shouldPreserveStoreSelectionForRegionTap({
    required String regionKey,
    required String? controlledSelectedStoreId,
    required BrazilMapPointLookup pointById,
  }) {
    final selectedStoreId = resolveSelectedStoreId(controlledSelectedStoreId);
    if (selectedStoreId == null) {
      return false;
    }

    final selectedPoint = pointById(selectedStoreId);
    if (selectedPoint == null) {
      return false;
    }

    return AppBrazilStoreSalesMapData.normalizeUf(selectedPoint.uf) ==
        AppBrazilStoreSalesMapData.normalizeUf(regionKey);
  }

  void applyStoreSelection(
    AppBrazilStoreSalesPoint point, {
    required bool focusStore,
    bool linkRegionHighlight = true,
  }) {
    internalSelectedStoreId = point.id;
    dismissedControlledSelectedStoreId = null;
    if (linkRegionHighlight) {
      internalSelectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(point.uf);
    }
    focusCameraOnSelectedStore = focusStore;
  }

  void applyRegionTap({
    required String regionKey,
    required bool preserveStoreSelection,
  }) {
    if (!preserveStoreSelection) {
      internalSelectedStoreId = null;
      focusCameraOnSelectedStore = false;
    }
    internalSelectedStateKey = regionKey;
  }

  void clearStoreSelection({String? controlledSelectedStoreId}) {
    if (controlledSelectedStoreId != null) {
      dismissedControlledSelectedStoreId = controlledSelectedStoreId;
    }
    internalSelectedStoreId = null;
    focusCameraOnSelectedStore = false;
  }

  void clearStoreAndStateSelection() {
    internalSelectedStoreId = null;
    focusCameraOnSelectedStore = false;
    internalSelectedStateKey = null;
  }

  void syncControlledSelection({
    required String? previousControlledId,
    required String? nextControlledId,
    required double selectedStoreZoomLevel,
    required void Function() onAdoptControlledSelection,
    required void Function() onReleaseControlledSelection,
  }) {
    if (previousControlledId != null && nextControlledId == null) {
      dismissedControlledSelectedStoreId = null;
      focusCameraOnSelectedStore = false;
      onReleaseControlledSelection();
    }
    if (previousControlledId != nextControlledId && nextControlledId != null) {
      focusCameraOnSelectedStore = true;
      dismissedControlledSelectedStoreId = null;
      onAdoptControlledSelection();
    }
  }

  void adoptControlledSelectionOnInit() {
    focusCameraOnSelectedStore = true;
  }

  /// Clears the one-shot camera focus flag after the preferred viewport was
  /// applied so later rebuilds do not keep driving Syncfusion pan/zoom.
  void consumeCameraFocus() {
    focusCameraOnSelectedStore = false;
  }

  bool storeMatchesActiveRegion({
    required String? storeId,
    required String? activeRegionKey,
    required BrazilMapPointLookup pointById,
  }) {
    final point = pointById(storeId ?? '');
    if (point == null) {
      return false;
    }
    return AppBrazilStoreSalesMapData.pointMatchesRegion(point, activeRegionKey);
  }

  void clearStoreIfOutsideActiveRegion({
    required String? activeRegionKey,
    required String? controlledSelectedStoreId,
    required BrazilMapPointLookup pointById,
  }) {
    final selectedStoreId = resolveSelectedStoreId(controlledSelectedStoreId);
    final selectedPoint = pointById(selectedStoreId ?? '');
    if (selectedPoint != null &&
        !AppBrazilStoreSalesMapData.pointMatchesRegion(
          selectedPoint,
          activeRegionKey,
        )) {
      internalSelectedStoreId = null;
      internalSelectedStateKey = null;
    }
  }
}
