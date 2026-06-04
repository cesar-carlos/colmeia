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
import 'package:flutter/material.dart';

enum SalesLiveMapChartPanelMode {
  inline,
  fullscreen,
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
      return chart;
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
          if (maxHeight.isFinite && maxHeight < double.infinity) {
            return SizedBox(height: maxHeight, child: chart);
          }
          return chart;
        },
      ),
    );
  }
}
