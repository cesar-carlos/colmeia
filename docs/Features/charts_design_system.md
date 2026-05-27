# Charts design system

Single reference for the chart layer of colmeia: which widgets exist, where
they are rendered today, and the conventions every engine must follow.

## Inventory

### Currently rendered (production)

The home dashboard mounts charts via
[`OverviewHomeChartsBelowKpis`](../../lib/features/overview/presentation/widgets/overview_home_charts_below_kpis.dart),
each wrapped by [`AppChartFadeIn`](../../lib/shared/widgets/charts/app_chart_fade_in.dart)
and a `RepaintBoundary` where applicable:

| #   | Widget                                   | Underlying engine                                    |
| --- | ---------------------------------------- | ---------------------------------------------------- |
| 1   | `OverviewPaymentMixCard`                 | `AppCategoryDonutCard` (Syncfusion `DoughnutSeries`) |
| 2   | `OverviewPaymentBarChart`                | `AppComparisonBarChart` (Syncfusion `ColumnSeries`)  |
| 3   | `OverviewMonthlyParcelsComboChart`       | `AppComboChart` (`ColumnSeries` + `LineSeries`)      |
| 4   | `OverviewWeekdaySalesTrendChart`         | `AppComparisonBarChart`                              |
| 5   | `OverviewWeekdayUserGroupedBarChart`     | direct `SfCartesianChart` (clustered columns)        |
| 6   | `OverviewAgentRankingCard` + `OverviewUserRankingCard` | `AppComparisonBarChart` x2 |
| 7   | `OverviewLucratividadeChart`             | `AppComboChart` (one category per agent, branches summed); mode **Percentuais** defaults to gross-margin % with sub-options cost % / markup % via [`overview_lucratividade_percent_metrics.dart`](../../lib/features/overview/presentation/widgets/overview_lucratividade_percent_metrics.dart) |

**Sales — resultado mensal (`SalesMonthlyPnlPage`):** [`SalesMonthlyPnlBarChartCard`](../../lib/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_card.dart) adds grouped monthly bars via [`AppGroupedColumnChart`](../../lib/shared/widgets/charts/app_grouped_column_chart.dart) (sales on primary Y-axis, profit + merchandise cost on secondary), optional **Percentuais** mode via `AppComparisonBarChart` with **~150 ms** series animation (via `resolveChartAnimationDurationMs`, matching the overview lucratividade percent chart); bar-chart mode and percent metric persist via [`SalesPreferences`](../../lib/features/sales/data/sales_preferences.dart); horizontal scroll regions use stable keys in [`sales_monthly_pnl_chart_keys.dart`](../../lib/features/sales/presentation/sales_monthly_pnl_chart_keys.dart) for tests; complements the existing three-series line chart on the same aggregates.

### Shared design-system catalog (24 widgets)

Each item below has a demo page under `Settings → Cardapio de UI → Graficos`
([`shared_components_demo_index_page.dart`](../../lib/features/settings/presentation/pages/shared_components_demo_index_page.dart)).
Demos are the only consumers today; they double as design references and as
smoke tests for the engines.

| Widget                       | Engine path                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| `AppComparisonBarChart`      | `engines/syncfusion_comparison_bar_chart.dart`               |
| `AppStackedBarChart`         | `engines/syncfusion_stacked_bar_chart.dart`                  |
| `AppAreaTrendChart`          | `engines/syncfusion_area_trend_chart.dart`                   |
| `AppRangeAreaChart`          | `engines/syncfusion_range_area_chart.dart`                   |
| `AppStepLineChart`           | `engines/syncfusion_step_line_chart.dart`                    |
| `AppTimeSeriesChart`         | `engines/syncfusion_time_series_chart.dart`                  |
| `AppComboChart`              | `engines/syncfusion_combo_chart.dart`                        |
| `AppGroupedColumnChart`      | `app_grouped_column_chart.dart` (dual axis, 3 `ColumnSeries`) |
| `AppWaterfallChart`          | `engines/syncfusion_waterfall_chart.dart`                    |
| `AppDistributionChart`       | `engines/syncfusion_distribution_chart.dart`                 |
| `AppCategoryDonutCard`       | `app_category_donut_card.dart` (engine inline)               |
| `AppFunnelChart`             | `engines/syncfusion_funnel_chart.dart`                       |
| `AppPyramidChart`            | `engines/syncfusion_pyramid_chart.dart`                      |
| `AppRadialBarChart`          | `engines/syncfusion_radial_bar_chart.dart`                   |
| `AppGaugeChart`              | `engines/syncfusion_gauge_chart.dart`                        |
| `AppScatterBubbleChart`      | `engines/syncfusion_scatter_bubble_chart.dart`               |
| `AppRegionMapChart`          | `engines/syncfusion_region_map_chart.dart` (Syncfusion Maps) |
| `AppTreemapChart`            | `engines/syncfusion_treemap_chart.dart` (Syncfusion Treemap) |
| `AppHeatmapChart`            | bespoke (CustomPaint + scrollable matrix)                    |
| `AppHorizontalProgressChart` | bespoke (Material + tween)                                   |
| `AppSparklineChart`          | bespoke (CustomPaint micro-line)                             |
| `AppRadarChart`              | `engines/custom_radar_chart.dart` (CustomPainter)            |
| `AppPolarChart`              | `engines/custom_polar_chart.dart` (CustomPainter)            |
| `AppSunburstChart`           | `engines/custom_sunburst_chart.dart` (CustomPainter)         |
| `AppBulletChart`             | `engines/custom_bullet_chart.dart` (Material rows)           |

### NOT_RENDERED widgets

Four cards in
[`lib/features/overview/presentation/widgets/`](../../lib/features/overview/presentation/widgets/README.md)
are committed but not mounted by any page or route today
(`OverviewSalesTrendCard`, `OverviewChartRenderer`, `OverviewCategoryMixCard`,
`OverviewAiInsightCard`). They carry top-of-file `// NOT_RENDERED` comments
and are catalogued in the local README. Decision: keep as scaffolding for
the upcoming overview revamp.

## Universal checklist for chart engines

The following conventions are applied to every Syncfusion engine consumed by
the design system. New engines must follow them; pull requests that opt out
of any item should explain why in the engine's source.

| #   | Convention                                   | How                                                                                                                                                                                                                                                                                         |
| --- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Tooltip header is sanitized                  | use [`buildSanitizingTooltipRenderer`](../../lib/shared/widgets/charts/engines/chart_engine_defaults.dart) — clears Syncfusion's `"Series 0"` header.                                                                                                                                       |
| 2   | Tooltip uses dark inverse-surface coloring   | use [`buildChartTooltipBehavior`](../../lib/shared/widgets/charts/engines/chart_engine_defaults.dart) — consistent body text, no border, 2.4 s duration.                                                                                                                                    |
| 3   | Animation default is uniform                 | use [`resolveChartAnimationDurationMs`](../../lib/shared/widgets/charts/engines/chart_engine_defaults.dart) with `AppChartEngineAnimationDefaults.cartesianSeriesMs` (350 ms) for bar/line/area/scatter/step series and `circularSeriesMs` (500 ms) for donut/pie/funnel/pyramid.           |
| 4   | OS reduce-motion is respected                | `resolveChartAnimationDurationMs` collapses to 0 ms when `MediaQuery.disableAnimations` is `true`. The gauge engine guards its `enableAnimation` flag manually for the same reason.                                                                                                         |
| 5   | Identity-based key when remount is expensive | `RepaintBoundary(key: ValueKey<int>(identityHashCode(items)))` lets Syncfusion update the existing `SfCircularChart` / `SfCartesianChart` instead of remounting on every rebuild. Used by `AppCategoryDonutCard` and `OverviewMonthlyParcelsComboChart`.                                    |
| 6   | Horizontal scroll uses the shared shell      | Wide charts wrap the inner chart with [`ChartHorizontalScrollShell`](../../lib/shared/widgets/charts/chart_horizontal_scroll_shell.dart) and deduct `chartHorizontalScrollBottomTrackSlotHeight(context)` (not the raw constant) from the chart body height to honour `TextScaler` scaling. |
| 7   | Tap-highlight is opt-in                      | Bar / radial engines expose `enableTapHighlight` on their style; when `true`, tapped point keeps full opacity while the rest fade to `tapHighlightDimmedOpacity` (default `0.35`) via Syncfusion `SelectionBehavior`.                                                                       |
| 8   | Smart compact currency for chart labels      | `AppBrFormatters.smartCompactCurrency` keeps full `R$ 26,80` below R$ 1.000 and switches to `R$ 1,2 mil` above, avoiding the "compact label cropped" reading.                                                                                                                               |
| 9   | Staged entrance animation                    | host pages can wrap chart cards with [`AppChartFadeIn`](../../lib/shared/widgets/charts/app_chart_fade_in.dart) (220 ms fade + 6 px slide). Auto-disables under reduce-motion.                                                                                                              |
| 10  | Staged placeholder height                    | engines that have an `_LoadingBlock` expose a static `loadingBlockHeight(tokens)` (donut card, comparison bar, combo) so external staged-mounting placeholders don't cause layout shift when the real card mounts.                                                                          |

## Helpers

- [`engines/chart_engine_defaults.dart`](../../lib/shared/widgets/charts/engines/chart_engine_defaults.dart)
  — single source of truth for items #1, #2, #3 and #4 above.
- [`chart_horizontal_scroll_shell.dart`](../../lib/shared/widgets/charts/chart_horizontal_scroll_shell.dart)
  — horizontal scroll wrapper with edge fades, scrollbar visibility per
  platform, semantics hint and the `TextScaler`-aware bottom-track slot
  helper.
- [`comparison_bar_plot_floor.dart`](../../lib/shared/widgets/charts/comparison_bar_plot_floor.dart)
  — minimum-height lift for tiny bars (so a "R$ 26,80" data point still
  renders next to a "R$ 25 mil" one).
- [`comparison_bar_chart_margin.dart`](../../lib/shared/widgets/charts/comparison_bar_chart_margin.dart)
  — top-margin reservation when outer data labels are visible.
- [`app_chart_fade_in.dart`](../../lib/shared/widgets/charts/app_chart_fade_in.dart)
  — entrance animation, promoted from the previous private
  `_StagedFadeIn` so any dashboard can use it.
- [`AppBrFormatters.smartCompactCurrency`](../../lib/core/formatters/app_br_formatters.dart)
  — locale-aware currency formatter for chart labels.

## Decisions worth remembering

- **Pan was traded for horizontal scroll** in the overview combo and
  comparison engines (rationale in
  [`overview_monthly_parcels_combo_chart.dart`](../../lib/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart)):
  Syncfusion's category-axis pan kept the Y-axis tied to the full dataset,
  which made low-volume months invisible (e.g. an 8-sale month inside a
  2.500 max). Scroll widens the plot so all months stay reachable with a
  consistent axis.
- **Animation defaults are intentionally short** (350 ms / 500 ms). Heavier
  tween durations (1200 / 1500 ms) used to cause visible jank on low-end
  Android during the staged dashboard mounting in
  `OverviewHomeChartsBelowKpis`.
- **Custom-painter charts (`custom_radar`, `custom_polar`, `custom_sunburst`,
  `custom_bullet`) do not animate** today — they paint statically. The
  reduce-motion guard does not apply because there is no motion to gate.
- **Dead-code widgets are kept** rather than deleted so the upcoming
  overview revamp does not have to re-author them. They carry
  `// NOT_RENDERED` comments and are listed in the widget folder README.

## Related tests

- [`test/shared/widgets/charts/engines/chart_engine_defaults_test.dart`](../../test/shared/widgets/charts/engines/chart_engine_defaults_test.dart)
  — covers items #1, #2 and #3 of the checklist for every engine that uses
  the helpers.
- [`test/shared/widgets/charts/app_chart_fade_in_test.dart`](../../test/shared/widgets/charts/app_chart_fade_in_test.dart)
  — covers item #9 and the reduce-motion guard.
- [`test/shared/widgets/charts/engines/syncfusion_area_trend_chart_smoke_test.dart`](../../test/shared/widgets/charts/engines/syncfusion_area_trend_chart_smoke_test.dart)
  — representative engine smoke test for the area-family change.
- Production charts have their own tests under
  [`test/features/overview/presentation/`](../../test/features/overview/presentation/).

## Adding a new chart

1. Pick / build the engine under `lib/shared/widgets/charts/engines/`.
2. Wire the four `chart_engine_defaults` helpers (tooltip + animation
   resolver). For circular series use `circularSeriesMs`; for everything
   else use `cartesianSeriesMs`.
3. Add a public `App<Name>Chart` wrapper under
   `lib/shared/widgets/charts/` — keep style and engine in separate files.
4. Add a `loadingBlockHeight(tokens)` static when host pages will need to
   render their own staged-mounting placeholder.
5. Author a demo page in `lib/features/settings/presentation/pages/`,
   register the route, link it from `shared_components_demo_index_page.dart`.
6. Drop a smoke test in
   `test/shared/widgets/charts/engines/<name>_smoke_test.dart` using the
   pattern from `syncfusion_area_trend_chart_smoke_test.dart`.
7. If your chart can be expensive to remount (any `SfCartesianChart` /
   `SfCircularChart`), peg the `RepaintBoundary` key to
   `identityHashCode(<dataset>)` and have the parent cache the dataset.
8. Update this document and add an entry to the inventory table above.
