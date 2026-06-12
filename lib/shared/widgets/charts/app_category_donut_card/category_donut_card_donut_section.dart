import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_constants.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_style.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CategoryDonutCardDonutSection extends StatelessWidget {
  const CategoryDonutCardDonutSection({
    required this.segments,
    required this.chartTheme,
    required this.style,
    required this.selectedIndex,
    required this.onSliceSelected,
    this.centerPrimary,
    this.centerSecondary,
    super.key,
  });

  final List<AppCategoryDonutSegment> segments;
  final AppChartTheme chartTheme;
  final AppCategoryDonutCardStyle style;
  final int selectedIndex;
  final ValueChanged<int> onSliceSelected;
  final String? centerPrimary;
  final String? centerSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = chartTheme.palette;
    final configuredMs =
        style.doughnutAnimationDurationMs ??
        AppCategoryDonutCardStyle.defaultDoughnutAnimationDurationMs;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animationDuration = (reduceMotion || configuredMs <= 0)
        ? 0.0
        : configuredMs.toDouble();
    final segmentsTotal = segments.donutWeightTotal;
    // Identity-based key: while the parent caches [segments] (e.g. the overview
    // payment / category mix cards), the same instance is reused across rebuilds
    // triggered by selection changes — keeping the key stable lets Syncfusion
    // update the existing series instead of remounting [SfCircularChart], which
    // is expensive (painters, hit-test cache). The key only changes when the
    // parent recomputes its segments list.
    final chart = RepaintBoundary(
      key: ValueKey<int>(identityHashCode(segments)),
      child: ExcludeSemantics(
        child: SfCircularChart(
          backgroundColor:
              style.chartBackgroundColor ??
              colors.surfaceContainerLow.withValues(alpha: 0.65),
          tooltipBehavior: buildChartTooltipBehavior(
            context,
            enable: true,
          ),
          onTooltipRender: buildSanitizingTooltipRenderer(
            bodyResolver: (args) {
              final raw = args.pointIndex;
              final i = raw is int ? raw : raw?.toInt();
              if (i == null || i < 0 || i >= segments.length) {
                return null;
              }
              final segment = segments[i];
              return '${segment.label}: ${segment.resolveValueLabel()} '
                  '(${segment.resolvePercentLabel(segmentsTotal)})';
            },
          ),
          series: <CircularSeries<AppCategoryDonutSegment, String>>[
            DoughnutSeries<AppCategoryDonutSegment, String>(
              dataSource: segments,
              xValueMapper: (s, _) => s.label,
              yValueMapper: (s, _) => s.value.toDouble(),
              animationDuration: animationDuration,
              innerRadius: style.innerRadius,
              radius: style.outerRadius,
              explode: true,
              explodeOffset: '4%',
              explodeIndex: selectedIndex,
              pointColorMapper: (s, i) =>
                  s.color ?? palette[i % palette.length],
              onPointTap: (details) {
                final i = details.pointIndex;
                if (i != null && i >= 0 && i < segments.length) {
                  onSliceSelected(i);
                }
              },
            ),
          ],
        ),
      ),
    );

    final hasCenter =
        (centerPrimary != null && centerPrimary!.isNotEmpty) ||
        (centerSecondary != null && centerSecondary!.isNotEmpty);

    final typography = theme.appTypography;
    final tokens = theme.extension<AppThemeTokens>()!;

    if (!hasCenter) {
      return chart;
    }

    final centerSummary = <String>[
      if (centerPrimary != null && centerPrimary!.isNotEmpty) centerPrimary!,
      if (centerSecondary != null && centerSecondary!.isNotEmpty)
        centerSecondary!,
    ].join(', ');

    final titleLargeSize = theme.textTheme.titleLarge?.fontSize;
    final centerPrimaryFontSize = titleLargeSize != null
        ? titleLargeSize * categoryDonutTypographyTightenFactor
        : tightenCategoryDonutTypographyFontSize(typography.displayH1).fontSize;

    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.appCategoryDonutChartSemantics(centerSummary),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          chart,
          IgnorePointer(
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (centerPrimary != null && centerPrimary!.isNotEmpty)
                    AnimatedSwitcher(
                      duration: categoryDonutCenterLabelSwitchDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final fade = FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1).animate(
                            animation,
                          ),
                          child: fade,
                        );
                      },
                      child: Text(
                        centerPrimary!,
                        key: ValueKey<String>(centerPrimary!),
                        textAlign: TextAlign.center,
                        style: typography.displayH1.copyWith(
                          fontSize: centerPrimaryFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (centerSecondary != null &&
                      centerSecondary!.isNotEmpty) ...<Widget>[
                    SizedBox(height: tokens.gapXs),
                    Text(
                      centerSecondary!,
                      textAlign: TextAlign.center,
                      style: tightenCategoryDonutTypographyFontSize(
                        typography.utilityOverline,
                      ).copyWith(
                        color: context.appColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
