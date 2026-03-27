import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
import 'package:colmeia/features/dashboards/presentation/routes/dashboard_routes.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_chart_renderer.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_summary_card.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
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
        title: 'Faturamento do dia',
        value: r'R$ 000,0 mil',
        deltaLabel: '+0,0% vs ontem',
        icon: DashboardSummaryMetricIcon.trendingUp,
      ),
      DashboardSummaryMetric(
        title: 'Ticket medio',
        value: r'R$ 000,00',
        deltaLabel: '+0,0% na semana',
        icon: DashboardSummaryMetricIcon.receiptLong,
      ),
    ],
    revenuePoints: <DashboardChartPoint>[
      DashboardChartPoint(label: 'Seg', value: 92000),
      DashboardChartPoint(label: 'Ter', value: 104000),
      DashboardChartPoint(label: 'Qua', value: 98700),
      DashboardChartPoint(label: 'Qui', value: 112400),
      DashboardChartPoint(label: 'Sex', value: 128400),
      DashboardChartPoint(label: 'Sab', value: 136800),
    ],
    sellerPerformancePoints: <DashboardChartPoint>[
      DashboardChartPoint(label: 'Amanda', value: 32400),
      DashboardChartPoint(label: 'Bruno', value: 28100),
      DashboardChartPoint(label: 'Carla', value: 26750),
    ],
    operationalHighlights: <DashboardDetailHighlight>[
      DashboardDetailHighlight(
        title: 'Ruptura controlada',
        subtitle: 'Itens criticos abaixo do limite nas ultimas 24h.',
        emphasis: '2 SKUs sob monitoramento',
      ),
      DashboardDetailHighlight(
        title: 'Checkout',
        subtitle: 'Tempo medio de atendimento percebido pela operacao.',
        emphasis: '4min26s no consolidado',
      ),
      DashboardDetailHighlight(
        title: 'Meta semanal',
        subtitle: 'Leitura projetada com base no ritmo atual da loja.',
        emphasis: '95% da meta prevista',
      ),
    ],
  );

  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
  }

  List<AppChartPoint> _buildSellerPoints(List<DashboardChartPoint> points) {
    return points
        .map(
          (point) => AppChartPoint(
            label: point.label,
            value: point.value,
          ),
        )
        .toList(growable: false);
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

                  return ListView(
                    padding: EdgeInsets.all(tokens.contentSpacing),
                    children: <Widget>[
                      Text(
                        'Bem-vinda, ${userContext.userScope.name}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.gapSm),
                      Text(
                        '${userContext.userScope.roleLabel} • '
                        '${selectedStore.name}',
                        style: theme.textTheme.bodyLarge,
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
                          child: AppSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Lojas no escopo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: tokens.gapMd),
                                Wrap(
                                  spacing: tokens.gapSm,
                                  runSpacing: tokens.gapSm,
                                  children: userContext.userScope.allowedStores
                                      .map((
                                        store,
                                      ) {
                                        final isActive =
                                            store.id == selectedStore.id;

                                        return ChoiceChip(
                                          label: Text(store.name),
                                          selected: isActive,
                                          onSelected: (_) {
                                            userContext
                                                .selectStore(store.id)
                                                .fold(
                                                  (_) {
                                                    context.goToData(
                                                      DashboardStoreRouteData(
                                                        storeId: StoreId(
                                                          store.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  (failure) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          failure
                                                              .displayMessage,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                          },
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: tokens.sectionSpacing),
                        AppSkeleton(
                          enabled: showSkeleton,
                          child: DashboardChartRenderer(
                            title: 'Evolucao semanal do faturamento',
                            subtitle:
                                'Pinch, pan e selection zoom ja preparados '
                                'para '
                                'analytics.',
                            points: resolvedOverview.revenuePoints,
                          ),
                        ),
                        SizedBox(height: tokens.sectionSpacing),
                        AppSkeleton(
                          enabled: showSkeleton,
                          child: AppChartShell(
                            title: 'Top vendedores do recorte',
                            subtitle:
                                'Comparativo rapido para leitura operacional.',
                            child: AppComparisonBarChart(
                              points: _buildSellerPoints(
                                resolvedOverview.sellerPerformancePoints,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: tokens.sectionSpacing),
                        AppSkeleton(
                          enabled: showSkeleton,
                          child: AppSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Leituras detalhadas',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: tokens.gapMd),
                                ...resolvedOverview.operationalHighlights.map((
                                  highlight,
                                ) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: tokens.gapMd,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          highlight.title,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        SizedBox(height: tokens.gapXs),
                                        Text(
                                          highlight.subtitle,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        SizedBox(height: tokens.gapXs),
                                        Text(
                                          highlight.emphasis,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.tertiary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
          ),
    );
  }
}
