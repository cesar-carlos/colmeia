# overview/presentation/widgets

This folder hosts the dashboard widgets consumed by the overview feature
(home screen + supporting cards).

## Inventory

### Currently rendered

These chart cards are mounted by `OverviewHomeChartsBelowKpis` on the home
screen and are the focus of design/polish work:

- `OverviewDailySalesTrendChart` - line/area "Daily sales".
- `OverviewMonthlyParcelsComboChart` - bar+line "Last 12 months".
- `OverviewPaymentMixCard` - donut "Mix by payment method".
- `OverviewWeekdaySalesTrendChart` - column "Sales/Revenue by weekday".
- `OverviewWeekdayUserSalesTrendChart` - clustered column "Sales/Revenue
  by weekday and user".
- `OverviewAgentRankingCard` - agent ranking columns.
- `OverviewUserRankingCard` - user ranking columns.
- `OverviewLucratividadeChart` - period profitability by agent.

Plus the supporting non-chart cards:

- `OverviewKpiBar` - KPI summary above the charts.
- `OverviewHomeAlertsSection` - consolidated banners for load and agent states.
- `OverviewFilterBar` - branch/agent and date filters.
- `OverviewHomeChartsBelowKpis` - mounts the cards above with per-section
  skeleton placeholders so each chart appears as its `OverviewProgressiveSection`
  completes.

### NOT_RENDERED (kept for the upcoming overview revamp)

The widgets below are committed to the repo but are **not wired to any page
or route today**. Each file carries a top-of-file `// NOT_RENDERED` comment
to surface this fact during code review. Modifications to these files will
not show up in the running app until a host page mounts them.

| File | Purpose |
|---|---|
| `overview_sales_trend_card.dart` | Weekly/monthly toggle around `AppTimeSeriesChart`. |
| `overview_chart_renderer.dart` | Thin wrapper used only by `OverviewSalesTrendCard`. |
| `overview_category_mix_card.dart` | Donut "Vendas por categoria" - distinct from the payment mix. |
| `overview_ai_insight_card.dart` | Editorial card for AI-generated insights. |

Decision rationale: chose to **keep** rather than delete (or move to
`lib/_legacy/`) because the overview revamp planning expects to consume
them. Deleting now would force a re-build later; gating them behind
`@Deprecated` would also pollute the import graph for tests. The
`NOT_RENDERED` comment + this README is the lighter path until the host
pages land.

## Editing guidance

When changing a widget that lives here:

1. Confirm it's in the **Currently rendered** list above. If it's
   `NOT_RENDERED`, the change won't surface in the app - make sure that's
   intentional (e.g. preparing for the revamp).
2. Re-run `flutter test test/features/overview/` before committing.
3. Cross-check the design-system inventory in
   [docs/Features/charts_design_system.md](../../../../../docs/Features/charts_design_system.md).
