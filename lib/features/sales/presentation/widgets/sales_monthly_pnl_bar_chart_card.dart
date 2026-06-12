import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_point_percent_metric.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_body.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_fullscreen.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

export 'sales_monthly_pnl_bar_chart_fullscreen.dart'
    show pushSalesMonthlyPnlBarChartFullscreen;

class SalesMonthlyPnlBarChartCard extends StatefulWidget {
  const SalesMonthlyPnlBarChartCard({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    required this.initialSession,
    required this.persistSession,
    super.key,
    this.loadFailure,
    this.loadFailureMessage,
    this.onOpenFullscreen,
    this.onRequestShare,
    this.exportHeaderContext,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final SalesMonthlyPnlBarChartPreferences initialSession;
  final Future<void> Function(SalesMonthlyPnlBarChartPreferences session)
  persistSession;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final VoidCallback? onOpenFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  State<SalesMonthlyPnlBarChartCard> createState() =>
      _SalesMonthlyPnlBarChartCardState();
}

class _SalesMonthlyPnlBarChartCardState
    extends State<SalesMonthlyPnlBarChartCard> {
  final GlobalKey _shareKey = GlobalKey();

  late SalesMonthlyPnlBarChartPreferences _session;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
  }

  Future<void> _persistSession(SalesMonthlyPnlBarChartPreferences next) async {
    await widget.persistSession(next);
  }

  void _setSession(SalesMonthlyPnlBarChartPreferences next) {
    setState(() => _session = next);
    unawaited(_persistSession(next));
  }

  String _formatMonthLong(SalesMonthlyPnlPoint p, String locale) {
    return DateFormat.yMMM(locale).format(DateTime(p.year, p.month));
  }

  String _semanticsSummary(
    AppLocalizations l10n,
    List<SalesMonthlyPnlPoint> pts,
  ) {
    if (pts.isEmpty) {
      return '';
    }
    final locale = l10n.localeName;
    var totalVenda = 0.0;
    var totalLucro = 0.0;
    var totalCusto = 0.0;
    var top = pts.first;
    for (final p in pts) {
      totalVenda += p.venda;
      totalLucro += p.lucro;
      totalCusto += p.custoMercadoria;
      if (p.venda > top.venda) {
        top = p;
      }
    }
    return l10n.salesMonthlyPnlBarSummarySemantics(
      AppBrFormatters.smartCompactCurrencyForLocale(totalVenda, locale),
      AppBrFormatters.smartCompactCurrencyForLocale(totalLucro, locale),
      AppBrFormatters.smartCompactCurrencyForLocale(totalCusto, locale),
      _formatMonthLong(top, locale),
      AppBrFormatters.smartCompactCurrencyForLocale(top.venda, locale),
    );
  }

  bool _valuesAllZero(List<SalesMonthlyPnlPoint> pts) {
    for (final p in pts) {
      if (p.venda != 0 || p.lucro != 0 || p.custoMercadoria != 0) {
        return false;
      }
    }
    return true;
  }

  bool _percentAllZero(
    List<SalesMonthlyPnlPoint> pts,
    LucratividadePercentMetric metric,
  ) {
    for (final p in pts) {
      if (p.metricBarValue(metric) != 0) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = context.appTokens;
    final theme = Theme.of(context);
    final localeTag = l10n.localeName;
    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ?? l10n.salesMonthlyPnlLoadFailed)
        : l10n.salesMonthlyPnlEmpty;
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final resolvedHeight = chartTheme.height;
    final primaryMoney = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    final gridLineColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );

    final percentMetric = _session.percentMetric;

    final percentRatioFormat = NumberFormat.decimalPercentPattern(
      locale: localeTag,
      decimalDigits: 1,
    );

    void openBarFullscreen() {
      unawaited(
        pushSalesMonthlyPnlBarChartFullscreen(
          context: context,
          points: List<SalesMonthlyPnlPoint>.of(
            widget.points,
            growable: false,
          ),
          initialSession: _session,
          isLoading: widget.isLoading,
          loadFailed: widget.loadFailed,
          loadFailureMessage: widget.loadFailureMessage,
        ),
      );
    }

    final summary = _semanticsSummary(l10n, widget.points);
    final shareMetadata = buildSalesMonthlyPnlBarChartShareMetadata(
      l10n: l10n,
      points: widget.points,
      session: _session,
      tokens: tokens,
      chartTheme: chartTheme,
      localeTag: localeTag,
      primaryMoney: primaryMoney,
      gridLineColor: gridLineColor,
      percentRatioFormat: percentRatioFormat,
      exportHeaderContext: widget.exportHeaderContext,
    );
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: shareMetadata,
      onRequestShare: widget.onRequestShare,
      shareEnabled: !widget.isLoading,
    );

    return Semantics(
      container: true,
      label: l10n.salesMonthlyPnlBarChartSemantics,
      value: summary.isEmpty ? null : summary,
      child: RepaintBoundary(
        key: _shareKey,
        child: SalesMonthlyPnlBarChartBody(
          l10n: l10n,
          points: widget.points,
          loadFailed: widget.loadFailed,
          loadFailure: widget.loadFailure,
          loadFailureMessage: widget.loadFailureMessage,
          isLoading: widget.isLoading,
          session: _session,
          onSessionChanged: _setSession,
          chartHeightOverride: resolvedHeight,
          emptyMessage: emptyMessage,
          summarySemantics: summary,
          tokens: tokens,
          theme: theme,
          chartTheme: chartTheme,
          localeTag: localeTag,
          primaryMoney: primaryMoney,
          gridLineColor: gridLineColor,
          percentRatioFormat: percentRatioFormat,
          openFullscreen: widget.onOpenFullscreen ?? openBarFullscreen,
          onShare: shareActions.shareCallback(),
          valuesAllZero: () => _valuesAllZero(widget.points),
          percentAllZero: () => _percentAllZero(widget.points, percentMetric),
          useChartShell: true,
        ),
      ),
    );
  }
}
