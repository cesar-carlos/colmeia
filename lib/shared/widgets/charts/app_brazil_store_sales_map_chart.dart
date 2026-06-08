import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_selection_policy.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_zoom_controller.dart';
import 'package:colmeia/shared/widgets/charts/region_map_viewport_sync_policy.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

part 'app_brazil_store_sales_map_chart_auxiliary.dart';
part 'app_brazil_store_sales_map_chart_details.dart';
part 'app_brazil_store_sales_map_chart_overlay.dart';
part 'app_brazil_store_sales_map_chart_sidebar.dart';

String _formatSalesCount(BuildContext context, num value) {
  final locale = Localizations.localeOf(context);
  return NumberFormat('#,##0', locale.toLanguageTag()).format(value.round());
}

class AppBrazilStoreSalesMapChart extends StatefulWidget {
  const AppBrazilStoreSalesMapChart({
    required this.points,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.initialMetric = AppBrazilStoreSalesMapMetric.revenue,
    this.selectedStoreId,
    this.filterBranchIds = const <String>{},
    this.fixedBranchIds = const <String>{},
    this.style = const AppBrazilStoreSalesMapStyle(),
    this.isRefreshing = false,
    this.onStoreTap,
    this.onStoreClusterTap,
    this.onMunicipalityTap,
    this.onStateTap,
    this.onMetricChanged,
    this.onDiagnosticsChanged,
    this.onShare,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.showDesktopBranchSidebar = false,
    this.presentationMode = AppBrazilStoreSalesMapPresentationMode.standard,
    this.useCleanFullscreenChrome = false,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppBrazilStoreSalesMapMetric initialMetric;

  /// Optional externally controlled selection (e.g. deep-link); when set and
  /// not dismissed, overrides internal marker selection.
  final String? selectedStoreId;

  /// Branch ids selected outside the map (e.g. sheet filter).
  final Set<String> filterBranchIds;

  /// Union of external highlights (e.g. filter); drives reuse keys and cleanup.
  final Set<String> fixedBranchIds;
  final AppBrazilStoreSalesMapStyle style;
  final bool isRefreshing;
  final ValueChanged<AppBrazilStoreSalesPointTapEvent>? onStoreTap;
  final ValueChanged<AppBrazilStoreSalesPointClusterTapEvent>?
  onStoreClusterTap;
  final ValueChanged<AppBrazilStoreSalesMunicipalityTapEvent>?
  onMunicipalityTap;
  final ValueChanged<AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>>?
  onStateTap;
  final ValueChanged<AppBrazilStoreSalesMapMetric>? onMetricChanged;
  final ValueChanged<AppBrazilStoreSalesMapDiagnostics>? onDiagnosticsChanged;
  final VoidCallback? onShare;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final bool showDesktopBranchSidebar;
  final AppBrazilStoreSalesMapPresentationMode presentationMode;
  final bool useCleanFullscreenChrome;

  @override
  State<AppBrazilStoreSalesMapChart> createState() =>
      _AppBrazilStoreSalesMapChartState();
}

/// Pure geometry policy for the optional desktop branch sidebar overlaid on
/// the Brazil store-sales map. Extracted from the chart state so the sizing
/// rules live in one focused, testable place.
@visibleForTesting
abstract final class BrazilMapDesktopSidebarLayout {
  static const double minWidth = 272;
  static const double maxWidth = 336;
  static const double minVisibleMapWidth = 760;
  static const double topInsetBase = 12;

  /// Sidebar width: 24% of the available width, clamped to [minWidth]..[maxWidth].
  static double width(double availableWidth) {
    if (!availableWidth.isFinite) {
      return minWidth;
    }
    return (availableWidth * 0.24).clamp(minWidth, maxWidth);
  }

  /// Whether the sidebar fits without squeezing the visible map below
  /// [minVisibleMapWidth] (and only on desktop-class widths).
  static bool shouldShow({
    required bool enabled,
    required double availableWidth,
    required double sidebarWidth,
    required double horizontalInset,
  }) {
    if (!enabled) {
      return false;
    }
    if (!availableWidth.isFinite || availableWidth < AppBreakpoints.desktop) {
      return false;
    }
    final remainingVisibleMapWidth =
        availableWidth - sidebarWidth - (horizontalInset * 2);
    return remainingVisibleMapWidth >= minVisibleMapWidth;
  }

  static double maxHeight({
    required double mapTileHeight,
    required double topInset,
  }) {
    const bottomInset = BrazilMapLayoutConstants.desktopSidebarBottomInset;
    final availableHeight = mapTileHeight - topInset - bottomInset;
    if (availableHeight <= 0) {
      return 0;
    }
    final proportionalCap =
        mapTileHeight *
        BrazilMapLayoutConstants.desktopSidebarProportionalCapFactor;
    final cappedHeight = availableHeight < proportionalCap
        ? availableHeight
        : proportionalCap;
    final lower = math.min(
      BrazilMapLayoutConstants.desktopSidebarMinHeight,
      availableHeight,
    );
    return cappedHeight.clamp(lower, availableHeight);
  }
}

/// Presentation-mode derived flags for the Brazil store-sales map, computed
/// purely from widget configuration (no [BuildContext]). Context-dependent
/// decisions (e.g. compact branch sheet on mobile) stay on the chart state.
@immutable
class _BrazilMapChrome {
  const _BrazilMapChrome({
    required this.usesInlineOperationalChrome,
    required this.usesCleanFullscreenChrome,
    required this.includeVisibleBranchListItems,
    required this.showsFloatingMetricSelector,
    required this.showsFloatingScopeSelector,
    required this.effectiveShowLegend,
    required this.effectiveShowMarkerScaleLegend,
    required this.effectiveShowDataQualityNotice,
    required this.useWindowsSafeMarkerDetails,
    required this.showBelowMapMarkerDetail,
  });

  factory _BrazilMapChrome.fromWidget(AppBrazilStoreSalesMapChart widget) {
    final style = widget.style;
    final usesInline =
        widget.presentationMode ==
        AppBrazilStoreSalesMapPresentationMode.inlineOperational;
    final usesClean =
        widget.presentationMode ==
            AppBrazilStoreSalesMapPresentationMode.cleanFullscreen ||
        widget.useCleanFullscreenChrome;
    final usesFloating = usesInline || usesClean;
    return _BrazilMapChrome(
      usesInlineOperationalChrome: usesInline,
      usesCleanFullscreenChrome: usesClean,
      includeVisibleBranchListItems: widget.showDesktopBranchSidebar,
      showsFloatingMetricSelector:
          usesFloating &&
          style.showMetricSelector &&
          AppBrazilStoreSalesMapMetric.values.length > 1,
      showsFloatingScopeSelector: usesFloating && style.showRegionFilter,
      effectiveShowLegend: style.showLegend && !usesClean && !usesInline,
      effectiveShowMarkerScaleLegend:
          style.showMarkerScaleLegend && !usesInline,
      effectiveShowDataQualityNotice: style.showDataQualityNotice,
      useWindowsSafeMarkerDetails:
          defaultTargetPlatform == TargetPlatform.windows,
      showBelowMapMarkerDetail:
          style.showStoreDetail &&
          (style.selectedMarkerDetailPlacement ==
                  AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap ||
              (defaultTargetPlatform == TargetPlatform.windows &&
                  style.selectedMarkerDetailPlacement ==
                      AppBrazilStoreSalesSelectedMarkerDetailPlacement
                          .overlay)),
    );
  }

  final bool usesInlineOperationalChrome;
  final bool usesCleanFullscreenChrome;
  final bool includeVisibleBranchListItems;
  final bool showsFloatingMetricSelector;
  final bool showsFloatingScopeSelector;
  final bool effectiveShowLegend;
  final bool effectiveShowMarkerScaleLegend;
  final bool effectiveShowDataQualityNotice;
  final bool useWindowsSafeMarkerDetails;
  final bool showBelowMapMarkerDetail;

  bool get usesFloatingMapControls =>
      usesInlineOperationalChrome || usesCleanFullscreenChrome;
}

/// Pure(ish) layout geometry for the Brazil store-sales map tile: resolves the
/// map height by deducting header/footer reserves from the available space.
/// Extracted from the chart state so the (intricate) sizing math lives in one
/// focused place; methods take [BuildContext] only to read theme/text scaling.
class _BrazilMapLayoutCalculator {
  const _BrazilMapLayoutCalculator({required this.chrome, required this.style});

  final _BrazilMapChrome chrome;
  final AppBrazilStoreSalesMapStyle style;

  /// When the parent supplies a finite max height, the map column uses [Expanded]
  /// and below-map selection detail uses its intrinsic height. Fixed footer
  /// reserves for those details would leave empty space under the detail bar.
  @visibleForTesting
  static bool usesBoundedVerticalLayout(BoxConstraints constraints) {
    final maxHeight = constraints.maxHeight;
    return maxHeight.isFinite && maxHeight < double.infinity;
  }

  /// Small shrink of the map tile when height is bounded: real layout (labels,
  /// chips, legend padding) can exceed our header/footer estimates by a few
  /// logical pixels and cause a [Column] overflow.
  static const double _boundedSafetyPx =
      BrazilMapLayoutConstants.boundedLayoutSafetyPx;
  static const double _cleanFullscreenExtraSafetyPx =
      BrazilMapLayoutConstants.cleanFullscreenExtraSafetyPx;
  static const double _inlineOperationalExtraMapHeight =
      BrazilMapLayoutConstants.inlineOperationalExtraMapHeight;

  double mapTileHeight({
    required BuildContext context,
    required BoxConstraints constraints,
    required _BrazilStoreSalesMapSnapshot snapshot,
    required bool usesCompactMapChrome,
    AppBrazilStoreSalesPoint? detailPoint,
    AppBrazilStoreSalesMarkerGroup? detailGroup,
    bool reserveBelowMapSelectionDetail = true,
  }) {
    final requested = _effectiveRequestedHeight(style.height);
    final maxParent = constraints.maxHeight;
    if (!maxParent.isFinite || maxParent >= double.infinity) {
      return requested;
    }

    return regionMapStyleHeightForMapArea(
      context: context,
      mapAreaHeight: mapAreaHeight(
        context: context,
        constraints: constraints,
        snapshot: snapshot,
        usesCompactMapChrome: usesCompactMapChrome,
        detailPoint: detailPoint,
        detailGroup: detailGroup,
        reserveBelowMapSelectionDetail: reserveBelowMapSelectionDetail,
      ),
    );
  }

  /// Syncfusion map tile height for a fixed vertical area that may also contain
  /// in-chart metric/scope controls above the tile.
  double regionMapStyleHeightForMapArea({
    required BuildContext context,
    required double mapAreaHeight,
  }) {
    final headerReserve = _headerReserve(context);
    return (mapAreaHeight - headerReserve).clamp(
      BrazilMapLayoutConstants.regionMapMinHeight,
      BrazilMapLayoutConstants.regionMapMaxHeight,
    );
  }

  /// Vertical space for the full [AppRegionMapChart] column (controls + tile).
  double mapAreaHeight({
    required BuildContext context,
    required BoxConstraints constraints,
    required _BrazilStoreSalesMapSnapshot snapshot,
    required bool usesCompactMapChrome,
    AppBrazilStoreSalesPoint? detailPoint,
    AppBrazilStoreSalesMarkerGroup? detailGroup,
    AppBrazilStoreSalesStateBucket? detailStateBucket,
    bool reserveBelowMapSelectionDetail = true,
  }) {
    final maxParent = constraints.maxHeight;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final footerReserve = _footerReserve(
      context: context,
      snapshot: snapshot,
      tokens: tokens,
      maxWidth: constraints.maxWidth,
      usesCompactMapChrome: usesCompactMapChrome,
      detailPoint: detailPoint,
      detailGroup: detailGroup,
      detailStateBucket: detailStateBucket,
      reserveBelowMapSelectionDetail: reserveBelowMapSelectionDetail,
    );
    final spare = maxParent - footerReserve;
    if (!spare.isFinite) {
      return _effectiveRequestedHeight(style.height);
    }
    final safetyPx =
        _boundedSafetyPx +
        (chrome.usesCleanFullscreenChrome ? _cleanFullscreenExtraSafetyPx : 0);
    return (spare - safetyPx).clamp(
      BrazilMapLayoutConstants.regionMapMinHeight,
      BrazilMapLayoutConstants.regionMapMaxHeight,
    );
  }

  double _effectiveRequestedHeight(double requestedHeight) {
    if (chrome.usesInlineOperationalChrome) {
      return requestedHeight + _inlineOperationalExtraMapHeight;
    }
    return requestedHeight;
  }

  double _headerReserve(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final scaler = MediaQuery.textScalerOf(context);
    final textTheme = Theme.of(context).textTheme;
    final overlineBlock = chrome.usesCleanFullscreenChrome
        ? scaler.scale((textTheme.bodySmall?.fontSize ?? 12) * 1.25 + 6)
        : scaler.scale((textTheme.labelSmall?.fontSize ?? 11) * 1.3) +
              tokens.gapXs +
              scaler.scale((textTheme.bodySmall?.fontSize ?? 12) * 1.35 + 8);
    var reserve = 0.0;
    if (!chrome.showsFloatingMetricSelector &&
        style.showMetricSelector &&
        AppBrazilStoreSalesMapMetric.values.length > 1) {
      reserve +=
          overlineBlock +
          (chrome.usesCleanFullscreenChrome ? tokens.gapXs : tokens.gapMd);
    }
    if (!chrome.showsFloatingScopeSelector && style.showRegionFilter) {
      reserve +=
          overlineBlock +
          (chrome.usesCleanFullscreenChrome ? tokens.gapXs : tokens.gapMd);
    }
    return reserve.clamp(0.0, BrazilMapLayoutConstants.headerReserveMax);
  }

  double _footerReserve({
    required BuildContext context,
    required _BrazilStoreSalesMapSnapshot snapshot,
    required AppThemeTokens tokens,
    required double maxWidth,
    required bool usesCompactMapChrome,
    AppBrazilStoreSalesPoint? detailPoint,
    AppBrazilStoreSalesMarkerGroup? detailGroup,
    AppBrazilStoreSalesStateBucket? detailStateBucket,
    bool reserveBelowMapSelectionDetail = true,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    var reserve = 0.0;
    if (style.showDataQualityNotice &&
        snapshot.diagnostics.hasDiscardedPoints) {
      reserve +=
          tokens.gapSm +
          scaler.scale(BrazilMapLayoutConstants.dataQualityNoticeReserve);
    }
    if (chrome.effectiveShowMarkerScaleLegend && snapshot.hasMarkers) {
      final compactLegend = shouldUseCompactMarkerLegend(
        usesCompactMapChrome: usesCompactMapChrome,
        maxWidth: maxWidth,
      );
      reserve +=
          tokens.gapMd +
          scaler.scale(
            compactLegend
                ? BrazilMapLayoutConstants.markerLegendCompactReserve
                : BrazilMapLayoutConstants.markerLegendStandardReserve,
          );
    }
    if (reserveBelowMapSelectionDetail) {
      final selectedMarkerGroup = detailGroup ?? snapshot.selectedMarkerGroup;
      final selectedPoint = detailPoint ?? snapshot.selectedPoint;
      if (chrome.showBelowMapMarkerDetail &&
          selectedMarkerGroup != null &&
          (selectedMarkerGroup.isMunicipalityAggregate ||
              selectedMarkerGroup.isCluster)) {
        reserve +=
            tokens.gapMd +
            scaler.scale(BrazilMapLayoutConstants.belowMapClusterDetailReserve);
      } else if (chrome.showBelowMapMarkerDetail && selectedPoint != null) {
        reserve +=
            tokens.gapMd +
            scaler.scale(
              BrazilMapLayoutConstants.belowMapSingleStoreDetailReserve,
            );
      }
      if (selectedPoint == null &&
          selectedMarkerGroup == null &&
          detailStateBucket != null) {
        reserve +=
            tokens.gapMd +
            scaler.scale(BrazilMapLayoutConstants.belowMapStateDetailReserve);
      }
    }
    return reserve;
  }

  bool shouldUseCompactMarkerLegend({
    required bool usesCompactMapChrome,
    required double maxWidth,
  }) {
    return usesCompactMapChrome ||
        (maxWidth.isFinite &&
            maxWidth < BrazilMapLayoutConstants.compactMarkerLegendMaxWidth);
  }

  double floatingMapControlsHeight(
    BuildContext context, {
    required bool cleanMode,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    var height = 0.0;
    if (chrome.showsFloatingMetricSelector) {
      height += scaler.scale(
        cleanMode
            ? BrazilMapLayoutConstants.floatingMetricSelectorHeightClean
            : BrazilMapLayoutConstants.floatingMetricSelectorHeightStandard,
      );
    }
    if (chrome.showsFloatingScopeSelector) {
      if (height > 0) {
        height += cleanMode
            ? BrazilMapLayoutConstants.floatingMapOverlayGap
            : BrazilMapLayoutConstants.floatingScopeSelectorGapStandard;
      }
      height += scaler.scale(
        cleanMode
            ? BrazilMapLayoutConstants.floatingScopeSelectorHeightClean
            : BrazilMapLayoutConstants.floatingScopeSelectorHeightStandard,
      );
    }
    return height;
  }
}

abstract interface class AppBrazilStoreSalesMapChartPreviewTestHandle {
  void previewBranchForTesting(AppBrazilStoreSalesPoint point);

  void clearPreviewBranchForTesting();

  Object? get snapshotDataIdentityForTesting;

  Object? get snapshotMapPointsIdentityForTesting;

  String? get previewedStoreIdForTesting;

  bool get suppressPreferredViewportForTesting;
}

class _AppBrazilStoreSalesMapChartState
    extends State<AppBrazilStoreSalesMapChart>
    implements AppBrazilStoreSalesMapChartPreviewTestHandle {
  late AppBrazilStoreSalesMapMetric _selectedMetric;

  /// Presentation-mode derived flags (config-pure). Context-dependent flags
  /// such as [_shouldUseCompactBranchSheet] stay on the state.
  late _BrazilMapChrome _chrome;
  final BrazilMapSelectionPolicy _selection = BrazilMapSelectionPolicy();
  final BrazilMapZoomController _zoom = BrazilMapZoomController();
  final RegionMapViewportController _viewportController =
      RegionMapViewportController();
  final ValueNotifier<BrazilMapMarkerSelection> _markerSelection =
      ValueNotifier<BrazilMapMarkerSelection>(const BrazilMapMarkerSelection());
  String? _previewedStoreId;
  String? _activeRegionKey;
  bool _desktopBranchSidebarCollapsed = false;
  bool _compactBranchSheetLayout = false;
  AppBrazilStoreSalesMapDiagnostics? _lastEmittedDiagnostics;
  AppBrazilStoreSalesMapSnapshotData? _snapshotData;
  _BrazilStoreSalesMapSnapshot? _snapshot;
  List<AppBrazilStoreSalesPoint>? _cachedPointsDigestSource;
  int? _cachedPointsDigest;
  Timer? _viewportClusterDebounceTimer;
  double? _pendingViewportClusterZoomLevel;
  Timer? _previewClearTimer;
  AppMapViewport? _cachedPreferredViewport;
  bool _userHasManualMapViewport = false;
  String? _cachedPreferredViewportBinding;

  void _cancelPendingViewportClusterSampling() {
    _viewportClusterDebounceTimer?.cancel();
    _viewportClusterDebounceTimer = null;
    _pendingViewportClusterZoomLevel = null;
  }

  void _cancelPendingPreviewClear() {
    _previewClearTimer?.cancel();
    _previewClearTimer = null;
  }

  void _scheduleConsumeCameraFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_selection.focusCameraOnSelectedStore) {
        return;
      }
      setState(_selection.consumeCameraFocus);
    });
  }

  void _invalidateResolvedSnapshotData() {
    _snapshotData = null;
    _snapshot = null;
  }

  void _invalidateResolvedSnapshotVisual() {
    _snapshot = null;
  }

  static const Duration _touchViewportClusterDebounceDuration = Duration(
    milliseconds: 180,
  );
  static const Duration _desktopViewportClusterDebounceDuration = Duration(
    milliseconds: 120,
  );
  static const Duration _windowsViewportClusterDebounceDuration = Duration(
    milliseconds: 500,
  );
  static const Duration _desktopBranchPreviewClearDelay = Duration(
    milliseconds: 200,
  );
  _BrazilMapLayoutCalculator get _layout =>
      _BrazilMapLayoutCalculator(chrome: _chrome, style: widget.style);

  void _publishMarkerSelection() {
    _markerSelection.value = BrazilMapMarkerSelection(
      selectedStoreId: _selectedStoreId,
      previewedStoreId: _previewedStoreId,
      shapeHighlightRegionKey: _selection.internalSelectedStateKey,
    );
  }

  bool get _suppressMapLayoutShiftOnStoreSelection =>
      !widget.style.autoFocusSelectedStore ||
      defaultTargetPlatform == TargetPlatform.windows;

  AppMapViewportChangedEvent? _filterViewportChangedEvent(
    AppMapViewportChangedEvent event,
  ) {
    if (defaultTargetPlatform == TargetPlatform.windows &&
        _selection.blocksViewportDrivenClustering(widget.selectedStoreId)) {
      return null;
    }
    return event;
  }

  void _handleRegionMapViewportChanged(AppMapViewportChangedEvent event) {
    final filtered = _filterViewportChangedEvent(event);
    if (filtered == null) {
      return;
    }
    _handleViewportChanged(filtered);
  }

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
    _chrome = _BrazilMapChrome.fromWidget(widget);
    _publishMarkerSelection();
    if (widget.selectedStoreId != null && widget.style.autoFocusSelectedStore) {
      _selection.adoptControlledSelectionOnInit();
      _zoom.clusteringZoomLevel = widget.style.selectedStoreZoomLevel;
      _scheduleConsumeCameraFocus();
    }
  }

  @override
  void didUpdateWidget(covariant AppBrazilStoreSalesMapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _chrome = _BrazilMapChrome.fromWidget(widget);
    if (oldWidget.initialMetric != widget.initialMetric) {
      _selectedMetric = widget.initialMetric;
      _invalidateResolvedSnapshotData();
    }

    if (oldWidget.selectedStoreId != widget.selectedStoreId ||
        oldWidget.style != widget.style) {
      if (widget.selectedStoreId == null) {
        _viewportController.reset();
      } else if (!widget.style.autoFocusSelectedStore) {
        _viewportController.withdrawPreferredViewportForStoreSelection();
      }
      _selection.syncControlledSelection(
        previousControlledId: oldWidget.selectedStoreId,
        nextControlledId: widget.selectedStoreId,
        selectedStoreZoomLevel: widget.style.selectedStoreZoomLevel,
        onAdoptControlledSelection: () {
          if (widget.style.autoFocusSelectedStore) {
            _zoom.clusteringZoomLevel = widget.style.selectedStoreZoomLevel;
          }
          _cancelPendingViewportClusterSampling();
        },
        onReleaseControlledSelection: () {
          if (oldWidget.style.autoFocusSelectedStore ||
              widget.style.autoFocusSelectedStore) {
            _zoom.resetToBrazilDefault();
          }
          _cancelPendingViewportClusterSampling();
        },
      );
      if (oldWidget.style != widget.style) {
        _invalidateResolvedSnapshotData();
      }
      if (widget.selectedStoreId != null &&
          widget.style.autoFocusSelectedStore &&
          _selection.focusCameraOnSelectedStore) {
        _scheduleConsumeCameraFocus();
      }
      _publishMarkerSelection();
    }

    if (oldWidget.filterBranchIds != widget.filterBranchIds ||
        oldWidget.fixedBranchIds != widget.fixedBranchIds) {
      _invalidateResolvedSnapshotData();
    }

    if (oldWidget.showDesktopBranchSidebar != widget.showDesktopBranchSidebar ||
        oldWidget.presentationMode != widget.presentationMode ||
        oldWidget.useCleanFullscreenChrome != widget.useCleanFullscreenChrome) {
      if (!widget.showDesktopBranchSidebar) {
        _desktopBranchSidebarCollapsed = false;
      }
      _invalidateResolvedSnapshotVisual();
    }

    if (!identical(oldWidget.points, widget.points)) {
      if (identical(_cachedPointsDigestSource, widget.points)) {
        _cachedPointsDigest = null;
      } else {
        _cachedPointsDigestSource = null;
      }
      _cachedPreferredViewport = null;
      final selectedStoreId = _selection.resolveSelectedStoreId(
        widget.selectedStoreId,
      );
      if (selectedStoreId != null && _pointById(selectedStoreId) == null) {
        _selection.clearStoreSelection(
          controlledSelectedStoreId: widget.selectedStoreId,
        );
        _previewedStoreId = null;
        if (widget.style.autoFocusSelectedStore) {
          _zoom.resetToBrazilDefault();
        }
        _cancelPendingViewportClusterSampling();
        _invalidateResolvedSnapshotData();
      }
    }

    final previewedStoreId = _previewedStoreId;
    if (previewedStoreId != null &&
        (_pointById(previewedStoreId) == null ||
            !_pointMatchesActiveRegion(previewedStoreId))) {
      _previewedStoreId = null;
    }
  }

  @override
  void dispose() {
    _cancelPendingViewportClusterSampling();
    _cancelPendingPreviewClear();
    _markerSelection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _resolveSnapshot(context);
    _emitDiagnosticsIfNeeded(snapshot.diagnostics);
    final markerSelection = _markerSelection.value;
    final markerDetail = _resolveMarkerDetailSelection(snapshot, markerSelection);
    final layoutSelectionPoint = _suppressMapLayoutShiftOnStoreSelection
        ? null
        : markerDetail.point;
    final layoutSelectionGroup = _suppressMapLayoutShiftOnStoreSelection
        ? null
        : markerDetail.group;
    final layoutSelectionStateBucket = _suppressMapLayoutShiftOnStoreSelection
        ? null
        : _resolveSelectedStateBucket(snapshot, markerSelection);
    final selectedRegionKey = widget.style.highlightSelectedState
        ? markerSelection.shapeHighlightRegionKey
        : null;
    final preferredViewport = _resolvePreferredViewportForBuild(snapshot);
    final resetViewport = _resetTargetViewportForScope();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Intentional layout-state capture: _compactBranchSheetLayout is read
        // from async event handlers (_handlePointTap) that run after the frame
        // completes, so it cannot be a local variable. The write happens during
        // the layout phase but never triggers a rebuild (no setState call).
        _compactBranchSheetLayout =
            widget.style.showStoreDetail &&
            constraints.maxWidth < AppBreakpoints.mobile;
        final l10n = AppLocalizations.of(context);
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final usesCompactMapChrome = constraints.hasBoundedHeight;
        final usesCompactStateLabels =
            usesCompactMapChrome &&
            constraints.maxWidth <
                BrazilMapLayoutConstants.compactStateLabelsMaxWidth;
        final stateDataLabelTextStyle = _stateDataLabelTextStyle(
          context,
          compact: usesCompactStateLabels,
          maxWidth: constraints.maxWidth,
        );
        final useCompactMarkerLegend = _layout.shouldUseCompactMarkerLegend(
          usesCompactMapChrome: usesCompactMapChrome,
          maxWidth: constraints.maxWidth,
        );
        final sidebarWidth = BrazilMapDesktopSidebarLayout.width(
          constraints.maxWidth,
        );
        final sidebarHorizontalInset = tokens.gapMd;
        final showsDesktopBranchSidebar =
            BrazilMapDesktopSidebarLayout.shouldShow(
              enabled: widget.showDesktopBranchSidebar,
              availableWidth: constraints.maxWidth,
              sidebarWidth: sidebarWidth,
              horizontalInset: sidebarHorizontalInset,
            );
        final sidebarTopInset = _resolvedDesktopBranchSidebarTopInset(
          context,
          tokens,
          cleanMode: _usesCleanFullscreenChrome,
        );
        final usesBoundedVerticalLayout =
            _BrazilMapLayoutCalculator.usesBoundedVerticalLayout(constraints);
        final reserveBelowMapSelectionDetail = !usesBoundedVerticalLayout;
        final mapAreaHeight = _layout.mapAreaHeight(
          context: context,
          constraints: constraints,
          snapshot: snapshot,
          usesCompactMapChrome: usesCompactMapChrome,
          detailPoint: layoutSelectionPoint,
          detailGroup: layoutSelectionGroup,
          detailStateBucket: layoutSelectionStateBucket,
          reserveBelowMapSelectionDetail: reserveBelowMapSelectionDetail &&
              !_suppressMapLayoutShiftOnStoreSelection,
        );
        final mapTileHeight = _layout.regionMapStyleHeightForMapArea(
          context: context,
          mapAreaHeight: mapAreaHeight,
        );
        final sidebarMapAreaHeight = usesBoundedVerticalLayout
            ? _layout.mapAreaHeight(
                context: context,
                constraints: constraints,
                snapshot: snapshot,
                usesCompactMapChrome: usesCompactMapChrome,
                detailPoint: layoutSelectionPoint,
                detailGroup: layoutSelectionGroup,
                detailStateBucket: layoutSelectionStateBucket,
                reserveBelowMapSelectionDetail: false,
              )
            : mapAreaHeight;
        Widget buildRegionMap(double height) {
          return RepaintBoundary(
            child: AppRegionMapChart<AppBrazilStoreSalesStateBucket>(
            mapDefinition: AppBrazilMapStaticData.brazilUfMapDefinition,
            items: snapshot.buckets,
            metrics: _buildMetrics(l10n),
            selectedMetricKey: _selectedMetric.key,
            selectedRegionKey: selectedRegionKey,
            regionKeyBuilder: (bucket) => bucket.uf,
            regionLabelBuilder: (bucket) => _stateLabelFor(
              bucket,
              compact: usesCompactStateLabels,
            ),
            scopeOptions: widget.style.showRegionFilter
                ? AppBrazilStoreSalesMapLocalizations.regionScopeOptions(l10n)
                : const <AppMapScopeOption>[],
            activeScopeKey: _activeRegionKey,
            preferredViewport: preferredViewport,
            resetViewport: resetViewport,
            onResetViewport: _handleResetViewport,
            points: snapshot.mapPoints,
            markerStyle: AppMapMarkerStyle(
              size: widget.style.markerMinSize,
              color: _markerColor(context),
              strokeColor: _markerStrokeColor(context),
            ),
            markerBuilder: (context, point, index) {
              return ValueListenableBuilder<BrazilMapMarkerSelection>(
                valueListenable: _markerSelection,
                builder: (context, selection, _) {
                  return _buildMarker(context, point, index, selection);
                },
              );
            },
            markerTooltipBuilder: _useWindowsSafeMarkerDetails
                ? null
                : _buildMarkerTooltip,
            onMetricChanged: _showsFloatingMetricSelector
                ? null
                : _handleMetricChanged,
            onScopeChanged: _showsFloatingScopeSelector
                ? null
                : widget.style.showRegionFilter
                ? _handleScopeChanged
                : null,
            onRegionTapEvent: _handleStateTap,
            onPointTap: _handlePointTap,
            onViewportChanged: _handleRegionMapViewportChanged,
            viewportController: _viewportController,
            preset: widget.style.enableZoomPan
                ? AppChartPreset.explorable
                : AppChartPreset.standard,
            style: AppRegionMapChartStyle(
              height: height,
              chartPadding: usesCompactMapChrome
                  ? EdgeInsets.all(tokens.gapSm)
                  : null,
              showLegend: _effectiveShowLegend,
              showTooltip:
                  widget.style.showTooltip && !_useWindowsSafeMarkerDetails,
              showShapeTooltip: false,
              showDataLabels: widget.style.showDataLabels,
              showMetricSelector:
                  widget.style.showMetricSelector &&
                  !_showsFloatingMetricSelector,
              enableZoomPan: widget.style.enableZoomPan,
              scopeRootLabel: l10n.brazilStoreSalesMapCountryLabel,
              lowValueColor: widget.style.lowValueColor ?? _lowColor(context),
              highValueColor:
                  widget.style.highValueColor ?? _highColor(context),
              dataLabelTextStyle: stateDataLabelTextStyle,
              metricSelectorPadding: usesCompactMapChrome
                  ? EdgeInsets.zero
                  : null,
              legendNumberFormat: _legendFormat,
              emptyStateMessage: _resolvedEmptyStateMessage(l10n),
              metricGroupLabel: l10n.brazilStoreSalesMapMetricGroupLabel,
              scopeGroupLabel: l10n.brazilStoreSalesMapRegionGroupLabel,
              mapLoadingMessage: l10n.brazilStoreSalesMapLoadingMessage,
              showGroupLabels:
                  !_usesCleanFullscreenChrome && !usesCompactMapChrome,
            ),
            isRefreshing: widget.isRefreshing,
            ),
          );
        }

        final mapContent = _BrazilStoreSalesMapContent(
          key: const ValueKey<String>('brazil-store-sales-map-content'),
          expandMapVertically: usesBoundedVerticalLayout,
          regionMapBuilder: buildRegionMap,
          fixedRegionMapHeight: mapTileHeight,
          regionMapStyleHeightForAvailableArea: usesBoundedVerticalLayout
              ? (availableMapAreaHeight) =>
                    _layout.regionMapStyleHeightForMapArea(
                      context: context,
                      mapAreaHeight: availableMapAreaHeight,
                    )
              : null,
          mapOverlay: _buildMapOverlay(
            mapTileHeight: sidebarMapAreaHeight,
            showsDesktopBranchSidebar: showsDesktopBranchSidebar,
            sidebarWidth: sidebarWidth,
            sidebarTopInset: sidebarTopInset,
            sidebarHorizontalInset: sidebarHorizontalInset,
            entries: snapshot.visibleBranchListItems,
            selectedStoreId: _selectedStoreId,
            l10n: l10n,
            snapshot: snapshot,
          ),
          diagnostics:
              _effectiveShowDataQualityNotice &&
                  snapshot.diagnostics.hasDiscardedPoints
              ? _MapDataQualityNotice(diagnostics: snapshot.diagnostics)
              : null,
          markerLegend:
              _effectiveShowMarkerScaleLegend &&
                  snapshot.hasMarkers &&
                  useCompactMarkerLegend
              ? _MarkerScaleLegendMenuButton(
                  sizeLegendLabel: l10n.brazilStoreSalesMapMarkerSizeLegend,
                  metric: _selectedMetric,
                  minValue: snapshot.minMarkerValue,
                  maxValue: snapshot.maxMarkerValue,
                  minSize: widget.style.markerMinSize,
                  maxSize: widget.style.markerMaxSize,
                  color: _markerColor(context),
                  strokeColor: _markerStrokeColor(context),
                  visual: widget.style.markerVisual,
                )
              : _effectiveShowMarkerScaleLegend && snapshot.hasMarkers
              ? _MarkerScaleLegend(
                  sizeLegendLabel: l10n.brazilStoreSalesMapMarkerSizeLegend,
                  metric: _selectedMetric,
                  minValue: snapshot.minMarkerValue,
                  maxValue: snapshot.maxMarkerValue,
                  minSize: widget.style.markerMinSize,
                  maxSize: widget.style.markerMaxSize,
                  color: _markerColor(context),
                  strokeColor: _markerStrokeColor(context),
                  visual: widget.style.markerVisual,
                )
              : null,
          detail: ValueListenableBuilder<BrazilMapMarkerSelection>(
            valueListenable: _markerSelection,
            builder: (context, selection, _) {
              return _buildBelowMapSelectionDetail(
                context: context,
                snapshot: snapshot,
                selection: selection,
              );
            },
          ),
        );
        final content = mapContent;

        if (widget.title == null && widget.subtitle == null) {
          return content;
        }

        return AppChartShell(
          title: widget.title ?? '',
          subtitle: widget.subtitle,
          titleTrailing: widget.titleTrailing,
          belowSubtitle: widget.belowSubtitle,
          onShare: widget.onShare,
          openShareTooltip: widget.openShareTooltip,
          openShareSemanticLabel: widget.openShareSemanticLabel,
          onOpenFullscreen: widget.onOpenFullscreen,
          cardPadding: _usesCleanFullscreenChrome
              ? EdgeInsets.fromLTRB(
                  tokens.contentSpacing,
                  tokens.gapMd,
                  tokens.contentSpacing,
                  tokens.gapSm,
                )
              : null,
          child: content,
        );
      },
    );
  }

  NumberFormat? get _legendFormat {
    if (widget.style.legendNumberFormat != null) {
      return widget.style.legendNumberFormat;
    }

    return switch (_selectedMetric) {
      AppBrazilStoreSalesMapMetric.revenue =>
        AppBrFormatters.compactCurrencyFormat,
      AppBrazilStoreSalesMapMetric.salesCount => null,
    };
  }

  String _resolvedEmptyStateMessage(AppLocalizations l10n) {
    if (widget.style.emptyStateMessage ==
        AppBrazilStoreSalesMapStyle.defaultEmptyStateMessage) {
      return l10n.brazilStoreSalesMapEmptyState;
    }
    return widget.style.emptyStateMessage;
  }

  double _resolvedDesktopBranchSidebarTopInset(
    BuildContext context,
    AppThemeTokens tokens, {
    required bool cleanMode,
  }) {
    return BrazilMapDesktopSidebarLayout.topInsetBase +
        (cleanMode ? 0 : tokens.gapXs) +
        _layout.floatingMapControlsHeight(
          context,
          cleanMode: cleanMode,
        );
  }

  bool get _showOverlayMarkerDetail =>
      widget.style.showStoreDetail &&
      !_shouldUseCompactBranchSheet &&
      widget.style.selectedMarkerDetailPlacement ==
          AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay &&
      !_useWindowsSafeMarkerDetails;

  bool get _showBelowMapMarkerDetail =>
      _chrome.showBelowMapMarkerDetail && !_shouldUseCompactBranchSheet;

  bool get _useWindowsSafeMarkerDetails => _chrome.useWindowsSafeMarkerDetails;

  bool get _blocksViewportDrivenClustering =>
      _selection.blocksViewportDrivenClustering(widget.selectedStoreId);

  bool get _usesCleanFullscreenChrome => _chrome.usesCleanFullscreenChrome;

  bool get _includeVisibleBranchListItems =>
      _chrome.includeVisibleBranchListItems;

  bool get _showsFloatingMetricSelector => _chrome.showsFloatingMetricSelector;

  bool get _showsFloatingScopeSelector => _chrome.showsFloatingScopeSelector;

  bool get _effectiveShowLegend => _chrome.effectiveShowLegend;

  bool get _effectiveShowMarkerScaleLegend =>
      _chrome.effectiveShowMarkerScaleLegend;

  bool get _effectiveShowDataQualityNotice =>
      _chrome.effectiveShowDataQualityNotice;

  Widget? _buildMapOverlay({
    required double mapTileHeight,
    required bool showsDesktopBranchSidebar,
    required double sidebarWidth,
    required double sidebarTopInset,
    required double sidebarHorizontalInset,
    required List<AppBrazilStoreSalesVisibleBranchListItem> entries,
    required String? selectedStoreId,
    required AppLocalizations l10n,
    required _BrazilStoreSalesMapSnapshot snapshot,
  }) {
    final overlays = <Widget>[];
    if (_showsFloatingMetricSelector || _showsFloatingScopeSelector) {
      overlays.add(
        _FloatingMapControlsOverlay(
          topInset: BrazilMapLayoutConstants.floatingMapControlsTopInset,
          leftInset: BrazilMapLayoutConstants.floatingMapControlsLeftInset,
          metrics: _showsFloatingMetricSelector ? _buildMetrics(l10n) : null,
          selectedMetricKey: _selectedMetric.key,
          onMetricChanged: _handleMetricChanged,
          scopeOptions: _showsFloatingScopeSelector
              ? AppBrazilStoreSalesMapLocalizations.regionScopeOptions(l10n)
              : const <AppMapScopeOption>[],
          activeScopeKey: _activeRegionKey,
          scopeRootLabel: l10n.brazilStoreSalesMapCountryLabel,
          onScopeChanged: _showsFloatingScopeSelector
              ? _handleScopeChanged
              : null,
        ),
      );
    }
    if (showsDesktopBranchSidebar) {
      final sidebarMaxHeight = BrazilMapDesktopSidebarLayout.maxHeight(
        mapTileHeight: mapTileHeight,
        topInset: sidebarTopInset,
      );
      if (sidebarMaxHeight > 0) {
        overlays.add(
          _desktopBranchSidebarCollapsed
              ? _DesktopBranchSidebarCollapsedOverlay(
                  topInset: sidebarTopInset,
                  horizontalInset: sidebarHorizontalInset,
                  onExpand: _toggleDesktopBranchSidebarCollapsed,
                )
              : _DesktopBranchSidebarOverlay(
                  width: sidebarWidth,
                  maxHeight: sidebarMaxHeight,
                  topInset: sidebarTopInset,
                  horizontalInset: sidebarHorizontalInset,
                  entries: entries,
                  selectedStoreId: selectedStoreId,
                  allowCollapse: _usesCleanFullscreenChrome,
                  onToggleCollapsed: _toggleDesktopBranchSidebarCollapsed,
                  onSelectBranch: (point) => _handleMarkerBranchAction(
                    point: point,
                    index: _mapPointIndexFor(point, snapshot),
                  ),
                  onPreviewBranchStart: _setPreviewedPoint,
                  onPreviewBranchEnd: _clearPreviewedPoint,
                ),
        );
      }
    }
    if (overlays.isEmpty) {
      return null;
    }
    if (overlays.length == 1) {
      return overlays.first;
    }
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: overlays,
      ),
    );
  }

  void _toggleDesktopBranchSidebarCollapsed() {
    setState(() {
      _desktopBranchSidebarCollapsed = !_desktopBranchSidebarCollapsed;
    });
  }

  List<AppMapMetric<AppBrazilStoreSalesStateBucket>> _buildMetrics(
    AppLocalizations l10n,
  ) => <AppMapMetric<AppBrazilStoreSalesStateBucket>>[
    AppMapMetric<AppBrazilStoreSalesStateBucket>(
      key: AppBrazilStoreSalesMapMetric.revenue.key,
      label: l10n.brazilStoreSalesMapMetricRevenueShort,
      legendLabel: l10n.brazilStoreSalesMapLegendRevenuePerState,
      valueBuilder: (bucket) => bucket.salesAmount,
      tooltipBuilder: _stateTooltipSubtitle,
    ),
    AppMapMetric<AppBrazilStoreSalesStateBucket>(
      key: AppBrazilStoreSalesMapMetric.salesCount.key,
      label: l10n.brazilStoreSalesMapMetricSalesShort,
      legendLabel: l10n.brazilStoreSalesMapLegendSalesPerState,
      valueBuilder: (bucket) => bucket.salesCount,
      tooltipBuilder: _stateTooltipSubtitle,
    ),
  ];

  AppMapViewport? _resolvePreferredViewportForBuild(
    _BrazilStoreSalesMapSnapshot snapshot,
  ) {
    final next = _preferredViewportForSyncfusion(snapshot);
    if (next == null) {
      _cachedPreferredViewport = null;
      return null;
    }
    final cached = _cachedPreferredViewport;
    if (cached == next) {
      return cached;
    }
    _cachedPreferredViewport = next;
    return next;
  }

  String get _regionViewportBindingKey => _activeRegionKey ?? '__brazil__';

  /// Preferred viewport passed to Syncfusion. Returns null when the map should
  /// keep the current camera (manual zoom/pan, open store detail, or region
  /// already bound) to avoid programmatic pan/zoom fighting on Windows.
  AppMapViewport _resetTargetViewportForScope() {
    final regionKey = _activeRegionKey;
    if (regionKey == null) {
      return AppBrazilMapStaticData.brazilViewport;
    }

    return AppBrazilMapStaticData.regionViewports[regionKey] ??
        AppBrazilMapStaticData.brazilViewport;
  }

  void _handleResetViewport() {
    setState(() {
      _viewportController.reset();
      _userHasManualMapViewport = false;
      _cachedPreferredViewportBinding = null;
      _cachedPreferredViewport = null;
      _zoom.applyScopeZoom(_resetTargetViewportForScope().zoomLevel);
    });
  }

  AppMapViewport? _preferredViewportForSyncfusion(
    _BrazilStoreSalesMapSnapshot snapshot,
  ) {
    if (_userHasManualMapViewport) {
      return null;
    }

    final selectedPoint =
        snapshot.selectedPoint ?? _pointById(_selectedStoreId);
    if (_selection.shouldFocusCameraOnSelectedStore(
          controlledSelectedStoreId: widget.selectedStoreId,
          autoFocusSelectedStore: widget.style.autoFocusSelectedStore,
        ) &&
        selectedPoint != null) {
      return AppMapViewport(
        centerLatitude: selectedPoint.latitude,
        centerLongitude: selectedPoint.longitude,
        zoomLevel: widget.style.selectedStoreZoomLevel,
      );
    }

    if (_selectedStoreId != null) {
      return null;
    }

    final bindingKey = _regionViewportBindingKey;
    if (_cachedPreferredViewportBinding == bindingKey) {
      return null;
    }
    // Intentional memoization: records which binding key last triggered a
    // preferred-viewport update so the same viewport is not re-applied on
    // every build when the region/store selection has not changed.
    // Invalidated by setState calls in selection, filter, and scope handlers.
    _cachedPreferredViewportBinding = bindingKey;

    final regionKey = _activeRegionKey;
    if (regionKey == null) {
      return AppBrazilMapStaticData.brazilViewport;
    }

    return AppBrazilMapStaticData.regionViewports[regionKey] ??
        AppBrazilMapStaticData.brazilViewport;
  }

  String _stateLabelFor(
    AppBrazilStoreSalesStateBucket bucket, {
    bool compact = false,
  }) {
    final requestedLabelMode = widget.style.stateLabelMode;
    if (compact &&
        requestedLabelMode != AppBrazilStoreSalesStateLabelMode.stateName) {
      return bucket.uf;
    }

    final labelMode = switch (requestedLabelMode) {
      AppBrazilStoreSalesStateLabelMode.responsive =>
        AppBreakpoints.isDesktop(context)
            ? AppBrazilStoreSalesStateLabelMode.stateName
            : AppBrazilStoreSalesStateLabelMode.uf,
      final labelMode => labelMode,
    };

    return switch (labelMode) {
      AppBrazilStoreSalesStateLabelMode.uf => bucket.uf,
      AppBrazilStoreSalesStateLabelMode.stateName =>
        compact ? _compactStateNameLabel(bucket) : bucket.stateName,
      AppBrazilStoreSalesStateLabelMode.responsive => bucket.uf,
    };
  }

  TextStyle? _stateDataLabelTextStyle(
    BuildContext context, {
    required bool compact,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelSmall;
    final requestedLabelMode = widget.style.stateLabelMode;
    final usesStateNames =
        requestedLabelMode == AppBrazilStoreSalesStateLabelMode.stateName ||
        (requestedLabelMode == AppBrazilStoreSalesStateLabelMode.responsive &&
            AppBreakpoints.isDesktop(context));
    final compactStateNames = compact && usesStateNames;
    final fontSize = compactStateNames
        ? _compactStateLabelFontSize(maxWidth)
        : (compact ? 10.0 : null);

    return base?.copyWith(
      color: theme.colorScheme.onSurface.withValues(
        alpha: compactStateNames ? 0.88 : 1,
      ),
      fontWeight: compactStateNames ? FontWeight.w800 : FontWeight.w700,
      fontSize: fontSize,
      height: compactStateNames ? 1.04 : null,
    );
  }

  double _compactStateLabelFontSize(double maxWidth) {
    if (!maxWidth.isFinite) {
      return 9;
    }
    if (maxWidth < 380) {
      return 7;
    }
    if (maxWidth < 600) {
      return 8;
    }
    return 9;
  }

  String _compactStateNameLabel(AppBrazilStoreSalesStateBucket bucket) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode != 'pt') {
      return bucket.stateName;
    }
    return switch (bucket.uf) {
      'DF' => 'Distrito\nFederal',
      'ES' => 'Espirito\nSanto',
      'MS' => 'Mato Grosso\ndo Sul',
      'MT' => 'Mato\nGrosso',
      'MG' => 'Minas\nGerais',
      'RJ' => 'Rio de\nJaneiro',
      'RN' => 'Rio Grande\ndo Norte',
      'RS' => 'Rio Grande\ndo Sul',
      'SC' => 'Santa\nCatarina',
      'SP' => 'Sao\nPaulo',
      final _ => bucket.stateName,
    };
  }

  String _computeSnapshotDataReuseKey() {
    final pointsDigest = _resolvePointsDigest();
    return AppBrazilStoreSalesMapSnapshotBuilder.buildReuseKey(
      points: widget.points,
      fixedBranchIds: widget.fixedBranchIds,
      filterBranchIds: widget.filterBranchIds,
      style: widget.style,
      metric: _selectedMetric,
      activeRegionKey: _activeRegionKey,
      zoomLevel: _zoom.clusteringZoomLevel,
      includeVisibleBranchListItems: _includeVisibleBranchListItems,
      pointsDigest: pointsDigest,
    );
  }

  int _resolvePointsDigest() {
    final points = widget.points;
    if (identical(_cachedPointsDigestSource, points) &&
        _cachedPointsDigest != null) {
      return _cachedPointsDigest!;
    }
    final digest = AppBrazilStoreSalesMapData.pointsContentDigest(points);
    _cachedPointsDigestSource = points;
    _cachedPointsDigest = digest;
    return digest;
  }

  AppBrazilStoreSalesMapSnapshotData _resolveSnapshotData(
    BuildContext context,
  ) {
    final reuseKey = _computeSnapshotDataReuseKey();
    final snapshotData = _snapshotData;
    if (snapshotData != null && snapshotData.cachedReuseKey == reuseKey) {
      return snapshotData;
    }

    final stopwatch = kDebugMode || kProfileMode
        ? (Stopwatch()..start())
        : null;
    final nextSnapshotData = AppBrazilStoreSalesMapSnapshotBuilder.buildData(
      AppBrazilStoreSalesMapSnapshotInput(
        points: widget.points,
        metric: _selectedMetric,
        activeRegionKey: _activeRegionKey,
        zoomLevel: _zoom.clusteringZoomLevel,
        style: widget.style,
        includeVisibleBranchListItems: _includeVisibleBranchListItems,
      ),
      cachedReuseKey: reuseKey,
      defaultBranchName: AppLocalizations.of(
        context,
      ).brazilStoreSalesMapDefaultBranchName,
    );
    if (stopwatch != null) {
      AppLogger.debug(
        'Brazil store sales map snapshot data built',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'inputPointCount': widget.points.length,
          'validPointCount': nextSnapshotData.validPointCount,
          'bucketCount': nextSnapshotData.buckets.length,
          'markerGroupCount': nextSnapshotData.markerGroups.length,
          'visibleBranchListItemCount':
              nextSnapshotData.visibleBranchListItems.length,
          'includeVisibleBranchListItems': _includeVisibleBranchListItems,
          'aggregation': widget.style.markerAggregation.name,
          'activeRegionKey': _activeRegionKey,
        },
      );
    }
    _snapshotData = nextSnapshotData;
    return nextSnapshotData;
  }

  _BrazilStoreSalesMapSnapshot _resolveSnapshot(BuildContext context) {
    final data = _resolveSnapshotData(context);
    final selectedStoreId = _selectedStoreId;
    final visualReuseKey = widget.style.autoFocusSelectedStore
        ? [
            data.cachedReuseKey,
            'ss=',
            'rs=',
            'pv=',
          ].join(';')
        : data.cachedReuseKey;
    final snapshot = _snapshot;
    if (snapshot != null && snapshot.visualReuseKey == visualReuseKey) {
      return snapshot;
    }

    final nextSnapshot = _BrazilStoreSalesMapSnapshot.fromData(
      context: context,
      data: data,
      selectedStoreId: selectedStoreId,
      requestedStateKey: _selection.internalSelectedStateKey,
      style: widget.style,
      visualReuseKey: visualReuseKey,
    );
    _snapshot = nextSnapshot;
    return nextSnapshot;
  }

  String? get _selectedStoreId =>
      _selection.resolveSelectedStoreId(widget.selectedStoreId);

  void _handleMetricChanged(AppMapMetricChangedEvent event) {
    final metric = AppBrazilStoreSalesMapMetric.values.firstWhere(
      (candidate) => candidate.key == event.metricKey,
      orElse: () => _selectedMetric,
    );

    if (metric == _selectedMetric) {
      return;
    }

    setState(() {
      _selectedMetric = metric;
      _invalidateResolvedSnapshotData();
    });
    widget.onMetricChanged?.call(metric);
  }

  void _handleScopeChanged(AppMapScopeChangedEvent event) {
    setState(() {
      _viewportController.reset();
      _userHasManualMapViewport = false;
      _cachedPreferredViewportBinding = null;
      _cachedPreferredViewport = null;
      _activeRegionKey = event.currentScopeKey;
      _zoom.applyScopeZoom(
        (event.currentScopeKey == null
                ? AppBrazilMapStaticData.brazilViewport
                : AppBrazilMapStaticData.regionViewports[event.currentScopeKey])
            ?.zoomLevel,
      );
      _selection.clearStoreIfOutsideActiveRegion(
        activeRegionKey: _activeRegionKey,
        controlledSelectedStoreId: widget.selectedStoreId,
        pointById: _pointById,
      );
      if (!_pointMatchesActiveRegion(_previewedStoreId)) {
        _previewedStoreId = null;
      }
      _publishMarkerSelection();
      _invalidateResolvedSnapshotData();
    });
  }

  void _handleStateTap(
    AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket> event,
  ) {
    final preserveStoreSelection = _selection
        .shouldPreserveStoreSelectionForRegionTap(
          regionKey: event.regionKey,
          controlledSelectedStoreId: widget.selectedStoreId,
          pointById: _pointById,
        );
    if (_selection.shouldSkipRedundantRegionTap(
      regionKey: event.regionKey,
      preserveStoreSelection: preserveStoreSelection,
      controlledSelectedStoreId: widget.selectedStoreId,
    )) {
      widget.onStateTap?.call(event);
      return;
    }

    setState(() {
      _selection.applyRegionTap(
        regionKey: event.regionKey,
        preserveStoreSelection: preserveStoreSelection,
      );
      if (!preserveStoreSelection) {
        _previewedStoreId = null;
        _viewportController.reset();
      }
      _invalidateResolvedSnapshotVisual();
      _publishMarkerSelection();
    });
    widget.onStateTap?.call(event);
  }

  void _handlePointTap(AppMapPointTapEvent event) {
    final payload = event.point.payload;
    if (payload is AppBrazilStoreSalesStateBubble) {
      _handleStateBubbleTap(payload, event.index);
      return;
    }

    if (payload is! AppBrazilStoreSalesMarkerGroup) {
      return;
    }

    final point = payload.primaryPoint;
    final focusSelectedStore =
        !payload.isCluster && !payload.isMunicipalityAggregate;
    _selectPoint(point, focusStore: focusSelectedStore);
    if (_shouldUseCompactBranchSheet) {
      unawaited(
        _openCompactBranchDetailSheet(
          group: payload,
          initialStoreId: point.id,
          markerIndex: event.index,
        ),
      );
    }

    if (payload.isMunicipalityAggregate) {
      widget.onMunicipalityTap?.call(
        AppBrazilStoreSalesMunicipalityTapEvent(
          points: payload.points,
          index: event.index,
          metric: _selectedMetric,
          latitude: payload.latitude,
          longitude: payload.longitude,
          salesAmount: payload.salesAmount,
          salesCount: payload.salesCount,
        ),
      );
      return;
    }

    if (payload.isCluster) {
      widget.onStoreClusterTap?.call(
        AppBrazilStoreSalesPointClusterTapEvent(
          points: payload.points,
          index: event.index,
          metric: _selectedMetric,
          latitude: payload.latitude,
          longitude: payload.longitude,
          salesAmount: payload.salesAmount,
          salesCount: payload.salesCount,
        ),
      );
      return;
    }

    _emitStoreTap(point: point, index: event.index);
  }

  void _selectPoint(
    AppBrazilStoreSalesPoint point, {
    bool focusStore = true,
  }) {
    _cancelPendingPreviewClear();
    _cancelPendingViewportClusterSampling();
    final shouldAutoFocusStore =
        focusStore && widget.style.autoFocusSelectedStore;

    if (!shouldAutoFocusStore) {
      _viewportController.withdrawPreferredViewportForStoreSelection();
      _selection.applyStoreSelection(
        point,
        focusStore: false,
        linkRegionHighlight: false,
      );
      _previewedStoreId = null;
      _publishMarkerSelection();
      return;
    }

    _viewportController.reset();
    setState(() {
      _selection.applyStoreSelection(
        point,
        focusStore: true,
      );
      _previewedStoreId = null;
      _cachedPreferredViewport = null;
      _cachedPreferredViewportBinding = null;
      _zoom.clusteringZoomLevel = widget.style.selectedStoreZoomLevel;
      _invalidateResolvedSnapshotData();
    });
    _publishMarkerSelection();
    _scheduleConsumeCameraFocus();
  }

  void _emitStoreTap({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    widget.onStoreTap?.call(
      AppBrazilStoreSalesPointTapEvent(
        point: point,
        index: index,
        metric: _selectedMetric,
      ),
    );
  }

  int _mapPointIndexFor(
    AppBrazilStoreSalesPoint point,
    _BrazilStoreSalesMapSnapshot snapshot,
  ) {
    final index = snapshot.mapPoints.indexWhere((mapPoint) {
      final payload = mapPoint.payload;
      return payload is AppBrazilStoreSalesMarkerGroup &&
          payload.points.any((groupPoint) => groupPoint.id == point.id);
    });
    return index < 0 ? 0 : index;
  }

  void _handleMarkerBranchAction({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    if (!mounted) {
      return;
    }
    _selectPoint(point);
    _emitStoreTap(point: point, index: index);
  }

  bool get _shouldUseCompactBranchSheet => _compactBranchSheetLayout;

  Future<void> _openCompactBranchDetailSheet({
    required AppBrazilStoreSalesMarkerGroup group,
    required String initialStoreId,
    required int markerIndex,
  }) async {
    final l10nContext = context;
    await showModalBottomSheet<void>(
      context: l10nContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final tokens = Theme.of(sheetContext).extension<AppThemeTokens>()!;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.gapMd,
            0,
            tokens.gapMd,
            tokens.gapMd,
          ),
          child: _SelectedMarkerGroupDetailCard(
            group: group,
            metric: _selectedMetric,
            initialStoreId: initialStoreId,
            onDismiss: () => unawaited(Navigator.of(sheetContext).maybePop()),
            onClose: () => unawaited(Navigator.of(sheetContext).maybePop()),
            onClearSelection: () {
              _clearSelectedMarkerDetail();
              unawaited(Navigator.of(sheetContext).maybePop());
            },
            onSelectBranch: (point) {
              unawaited(Navigator.of(sheetContext).maybePop());
              _handleMarkerBranchAction(point: point, index: markerIndex);
            },
            selectBranchLabelBuilder: (_) => AppLocalizations.of(
              sheetContext,
            ).brazilStoreSalesMapShowBranchOnMapAction,
          ),
        );
      },
    );
  }

  void _clearSelectedMarkerDetail() {
    _cancelPendingPreviewClear();
    _viewportController.reset();
    setState(() {
      _selection.clearStoreSelection(
        controlledSelectedStoreId: widget.selectedStoreId,
      );
      _previewedStoreId = null;
      _cachedPreferredViewportBinding = null;
      _cachedPreferredViewport = null;
      _publishMarkerSelection();
    });
  }

  void _handleStateBubbleTap(
    AppBrazilStoreSalesStateBubble bubble,
    int index,
  ) {
    final bucket = bubble.bucket;
    setState(() {
      _viewportController.reset();
      _selection.clearStoreAndStateSelection();
      _previewedStoreId = null;
      _selection.internalSelectedStateKey = bucket.uf;
      _publishMarkerSelection();
    });

    widget.onStateTap?.call(
      AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
        item: bucket,
        regionKey: bucket.uf,
        regionLabel: _stateLabelFor(bucket),
        metricKey: _selectedMetric.key,
        metricValue: _selectedMetric.valueForBucket(bucket),
        index: index,
      ),
    );
  }

  void _handleViewportChanged(AppMapViewportChangedEvent event) {
    if (event.source == AppMapViewportChangeSource.user) {
      _userHasManualMapViewport = true;
    }

    if (!widget.style.enableProximityCluster) {
      return;
    }

    if (event.source == AppMapViewportChangeSource.programmatic) {
      return;
    }

    // Syncfusion Maps + debounced viewport clustering + overlay rebuilds can
    // freeze or crash the Windows desktop host (AXTree / "Lost connection to
    // device"). Keep clustering zoom driven by scope/selection only on Windows.
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _cancelPendingViewportClusterSampling();
      return;
    }

    // While a store is selected, ignore viewport-driven re-clustering. Syncfusion
    // emits many zoom ticks during marker focus and detail layout; each sample
    // rebuilds snapshot data synchronously and can freeze the UI.
    if (_blocksViewportDrivenClustering) {
      _cancelPendingViewportClusterSampling();
      return;
    }

    final rawZoom = event.viewport.zoomLevel;
    final nextZoomLevel =
        defaultTargetPlatform == TargetPlatform.windows && kReleaseMode
        ? (rawZoom * 4).round() / 4.0
        : rawZoom;

    final debounceDuration =
        defaultTargetPlatform == TargetPlatform.windows && kReleaseMode
        ? _windowsViewportClusterDebounceDuration
        : (_shouldDebounceTouchViewportClustering
              ? _touchViewportClusterDebounceDuration
              : _desktopViewportClusterDebounceDuration);

    _pendingViewportClusterZoomLevel = nextZoomLevel;
    _viewportClusterDebounceTimer?.cancel();
    _viewportClusterDebounceTimer = Timer(
      debounceDuration,
      () {
        final pendingZoomLevel = _pendingViewportClusterZoomLevel;
        _pendingViewportClusterZoomLevel = null;
        if (pendingZoomLevel == null) {
          return;
        }
        _applyViewportClusterZoomLevel(pendingZoomLevel);
      },
    );
  }

  bool get _shouldDebounceTouchViewportClustering {
    if (!widget.style.enableZoomPan) {
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

  void _applyViewportClusterZoomLevel(double nextZoomLevel) {
    if (!mounted) {
      return;
    }
    if (_blocksViewportDrivenClustering) {
      return;
    }
    if (!_zoom.shouldApplyViewportClusterSample(
      nextZoomLevel,
      blocksViewportDrivenClustering: _blocksViewportDrivenClustering,
    )) {
      return;
    }

    setState(() {
      _zoom.clusteringZoomLevel = nextZoomLevel;
      _invalidateResolvedSnapshotData();
    });
    if (kDebugMode || kProfileMode) {
      AppLogger.debug(
        'Brazil store sales map viewport changed',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'zoomLevel': nextZoomLevel,
          'pointCount': widget.points.length,
          'activeRegionKey': _activeRegionKey,
        },
      );
    }
  }

  void _emitDiagnosticsIfNeeded(
    AppBrazilStoreSalesMapDiagnostics diagnostics,
  ) {
    final callback = widget.onDiagnosticsChanged;
    if (callback == null || _lastEmittedDiagnostics == diagnostics) {
      return;
    }

    _lastEmittedDiagnostics = diagnostics;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      callback(diagnostics);
    });
  }

  AppBrazilStoreSalesPoint? _pointById(String? selectedStoreId) {
    if (selectedStoreId == null) {
      return null;
    }

    for (final point in widget.points) {
      if (point.id == selectedStoreId) {
        return point;
      }
    }

    return null;
  }

  Widget _buildBelowMapSelectionDetail({
    required BuildContext context,
    required _BrazilStoreSalesMapSnapshot snapshot,
    required BrazilMapMarkerSelection selection,
  }) {
    final markerDetail = _resolveMarkerDetailSelection(snapshot, selection);
    final selectedPoint = markerDetail.point;
    final selectedMarkerGroup = markerDetail.group;
    final selectedStateBucket = _resolveSelectedStateBucket(
      snapshot,
      selection,
    );

    if (_showBelowMapMarkerDetail &&
        selectedMarkerGroup != null &&
        (selectedMarkerGroup.isMunicipalityAggregate ||
            selectedMarkerGroup.isCluster)) {
      return _SelectedMunicipalityDetail(
        group: selectedMarkerGroup,
        metric: _selectedMetric,
        selectedStoreId: selection.selectedStoreId,
        onSelectBranch: (point) => _handleMarkerBranchAction(
          point: point,
          index: _mapPointIndexFor(point, snapshot),
        ),
        selectBranchLabelBuilder: (_) => AppLocalizations.of(
          context,
        ).brazilStoreSalesMapShowBranchOnMapAction,
      );
    }
    if (_showBelowMapMarkerDetail && selectedPoint != null) {
      return _SelectedStoreDetail(
        point: selectedPoint,
        metric: _selectedMetric,
      );
    }
    if (selectedPoint == null &&
        selectedMarkerGroup == null &&
        selectedStateBucket != null) {
      return _SelectedStateDetail(
        bucket: selectedStateBucket,
        metric: _selectedMetric,
      );
    }
    return const SizedBox.shrink();
  }

  AppBrazilStoreSalesStateBucket? _resolveSelectedStateBucket(
    _BrazilStoreSalesMapSnapshot snapshot,
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

  ({AppBrazilStoreSalesPoint? point, AppBrazilStoreSalesMarkerGroup? group})
  _resolveMarkerDetailSelection(
    _BrazilStoreSalesMapSnapshot snapshot,
    BrazilMapMarkerSelection selection,
  ) {
    final selectedStoreId = selection.selectedStoreId;
    var point = snapshot.selectedPoint;
    var group = snapshot.selectedMarkerGroup;
    if (selectedStoreId == null) {
      return (point: null, group: null);
    }

    point ??= _pointById(selectedStoreId);
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

  bool _pointMatchesActiveRegion(String? pointId) {
    final point = _pointById(pointId);
    if (point == null) {
      return false;
    }
    return AppBrazilStoreSalesMapData.pointMatchesRegion(
      point,
      _activeRegionKey,
    );
  }

  void _setPreviewedPoint(AppBrazilStoreSalesPoint point) {
    _cancelPendingPreviewClear();
    if (!AppBreakpoints.isDesktop(context) ||
        !_pointMatchesActiveRegion(point.id) ||
        _previewedStoreId == point.id) {
      return;
    }
    setState(() {
      _previewedStoreId = point.id;
      _publishMarkerSelection();
    });
  }

  void _clearPreviewedPoint() {
    if (_previewedStoreId == null) {
      return;
    }
    _cancelPendingPreviewClear();
    _previewClearTimer = Timer(_desktopBranchPreviewClearDelay, () {
      if (!mounted || _previewedStoreId == null) {
        return;
      }
      setState(() {
        _previewedStoreId = null;
        _publishMarkerSelection();
      });
    });
  }

  @override
  @visibleForTesting
  void previewBranchForTesting(AppBrazilStoreSalesPoint point) {
    _cancelPendingPreviewClear();
    _previewedStoreId = point.id;
    _publishMarkerSelection();
  }

  @override
  @visibleForTesting
  void clearPreviewBranchForTesting() {
    _cancelPendingPreviewClear();
    _previewedStoreId = null;
    _publishMarkerSelection();
  }

  AppMapMarkerStyle _resolveStateBubbleMarkerStyle(
    BuildContext context,
    AppMapMarkerStyle base,
    AppBrazilStoreSalesStateBucket bucket,
  ) {
    final selectedStateKey = _selection.internalSelectedStateKey;
    if (selectedStateKey == null || bucket.uf != selectedStateKey) {
      return base;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectedMarkerColor =
        widget.style.selectedMarkerColor ?? context.appColors.secondary;
    final selectedMarkerStrokeColor =
        widget.style.selectedMarkerStrokeColor ?? colorScheme.surface;
    return base.copyWith(
      size: base.size + 4,
      color: selectedMarkerColor,
      strokeColor: selectedMarkerStrokeColor,
      strokeWidth: 2.4,
    );
  }

  AppMapMarkerStyle _resolveStoreGroupMarkerStyle(
    BuildContext context,
    AppMapMarkerStyle base,
    AppBrazilStoreSalesMarkerGroup group,
    BrazilMapMarkerSelection selection,
  ) {
    final selectedStoreId = selection.selectedStoreId;
    final previewedStoreId = selection.previewedStoreId;
    final selected =
        selectedStoreId != null &&
        group.points.any((point) => point.id == selectedStoreId);
    final previewed =
        previewedStoreId != null &&
        group.points.any((point) => point.id == previewedStoreId);
    if (!selected && !previewed) {
      return base;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectedMarkerColor =
        widget.style.selectedMarkerColor ?? context.appColors.secondary;
    final selectedMarkerStrokeColor =
        widget.style.selectedMarkerStrokeColor ?? colorScheme.surface;
    return base.copyWith(
      size: previewed ? base.size + 8 : base.size + 4,
      color: selectedMarkerColor,
      strokeColor: selectedMarkerStrokeColor,
      strokeWidth: previewed ? 3 : 2.4,
    );
  }

  @override
  @visibleForTesting
  Object? get snapshotDataIdentityForTesting => _snapshotData;

  @override
  @visibleForTesting
  Object? get snapshotMapPointsIdentityForTesting => _snapshot?.mapPoints;

  @override
  @visibleForTesting
  String? get previewedStoreIdForTesting => _previewedStoreId;

  @override
  @visibleForTesting
  bool get suppressPreferredViewportForTesting =>
      _viewportController.suppressPreferredViewport;

  Widget _buildMarker(
    BuildContext context,
    AppMapPoint point,
    int index,
    BrazilMapMarkerSelection selection,
  ) {
    final payload = point.payload;
    if (payload is AppBrazilStoreSalesStateBubble) {
      final baseStyle = point.style ?? const AppMapMarkerStyle();
      return _StateBubbleMarker(
        bucket: payload.bucket,
        metric: _selectedMetric,
        style: _resolveStateBubbleMarkerStyle(
          context,
          baseStyle,
          payload.bucket,
        ),
        semanticLabel: _stateBubbleSemanticLabel(payload.bucket),
      );
    }

    final group = payload is AppBrazilStoreSalesMarkerGroup ? payload : null;
    final baseStyle = point.style ?? const AppMapMarkerStyle();
    final style = group == null
        ? baseStyle
        : _resolveStoreGroupMarkerStyle(context, baseStyle, group, selection);
    final marker = _StoreMapMarker(
      key: ValueKey<String>('brazil-store-sales-map-marker-$index'),
      style: style,
      count: group?.points.length ?? 1,
      visual: widget.style.markerVisual,
      semanticLabel: _markerSemanticLabel(group),
    );
    final selectedStoreId = selection.selectedStoreId;
    final previewedStoreId = selection.previewedStoreId;
    final showDetailOverlay =
        _showOverlayMarkerDetail &&
        previewedStoreId == null &&
        group != null &&
        selectedStoreId != null &&
        group.points.any((point) => point.id == selectedStoreId);
    final showPreviewOverlay =
        !showDetailOverlay &&
        _showOverlayMarkerDetail &&
        group != null &&
        previewedStoreId != null &&
        group.points.any((point) => point.id == previewedStoreId);

    if (!showDetailOverlay && !showPreviewOverlay) {
      if (group == null ||
          !widget.style.showTooltip ||
          _useWindowsSafeMarkerDetails) {
        return marker;
      }

      return AppBrazilStoreSalesBranchHoverDetailAnchor(
        group: group,
        metric: _selectedMetric,
        marker: marker,
      );
    }

    if (showPreviewOverlay && !_useWindowsSafeMarkerDetails) {
      return AppBrazilStoreSalesBranchHoverDetailAnchor(
        group: group,
        metric: _selectedMetric,
        marker: marker,
        forceVisible: true,
        initialStoreId: previewedStoreId,
      );
    }

    if (showDetailOverlay) {
      return AppBrazilStoreSalesSelectedMarkerDetailAnchor(
        group: group,
        selectedStoreId: selectedStoreId,
        metric: _selectedMetric,
        marker: marker,
        onClose: _clearSelectedMarkerDetail,
        onClearSelection: _clearSelectedMarkerDetail,
        onSelectBranch: (point) =>
            _handleMarkerBranchAction(point: point, index: index),
        selectBranchLabelBuilder: (_) => AppLocalizations.of(
          context,
        ).brazilStoreSalesMapShowBranchOnMapAction,
      );
    }

    return marker;
  }

  Widget _buildMarkerTooltip(
    BuildContext context,
    AppMapPoint point,
    int index,
  ) {
    if ((point.tooltip == null || point.tooltip!.isEmpty) &&
        (point.label == null || point.label!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final payload = point.payload;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(260.0, 360.0);

    final Widget child;
    if (payload is AppBrazilStoreSalesMarkerGroup) {
      child = payload.isCluster || payload.isMunicipalityAggregate
          ? _SelectedMarkerGroupDetailCard(
              group: payload,
              metric: _selectedMetric,
            )
          : _SelectedMarkerStoreDetailCard(
              point: payload.primaryPoint,
              metric: _selectedMetric,
              showTechnicalLocationDetails: false,
            );
    } else if (payload is AppBrazilStoreSalesStateBubble) {
      child = _StateBubbleTooltipCard(
        bucket: payload.bucket,
        metric: _selectedMetric,
      );
    } else {
      final text = point.tooltip ?? point.label;
      child = text == null || text.isEmpty
          ? const SizedBox.shrink()
          : _PlainMapTooltipCard(text: text);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }

  String _stateTooltipSubtitle(AppBrazilStoreSalesStateBucket bucket) {
    final l10n = AppLocalizations.of(context);
    final revenue = AppBrFormatters.currency(bucket.salesAmount);
    final salesCount = _formatSalesCount(context, bucket.salesCount);
    final stores = _formatSalesCount(context, bucket.storeCount);
    return l10n.brazilStoreSalesMapStateInlineTooltip(
      bucket.stateName,
      bucket.uf,
      revenue,
      salesCount,
      stores,
    );
  }

  Color _markerColor(BuildContext context) {
    return widget.style.markerColor ?? context.appColors.tertiary;
  }

  Color _markerStrokeColor(BuildContext context) {
    return widget.style.markerStrokeColor ??
        Theme.of(context).colorScheme.surface;
  }

  Color _lowColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _highColor(BuildContext context) {
    return context.appColors.secondary;
  }

  String _markerSemanticLabel(AppBrazilStoreSalesMarkerGroup? group) {
    final l10n = AppLocalizations.of(context);
    if (group == null) {
      return l10n.brazilStoreSalesMapSemanticsStoreOnMap;
    }

    final salesStatus = group.points.any((point) => point.salesDataLoading)
        ? l10n.brazilStoreSalesMapSemanticsSalesLoadingSuffix
        : group.points.any((point) => point.salesDataUnavailable)
        ? l10n.brazilStoreSalesMapSemanticsSalesUnavailableSuffix
        : '';

    if (group.isCluster) {
      return l10n.brazilStoreSalesMapSemanticsClusterStores(
        _formatSalesCount(context, group.points.length),
        group.cityLabel,
        AppBrFormatters.currency(group.salesAmount),
        _formatSalesCount(context, group.salesCount),
        salesStatus,
      );
    }

    final point = group.primaryPoint;
    return l10n.brazilStoreSalesMapSemanticsSingleStore(
      point.name,
      group.cityLabel,
      AppBrFormatters.currency(point.salesAmount),
      _formatSalesCount(context, point.salesCount),
      salesStatus,
    );
  }

  String _stateBubbleSemanticLabel(AppBrazilStoreSalesStateBucket bucket) {
    final l10n = AppLocalizations.of(context);
    return l10n.brazilStoreSalesMapSemanticsStateAggregate(
      bucket.stateName,
      AppBrFormatters.currency(bucket.salesAmount),
      _formatSalesCount(context, bucket.salesCount),
      _formatSalesCount(context, bucket.storeCount),
    );
  }
}

class _BrazilStoreSalesMapSnapshot {
  const _BrazilStoreSalesMapSnapshot({
    required this.data,
    required this.mapPoints,
    required this.visualReuseKey,
    required this.selectedStoreId,
    required this.requestedStateKey,
    required this.selectedPoint,
    required this.selectedMarkerGroup,
    required this.selectedStateKey,
    required this.selectedStateBucket,
  });

  factory _BrazilStoreSalesMapSnapshot.fromData({
    required BuildContext context,
    required AppBrazilStoreSalesMapSnapshotData data,
    required String? selectedStoreId,
    required String? requestedStateKey,
    required AppBrazilStoreSalesMapStyle style,
    required String visualReuseKey,
  }) {
    final stopwatch = kDebugMode || kProfileMode
        ? (Stopwatch()..start())
        : null;
    final selectedState = _resolveSelectedState(
      data: data,
      selectedStoreId: selectedStoreId,
      requestedStateKey: requestedStateKey,
    );
    final mapPoints = _buildMapPoints(
      context: context,
      data: data,
      style: style,
    );

    final snapshot = _BrazilStoreSalesMapSnapshot(
      data: data,
      mapPoints: mapPoints,
      visualReuseKey: visualReuseKey,
      selectedStoreId: selectedStoreId,
      requestedStateKey: requestedStateKey,
      selectedPoint: selectedState.selectedPoint,
      selectedMarkerGroup: selectedState.selectedMarkerGroup,
      selectedStateKey: selectedState.selectedStateKey,
      selectedStateBucket: selectedState.selectedStateBucket,
    );
    if (stopwatch != null) {
      AppLogger.debug(
        'Brazil store sales map snapshot built',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'inputPointCount': data.validPointCount,
          'validPointCount': data.validPointCount,
          'bucketCount': data.buckets.length,
          'markerGroupCount': data.markerGroups.length,
          'mapPointCount': mapPoints.length,
          'aggregation': style.markerAggregation.name,
          'activeRegionKey': data.activeRegionKey,
        },
      );
    }
    return snapshot;
  }

  final AppBrazilStoreSalesMapSnapshotData data;
  final List<AppMapPoint> mapPoints;
  final String visualReuseKey;
  final String? selectedStoreId;
  final String? requestedStateKey;
  final AppBrazilStoreSalesPoint? selectedPoint;
  final AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
  final String? selectedStateKey;
  final AppBrazilStoreSalesStateBucket? selectedStateBucket;

  AppBrazilStoreSalesMapMetric get metric => data.metric;
  String? get activeRegionKey => data.activeRegionKey;
  double get zoomLevel => data.zoomLevel;
  List<AppBrazilStoreSalesPoint> get visiblePoints => data.visiblePoints;
  List<AppBrazilStoreSalesVisibleBranchListItem> get visibleBranchListItems =>
      data.visibleBranchListItems;
  List<AppBrazilStoreSalesStateBucket> get buckets => data.buckets;
  num get minMarkerValue => data.minMarkerValue;
  num get maxMarkerValue => data.maxMarkerValue;
  AppBrazilStoreSalesMapDiagnostics get diagnostics => data.diagnostics;
  String get cachedReuseKey => data.cachedReuseKey;

  bool get hasMarkers => mapPoints.isNotEmpty;

  static List<AppMapPoint> _buildMapPoints({
    required BuildContext context,
    required AppBrazilStoreSalesMapSnapshotData data,
    required AppBrazilStoreSalesMapStyle style,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = style.markerColor ?? context.appColors.tertiary;
    final markerStrokeColor = style.markerStrokeColor ?? colorScheme.surface;
    final pendingMarkerColor = context.appColors.secondary;
    final unavailableMarkerColor = colorScheme.onSurfaceVariant;
    final mapPoints = <AppMapPoint>[];

    for (final bucket in data.stateBubbleBuckets) {
      final centroid = AppBrazilMapStaticData.stateCentroidsByUf[bucket.uf];
      if (centroid == null) {
        continue;
      }

      final value = data.metric.valueForBucket(bucket);
      final markerSize = _effectiveMarkerSize(
        size: AppBrazilStoreSalesMapData.markerSizeFor(
          value: value,
          minValue: data.minMarkerValue,
          maxValue: data.maxMarkerValue,
          minSize: style.markerMinSize,
          maxSize: style.markerMaxSize,
        ),
        isCluster: false,
        visual: AppBrazilStoreSalesMarkerVisual.bubble,
      );

      mapPoints.add(
        AppMapPoint(
          latitude: centroid.latitude,
          longitude: centroid.longitude,
          label: style.showTooltip ? bucket.uf : null,
          tooltip: style.showTooltip
              ? _stateBubbleTooltip(context, bucket)
              : null,
          payload: AppBrazilStoreSalesStateBubble(bucket: bucket),
          style: AppMapMarkerStyle(
            size: markerSize,
            color: markerColor,
            strokeColor: markerStrokeColor,
          ),
        ),
      );
    }

    for (final group in data.markerGroups) {
      final size = AppBrazilStoreSalesMapData.markerSizeFor(
        value: group.valueForMetric(data.metric),
        minValue: data.minMarkerValue,
        maxValue: data.maxMarkerValue,
        minSize: style.markerMinSize,
        maxSize: style.markerMaxSize,
      );
      final markerSize = _effectiveMarkerSize(
        size: size,
        isCluster: group.isCluster,
        visual: style.markerVisual,
      );
      final hasLoadingSales = group.points.any(
        (point) => point.salesDataLoading,
      );
      final hasUnavailableSales =
          !hasLoadingSales &&
          group.points.any((point) => point.salesDataUnavailable);
      final effectiveMarkerColor = hasLoadingSales
          ? pendingMarkerColor
          : hasUnavailableSales
          ? unavailableMarkerColor
          : markerColor;
      final effectiveStrokeColor = hasLoadingSales
          ? colorScheme.surface
          : markerStrokeColor;
      mapPoints.add(
        AppMapPoint(
          latitude: group.latitude,
          longitude: group.longitude,
          payload: group,
          style: AppMapMarkerStyle(
            size: markerSize,
            color: effectiveMarkerColor,
            strokeColor: effectiveStrokeColor,
            strokeWidth: hasLoadingSales ? 2.4 : 1.5,
          ),
        ),
      );
    }

    return mapPoints;
  }

  static ({
    AppBrazilStoreSalesPoint? selectedPoint,
    AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup,
    String? selectedStateKey,
    AppBrazilStoreSalesStateBucket? selectedStateBucket,
  })
  _resolveSelectedState({
    required AppBrazilStoreSalesMapSnapshotData data,
    required String? selectedStoreId,
    required String? requestedStateKey,
  }) {
    AppBrazilStoreSalesPoint? selectedPoint;
    AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
    var selectedStateKey = requestedStateKey;
    if (selectedStoreId != null) {
      for (final group in data.markerGroups) {
        final selected = group.points.any(
          (point) => point.id == selectedStoreId,
        );
        if (!selected) {
          continue;
        }
        selectedMarkerGroup = group;
        selectedPoint = group.points.firstWhere(
          (point) => point.id == selectedStoreId,
          orElse: () => group.primaryPoint,
        );
        selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
          selectedPoint.uf,
        );
        break;
      }

      if (selectedPoint == null) {
        for (final point in data.visiblePoints) {
          if (point.id == selectedStoreId) {
            selectedPoint = point;
            break;
          }
        }
      }
      if (selectedPoint != null) {
        selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
          selectedPoint.uf,
        );
      }
    }

    AppBrazilStoreSalesStateBucket? selectedStateBucket;
    if (selectedStateKey != null) {
      for (final bucket in data.buckets) {
        if (bucket.uf == selectedStateKey) {
          selectedStateBucket = bucket;
          break;
        }
      }
    }

    return (
      selectedPoint: selectedPoint,
      selectedMarkerGroup: selectedMarkerGroup,
      selectedStateKey: selectedStateKey,
      selectedStateBucket: selectedStateBucket,
    );
  }

  static double _effectiveMarkerSize({
    required double size,
    required bool isCluster,
    required AppBrazilStoreSalesMarkerVisual visual,
  }) {
    final minimumSize = switch (visual) {
      AppBrazilStoreSalesMarkerVisual.dot => isCluster ? 22.0 : size,
      AppBrazilStoreSalesMarkerVisual.bubble => 30.0,
      AppBrazilStoreSalesMarkerVisual.storeIcon => 26.0,
    };

    return size.clamp(minimumSize, double.infinity);
  }

  static String _stateBubbleTooltip(
    BuildContext context,
    AppBrazilStoreSalesStateBucket bucket,
  ) {
    final l10n = AppLocalizations.of(context);
    return l10n.brazilStoreSalesMapStateBucketTooltip(
      bucket.stateName,
      bucket.uf,
      AppBrFormatters.currency(bucket.salesAmount),
      _formatSalesCount(context, bucket.salesCount),
      _formatSalesCount(context, bucket.storeCount),
    );
  }
}

String _formatMetricValue(
  BuildContext context,
  AppBrazilStoreSalesMapMetric metric,
  num value,
) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue => AppBrFormatters.compactCurrency(
      value,
    ),
    AppBrazilStoreSalesMapMetric.salesCount => _formatSalesCount(
      context,
      value,
    ),
  };
}

String _metricShortLabel(
  AppLocalizations l10n,
  AppBrazilStoreSalesMapMetric metric,
) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue =>
      l10n.brazilStoreSalesMapMetricRevenueShort,
    AppBrazilStoreSalesMapMetric.salesCount =>
      l10n.brazilStoreSalesMapMetricSalesShort,
  };
}

String _cityLabelFor(AppBrazilStoreSalesPoint point) {
  return switch (point.city) {
    final city? when city.trim().isNotEmpty =>
      '${city.trim()} / ${AppBrazilStoreSalesMapData.normalizeUf(point.uf)}',
    _ => AppBrazilStoreSalesMapData.normalizeUf(point.uf),
  };
}

Alignment _followerAnchorFor({
  required double screenWidth,
  required double maxWidth,
  required double? markerGlobalDx,
}) {
  final markerDx = markerGlobalDx;
  if (markerDx == null) {
    return Alignment.bottomCenter;
  }

  const margin = 16.0;
  final halfWidth = maxWidth / 2;
  if (markerDx < halfWidth + margin) {
    return Alignment.bottomLeft;
  }
  if (markerDx > screenWidth - halfWidth - margin) {
    return Alignment.bottomRight;
  }
  return Alignment.bottomCenter;
}

Offset _followerOffsetFor(Alignment followerAnchor) {
  if (followerAnchor == Alignment.bottomLeft) {
    return const Offset(8, -10);
  }
  if (followerAnchor == Alignment.bottomRight) {
    return const Offset(-8, -10);
  }
  return const Offset(0, -10);
}

List<AppBrazilStoreSalesPoint> _orderedBranchPoints(
  AppBrazilStoreSalesMarkerGroup group, {
  required String? initialStoreId,
}) {
  final selected = <AppBrazilStoreSalesPoint>[];
  final remaining = <AppBrazilStoreSalesPoint>[];

  for (final point in group.points) {
    if (initialStoreId != null && point.id == initialStoreId) {
      selected.add(point);
    } else {
      remaining.add(point);
    }
  }

  remaining.sort(_compareBranchPoints);
  return <AppBrazilStoreSalesPoint>[...selected, ...remaining];
}

int _compareBranchPoints(
  AppBrazilStoreSalesPoint left,
  AppBrazilStoreSalesPoint right,
) {
  final amount = right.salesAmount.compareTo(left.salesAmount);
  if (amount != 0) {
    return amount;
  }

  final salesCount = right.salesCount.compareTo(left.salesCount);
  if (salesCount != 0) {
    return salesCount;
  }

  return _branchOrdinalName(left).compareTo(_branchOrdinalName(right));
}

String _branchOrdinalName(AppBrazilStoreSalesPoint point) {
  return _branchDisplayModel(point).primaryName;
}

String _branchDisplayNameUi(
  BuildContext context,
  AppBrazilStoreSalesPoint point,
) {
  return resolveAppBranchDisplayModel(
    registrationName: point.branchName,
    fantasyName: point.fantasyName,
    fallbackName:
        _trimmedOrNull(point.name) ??
        AppLocalizations.of(context).brazilStoreSalesMapDefaultBranchName,
  ).primaryName;
}

String? _branchNameLabel(AppBrazilStoreSalesPoint point) {
  return _branchDisplayModel(point).secondaryName;
}

AppBranchDisplayModel _branchDisplayModel(AppBrazilStoreSalesPoint point) {
  return resolveAppBranchDisplayModel(
    registrationName: point.branchName,
    fantasyName: point.fantasyName,
    fallbackName: _trimmedOrNull(point.name) ?? point.id,
  );
}

String _agentChipLabel(AppLocalizations l10n, String agentName) {
  return l10n.brazilStoreSalesMapAgentChipWithName(
    appBranchDisplayName(agentName),
  );
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _locationResolutionLabel(
  AppLocalizations l10n,
  AppBrazilStoreSalesLocationResolution? resolution,
) {
  return switch (resolution) {
    AppBrazilStoreSalesLocationResolution.providedGeoPoint =>
      l10n.brazilStoreSalesMapLocationProvidedGeoPoint,
    AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode =>
      l10n.brazilStoreSalesMapLocationIbge,
    AppBrazilStoreSalesLocationResolution.cep =>
      l10n.brazilStoreSalesMapLocationCep,
    AppBrazilStoreSalesLocationResolution.cityUf =>
      l10n.brazilStoreSalesMapLocationCityUf,
    AppBrazilStoreSalesLocationResolution.capitalUf =>
      l10n.brazilStoreSalesMapLocationCapitalUf,
    AppBrazilStoreSalesLocationResolution.stateUf =>
      l10n.brazilStoreSalesMapLocationStateUf,
    null => l10n.brazilStoreSalesMapLocationUnknown,
  };
}
