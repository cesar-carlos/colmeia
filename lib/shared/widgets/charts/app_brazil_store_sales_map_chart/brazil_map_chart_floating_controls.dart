import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

class BrazilMapChartFloatingMapControlsOverlay extends StatelessWidget {
  const BrazilMapChartFloatingMapControlsOverlay({
    required this.topInset,
    required this.leftInset,
    required this.selectedMetricKey,
    required this.onMetricChanged,
    required this.scopeOptions,
    required this.activeScopeKey,
    required this.scopeRootLabel,
    required this.onScopeChanged,
    super.key,
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
