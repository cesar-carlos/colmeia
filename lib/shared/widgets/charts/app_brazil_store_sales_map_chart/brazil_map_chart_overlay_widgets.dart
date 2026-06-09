import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_detail_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BrazilMapChartFloatingMapControlsOverlay extends StatelessWidget {
  const BrazilMapChartFloatingMapControlsOverlay({required this.topInset, required this.leftInset, required this.selectedMetricKey, required this.onMetricChanged, required this.scopeOptions, required this.activeScopeKey, required this.scopeRootLabel, required this.onScopeChanged, super.key,
    this.metrics,
  });

  final double topInset;
  final double leftInset;
  final List<AppMapMetric<AppBrazilStoreSalesStateBucket>>? metrics;
  final String selectedMetricKey;
  final ValueChanged<AppMapMetricChangedEvent> onMetricChanged;
  final List<AppMapScopeOption> scopeOptions;
  final String? activeScopeKey;
  final String scopeRootLabel;
  final ValueChanged<AppMapScopeChangedEvent>? onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final controls = <Widget>[];
    final visibleMetrics = metrics;
    if (visibleMetrics != null && visibleMetrics.isNotEmpty) {
      controls.add(
        BrazilMapChartFloatingControlSurface(
          child: KeyedSubtree(
            key: const ValueKey<String>('app-region-map-metric-selector'),
            child: Semantics(
              label: l10n.regionMapMetricSelectorSemanticsLabel,
              child: AppSegmentedControl<String>(
                options: visibleMetrics
                    .map(
                      (metric) => AppSegmentedControlOption<String>(
                        value: metric.key,
                        label: metric.label,
                      ),
                    )
                    .toList(growable: false),
                value: selectedMetricKey,
                onChanged: (nextMetricKey) {
                  if (nextMetricKey == selectedMetricKey) {
                    return;
                  }
                  onMetricChanged(
                    AppMapMetricChangedEvent(
                      metricKey: nextMetricKey,
                      previousMetricKey: selectedMetricKey,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
    if (onScopeChanged != null && scopeOptions.isNotEmpty) {
      if (controls.isNotEmpty) {
        controls.add(
          const SizedBox(
            height: BrazilMapLayoutConstants.floatingMapOverlayGap,
          ),
        );
      }
      controls.add(
        BrazilMapChartFloatingControlSurface(
          child: KeyedSubtree(
            key: const ValueKey<String>('app-region-map-scope-selector'),
            child: Semantics(
              label: l10n.regionMapScopeSemanticsLabel,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: <Widget>[
                    AppChoiceChip(
                      label: scopeRootLabel,
                      selected: activeScopeKey == null,
                      tooltip: l10n.regionMapViewFullScopeTooltip(
                        scopeRootLabel,
                      ),
                      semanticLabel: l10n.regionMapViewFullScopeSemanticLabel(
                        scopeRootLabel,
                      ),
                      onSelected: () {
                        if (activeScopeKey == null) {
                          return;
                        }
                        onScopeChanged!(
                          AppMapScopeChangedEvent(
                            previousScopeKey: activeScopeKey,
                            currentScopeKey: null,
                          ),
                        );
                      },
                    ),
                    for (final option in scopeOptions)
                      AppChoiceChip(
                        label: option.label,
                        selected: option.key == activeScopeKey,
                        tooltip: l10n.regionMapFocusScopeTooltip(
                          option.label,
                        ),
                        semanticLabel: l10n.regionMapFocusScopeSemanticLabel(
                          option.label,
                        ),
                        onSelected: () {
                          if (option.key == activeScopeKey) {
                            return;
                          }
                          onScopeChanged!(
                            AppMapScopeChangedEvent(
                              previousScopeKey: activeScopeKey,
                              currentScopeKey: option.key,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (controls.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppBrazilStoreSalesMapOverlayTooltipScope(
      child: Positioned(
        top: topInset,
        left: leftInset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: controls,
        ),
      ),
    );
  }
}

class BrazilMapChartFloatingControlSurface extends StatelessWidget {
  const BrazilMapChartFloatingControlSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.94),
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(
        BrazilMapLayoutConstants.floatingMapOverlaySurfaceRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          BrazilMapLayoutConstants.tightInternalPadding,
        ),
        child: child,
      ),
    );
  }
}

@visibleForTesting
class AppBrazilStoreSalesSelectedMarkerDetailAnchor extends StatefulWidget {
  const AppBrazilStoreSalesSelectedMarkerDetailAnchor({
    required this.group,
    required this.selectedStoreId,
    required this.metric,
    required this.marker,
    required this.onClose,
    super.key,
    this.onClearSelection,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final String selectedStoreId;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget marker;
  final VoidCallback onClose;
  final VoidCallback? onClearSelection;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  State<AppBrazilStoreSalesSelectedMarkerDetailAnchor> createState() =>
      BrazilMapChartSelectedMarkerDetailAnchorState();
}

class BrazilMapChartSelectedMarkerDetailAnchorState
    extends State<AppBrazilStoreSalesSelectedMarkerDetailAnchor> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _markerKey = GlobalKey();
  double? _markerGlobalDx;
  bool _postFrameOverlaySyncPending = false;

  @override
  void initState() {
    super.initState();
    _syncOverlayVisibility();
  }

  @override
  void didUpdateWidget(
    covariant AppBrazilStoreSalesSelectedMarkerDetailAnchor oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (AppBrazilStoreSalesMapData.markerGroupContentFingerprint(
              oldWidget.group,
            ) !=
            AppBrazilStoreSalesMapData.markerGroupContentFingerprint(
              widget.group,
            ) ||
        oldWidget.selectedStoreId != widget.selectedStoreId ||
        oldWidget.metric != widget.metric) {
      _syncOverlayVisibility();
    }
  }

  void _syncOverlayVisibility() {
    if (_postFrameOverlaySyncPending) {
      return;
    }
    _postFrameOverlaySyncPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameOverlaySyncPending = false;
      if (!mounted) {
        return;
      }
      _updateMarkerGlobalDx();
      _controller.show();
    });
  }

  void _updateMarkerGlobalDx() {
    final markerContext = _markerKey.currentContext;
    final renderObject = markerContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final nextDx = renderObject
        .localToGlobal(
          renderObject.size.center(Offset.zero),
        )
        .dx;
    if (_markerGlobalDx == nextDx) {
      return;
    }

    setState(() {
      _markerGlobalDx = nextDx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return BrazilMapChartSelectedMarkerDetailFollower(
            link: _link,
            group: widget.group,
            selectedStoreId: widget.selectedStoreId,
            metric: widget.metric,
            onClose: widget.onClose,
            onClearSelection: widget.onClearSelection,
            onSelectBranch: widget.onSelectBranch,
            selectBranchLabel: widget.selectBranchLabel,
            selectBranchLabelBuilder: widget.selectBranchLabelBuilder,
            markerGlobalDx: _markerGlobalDx,
          );
        },
        child: KeyedSubtree(key: _markerKey, child: widget.marker),
      ),
    );
  }
}

class BrazilMapChartSelectedMarkerDetailFollower extends StatelessWidget {
  const BrazilMapChartSelectedMarkerDetailFollower({required this.link, required this.group, required this.selectedStoreId, required this.metric, required this.onClose, required this.markerGlobalDx, super.key,
    this.onClearSelection,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
  });

  final LayerLink link;
  final AppBrazilStoreSalesMarkerGroup group;
  final String selectedStoreId;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback onClose;
  final double? markerGlobalDx;
  final VoidCallback? onClearSelection;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(260.0, 340.0);
    final followerAnchor = brazilMapFollowerAnchorFor(
      screenWidth: screenWidth,
      maxWidth: maxWidth,
      markerGlobalDx: markerGlobalDx,
    );
    void handleSelectBranch(AppBrazilStoreSalesPoint point) {
      onSelectBranch?.call(point);
    }

    final selectBranch = onSelectBranch == null ? null : handleSelectBranch;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topCenter,
          followerAnchor: followerAnchor,
          offset: brazilMapFollowerOffsetFor(followerAnchor),
          child: UnconstrainedBox(
            alignment: followerAnchor,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: BrazilMapChartMarkerDetailSemanticsBoundary(
                child: BrazilMapChartSelectedMarkerGroupDetailCard(
                  group: group,
                  metric: metric,
                  initialStoreId: selectedStoreId,
                  onClose: onClose,
                  onClearSelection: onClearSelection ?? onClose,
                  onSelectBranch: selectBranch,
                  selectBranchLabel: selectBranchLabel,
                  selectBranchLabelBuilder: selectBranchLabelBuilder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class AppBrazilStoreSalesBranchHoverDetailAnchor extends StatefulWidget {
  const AppBrazilStoreSalesBranchHoverDetailAnchor({
    required this.group,
    required this.metric,
    required this.marker,
    super.key,
    this.initialStoreId,
    this.forceVisible = false,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget marker;
  final String? initialStoreId;
  final bool forceVisible;

  @override
  State<AppBrazilStoreSalesBranchHoverDetailAnchor> createState() =>
      BrazilMapChartHoverMarkerDetailAnchorState();
}

class BrazilMapChartHoverMarkerDetailAnchorState
    extends State<AppBrazilStoreSalesBranchHoverDetailAnchor> {
  static const Duration _hideDelay = Duration(milliseconds: 140);

  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _markerKey = GlobalKey();
  Timer? _hideTimer;
  bool _hoveringMarker = false;
  bool _hoveringCard = false;
  double? _markerGlobalDx;

  @override
  void initState() {
    super.initState();
    if (widget.forceVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _show();
        }
      });
    }
  }

  @override
  void didUpdateWidget(
    covariant AppBrazilStoreSalesBranchHoverDetailAnchor oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _show();
        }
      });
    } else if (oldWidget.forceVisible) {
      _controller.hide();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    _updateMarkerGlobalDx();
    _controller.show();
  }

  void _updateMarkerGlobalDx() {
    final markerContext = _markerKey.currentContext;
    final renderObject = markerContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final nextDx = renderObject
        .localToGlobal(
          renderObject.size.center(Offset.zero),
        )
        .dx;
    if (_markerGlobalDx == nextDx) {
      return;
    }

    setState(() {
      _markerGlobalDx = nextDx;
    });
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted || _hoveringMarker || _hoveringCard) {
        return;
      }
      _controller.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return BrazilMapChartHoverMarkerDetailFollower(
            link: _link,
            group: widget.group,
            metric: widget.metric,
            initialStoreId: widget.initialStoreId,
            onDismiss: _controller.hide,
            markerGlobalDx: _markerGlobalDx,
            onEnter: () {
              _hoveringCard = true;
              _show();
            },
            onExit: () {
              _hoveringCard = false;
              _scheduleHide();
            },
          );
        },
        child: MouseRegion(
          onEnter: widget.forceVisible
              ? null
              : (_) {
                  _hoveringMarker = true;
                  _show();
                },
          onExit: widget.forceVisible
              ? null
              : (_) {
                  _hoveringMarker = false;
                  _scheduleHide();
                },
          child: KeyedSubtree(key: _markerKey, child: widget.marker),
        ),
      ),
    );
  }
}

class BrazilMapChartHoverMarkerDetailFollower extends StatelessWidget {
  const BrazilMapChartHoverMarkerDetailFollower({required this.link, required this.group, required this.metric, required this.initialStoreId, required this.onEnter, required this.onExit, required this.markerGlobalDx, super.key,
    this.onDismiss,
  });

  final LayerLink link;
  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? initialStoreId;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final double? markerGlobalDx;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(280.0, 360.0);
    final followerAnchor = brazilMapFollowerAnchorFor(
      screenWidth: screenWidth,
      maxWidth: maxWidth,
      markerGlobalDx: markerGlobalDx,
    );

    return Positioned.fill(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topCenter,
        followerAnchor: followerAnchor,
        offset: brazilMapFollowerOffsetFor(followerAnchor),
        child: UnconstrainedBox(
          alignment: followerAnchor,
          child: MouseRegion(
            onEnter: (_) => onEnter(),
            onExit: (_) => onExit(),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: BrazilMapChartMarkerDetailSemanticsBoundary(
                child: BrazilMapChartSelectedMarkerGroupDetailCard(
                  group: group,
                  metric: metric,
                  initialStoreId: initialStoreId,
                  showTechnicalLocationDetails: false,
                  onDismiss: onDismiss,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrazilMapChartMarkerDetailSemanticsBoundary extends StatelessWidget {
  const BrazilMapChartMarkerDetailSemanticsBoundary({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      return child;
    }

    // Windows' accessibility bridge can reject fast-changing overlay
    // semantics when marker hover cards mount/remount. Keep one stable
    // semantic boundary for the overlay and exclude the dynamic internals.
    return Semantics(
      container: true,
      label: AppLocalizations.of(
        context,
      ).brazilStoreSalesMapBranchDetailSemanticsLabel,
      child: ExcludeSemantics(child: child),
    );
  }
}

class BrazilMapChartStateBubbleMarker extends StatelessWidget {
  const BrazilMapChartStateBubbleMarker({required this.bucket, required this.metric, required this.style, required this.semanticLabel, super.key,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;
  final AppMapMarkerStyle style;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final markerColor = style.color ?? context.appColors.tertiary;
    final markerStrokeColor =
        style.strokeColor ?? Theme.of(context).colorScheme.surface;
    final dimension = style.size;
    final metricValue = metric.valueForBucket(bucket);
    final label = metric == AppBrazilStoreSalesMapMetric.salesCount
        ? brazilMapChartFormatSalesCount(context, metricValue)
        : bucket.uf;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: markerColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: markerStrokeColor.withValues(alpha: 0.92),
              width: style.strokeWidth,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: markerColor,
                fontWeight: FontWeight.w900,
                fontSize: dimension >= 54 ? 11 : 9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrazilMapChartStateBubbleTooltipCard extends StatelessWidget {
  const BrazilMapChartStateBubbleTooltipCard({required this.bucket, required this.metric, super.key,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return BrazilMapChartSelectedMarkerDetailSurface(
      title: bucket.stateName,
      subtitle: AppBrazilStoreSalesMapLocalizations.regionName(
        l10n,
        bucket.regionKey,
        fallback: bucket.regionName,
      ),
      icon: Icons.map_outlined,
      metric: metric,
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppTagChip(
            label: AppBrFormatters.currency(bucket.salesAmount),
            icon: Icons.attach_money,
          ),
          AppTagChip(
            label: l10n.brazilStoreSalesMapDetailChipSales(
              brazilMapChartFormatSalesCount(context, bucket.salesCount),
            ),
            icon: Icons.receipt_long_outlined,
          ),
          AppTagChip(
            label: l10n.brazilStoreSalesMapDetailChipBranches(
              brazilMapChartFormatSalesCount(context, bucket.storeCount),
            ),
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
    );
  }
}

class BrazilMapChartPlainMapTooltipCard extends StatelessWidget {
  const BrazilMapChartPlainMapTooltipCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 8,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.gapMd),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
