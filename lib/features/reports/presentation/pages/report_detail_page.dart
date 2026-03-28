import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/entities/report_page_info.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/report_summary_metric.dart';
import 'package:colmeia/features/reports/presentation/controllers/report_detail_controller.dart';
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
import 'package:colmeia/shared/widgets/metrics/app_executive_metric_tile.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/pagination/app_inline_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Duration _reportDetailCriticalSkeletonDelay = Duration.zero;
const Duration _reportDetailSecondarySkeletonDelay = Duration(
  milliseconds: 120,
);

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    required this.reportId,
    this.storeId,
    super.key,
  });

  final ReportId reportId;
  final StoreId? storeId;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  static final ReportDetail _skeletonDetail = ReportDetail(
    definition: const ReportDefinition(
      id: 'sales_overview',
      title: 'Vendas por loja',
      subtitle: 'Detalhamento operacional consolidado.',
    ),
    storeName: 'Loja Centro',
    generatedAtLabel: 'Atualizado em 27/03/2026 10:00',
    parameters: <ReportParameterDescriptor>[
      const ReportParameterDescriptor(
        name: 'store',
        label: 'Loja',
        type: ReportParameterType.singleSelect,
        required: true,
        initialValue: '03',
        options: <ReportParameterOption>[
          ReportParameterOption(value: '03', label: 'Loja Centro'),
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
        initialValue: DateTime(2026, 3, 27),
      ),
      const ReportParameterDescriptor(
        name: 'onlyPositiveMargin',
        label: 'Somente margem positiva',
        type: ReportParameterType.toggle,
        initialValue: true,
      ),
    ],
    pageInfo: const ReportPageInfo(
      currentPage: 1,
      pageSize: 2,
      totalRows: 4,
      totalPages: 2,
    ),
    summaryMetrics: <ReportSummaryMetric>[
      const ReportSummaryMetric(
        title: 'Faturamento total',
        value: r'R$ 00.000,00',
        detailLabel: '0 vendedores no recorte',
      ),
      const ReportSummaryMetric(
        title: 'Pedidos',
        value: '0',
        detailLabel: 'Media de 0,0 por vendedor',
      ),
    ],
    rows: <ReportResultRow>[
      const ReportResultRow(
        seller: 'Amanda',
        store: 'Loja Centro',
        revenue: 18234.2,
        orders: 61,
      ),
    ],
  );

  late final ReportDetailController _controller;
  String? _lastLoadSignature;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ReportDetailController>();
  }

  void _scheduleLoad({
    required String userId,
    required StoreId storeId,
  }) {
    final loadSignature = '$userId:${widget.reportId.value}:${storeId.value}';
    if (_lastLoadSignature == loadSignature) {
      return;
    }

    _lastLoadSignature = loadSignature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(
        _controller.initialize(
          userId: userId,
          reportId: widget.reportId,
          storeId: storeId,
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
    return ChangeNotifierProvider<ReportDetailController>.value(
      value: _controller,
      child:
          Consumer3<
            AuthController,
            CurrentUserContextController,
            ReportDetailController
          >(
            builder: (context, authController, userContext, controller, child) {
              final theme = Theme.of(context);
              final tokens = theme.extension<AppThemeTokens>()!;
              final session = authController.session;
              final resolvedStoreResult = userContext.resolveStore(
                preferredStoreId: widget.storeId,
              );
              final resolvedStore = resolvedStoreResult.getOrElse(
                (_) => userContext.activeStore,
              );
              if (session != null &&
                  !userContext.isLoading &&
                  !UserContextPlaceholders.isLoadingStoreId(
                    resolvedStore.id,
                  )) {
                _scheduleLoad(
                  userId: session.userId,
                  storeId: StoreId(resolvedStore.id),
                );
              }

              final detail = controller.detail ?? _skeletonDetail;
              final showSkeleton =
                  controller.isLoading && controller.detail == null;
              Future<void> onRefresh() async {
                if (session == null ||
                    UserContextPlaceholders.isLoadingStoreId(
                      resolvedStore.id,
                    )) {
                  return;
                }

                await controller.initialize(
                  userId: session.userId,
                  reportId: widget.reportId,
                  storeId: StoreId(resolvedStore.id),
                );
              }

              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(tokens.contentSpacing),
                  children: <Widget>[
                    AppShellPageIntro(
                      eyebrow: 'Análise detalhada',
                      title: detail.definition.title,
                      subtitle: detail.definition.subtitle,
                      footer: Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: <Widget>[
                          Chip(label: Text(resolvedStore.name)),
                          Chip(label: Text(detail.generatedAtLabel)),
                          Chip(
                            label: Text(
                              'Página ${detail.pageInfo.currentPage}'
                              '/${detail.pageInfo.totalPages}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (resolvedStoreResult.exceptionOrNull()
                        case final failure?) ...<Widget>[
                      SizedBox(height: tokens.gapMd),
                      AppInlineErrorPanel(
                        title: 'Loja indisponivel',
                        message: failure.displayMessage,
                        onRetry: session != null
                            ? () {
                                unawaited(userContext.reloadUserContext());
                              }
                            : null,
                      ),
                    ],
                    if (controller.errorMessage
                        case final String errorMessage) ...<Widget>[
                      SizedBox(height: tokens.gapMd),
                      AppInlineErrorPanel(
                        title: 'Nao foi possivel carregar o relatorio',
                        message: errorMessage,
                        onRetry:
                            session != null &&
                                !UserContextPlaceholders.isLoadingStoreId(
                                  resolvedStore.id,
                                )
                            ? () {
                                unawaited(
                                  _controller.initialize(
                                    userId: session.userId,
                                    reportId: widget.reportId,
                                    storeId: StoreId(resolvedStore.id),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportDetailCriticalSkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando indicadores do relatório...',
                      child: AppSectionCard(
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: AppCompactKpiStat(
                                label: 'Métricas',
                                value: detail.summaryMetrics.length.toString(),
                              ),
                            ),
                            Expanded(
                              child: AppCompactKpiStat(
                                label: 'Linhas',
                                value: detail.rows.length.toString(),
                              ),
                            ),
                            Expanded(
                              child: AppCompactKpiStat(
                                label: 'Parâmetros',
                                value: detail.parameters.length.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportDetailCriticalSkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando resumo executivo do relatório...',
                      child: AppSectionCardWithHeading(
                        title: 'Resumo executivo',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: detail.summaryMetrics
                              .map(
                                (metric) => AppExecutiveMetricTile(
                                  label: metric.title,
                                  value: metric.value,
                                  detailLabel: metric.detailLabel,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportDetailSecondarySkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando parâmetros do relatório...',
                      child: ReportParameterForm(
                        parameters: detail.parameters,
                        initialValues: controller.filters,
                        onApply: (filters) {
                          if (session == null) {
                            return;
                          }

                          unawaited(
                            controller.applyFilters(
                              userId: session.userId,
                              reportId: widget.reportId,
                              storeId: StoreId(resolvedStore.id),
                              filters: filters,
                            ),
                          );
                        },
                        onClear: () {
                          if (session == null) {
                            return;
                          }

                          unawaited(
                            controller.clearFilters(
                              userId: session.userId,
                              reportId: widget.reportId,
                              storeId: StoreId(resolvedStore.id),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportDetailSecondarySkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando gráfico comparativo...',
                      child: AppComparisonBarChart<ReportResultRow>(
                        title: 'Comparativo de faturamento por vendedor',
                        subtitle: 'Leitura rapida baseada no resultado atual.',
                        items: detail.rows,
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
                      showDelay: _reportDetailSecondarySkeletonDelay,
                      loadingSemanticsLabel:
                          'Carregando tabela de resultados...',
                      child: ReportResultsGrid(rows: detail.rows),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    AppSkeleton(
                      enabled: showSkeleton,
                      showDelay: _reportDetailSecondarySkeletonDelay,
                      loadingSemanticsLabel: 'Carregando paginação...',
                      child: AppSectionCard(
                        child: AppInlinePaginationBar(
                          centerLabel:
                              'Pagina ${detail.pageInfo.currentPage} de '
                              '${detail.pageInfo.totalPages}',
                          onPrevious:
                              session != null &&
                                  controller.canLoadPreviousPage &&
                                  !controller.isLoading
                              ? () {
                                  unawaited(
                                    controller.loadPreviousPage(
                                      userId: session.userId,
                                      reportId: widget.reportId,
                                      storeId: StoreId(resolvedStore.id),
                                    ),
                                  );
                                }
                              : null,
                          onNext:
                              session != null &&
                                  controller.canLoadNextPage &&
                                  !controller.isLoading
                              ? () {
                                  unawaited(
                                    controller.loadNextPage(
                                      userId: session.userId,
                                      reportId: widget.reportId,
                                      storeId: StoreId(resolvedStore.id),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
