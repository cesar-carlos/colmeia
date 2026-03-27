import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
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
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  static const String _placeholderStoreId = 'loading-store';
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

  List<AppChartPoint> _buildSellerRevenuePoints(List<ReportResultRow> rows) {
    return rows
        .map(
          (row) => AppChartPoint(
            label: row.seller,
            value: row.revenue,
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
                  resolvedStore.id != _placeholderStoreId) {
                _scheduleLoad(
                  userId: session.userId,
                  storeId: StoreId(resolvedStore.id),
                );
              }

              final detail = controller.detail ?? _skeletonDetail;
              final showSkeleton =
                  controller.isLoading && controller.detail == null;

              return ListView(
                padding: EdgeInsets.all(tokens.contentSpacing),
                children: <Widget>[
                  Text(
                    detail.definition.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.gapSm),
                  Text(
                    '${resolvedStore.name} • ${detail.generatedAtLabel}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  SizedBox(height: tokens.gapXs),
                  Text(
                    detail.definition.subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (resolvedStoreResult.exceptionOrNull()
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
                  if (controller.errorMessage
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
                  AppSkeleton(
                    enabled: showSkeleton,
                    child: AppSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Resumo executivo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: tokens.gapMd),
                          ...detail.summaryMetrics.map((metric) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: tokens.gapMd),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    metric.title,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  SizedBox(height: tokens.gapXs),
                                  Text(
                                    metric.value,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: tokens.gapXs),
                                  Text(
                                    metric.detailLabel,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
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
                    child: AppChartShell(
                      title: 'Faturamento por vendedor',
                      subtitle:
                          'Recorte atual considerando a loja selecionada.',
                      child: AppComparisonBarChart(
                        points: _buildSellerRevenuePoints(detail.rows),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    child: ReportResultsGrid(rows: detail.rows),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    child: AppSectionCard(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
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
                              child: const Text('Pagina anterior'),
                            ),
                          ),
                          SizedBox(width: tokens.gapMd),
                          Text(
                            'Pagina ${detail.pageInfo.currentPage} de '
                            '${detail.pageInfo.totalPages}',
                            style: theme.textTheme.labelLarge,
                          ),
                          SizedBox(width: tokens.gapMd),
                          Expanded(
                            child: FilledButton(
                              onPressed:
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
                              child: const Text('Proxima pagina'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
