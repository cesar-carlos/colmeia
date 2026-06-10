import 'dart:async';

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_selection_policy.dart';
import 'package:flutter/material.dart';

/// Publishes marker highlight state and manages desktop branch preview lifecycle.
class BrazilMapMarkerSelectionController {
  BrazilMapMarkerSelectionController();

  final ValueNotifier<BrazilMapMarkerSelection> notifier =
      ValueNotifier<BrazilMapMarkerSelection>(const BrazilMapMarkerSelection());

  String? previewedStoreId;
  bool selectedDetailIsClusterOrMunicipality = false;
  Timer? _previewClearTimer;

  static const Duration desktopPreviewClearDelay = Duration(milliseconds: 200);

  void dispose() {
    _previewClearTimer?.cancel();
    notifier.dispose();
  }

  void publishWithControlledId(
    BrazilMapSelectionPolicy selection,
    String? controlledSelectedStoreId,
  ) {
    notifier.value = BrazilMapMarkerSelection(
      selectedStoreId: selection.resolveSelectedStoreId(
        controlledSelectedStoreId,
      ),
      previewedStoreId: previewedStoreId,
      shapeHighlightRegionKey: selection.internalSelectedStateKey,
    );
  }

  void cancelPendingPreviewClear() {
    _previewClearTimer?.cancel();
    _previewClearTimer = null;
  }

  void setPreviewedPoint({
    required BuildContext context,
    required AppBrazilStoreSalesPoint point,
    required BrazilMapSelectionPolicy selection,
    required String? controlledSelectedStoreId,
    required bool Function(String? pointId) pointMatchesActiveRegion,
    required VoidCallback onChanged,
  }) {
    cancelPendingPreviewClear();
    if (!AppBreakpoints.isDesktop(context) ||
        !pointMatchesActiveRegion(point.id) ||
        previewedStoreId == point.id) {
      return;
    }
    previewedStoreId = point.id;
    publishWithControlledId(selection, controlledSelectedStoreId);
    onChanged();
  }

  void clearPreviewedPoint({
    required BrazilMapSelectionPolicy selection,
    required String? controlledSelectedStoreId,
    required VoidCallback onChanged,
  }) {
    if (previewedStoreId == null) {
      return;
    }
    cancelPendingPreviewClear();
    _previewClearTimer = Timer(desktopPreviewClearDelay, () {
      if (previewedStoreId == null) {
        return;
      }
      previewedStoreId = null;
      publishWithControlledId(selection, controlledSelectedStoreId);
      onChanged();
    });
  }

  void previewBranchForTesting(AppBrazilStoreSalesPoint point) {
    cancelPendingPreviewClear();
    previewedStoreId = point.id;
  }

  void clearPreviewBranchForTesting() {
    cancelPendingPreviewClear();
    previewedStoreId = null;
  }

  static AppBrazilStoreSalesStateBucket? resolveSelectedStateBucket(
    BrazilMapChartVisualSnapshot snapshot,
    BrazilMapMarkerSelection selection,
  ) {
    final stateKey =
        selection.shapeHighlightRegionKey ?? snapshot.selectedStateKey;
    if (stateKey == null) {
      return null;
    }

    for (final bucket in snapshot.buckets) {
      if (bucket.uf == stateKey) {
        return bucket;
      }
    }

    return null;
  }

  static ({
    AppBrazilStoreSalesPoint? point,
    AppBrazilStoreSalesMarkerGroup? group,
  })
  resolveMarkerDetailSelection(
    BrazilMapChartVisualSnapshot snapshot,
    BrazilMapMarkerSelection selection,
    AppBrazilStoreSalesPoint? Function(String id) pointById,
  ) {
    final selectedStoreId = selection.selectedStoreId;
    var point = snapshot.selectedPoint;
    var group = snapshot.selectedMarkerGroup;
    if (selectedStoreId == null) {
      return (point: null, group: null);
    }

    point ??= pointById(selectedStoreId);
    if (group == null) {
      for (final candidate in snapshot.data.markerGroups) {
        if (candidate.points.any((branch) => branch.id == selectedStoreId)) {
          group = candidate;
          break;
        }
      }
      if (group == null && point != null) {
        group = AppBrazilStoreSalesMarkerGroup(
          points: <AppBrazilStoreSalesPoint>[point],
        );
      }
    }

    return (point: point, group: group);
  }
}
