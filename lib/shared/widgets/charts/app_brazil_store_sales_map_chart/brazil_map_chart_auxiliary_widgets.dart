import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_auxiliary_surface.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:flutter/material.dart';

export 'brazil_map_chart_auxiliary_surface.dart';
export 'brazil_map_chart_scale_legend_widgets.dart';
export 'brazil_map_chart_state_label_resolver.dart';
export 'brazil_map_chart_store_marker_widget.dart';

class BrazilMapChartDataQualityNotice extends StatelessWidget {
  const BrazilMapChartDataQualityNotice({required this.diagnostics, super.key});

  final AppBrazilStoreSalesMapDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final details = <String>[
      if (diagnostics.invalidCoordinateCount > 0)
        l10n.brazilStoreSalesMapDataQualityInvalidCoords(
          brazilMapChartFormatSalesCount(
            context,
            diagnostics.invalidCoordinateCount,
          ),
        ),
      if (diagnostics.unknownUfCount > 0)
        l10n.brazilStoreSalesMapDataQualityUnknownUf(
          brazilMapChartFormatSalesCount(context, diagnostics.unknownUfCount),
        ),
      if (diagnostics.filteredByRegionCount > 0)
        l10n.brazilStoreSalesMapDataQualityOutsideClip(
          brazilMapChartFormatSalesCount(
            context,
            diagnostics.filteredByRegionCount,
          ),
        ),
    ].join(' | ');

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapSm),
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-data-quality'),
        child: BrazilMapChartAuxiliarySurface(
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: Text(
                  '${l10n.brazilStoreSalesMapDataQualityLead(brazilMapChartFormatSalesCount(context, diagnostics.discardedPointCount))}'
                  '${details.isEmpty ? '' : ': $details'}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrazilMapTouchGestureViewportWrapper extends StatelessWidget {
  const BrazilMapTouchGestureViewportWrapper({
    required this.child,
    required this.deferDuringGesture,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
    super.key,
  });

  final Widget child;
  final bool deferDuringGesture;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;

  @override
  Widget build(BuildContext context) {
    if (!deferDuringGesture) {
      return child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onPointerDown(),
      onPointerUp: (_) => onPointerUp(),
      onPointerCancel: (_) => onPointerCancel(),
      child: child,
    );
  }
}
