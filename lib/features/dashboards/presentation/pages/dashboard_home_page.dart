import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/core/di/injector.dart';
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
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
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
  static const String _placeholderStoreId = 'loading-store';

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
                      selectedStore.id != _placeholderStoreId) {
                    dashboardController.scheduleOverviewLoadIfNeeded(
                      userId: session.userId,
                      storeId: StoreId(selectedStore.id),
                    );
                  }

                  final greetingName = _greetingFirstName(
                    userContext.userScope.name,
                  );

                  Future<void> onRefresh() async {
                    final currentSession = authController.session;
                    if (currentSession == null ||
                        selectedStore.id == _placeholderStoreId) {
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
                        Text(
                          'Colmeia BI',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: tokens.gapXs),
                        Text(
                          'Dashboard',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: tokens.sectionSpacing),
                        Text(
                          'Olá, $greetingName',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: tokens.gapSm),
                        Text(
                          'Aqui está o resumo da sua operação hoje.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: tokens.gapMd),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: userContext.userScope.allowedStores.map((
                              store,
                            ) {
                              final isActive = store.id == selectedStore.id;
                              return Padding(
                                padding: EdgeInsets.only(right: tokens.gapSm),
                                child: ChoiceChip(
                                  label: Text(store.name),
                                  selected: isActive,
                                  onSelected: (_) {
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
                              );
                            }).toList(),
                          ),
                        ),
                        if (selectedStoreResult.exceptionOrNull()
                            case final failure?) ...<Widget>[
                          SizedBox(height: tokens.gapMd),
                          AppSectionCard(
                            child: Text(
                              failure.displayMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        if (dashboardController.errorMessage
                            case final String errorMessage) ...<Widget>[
                          SizedBox(height: tokens.gapMd),
                          AppSectionCard(
                            child: Text(
                              errorMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
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
                                            'Sugestão registrada para análise '
                                            'da equipe.',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          SizedBox(height: tokens.sectionSpacing),
                          ...resolvedOverview.summaryMetrics.map((metric) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: tokens.contentSpacing,
                              ),
                              child: AppSkeleton(
                                enabled: showSkeleton,
                                child: DashboardSummaryCard(
                                  title: metric.title,
                                  value: metric.value,
                                  deltaLabel: metric.deltaLabel,
                                  icon: metric.icon,
                                ),
                              ),
                            );
                          }),
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
