part of 'app_brazil_store_sales_map_chart.dart';

class _FloatingMapControlsOverlay extends StatelessWidget {
  const _FloatingMapControlsOverlay({
    required this.topInset,
    required this.leftInset,
    required this.selectedMetricKey,
    required this.onMetricChanged,
    required this.scopeOptions,
    required this.activeScopeKey,
    required this.scopeRootLabel,
    required this.onScopeChanged,
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
        _FloatingControlSurface(
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
          const SizedBox(height: BrazilMapLayoutConstants.floatingMapOverlayGap),
        );
      }
      controls.add(
        _FloatingControlSurface(
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

class _FloatingControlSurface extends StatelessWidget {
  const _FloatingControlSurface({required this.child});

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
      _SelectedMarkerDetailAnchorState();
}

class _SelectedMarkerDetailAnchorState
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
          return _SelectedMarkerDetailFollower(
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

class _SelectedMarkerDetailFollower extends StatelessWidget {
  const _SelectedMarkerDetailFollower({
    required this.link,
    required this.group,
    required this.selectedStoreId,
    required this.metric,
    required this.onClose,
    required this.markerGlobalDx,
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
    final followerAnchor = _followerAnchorFor(
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
          offset: _followerOffsetFor(followerAnchor),
          child: UnconstrainedBox(
            alignment: followerAnchor,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _MapMarkerDetailSemanticsBoundary(
                child: _SelectedMarkerGroupDetailCard(
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
      _HoverMarkerDetailAnchorState();
}

class _HoverMarkerDetailAnchorState
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
          return _HoverMarkerDetailFollower(
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

class _HoverMarkerDetailFollower extends StatelessWidget {
  const _HoverMarkerDetailFollower({
    required this.link,
    required this.group,
    required this.metric,
    required this.initialStoreId,
    required this.onEnter,
    required this.onExit,
    required this.markerGlobalDx,
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
    final followerAnchor = _followerAnchorFor(
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
        offset: _followerOffsetFor(followerAnchor),
        child: UnconstrainedBox(
          alignment: followerAnchor,
          child: MouseRegion(
            onEnter: (_) => onEnter(),
            onExit: (_) => onExit(),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _MapMarkerDetailSemanticsBoundary(
                child: _SelectedMarkerGroupDetailCard(
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

class _MapMarkerDetailSemanticsBoundary extends StatelessWidget {
  const _MapMarkerDetailSemanticsBoundary({required this.child});

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

class _StateBubbleMarker extends StatelessWidget {
  const _StateBubbleMarker({
    required this.bucket,
    required this.metric,
    required this.style,
    required this.semanticLabel,
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
        ? _formatSalesCount(context, metricValue)
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

class _StoreMapMarker extends StatelessWidget {
  const _StoreMapMarker({
    required this.style,
    required this.count,
    required this.visual,
    required this.semanticLabel,
    super.key,
  });

  final AppMapMarkerStyle style;
  final int count;
  final AppBrazilStoreSalesMarkerVisual visual;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final markerColor = style.color ?? context.appColors.tertiary;
    final markerStrokeColor =
        style.strokeColor ?? Theme.of(context).colorScheme.surface;
    final dimension = style.size;
    final showCount = count > 1 && dimension >= 22;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: dimension,
        child: switch (visual) {
          AppBrazilStoreSalesMarkerVisual.dot => DecoratedBox(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: markerStrokeColor,
                width: style.strokeWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: showCount
                ? Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: dimension >= 28 ? 10 : 8,
                      ),
                    ),
                  )
                : null,
          ),
          AppBrazilStoreSalesMarkerVisual.bubble => DecoratedBox(
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: markerColor.withValues(alpha: 0.82),
                width: 2.2,
              ),
            ),
            child: showCount
                ? Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: markerColor,
                                fontWeight: FontWeight.w800,
                                fontSize: dimension >= 48 ? 11 : 9,
                              ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          AppBrazilStoreSalesMarkerVisual.storeIcon => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerStrokeColor,
                      width: style.strokeWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: (dimension * 0.52).clamp(13, 22).toDouble(),
                    color: colorScheme.onTertiary,
                  ),
                ),
              ),
              if (showCount)
                Positioned(
                  right: -2,
                  top: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: markerColor,
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        BrazilMapLayoutConstants.tightInternalPadding,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: markerColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _StateBubbleTooltipCard extends StatelessWidget {
  const _StateBubbleTooltipCard({
    required this.bucket,
    required this.metric,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return _SelectedMarkerDetailSurface(
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
              _formatSalesCount(context, bucket.salesCount),
            ),
            icon: Icons.receipt_long_outlined,
          ),
          AppTagChip(
            label: l10n.brazilStoreSalesMapDetailChipBranches(
              _formatSalesCount(context, bucket.storeCount),
            ),
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
    );
  }
}

class _PlainMapTooltipCard extends StatelessWidget {
  const _PlainMapTooltipCard({required this.text});

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
