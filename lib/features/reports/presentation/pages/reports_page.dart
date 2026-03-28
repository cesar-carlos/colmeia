import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/presentation/controllers/reports_controller.dart';
import 'package:colmeia/features/reports/presentation/routes/report_routes.dart';
import 'package:colmeia/features/reports/presentation/widgets/report_parameter_form.dart';
import 'package:colmeia/features/reports/presentation/widgets/report_results_grid.dart';
import 'package:colmeia/features/user_context/domain/user_context_placeholders.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/metrics/app_compact_kpi_stat.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Duration _reportsCriticalSkeletonDelay = Duration.zero;
const Duration _reportsSecondarySkeletonDelay = Duration(milliseconds: 120);

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const List<ReportDefinition> _skeletonReports = <ReportDefinition>[
    ReportDefinition(
      id: 'sales_overview',
      title: 'Vendas por loja',
      subtitle: 'Comparativo diario com filtros por periodo e vendedor.',
    ),
    ReportDefinition(
      id: 'margin_audit',
      title: 'Auditoria de margem',
      subtitle: 'Leitura tabular com foco em excecoes comerciais.',
    ),
  ];

  static final List<ReportParameterDescriptor> _skeletonParameters =
      <ReportParameterDescriptor>[
        const ReportParameterDescriptor(
          name: 'store',
          label: 'Loja',
          type: ReportParameterType.singleSelect,
          required: true,
          initialValue: '03',
          options: <ReportParameterOption>[
            ReportParameterOption(value: '03', label: 'Loja Centro'),
            ReportParameterOption(value: '08', label: 'Loja Norte'),
          ],
        ),
        const ReportParameterDescriptor(
          name: 'seller',
          label: 'Vendedor',
          type: ReportParameterType.text,
        ),
        ReportParameterDescriptor(
          name: 'referenceDate',
          label: 'Data de referencia',
          type: ReportParameterType.date,
          required: true,
          initialValue: DateTime(2026, 3),
        ),
      ];

  static const List<ReportResultRow> _skeletonRows = <ReportResultRow>[
    ReportResultRow(
      seller: 'Amanda',
      store: 'Loja Centro',
      revenue: 18234.2,
      orders: 61,
    ),
    ReportResultRow(
      seller: 'Bruno',
      store: 'Loja Norte',
      revenue: 16490.8,
      orders: 54,
    ),
    ReportResultRow(
      seller: 'Carla',
      store: 'Loja Sul',
      revenue: 21345.7,
      orders: 73,
    ),
  ];

  late final ReportsController _controller;
  String? _lastLoadSignature;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ReportsController>();
  }

  void _scheduleOverviewLoad({
    required String userId,
    required StoreId activeStoreId,
  }) {
    final loadSignature = '$userId:${activeStoreId.value}';
    if (_lastLoadSignature == loadSignature) {
      return;
    }

    _lastLoadSignature = loadSignature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(
        _controller.loadOverview(
          userId: userId,
          activeStoreId: activeStoreId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReportsController>.value(
      value: _controller,
      child:
          Consumer3<
            AuthController,
            CurrentUserContextController,
            ReportsController
          >(
            builder: (context, authController, userContext, controller, child) {
              final theme = Theme.of(context);
              final tokens = theme.extension<AppThemeTokens>()!;
              final session = authController.session;
              final activeStore = userContext.activeStore;
              final showSkeleton =
                  controller.isLoading &&
                  controller.availableReports.isEmpty &&
                  controller.parameters.isEmpty &&
                  controller.rows.isEmpty;
              final reports = showSkeleton
                  ? _skeletonReports
                  : controller.availableReports;
              final parameters = showSkeleton
                  ? _skeletonParameters
                  : controller.parameters;
              final rows = showSkeleton ? _skeletonRows : controller.rows;
              final hasGrantedReports = reports.isNotEmpty;
              if (session != null &&
                  !userContext.isLoading &&
                  !UserContextPlaceholders.isLoadingStoreId(activeStore.id)) {
                _scheduleOverviewLoad(
                  userId: session.userId,
                  activeStoreId: StoreId(activeStore.id),
                );
              }

              Future<void> onRefresh() async {
                if (session == null ||
                    UserContextPlaceholders.isLoadingStoreId(activeStore.id)) {
                  return;
                }
                await controller.loadOverview(
                  userId: session.userId,
                  activeStoreId: StoreId(activeStore.id),
                );
              }

              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(tokens.contentSpacing),
                  children: <Widget>[
                    AppShellPageIntro(
                      eyebrow: 'Colmeia Insights',
                      title: 'Relatórios liberados',
                      subtitle:
                          'Acompanhe consultas, filtros e resultados da loja '
                          'ativa em um só fluxo.',
                      footer: Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: <Widget>[
                          Chip(label: Text(userContext.userScope.roleLabel)),
                          Chip(label: Text(activeStore.name)),
                          if (!showSkeleton)
                            Chip(
                              label: Text(
                                '${reports.length} rotas disponíveis',
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (userContext.errorMessage
                        case final String contextError) ...<Widget>[
                      SizedBox(height: tokens.sectionSpacing),
                      AppInlineErrorPanel(
                        title: 'Nao foi possivel sincronizar',
                        message: contextError,
                        onRetry: session != null
                            ? () {
                                unawaited(userContext.reloadUserContext());
                              }
                            : null,
                      ),
                    ],
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportsCriticalSkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando indicadores gerais de relatórios...',
                      child: AppSectionCard(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: AppCompactKpiStat(
                                label: 'Rotas',
                                value: reports.length.toString(),
                              ),
                            ),
                            Expanded(
                              child: AppCompactKpiStat(
                                label: 'Filtros',
                                value: parameters.length.toString(),
                              ),
                            ),
                            Expanded(
                              child: AppCompactKpiStat(
                                label: 'Linhas',
                                value: rows.length.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportsCriticalSkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando lista de relatórios liberados...',
                      child: AppSectionCardWithHeading(
                        title: 'Rotas parametrizadas de relatório',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ...reports.map((report) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(report.title),
                                subtitle: Text(report.subtitle),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  unawaited(
                                    context.pushToData<void>(
                                      ReportDetailRouteData(
                                        reportId: ReportId(report.id),
                                        storeId: StoreId(activeStore.id),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            if (!showSkeleton && !hasGrantedReports)
                              const ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Nenhum relatório liberado.'),
                                subtitle: Text(
                                  'O seu acesso atual não possui relatórios '
                                  'habilitados para esta loja.',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    if (parameters.isNotEmpty)
                      AppSkeleton(
                        enabled: showSkeleton,
                        showDelay: _reportsSecondarySkeletonDelay,
                        loadingSemanticsLabel:
                            'Carregando formulário de filtros...',
                        child: ReportParameterForm(
                          parameters: parameters,
                          onApply: (filters) {
                            controller.applyFilters(filters).fold(
                              (normalizedFilters) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Filtros aplicados: '
                                      '${normalizedFilters.keys.join(', ')}',
                                    ),
                                  ),
                                );
                              },
                              (_) {},
                            );
                          },
                        ),
                      ),
                    if (controller.errorMessage
                        case final String errorMessage) ...<Widget>[
                      SizedBox(height: tokens.sectionSpacing),
                      AppInlineErrorPanel(
                        title: 'Nao foi possivel carregar os relatorios',
                        message: errorMessage,
                        onRetry:
                            session != null &&
                                !UserContextPlaceholders.isLoadingStoreId(
                                  activeStore.id,
                                )
                            ? () {
                                unawaited(
                                  controller.loadOverview(
                                    userId: session.userId,
                                    activeStoreId: StoreId(activeStore.id),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                    if (controller.hasAppliedFilters) ...<Widget>[
                      SizedBox(height: tokens.sectionSpacing),
                      AppSectionCard(
                        child: Text(
                          'Ultimos filtros aplicados: '
                          '${controller.lastAppliedFilters.keys.join(', ')}',
                        ),
                      ),
                    ],
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportsSecondarySkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando gráfico comparativo de faturamento...',
                      child: AppComparisonBarChart<ReportResultRow>(
                        title: 'Comparativo de faturamento por vendedor',
                        subtitle: 'Leitura rapida baseada no resultado atual.',
                        items: rows,
                        labelBuilder: (row) => row.seller,
                        valueBuilder: (row) => row.revenue,
                        dataLabelBuilder: (row, value) =>
                            AppBrFormatters.compactCurrency(value),
                        style: AppComparisonBarChartStyle(
                          yAxisFormat: AppBrFormatters.compactCurrencyFormat,
                          showDataLabels: true,
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportsSecondarySkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando grade de resultados...',
                      child: ReportResultsGrid(rows: rows),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
