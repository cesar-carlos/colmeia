import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:flutter/material.dart';

class BrazilMapChartStoreMarker extends StatelessWidget {
  const BrazilMapChartStoreMarker({
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
