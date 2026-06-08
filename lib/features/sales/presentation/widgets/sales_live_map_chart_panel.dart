import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_chart_mapper.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_visual_spec_mapper.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

enum SalesLiveMapChartPanelMode {
  inline,
  fullscreen,
}

/// Notifies an ancestor [SingleChildScrollView] to pause vertical scrolling
/// while the user interacts with the inline map on mobile.
class SalesLiveMapParentScrollLockNotification extends Notification {
  const SalesLiveMapParentScrollLockNotification({
    required this.lockParentScroll,
  });

  final bool lockParentScroll;
}

class SalesLiveMapChartPanel extends StatefulWidget {
  const SalesLiveMapChartPanel({
    required this.mode,
    required this.mapPayloadDigest,
    required this.points,
    required this.metric,
    required this.filterBranchIds,
    required this.visualSpec,
    required this.isRefreshing,
    required this.onMetricChanged,
    super.key,
    this.onOpenFullscreen,
    this.showSidebar = false,
    this.showHeader = true,
    this.title,
    this.subtitle,
  });

  final SalesLiveMapChartPanelMode mode;
  final int mapPayloadDigest;
  final List<SalesLiveMapPoint> points;
  final SalesLiveMapMetric metric;
  final Set<String> filterBranchIds;
  final SalesLiveMapVisualSpec visualSpec;
  final bool isRefreshing;
  final ValueChanged<SalesLiveMapMetric> onMetricChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showSidebar;
  final bool showHeader;
  final String? title;
  final String? subtitle;

  @override
  State<SalesLiveMapChartPanel> createState() => _SalesLiveMapChartPanelState();
}

class _SalesLiveMapChartPanelState extends State<SalesLiveMapChartPanel> {
  final GlobalKey _shareKey = GlobalKey();

  int? _cachedMapPayloadDigest;
  SalesLiveMapMetric? _cachedMetric;
  SalesLiveMapVisualSpec? _cachedVisualSpec;
  Locale? _cachedLocale;
  List<AppBrazilStoreSalesPoint>? _cachedChartPoints;
  AppBrazilStoreSalesMapStyle? _cachedChartStyle;

  List<AppBrazilStoreSalesPoint> _resolveChartPoints(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    if (_cachedChartPoints != null &&
        _cachedMapPayloadDigest == widget.mapPayloadDigest &&
        _cachedMetric == widget.metric &&
        _cachedVisualSpec == widget.visualSpec &&
        _cachedLocale == locale) {
      return _cachedChartPoints!;
    }

    final chartPoints = SalesLiveMapChartMapper.toChartPoints(
      widget.points,
      l10n,
    );
    _cachedMapPayloadDigest = widget.mapPayloadDigest;
    _cachedMetric = widget.metric;
    _cachedVisualSpec = widget.visualSpec;
    _cachedLocale = locale;
    _cachedChartPoints = chartPoints;
    return chartPoints;
  }

  AppBrazilStoreSalesMapStyle _resolveChartStyle() {
    if (_cachedChartStyle != null &&
        _cachedMapPayloadDigest == widget.mapPayloadDigest &&
        _cachedMetric == widget.metric &&
        _cachedVisualSpec == widget.visualSpec) {
      return _cachedChartStyle!;
    }

    final chartStyle = SalesLiveMapVisualSpecMapper.toChartStyle(
      widget.visualSpec,
    );
    _cachedMapPayloadDigest = widget.mapPayloadDigest;
    _cachedMetric = widget.metric;
    _cachedVisualSpec = widget.visualSpec;
    _cachedChartStyle = chartStyle;
    return chartStyle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chartPoints = _resolveChartPoints(l10n);
    final chartStyle = _resolveChartStyle();
    final shareTitle = widget.title;
    final chart = AppBrazilStoreSalesMapChart(
      title: widget.showHeader ? widget.title : null,
      subtitle: widget.showHeader ? widget.subtitle : null,
      points: chartPoints,
      initialMetric: SalesLiveMapChartMapper.toChartMetric(widget.metric),
      filterBranchIds: widget.filterBranchIds,
      fixedBranchIds: widget.filterBranchIds,
      style: chartStyle,
      isRefreshing: widget.isRefreshing,
      onMetricChanged: (metric) => widget.onMetricChanged(
        SalesLiveMapChartMapper.fromChartMetric(metric),
      ),
      onShare: widget.showHeader && shareTitle != null && !widget.isRefreshing
          ? () => context.shareChartFromRequest(
              ChartShareMetadata(
                title: shareTitle,
                subtitle: widget.subtitle,
                tableData: ChartShareTableData(
                  headers: <String>[
                    l10n.chartSharePdfColumnStore,
                    l10n.chartSharePdfColumnSalesCount,
                    l10n.chartSharePdfColumnAmount,
                  ],
                  rows: <List<String>>[
                    for (final point in chartPoints)
                      <String>[
                        point.name,
                        point.salesCount.toString(),
                        AppBrFormatters.currency(point.salesAmount),
                      ],
                  ],
                ),
              ).toShareRequest(_shareKey),
            )
          : null,
      onOpenFullscreen: widget.showHeader ? widget.onOpenFullscreen : null,
      showDesktopBranchSidebar: widget.showSidebar,
      presentationMode: switch (widget.mode) {
        SalesLiveMapChartPanelMode.inline =>
          AppBrazilStoreSalesMapPresentationMode.inlineOperational,
        SalesLiveMapChartPanelMode.fullscreen =>
          AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
      },
    );

    if (widget.mode == SalesLiveMapChartPanelMode.inline) {
      return RepaintBoundary(
        key: _shareKey,
        child: _SalesLiveMapInlineParentScrollGuard(
          child: _SalesLiveMapChartRefreshOverlay(
            isRefreshing: widget.isRefreshing,
            child: chart,
          ),
        ),
      );
    }

    final tokens = context.appTokens;
    return AppSectionCard(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final maxHeight = cardConstraints.maxHeight;
          final chartChild = _SalesLiveMapChartRefreshOverlay(
            isRefreshing: widget.isRefreshing,
            child: chart,
          );
          if (maxHeight.isFinite && maxHeight < double.infinity) {
            return SizedBox(height: maxHeight, child: chartChild);
          }
          return chartChild;
        },
      ),
    );
  }
}

class _SalesLiveMapInlineParentScrollGuard extends StatelessWidget {
  const _SalesLiveMapInlineParentScrollGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isMobile(context)) {
      return child;
    }

    return Listener(
      key: const ValueKey<String>('sales-live-map-inline-scroll-guard'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _dispatch(context, lockParentScroll: true),
      onPointerUp: (_) => _dispatch(context, lockParentScroll: false),
      onPointerCancel: (_) => _dispatch(context, lockParentScroll: false),
      child: child,
    );
  }

  void _dispatch(BuildContext context, {required bool lockParentScroll}) {
    SalesLiveMapParentScrollLockNotification(
      lockParentScroll: lockParentScroll,
    ).dispatch(context);
  }
}

class _SalesLiveMapChartRefreshOverlay extends StatelessWidget {
  const _SalesLiveMapChartRefreshOverlay({
    required this.isRefreshing,
    required this.child,
  });

  final bool isRefreshing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isRefreshing) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: colorScheme.surface.withValues(alpha: 0.45),
              child: Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
