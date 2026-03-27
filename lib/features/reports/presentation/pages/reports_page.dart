import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/core/di/injector.dart';
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
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const String _placeholderStoreId = 'loading-store';
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

  List<AppChartPoint> _buildSellerRevenuePoints(List<ReportResultRow> rows) {
    return rows
        .map(
          (row) => AppChartPoint(
            label: row.seller,
            value: row.revenue,
          ),
        )
        .toList();
  }

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
                  activeStore.id != _placeholderStoreId) {
                _scheduleOverviewLoad(
                  userId: session.userId,
                  activeStoreId: StoreId(activeStore.id),
                );
              }

              return ListView(
                padding: EdgeInsets.all(tokens.contentSpacing),
                children: <Widget>[
                  Text(
                    'Relatorios liberados',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.gapSm),
                  Text(
                    '${userContext.userScope.roleLabel} • ${activeStore.name}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  SizedBox(height: tokens.gapXs),
                  Text(
                    'A base da feature ja esta pronta para filtros, paginacao '
                    'e ordenacao.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    child: AppSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Rotas parametrizadas de relatorio',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: tokens.gapMd),
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
                              title: Text('Nenhum relatorio liberado.'),
                              subtitle: Text(
                                'O seu acesso atual nao possui relatorios '
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
                    AppSectionCard(
                      child: Text(
                        errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
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
                    child: AppChartShell(
                      title: 'Comparativo de faturamento por vendedor',
                      subtitle: 'Baseado nas linhas do resultado atual.',
                      child: AppComparisonBarChart(
                        points: _buildSellerRevenuePoints(rows),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    child: ReportResultsGrid(rows: rows),
                  ),
                ],
              );
            },
          ),
    );
  }
}
