import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/application/usecases/load_persisted_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_report_detail_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/persist_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/entities/report_page_info.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/report_summary_metric.dart';
import 'package:colmeia/features/reports/domain/entities/reports_overview.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';
import 'package:colmeia/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('ReportDetailController', () {
    test('should load report detail from use case', () async {
      final repository = _FakeReportsRepository();
      final controller = ReportDetailController(
        LoadReportDetailUseCase(repository),
        LoadPersistedReportDetailFiltersUseCase(repository),
        PersistReportDetailFiltersUseCase(repository),
      );

      await controller.loadDetail(
        userId: 'demo-user',
        reportId: ReportId('sales_overview'),
        storeId: StoreId('03'),
        filters: const <String, Object?>{},
      );

      check(controller.detail).isNotNull();
      check(controller.errorMessage).isNull();
      check(controller.detail!.summaryMetrics.length).equals(1);
      check(controller.detail!.rows.length).equals(1);
    });

    test('should restore persisted filters on initialize', () async {
      final repository = _FakeReportsRepository(
        persistedFilters: <String, Object?>{
          'seller': 'Amanda',
        },
      );
      final controller = ReportDetailController(
        LoadReportDetailUseCase(repository),
        LoadPersistedReportDetailFiltersUseCase(repository),
        PersistReportDetailFiltersUseCase(repository),
      );

      await controller.initialize(
        userId: 'demo-user',
        reportId: ReportId('sales_overview'),
        storeId: StoreId('03'),
      );

      check(controller.filters['seller']).equals('Amanda');
    });

    test('should reject filters outside granted parameter set', () async {
      final repository = _FakeReportsRepository();
      final controller = ReportDetailController(
        LoadReportDetailUseCase(repository),
        LoadPersistedReportDetailFiltersUseCase(repository),
        PersistReportDetailFiltersUseCase(repository),
      );

      await controller.loadDetail(
        userId: 'demo-user',
        reportId: ReportId('sales_overview'),
        storeId: StoreId('03'),
        filters: const <String, Object?>{},
      );
      await controller.applyFilters(
        userId: 'demo-user',
        reportId: ReportId('sales_overview'),
        storeId: StoreId('03'),
        filters: const <String, Object?>{
          'unauthorizedFilter': true,
        },
      );

      check(controller.errorMessage).equals(
        'Alguns filtros nao estao liberados para este usuario.',
      );
    });
  });
}

class _FakeReportsRepository implements ReportsRepository {
  _FakeReportsRepository({
    this.persistedFilters = const <String, Object?>{},
  });

  final Map<String, Object?> persistedFilters;

  @override
  Future<AppResult<ReportsOverview>> loadOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    throw UnimplementedError();
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
    return persistedFilters;
  }

  @override
  Future<void> savePersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  }) async {}
}
