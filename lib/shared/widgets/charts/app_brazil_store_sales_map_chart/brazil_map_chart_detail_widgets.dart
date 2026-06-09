import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrazilMapChartSelectedStateDetail extends StatelessWidget {
  const BrazilMapChartSelectedStateDetail({
    required this.bucket,
    required this.metric,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-state-detail'),
        child: BrazilMapChartSelectedMarkerDetailSurface(
          title: bucket.stateName,
          subtitle: l10n.brazilStoreSalesMapStateSelectedSubtitle(bucket.uf),
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
        ),
      ),
    );
  }
}

class BrazilMapChartSelectedMunicipalityDetail extends StatelessWidget {
  const BrazilMapChartSelectedMunicipalityDetail({
    required this.group,
    required this.metric,
    this.selectedStoreId,
    this.onSelectBranch,
    this.selectBranchLabelBuilder,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? selectedStoreId;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: KeyedSubtree(
        key: const ValueKey<String>(
          'brazil-store-sales-map-municipality-detail',
        ),
        child: BrazilMapChartSelectedMarkerGroupDetailCard(
          group: group,
          metric: metric,
          initialStoreId: selectedStoreId,
          onSelectBranch: onSelectBranch,
          selectBranchLabelBuilder: selectBranchLabelBuilder,
        ),
      ),
    );
  }
}

class BrazilMapChartSelectedStoreDetail extends StatelessWidget {
  const BrazilMapChartSelectedStoreDetail({
    required this.point,
    required this.metric,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-store-detail'),
        child: BrazilMapChartSelectedMarkerStoreDetailCard(
          point: point,
          metric: metric,
        ),
      ),
    );
  }
}

class BrazilMapChartSelectedMarkerGroupDetailCard extends StatelessWidget {
  const BrazilMapChartSelectedMarkerGroupDetailCard({
    required this.group,
    required this.metric,
    this.initialStoreId,
    this.onClose,
    this.onDismiss,
    this.onClearSelection,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? initialStoreId;
  final VoidCallback? onClose;
  final VoidCallback? onDismiss;
  final VoidCallback? onClearSelection;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;
  final bool showTechnicalLocationDetails;

  @override
  Widget build(BuildContext context) {
    return BrazilMapChartSelectedMarkerBranchCarouselCard(
      group: group,
      metric: metric,
      initialStoreId: initialStoreId,
      onClose: onClose,
      onDismiss: onDismiss,
      onClearSelection: onClearSelection,
      onSelectBranch: onSelectBranch,
      selectBranchLabel: selectBranchLabel,
      selectBranchLabelBuilder: selectBranchLabelBuilder,
      showTechnicalLocationDetails: showTechnicalLocationDetails,
    );
  }
}

class BrazilMapChartSelectedMarkerStoreDetailCard extends StatelessWidget {
  const BrazilMapChartSelectedMarkerStoreDetailCard({
    required this.point,
    required this.metric,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final bool showTechnicalLocationDetails;

  @override
  Widget build(BuildContext context) {
    return BrazilMapChartSelectedMarkerBranchDetailSurface(
      point: point,
      metric: metric,
      showTechnicalLocationDetails: showTechnicalLocationDetails,
    );
  }
}

class BrazilMapChartSelectedMarkerBranchCarouselCard extends StatefulWidget {
  const BrazilMapChartSelectedMarkerBranchCarouselCard({
    required this.group,
    required this.metric,
    this.initialStoreId,
    this.onClose,
    this.onDismiss,
    this.onClearSelection,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? initialStoreId;
  final VoidCallback? onClose;
  final VoidCallback? onDismiss;
  final VoidCallback? onClearSelection;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;
  final bool showTechnicalLocationDetails;

  @override
  State<BrazilMapChartSelectedMarkerBranchCarouselCard> createState() =>
      BrazilMapChartSelectedMarkerBranchCarouselCardState();
}

class BrazilMapChartSelectedMarkerBranchCarouselCardState
    extends State<BrazilMapChartSelectedMarkerBranchCarouselCard> {
  late int _selectedIndex;
  late List<AppBrazilStoreSalesPoint> _orderedPoints;

  @override
  void initState() {
    super.initState();
    _orderedPoints = brazilMapOrderedBranchPoints(
      widget.group,
      initialStoreId: widget.initialStoreId,
    );
    _selectedIndex = _initialIndex();
  }

  @override
  void didUpdateWidget(
    covariant BrazilMapChartSelectedMarkerBranchCarouselCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group ||
        oldWidget.initialStoreId != widget.initialStoreId) {
      _orderedPoints = brazilMapOrderedBranchPoints(
        widget.group,
        initialStoreId: widget.initialStoreId,
      );
      _selectedIndex = _initialIndex();
    } else if (_selectedIndex >= _orderedPoints.length) {
      _selectedIndex = 0;
    }
  }

  int _initialIndex() {
    final storeId = widget.initialStoreId;
    if (storeId == null) {
      return 0;
    }

    final index = _orderedPoints.indexWhere(
      (point) => point.id == storeId,
    );
    return index < 0 ? 0 : index;
  }

  void _move(int delta) {
    final count = _orderedPoints.length;
    if (count <= 1) {
      return;
    }

    final nextIndex = (_selectedIndex + delta).clamp(0, count - 1);
    if (nextIndex == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final point = _orderedPoints[_selectedIndex];
    final count = _orderedPoints.length;
    final selectedStoreId = widget.initialStoreId;
    final isPinnedPoint =
        selectedStoreId != null && point.id == selectedStoreId;
    final branchAction = isPinnedPoint
        ? widget.onClearSelection
        : widget.onSelectBranch == null
        ? null
        : () => widget.onSelectBranch!(point);
    final branchActionLabel = isPinnedPoint
        ? AppLocalizations.of(context).brazilStoreSalesMapUnpinBranchButton
        : widget.selectBranchLabelBuilder?.call(point) ??
              widget.selectBranchLabel;

    return Focus(
      autofocus: defaultTargetPlatform != TargetPlatform.windows,
      onKeyEvent: _handleKeyEvent,
      child: BrazilMapChartSelectedMarkerBranchDetailSurface(
        point: point,
        metric: widget.metric,
        onClose: widget.onClose,
        showTechnicalLocationDetails: widget.showTechnicalLocationDetails,
        branchPositionLabel: count > 1
            ? AppLocalizations.of(context).brazilStoreSalesMapCarouselPosition(
                brazilMapChartFormatSalesCount(context, _selectedIndex + 1),
                brazilMapChartFormatSalesCount(context, count),
              )
            : null,
        aggregateSummary: count > 1
            ? BrazilMapChartBranchAggregateSummary(
                group: widget.group,
                metric: widget.metric,
              )
            : null,
        onSelectBranch: branchAction,
        selectBranchLabel: branchActionLabel,
        navigation: count > 1
            ? BrazilMapChartBranchCarouselNavigation(
                currentIndex: _selectedIndex,
                points: _orderedPoints,
                onPrevious: () => _move(-1),
                onNext: () => _move(1),
                onSelectIndex: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              )
            : null,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final dismiss = widget.onDismiss ?? widget.onClose;
      dismiss?.call();
      return dismiss == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

class BrazilMapChartSelectedMarkerBranchDetailSurface extends StatelessWidget {
  const BrazilMapChartSelectedMarkerBranchDetailSurface({
    required this.point,
    required this.metric,
    this.onClose,
    this.showTechnicalLocationDetails = true,
    this.branchPositionLabel,
    this.aggregateSummary,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.navigation,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback? onClose;
  final bool showTechnicalLocationDetails;
  final String? branchPositionLabel;
  final Widget? aggregateSummary;
  final VoidCallback? onSelectBranch;
  final String? selectBranchLabel;
  final Widget? navigation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cityLabel = brazilMapCityLabelFor(point);
    final municipalityCode = point.municipalityCode?.trim();
    final branchName = brazilMapBranchNameLabel(point);
    final agentName = brazilMapTrimmedOrNull(point.agentName);
    final legacySubtitle = brazilMapTrimmedOrNull(point.subtitle);
    final maxCardHeight = (MediaQuery.sizeOf(context).height - 48).clamp(
      260.0,
      460.0,
    );

    return Semantics(
      container: true,
      label: l10n.brazilStoreSalesMapBranchDetailSemanticsLabel,
      child: AppBrazilStoreSalesMapOverlayTooltipScope(
        child: BrazilMapChartMapDetailCard(
          key: const ValueKey<String>('brazil-store-sales-branch-card'),
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxCardHeight),
            child: SingleChildScrollView(
              key: const ValueKey<String>(
                'brazil-store-sales-branch-card-scroll',
              ),
              padding: EdgeInsets.all(tokens.contentSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        color: context.appColors.secondary,
                        size: 20,
                      ),
                      SizedBox(width: tokens.gapSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brazilMapBranchDisplayNameUi(context, point),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: tokens.gapXs),
                            Text(
                              cityLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: tokens.gapSm),
                      if (onClose == null)
                        AppTagChip(
                          label:
                              branchPositionLabel ??
                              brazilMapChartMetricShortLabel(l10n, metric),
                        )
                      else
                        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
                          key: const ValueKey<String>(
                            'brazil-store-sales-branch-card-close',
                          ),
                          icon: Icons.close_rounded,
                          iconSize: 18,
                          dimension: 32,
                          onPressed: onClose,
                          tooltipMessage:
                              l10n.brazilStoreSalesMapCloseBranchDetailsTooltip,
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.gapMd),
                  if (onClose != null) ...[
                    Wrap(
                      spacing: tokens.gapSm,
                      runSpacing: tokens.gapSm,
                      children: [
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapBranchPinnedChip,
                        ),
                        AppTagChip(
                          label: brazilMapChartMetricShortLabel(l10n, metric),
                        ),
                        if (branchPositionLabel != null)
                          AppTagChip(label: branchPositionLabel!),
                      ],
                    ),
                    SizedBox(height: tokens.gapSm),
                  ],
                  if (aggregateSummary != null) ...[
                    aggregateSummary!,
                    SizedBox(height: tokens.gapMd),
                  ],
                  Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: [
                      if (point.salesDataLoading)
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapSalesLoadingLabel,
                          icon: Icons.sync_rounded,
                        )
                      else ...[
                        AppTagChip(
                          label: AppBrFormatters.currency(point.salesAmount),
                          icon: Icons.attach_money,
                        ),
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapDetailChipSales(
                            brazilMapChartFormatSalesCount(
                              context,
                              point.salesCount,
                            ),
                          ),
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                      if (!point.salesDataLoading && point.salesDataUnavailable)
                        AppTagChip(
                          label:
                              point.salesDataStatusLabel ??
                              l10n.brazilStoreSalesMapSalesUnavailableFallback,
                          icon: Icons.sync_problem_outlined,
                        ),
                      if (agentName != null)
                        AppTagChip(
                          label: brazilMapAgentChipLabel(l10n, agentName),
                          icon: Icons.hub_outlined,
                        )
                      else if (legacySubtitle != null)
                        AppTagChip(
                          label: legacySubtitle,
                          icon: Icons.hub_outlined,
                        ),
                      if (branchName != null)
                        AppTagChip(
                          label: branchName,
                          icon: Icons.store_mall_directory_outlined,
                        ),
                      if (showTechnicalLocationDetails &&
                          municipalityCode != null &&
                          municipalityCode.isNotEmpty)
                        AppTagChip(
                          label: l10n.brazilStoreSalesMapIbgeCodeLabel(
                            municipalityCode,
                          ),
                          icon: Icons.pin_drop_outlined,
                        ),
                      if (showTechnicalLocationDetails)
                        AppTagChip(
                          label: brazilMapLocationResolutionLabel(
                            l10n,
                            point.locationResolution,
                          ),
                          icon: Icons.my_location_outlined,
                        ),
                      if (showTechnicalLocationDetails)
                        AppTagChip(
                          label:
                              '${point.latitude.toStringAsFixed(4)}, '
                              '${point.longitude.toStringAsFixed(4)}',
                          icon: Icons.explore_outlined,
                        ),
                    ],
                  ),
                  if (onSelectBranch != null) ...[
                    SizedBox(height: tokens.gapMd),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>(
                          'brazil-store-sales-branch-card-select',
                        ),
                        onPressed: onSelectBranch,
                        icon: const Icon(Icons.push_pin_outlined, size: 18),
                        label: Text(
                          selectBranchLabel ??
                              l10n.brazilStoreSalesMapSelectBranchButton,
                        ),
                      ),
                    ),
                  ],
                  if (navigation != null) ...[
                    SizedBox(height: tokens.gapMd),
                    Divider(color: colorScheme.outlineVariant, height: 1),
                    SizedBox(height: tokens.gapXs),
                    navigation!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrazilMapChartBranchCarouselNavigation extends StatelessWidget {
  const BrazilMapChartBranchCarouselNavigation({
    required this.currentIndex,
    required this.points,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectIndex,
  });

  final int currentIndex;
  final List<AppBrazilStoreSalesPoint> points;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final branchCount = points.length;
    final showBranchPicker = branchCount >= 10;

    final pickerTooltip = defaultTargetPlatform == TargetPlatform.windows
        ? ''
        : l10n.brazilStoreSalesMapChooseBranchMenuTooltip;

    return Row(
      children: [
        if (showBranchPicker) ...[
          PopupMenuButton<int>(
            key: const ValueKey<String>(
              'brazil-store-sales-branch-card-picker',
            ),
            tooltip: pickerTooltip,
            onSelected: onSelectIndex,
            itemBuilder: (context) => [
              for (var index = 0; index < points.length; index++)
                PopupMenuItem<int>(
                  value: index,
                  child: Text(
                    '${brazilMapChartFormatSalesCount(context, index + 1)}. '
                    '${brazilMapBranchDisplayNameUi(context, points[index])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            icon: const Icon(Icons.list_alt_outlined),
          ),
          SizedBox(width: tokens.gapXs),
        ],
        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
          key: const ValueKey<String>(
            'brazil-store-sales-branch-card-previous',
          ),
          icon: Icons.chevron_left_rounded,
          dimension: 34,
          onPressed: currentIndex > 0 ? onPrevious : null,
          tooltipMessage:
              l10n.brazilStoreSalesMapBranchNavigationPreviousTooltip,
        ),
        Expanded(
          child: Text(
            l10n.brazilStoreSalesMapCarouselPosition(
              brazilMapChartFormatSalesCount(context, currentIndex + 1),
              brazilMapChartFormatSalesCount(context, branchCount),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: tokens.gapXs),
        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
          key: const ValueKey<String>('brazil-store-sales-branch-card-next'),
          icon: Icons.chevron_right_rounded,
          dimension: 34,
          onPressed: currentIndex < branchCount - 1 ? onNext : null,
          tooltipMessage: l10n.brazilStoreSalesMapBranchNavigationNextTooltip,
        ),
      ],
    );
  }
}

class BrazilMapChartBranchAggregateSummary extends StatelessWidget {
  const BrazilMapChartBranchAggregateSummary({
    required this.group,
    required this.metric,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasLoadingSales = group.points.any(
      (point) => point.salesDataLoading,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.gapSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.brazilStoreSalesMapMarkerGroupTotalTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: [
                if (hasLoadingSales)
                  AppTagChip(
                    label: l10n.brazilStoreSalesMapSalesLoadingLabel,
                    icon: Icons.sync_rounded,
                  )
                else ...[
                  AppTagChip(
                    label: AppBrFormatters.currency(group.salesAmount),
                    icon: Icons.attach_money,
                  ),
                  AppTagChip(
                    label: l10n.brazilStoreSalesMapDetailChipSales(
                      brazilMapChartFormatSalesCount(context, group.salesCount),
                    ),
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
                AppTagChip(
                  label: l10n.brazilStoreSalesMapDetailChipBranches(
                    brazilMapChartFormatSalesCount(
                      context,
                      group.points.length,
                    ),
                  ),
                  icon: Icons.storefront_outlined,
                ),
                AppTagChip(label: brazilMapChartMetricShortLabel(l10n, metric)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BrazilMapChartSelectedMarkerDetailSurface extends StatelessWidget {
  const BrazilMapChartSelectedMarkerDetailSurface({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metric,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return BrazilMapChartMapDetailCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.contentSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: context.appColors.secondary, size: 20),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.gapXs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.gapSm),
                AppTagChip(label: brazilMapChartMetricShortLabel(l10n, metric)),
              ],
            ),
            SizedBox(height: tokens.gapMd),
            child,
          ],
        ),
      ),
    );
  }
}

/// Shared surface for overlay and below-map detail cards in the Brazil
/// store-sales map. Wraps a [Material] + [DecoratedBox] pair to provide the
/// correct radius, border, background colour, and shadow for map-local cards
/// without using the full [AppSectionCard] radius (which is too large for
/// compact detail surfaces).
class BrazilMapChartMapDetailCard extends StatelessWidget {
  const BrazilMapChartMapDetailCard({
    required this.child,
    super.key,
    this.elevation = 0,
  });

  final Widget child;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: elevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: child,
      ),
    );
  }
}

class BrazilMapChartStoreSalesMapContent extends StatelessWidget {
  const BrazilMapChartStoreSalesMapContent({
    required this.regionMapBuilder,
    required this.fixedRegionMapHeight,
    this.regionMapStyleHeightForAvailableArea,
    this.expandMapVertically = false,
    super.key,
    this.mapOverlay,
    this.diagnostics,
    this.markerLegend,
    this.detail,
  });

  final Widget Function(double height) regionMapBuilder;
  final double fixedRegionMapHeight;
  final double Function(double availableMapAreaHeight)?
  regionMapStyleHeightForAvailableArea;
  final bool expandMapVertically;
  final Widget? mapOverlay;
  final Widget? diagnostics;
  final Widget? markerLegend;
  final Widget? detail;

  Widget _regionMapStack(double height) {
    final regionMap = regionMapBuilder(height);
    if (mapOverlay == null) {
      return regionMap;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        regionMap,
        mapOverlay!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapSection = expandMapVertically
        ? Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final resolvedHeight =
                    regionMapStyleHeightForAvailableArea?.call(
                      constraints.maxHeight,
                    ) ??
                    fixedRegionMapHeight;
                return _regionMapStack(resolvedHeight);
              },
            ),
          )
        : _regionMapStack(fixedRegionMapHeight);
    final children = <Widget>[mapSection];
    if (diagnostics != null) {
      children.add(diagnostics!);
    }
    if (markerLegend != null) {
      children.add(markerLegend!);
    }
    if (detail != null) {
      children.add(detail!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
