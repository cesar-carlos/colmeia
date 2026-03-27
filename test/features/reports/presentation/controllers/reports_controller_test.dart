import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/application/usecases/load_reports_overview_use_case.dart';
import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/entities/report_page_info.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/report_summary_metric.dart';
import 'package:colmeia/features/reports/domain/entities/reports_overview.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';
import 'package:colmeia/features/reports/presentation/controllers/reports_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('ReportsController', () {
    test('should load overview from use case', () async {
      final controller = ReportsController(
        LoadReportsOverviewUseCase(_FakeReportsRepository()),
      );

      await controller.loadOverview(
        userId: 'demo-user',
        activeStoreId: StoreId('03'),
      );

      check(controller.availableReports.length).equals(1);
      check(controller.parameters.length).equals(3);
      check(controller.rows.length).equals(1);
    });

    test('should normalize filters when store and date are valid', () async {
      final controller = ReportsController(
        LoadReportsOverviewUseCase(_FakeReportsRepository()),
      );
      await controller.loadOverview(
        userId: 'demo-user',
        activeStoreId: StoreId('03'),
      );

      final result = controller.applyFilters(<String, Object?>{
        'store': '03',
        'referenceDate': DateTime(2026, 3),
        'seller': 'Amanda',
      });

      check(result.isSuccess()).isTrue();
      check(controller.errorMessage).isNull();
      check(controller.lastAppliedFilters['store']).equals('03');
    });

    test('should expose clear error when store is missing', () async {
      final controller = ReportsController(
        LoadReportsOverviewUseCase(_FakeReportsRepository()),
      );
      await controller.loadOverview(
        userId: 'demo-user',
        activeStoreId: StoreId('03'),
      );

      final result = controller.applyFilters(<String, Object?>{
        'referenceDate': DateTime(2026, 3),
      });

      check(result.isError()).isTrue();
      check(controller.errorMessage).equals(
        'Selecione uma loja para consultar o relatorio.',
      );
    });
  });
}

class _FakeReportsRepository implements ReportsRepository {
  @override
  Future<AppResult<ReportsOverview>> loadOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    return const Success<ReportsOverview, AppFailure>(
      ReportsOverview(
        availableReports: <ReportDefinition>[
          ReportDefinition(
            id: 'sales_overview',
            title: 'Vendas por loja',
            subtitle: 'Comparativo diario.',
          ),
        ],
        parameters: <ReportParameterDescriptor>[
          ReportParameterDescriptor(
            name: 'store',
            label: 'Loja',
            type: ReportParameterType.singleSelect,
            required: true,
            options: <ReportParameterOption>[
              ReportParameterOption(value: '03', label: 'Loja Centro'),
              ReportParameterOption(value: '08', label: 'Loja Norte'),
            ],
          ),
          ReportParameterDescriptor(
            name: 'seller',
            label: 'Vendedor',
            type: ReportParameterType.text,
          ),
          ReportParameterDescriptor(
            name: 'referenceDate',
            label: 'Data de referencia',
            type: ReportParameterType.date,
            required: true,
          ),
        ],
        rows: <ReportResultRow>[
          ReportResultRow(
            seller: 'Amanda',
            store: 'Loja Centro',
            revenue: 18234.2,
            orders: 61,
          ),
        ],
      ),
    );
  }

  @override
  Future<AppResult<ReportDetail>> loadDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    int page = 1,
    int pageSize = 2,
  }) async {
    return const Success<ReportDetail, AppFailure>(
      ReportDetail(
        definition: ReportDefinition(
          id: 'sales_overview',
          title: 'Vendas por loja',
          subtitle: 'Comparativo diario.',
        ),
        storeName: 'Loja Centro',
        generatedAtLabel: 'Atualizado em 27/03/2026 10:00',
        parameters: <ReportParameterDescriptor>[
          ReportParameterDescriptor(
            name: 'seller',
            label: 'Vendedor',
            type: ReportParameterType.text,
          ),
        ],
        pageInfo: ReportPageInfo(
          currentPage: 1,
          pageSize: 2,
          totalRows: 1,
          totalPages: 1,
        ),
        summaryMetrics: <ReportSummaryMetric>[
          ReportSummaryMetric(
            title: 'Faturamento total',
            value: r'R$ 18.234,20',
            detailLabel: '1 vendedores no recorte',
          ),
        ],
        rows: <ReportResultRow>[
          ReportResultRow(
            seller: 'Amanda',
            store: 'Loja Centro',
            revenue: 18234.2,
            orders: 61,
          ),
        ],
      ),
    );
  }

  @override
  Future<Map<String, Object?>> readPersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) async {
    return const <String, Object?>{};
  }

  @override
  Future<void> savePersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  }) async {}
}
