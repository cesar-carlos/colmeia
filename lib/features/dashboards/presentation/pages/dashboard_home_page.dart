import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
import 'package:colmeia/features/dashboards/presentation/routes/dashboard_routes.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_ai_insight_card.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_category_mix_card.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_sales_trend_card.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_summary_card.dart';
import 'package:colmeia/features/user_context/domain/user_context_placeholders.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/features/user_context/presentation/widgets/allowed_store_selector_strip.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({
    this.storeId,
    super.key,
  });

  final StoreId? storeId;

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  static const DashboardOverview _skeletonOverview = DashboardOverview(
    summaryMetrics: <DashboardSummaryMetric>[
      DashboardSummaryMetric(
        title: 'Total de vendas',
        value: r'R$ 142.850',
        deltaLabel: '+12,4%',
        icon: DashboardSummaryMetricIcon.payments,
      ),
      DashboardSummaryMetric(
        title: 'Ticket médio',
        value: r'R$ 84,20',
        deltaLabel: '+2,1%',
        icon: DashboardSummaryMetricIcon.receiptLong,
      ),
      DashboardSummaryMetric(
        title: 'Rentabilidade',
        value: '24,5%',
        deltaLabel: '-0,8%',
        icon: DashboardSummaryMetricIcon.trendingDown,
      ),
    ],
    revenuePoints: <DashboardChartPoint>[
      DashboardChartPoint(label: 'Seg', value: 92000),
      DashboardChartPoint(label: 'Ter', value: 104000),
      DashboardChartPoint(label: 'Qua', value: 98700),
      DashboardChartPoint(label: 'Qui', value: 112400),
      DashboardChartPoint(label: 'Sex', value: 128400),
      DashboardChartPoint(label: 'Sab', value: 136800),
      DashboardChartPoint(label: 'Dom', value: 118000),
    ],
    sellerPerformancePoints: <DashboardChartPoint>[
      DashboardChartPoint(label: 'Amanda', value: 32400),
      DashboardChartPoint(label: 'Bruno', value: 28100),
      DashboardChartPoint(label: 'Carla', value: 26750),
    ],
    operationalHighlights: <DashboardDetailHighlight>[
      DashboardDetailHighlight(
        title: 'Ruptura controlada',
        subtitle: 'Itens críticos abaixo do limite nas últimas 24h.',
        emphasis: '2 SKUs sob monitoramento',
      ),
    ],
    aiInsight: DashboardAiInsight(
      title: 'Insight de IA',
      body:
          'Aumentar equipe no horário de pico (11h–13h) pode reduzir a '
          'perda de conversão em até 15%.',
      ctaLabel: 'Aplicar estratégia',
    ),
    categoryShares: <DashboardCategoryShare>[
      DashboardCategoryShare(label: 'Bebidas', percent: 42),
      DashboardCategoryShare(label: 'Lanches', percent: 28),
      DashboardCategoryShare(label: 'Mercearia', percent: 18),
      DashboardCategoryShare(label: 'Outros', percent: 12),
    ],
  );

  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
  }

  void _retryUserStores(
    BuildContext context,
    CurrentUserContextController userContext,
  ) {
    unawaited(
      userContext.reloadUserContext().catchError((Object error, StackTrace st) {
        AppLogger.warning(
          'Reload user context failed',
          context: const <String, Object?>{
            'operation': 'reloadUserContext',
          },
          error: error,
          stackTrace: st,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel atualizar as lojas.'),
          ),
        );
      }),
    );
  }

  String _greetingFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return 'Gestor';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child:
          Consumer3<
            AuthController,
            CurrentUserContextController,
            DashboardController
          >(
            builder:
                (
                  context,
                  authController,
                  userContext,
                  dashboardController,
                  child,
                ) {
                  final theme = Theme.of(context);
                  final tokens = theme.extension<AppThemeTokens>()!;
                  final session = authController.session;
                  final selectedStoreResult = userContext.resolveStore(
                    preferredStoreId: widget.storeId,
                  );
                  final selectedStore = selectedStoreResult.getOrElse(
                    (_) => userContext.activeStore,
                  );
                  final overview = dashboardController.overview;
                  final showSkeleton =
                      dashboardController.isLoading && overview == null;
                  final resolvedOverview = overview ?? _skeletonOverview;
                  final shouldShowOverview = showSkeleton || overview != null;
                  if (session != null &&
                      !userContext.isLoading &&
                      !UserContextPlaceholders.isLoadingStoreId(
                        selectedStore.id,
                      )) {
                    dashboardController.scheduleOverviewLoadIfNeeded(
                      userId: session.userId,
                      storeId: StoreId(selectedStore.id),
                    );
                  }

                  final greetingName = _greetingFirstName(
                    userContext.userScope.name,
                  );
                  final showReportsEntry = userContext.availableShellRoutes
                      .contains(AppRoute.reports);
                  final cs = theme.colorScheme;
                  final sessionUserId = session?.userId;

                  Future<void> onRefresh() async {
                    final currentSession = authController.session;
                    if (currentSession == null ||
                        UserContextPlaceholders.isLoadingStoreId(
                          selectedStore.id,
                        )) {
                      return;
                    }
                    await dashboardController.loadOverview(
                      userId: currentSession.userId,
                      storeId: StoreId(selectedStore.id),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(tokens.contentSpacing),
                      children: <Widget>[
                        AppShellPageIntro(
                          title: 'Olá, $greetingName',
                          subtitle: 'Aqui está o resumo da sua operação hoje.',
                          footer: AllowedStoreSelectorStrip(
                            stores: userContext.userScope.allowedStores,
                            selectedStoreId: selectedStore.id,
                            isLoading: userContext.isLoading,
                            errorMessage: userContext.errorMessage,
                            onRetry: session == null
                                ? null
                                : () => _retryUserStores(
                                    context,
                                    userContext,
                                  ),
                            onStoreSelected: (store) {
                              userContext
                                  .selectStore(store.id)
                                  .fold(
                                    (_) {
                                      context.goToData(
                                        DashboardStoreRouteData(
                                          storeId: StoreId(store.id),
                                        ),
                                      );
                                    },
                                    (failure) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            failure.displayMessage,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                            },
                          ),
                        ),
                        if (selectedStoreResult.exceptionOrNull()
                            case final failure?) ...<Widget>[
                          SizedBox(height: tokens.gapMd),
                          AppInlineErrorPanel(
                            title: 'Loja indisponivel',
                            message: failure.displayMessage,
                            onRetry: session != null
                                ? () {
                                    unawaited(
                                      userContext.reloadUserContext(),
                                    );
                                  }
                                : null,
                          ),
                        ],
                        if (dashboardController.errorMessage
                            case final String errorMessage) ...<Widget>[
                          SizedBox(height: tokens.gapMd),
                          AppInlineErrorPanel(
                            title: 'Nao foi possivel carregar o dashboard',
                            message: errorMessage,
                            onRetry:
                                sessionUserId != null &&
                                    !UserContextPlaceholders.isLoadingStoreId(
                                      selectedStore.id,
                                    )
                                ? () {
                                    unawaited(
                                      dashboardController.loadOverview(
                                        userId: sessionUserId,
                                        storeId: StoreId(selectedStore.id),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ],
                        SizedBox(height: tokens.sectionSpacing),
                        if (shouldShowOverview) ...<Widget>[
                          AppSkeleton(
                            enabled: showSkeleton,
                            child: DashboardAiInsightCard(
                              insight: resolvedOverview.aiInsight,
                              onApply: showSkeleton
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Sugestão enviada para a equipe.',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          SizedBox(height: tokens.sectionSpacing),
                          ..._summaryMetricWidgets(
                            metrics: resolvedOverview.summaryMetrics,
                            showSkeleton: showSkeleton,
                            tokens: tokens,
                          ),
                          if (showReportsEntry) ...<Widget>[
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: showSkeleton
                                      ? null
                                      : () => context.goTo(AppRoute.reports),
                                  icon: const Icon(Icons.bar_chart_rounded),
                                  label: Text(
                                    'VER RELATÓRIO COMPLETO',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.primaryContainer,
                                    foregroundColor: cs.onPrimaryContainer,
                                    minimumSize: Size(
                                      48,
                                      tokens.actionButtonMinHeight + 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: tokens.sectionSpacing),
                          AppSkeleton(
                            enabled: showSkeleton,
                            child: DashboardSalesTrendCard(
                              points: resolvedOverview.revenuePoints,
                            ),
                          ),
                          SizedBox(height: tokens.sectionSpacing),
                          AppSkeleton(
                            enabled: showSkeleton,
                            child: DashboardCategoryMixCard(
                              shares: resolvedOverview.categoryShares,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
          ),
    );
  }
}

List<Widget> _summaryMetricWidgets({
  required List<DashboardSummaryMetric> metrics,
  required bool showSkeleton,
  required AppThemeTokens tokens,
}) {
  if (metrics.isEmpty) {
    return <Widget>[];
  }

  if (metrics.length == 1) {
    final m = metrics.single;
    return <Widget>[
      AppSkeleton(
        enabled: showSkeleton,
        child: DashboardSummaryCard(
          title: m.title,
          value: m.value,
          deltaLabel: m.deltaLabel,
          icon: m.icon,
          emphasis: DashboardSummaryCardEmphasis.accent,
          trendPlacement: AppMetricStatTrendPlacement.inlineStart,
        ),
      ),
    ];
  }

  final first = metrics[0];
  final second = metrics[1];
  final rest = <Widget>[];
  for (var i = 2; i < metrics.length; i++) {
    final m = metrics[i];
    rest
      ..add(SizedBox(height: tokens.contentSpacing))
      ..add(
        AppSkeleton(
          enabled: showSkeleton,
          child: DashboardSummaryCard(
            title: m.title,
            value: m.value,
            deltaLabel: m.deltaLabel,
            icon: m.icon,
            trendPlacement: AppMetricStatTrendPlacement.inlineStart,
          ),
        ),
      );
  }

  return <Widget>[
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: AppSkeleton(
            enabled: showSkeleton,
            child: DashboardSummaryCard(
              title: first.title,
              value: first.value,
              deltaLabel: first.deltaLabel,
              icon: first.icon,
              emphasis: DashboardSummaryCardEmphasis.accent,
            ),
          ),
        ),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: AppSkeleton(
            enabled: showSkeleton,
            child: DashboardSummaryCard(
              title: second.title,
              value: second.value,
              deltaLabel: second.deltaLabel,
              icon: second.icon,
            ),
          ),
        ),
      ],
    ),
    ...rest,
  ];
}
