import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/data/models/report_detail_model.dart';
import 'package:colmeia/features/reports/data/models/reports_overview_model.dart';
import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_page_info.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/features/reports/domain/entities/report_summary_metric.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:dio/dio.dart';

class ReportsRemoteDataSource {
  Future<ReportsOverviewModel> fetchOverview({
    required String userId,
    required StoreId activeStoreId,
  }) {
    throw UnimplementedError();
  }

  Future<ReportDetailModel> fetchDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    required int page,
    required int pageSize,
  }) {
    throw UnimplementedError();
  }
}

class ApiReportsRemoteDataSource implements ReportsRemoteDataSource {
  ApiReportsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ReportsOverviewModel> fetchOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/overview',
      queryParameters: <String, Object?>{
        'userId': userId,
        'storeId': activeStoreId.value,
      },
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Reports overview response is null');
    }

    return ReportsOverviewModel.fromJson(responseBody);
  }

  @override
  Future<ReportDetailModel> fetchDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/${reportId.value}',
      queryParameters: <String, Object?>{
        'userId': userId,
        'storeId': storeId.value,
        'page': page,
        'pageSize': pageSize,
        ...filters,
      },
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Report detail response is null');
    }

    return ReportDetailModel.fromJson(responseBody);
  }
}

class FakeReportsRemoteDataSource implements ReportsRemoteDataSource {
  FakeReportsRemoteDataSource(this._fakeBackendStore);

  static const Map<String, ReportDefinition> _availableReportDefinitions =
      <String, ReportDefinition>{
        'sales_overview': ReportDefinition(
          id: 'sales_overview',
          title: 'Vendas por loja',
          subtitle: 'Comparativo diario consolidado por unidade e vendedor.',
        ),
        'margin_audit': ReportDefinition(
          id: 'margin_audit',
          title: 'Auditoria de margem',
          subtitle: 'Leitura tabular com foco em excecoes comerciais.',
        ),
      };

  final FakeIdentityBackendStore _fakeBackendStore;

  @override
  Future<ReportsOverviewModel> fetchOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw const FormatException('Fake reports user not found');
    }

    final selectedStore = user.allowedStores
        .where((store) => store.id == activeStoreId.value)
        .firstOrNull;
    if (selectedStore == null) {
      throw StateError('Requested reports store is outside user scope');
    }

    final availableReports = _resolveReportsForUser(user);
    final allowedOverviewFilterKeys = _resolveAllowedOverviewFilterKeys(
      user: user,
      availableReports: availableReports,
    );
    final storeOptions = user.allowedStores
        .map(
          (store) => ReportParameterOption(
            value: store.id,
            label: store.name,
          ),
        )
        .toList(growable: false);

    return ReportsOverviewModel(
      availableReports: availableReports,
      parameters: _buildOverviewParameters(
        allowedFilterKeys: allowedOverviewFilterKeys,
        selectedStore: selectedStore,
        storeOptions: storeOptions,
      ),
      rows: availableReports.isEmpty
          ? const <ReportResultRow>[]
          : _buildRows(
              allowedStores: user.allowedStores,
              roleLabel: user.roleLabel,
              reportId: ReportId('sales_overview'),
            ),
    );
  }

  @override
  Future<ReportDetailModel> fetchDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    required int page,
    required int pageSize,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));

    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw const FormatException('Fake report detail user not found');
    }

    final selectedStore = user.allowedStores
        .where((store) => store.id == storeId.value)
        .firstOrNull;
    if (selectedStore == null) {
      throw StateError('Requested report detail store is outside user scope');
    }

    final availableReports = _resolveReportsForUser(user);
    final definition = availableReports
        .where((report) => report.id == reportId.value)
        .firstOrNull;
    if (definition == null) {
      throw StateError('Requested report is not available for this user');
    }

    final allowedFilterKeys = user.reportGrants
        .where((grant) => grant.reportId == reportId.value)
        .firstOrNull
        ?.allowedFilterKeys;
    if (allowedFilterKeys == null || allowedFilterKeys.isEmpty) {
      throw StateError('Requested report has no granted filter scope');
    }

    final detailParameters = _buildDetailParameters(
      selectedStore: selectedStore,
      reportId: reportId,
      allowedFilterKeys: allowedFilterKeys,
    );
    final normalizedFilters = _normalizeDetailFilters(
      filters: filters,
      selectedStore: selectedStore,
      allowedFilterKeys: allowedFilterKeys,
    );
    final storeRows = _buildRows(
      allowedStores: <StoreScope>[selectedStore],
      roleLabel: user.roleLabel,
      reportId: reportId,
    );
    final filteredRows = _applyFilters(
      rows: storeRows,
      filters: normalizedFilters,
    );
    final totalRevenue = filteredRows.fold<double>(
      0,
      (total, row) => total + row.revenue,
    );
    final totalOrders = filteredRows.fold<int>(
      0,
      (total, row) => total + row.orders,
    );
    final averageTicket = totalOrders == 0 ? 0 : totalRevenue / totalOrders;
    final safePageSize = pageSize < 1 ? 1 : pageSize;
    final totalPages = filteredRows.isEmpty
        ? 1
        : (filteredRows.length / safePageSize).ceil();
    final currentPage = page.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * safePageSize;
    final endIndex = (startIndex + safePageSize).clamp(0, filteredRows.length);
    final pagedRows = filteredRows.sublist(startIndex, endIndex);

    return ReportDetailModel(
      definition: definition,
      storeName: selectedStore.name,
      generatedAtLabel:
          'Atualizado em ${AppBrFormatters.shortDateTime(DateTime.now())}',
      parameters: detailParameters,
      pageInfo: ReportPageInfo(
        currentPage: currentPage,
        pageSize: safePageSize,
        totalRows: filteredRows.length,
        totalPages: totalPages,
      ),
      summaryMetrics: <ReportSummaryMetric>[
        ReportSummaryMetric(
          title: 'Faturamento total',
          value: AppBrFormatters.currency(totalRevenue),
          detailLabel: '${filteredRows.length} linhas no recorte',
        ),
        ReportSummaryMetric(
          title: 'Pedidos',
          value: '$totalOrders',
          detailLabel:
              'Media de '
              '${_formatDecimal(totalOrders / storeRows.length)} '
              'por vendedor',
        ),
        ReportSummaryMetric(
          title: 'Ticket medio',
          value: AppBrFormatters.currency(averageTicket),
          detailLabel: switch (reportId.value) {
            'margin_audit' => 'Margem monitorada no fechamento',
            _ => 'Leitura consolidada da loja ativa',
          },
        ),
      ],
      rows: pagedRows,
    );
  }

  List<ReportParameterDescriptor> _buildDetailParameters({
    required StoreScope selectedStore,
    required ReportId reportId,
    required Set<String> allowedFilterKeys,
  }) {
    final parameters = <ReportParameterDescriptor>[];
    if (allowedFilterKeys.contains('store')) {
      parameters.add(
        ReportParameterDescriptor(
          name: 'store',
          label: 'Loja',
          type: ReportParameterType.singleSelect,
          required: true,
          initialValue: selectedStore.id,
          options: <ReportParameterOption>[
            ReportParameterOption(
              value: selectedStore.id,
              label: selectedStore.name,
            ),
          ],
        ),
      );
    }
    if (allowedFilterKeys.contains('seller')) {
      parameters.add(
        const ReportParameterDescriptor(
          name: 'seller',
          label: 'Vendedor',
          type: ReportParameterType.text,
        ),
      );
    }
    if (allowedFilterKeys.contains('referenceDate')) {
      parameters.add(
        ReportParameterDescriptor(
          name: 'referenceDate',
          label: 'Data de referencia',
          type: ReportParameterType.date,
          required: true,
          initialValue: DateTime(2026, 3, 27),
        ),
      );
    }
    if (allowedFilterKeys.contains('onlyPositiveMargin')) {
      parameters.add(
        ReportParameterDescriptor(
          name: 'onlyPositiveMargin',
          label: reportId.value == 'margin_audit'
              ? 'Somente margem positiva'
              : 'Somente vendedores acima da media',
          type: ReportParameterType.toggle,
          initialValue: true,
        ),
      );
    }
    return parameters;
  }

  Map<String, Object?> _normalizeDetailFilters({
    required Map<String, Object?> filters,
    required StoreScope selectedStore,
    required Set<String> allowedFilterKeys,
  }) {
    final normalized = <String, Object?>{};
    if (allowedFilterKeys.contains('store')) {
      normalized['store'] = selectedStore.id;
    }
    if (allowedFilterKeys.contains('referenceDate')) {
      normalized['referenceDate'] =
          filters['referenceDate'] as DateTime? ?? DateTime(2026, 3, 27);
    }
    if (allowedFilterKeys.contains('seller')) {
      normalized['seller'] = filters['seller'] as String? ?? '';
    }
    if (allowedFilterKeys.contains('onlyPositiveMargin')) {
      normalized['onlyPositiveMargin'] =
          filters['onlyPositiveMargin'] as bool? ?? true;
    }
    return normalized;
  }

  List<ReportResultRow> _applyFilters({
    required List<ReportResultRow> rows,
    required Map<String, Object?> filters,
  }) {
    final sellerQuery = (filters['seller'] as String?)?.trim().toLowerCase();
    final onlyPositiveMargin = filters['onlyPositiveMargin'] as bool? ?? false;

    return rows
        .where((row) {
          final matchesSeller =
              sellerQuery == null ||
              sellerQuery.isEmpty ||
              row.seller.toLowerCase().contains(sellerQuery);
          final marginGate =
              !onlyPositiveMargin || row.revenue >= 18000 || row.orders >= 55;

          return matchesSeller && marginGate;
        })
        .toList(growable: false);
  }

  List<ReportDefinition> _resolveReportsForUser(FakeIdentityUserRecord user) {
    return user.reportGrants
        .map((grant) => _availableReportDefinitions[grant.reportId])
        .whereType<ReportDefinition>()
        .toList(growable: false);
  }

  Set<String> _resolveAllowedOverviewFilterKeys({
    required FakeIdentityUserRecord user,
    required List<ReportDefinition> availableReports,
  }) {
    if (availableReports.isEmpty) {
      return const <String>{};
    }

    final allowedReportIds = availableReports
        .map((report) => report.id)
        .toSet();
    final allowedFilters = <String>{};
    for (final grant in user.reportGrants) {
      if (!allowedReportIds.contains(grant.reportId)) {
        continue;
      }
      allowedFilters.addAll(grant.allowedFilterKeys);
    }
    return allowedFilters;
  }

  List<ReportParameterDescriptor> _buildOverviewParameters({
    required Set<String> allowedFilterKeys,
    required StoreScope selectedStore,
    required List<ReportParameterOption> storeOptions,
  }) {
    final parameters = <ReportParameterDescriptor>[];
    if (allowedFilterKeys.contains('store')) {
      parameters.add(
        ReportParameterDescriptor(
          name: 'store',
          label: 'Loja',
          type: ReportParameterType.singleSelect,
          required: true,
          initialValue: selectedStore.id,
          options: storeOptions,
        ),
      );
    }
    if (allowedFilterKeys.contains('seller')) {
      parameters.add(
        const ReportParameterDescriptor(
          name: 'seller',
          label: 'Vendedor',
          type: ReportParameterType.text,
        ),
      );
    }
    if (allowedFilterKeys.contains('referenceDate')) {
      parameters.add(
        ReportParameterDescriptor(
          name: 'referenceDate',
          label: 'Data de referencia',
          type: ReportParameterType.date,
          required: true,
          initialValue: DateTime(2026, 3, 27),
        ),
      );
    }
    if (allowedFilterKeys.contains('onlyPositiveMargin')) {
      parameters.add(
        const ReportParameterDescriptor(
          name: 'onlyPositiveMargin',
          label: 'Somente margem positiva',
          type: ReportParameterType.toggle,
          initialValue: true,
        ),
      );
    }
    return parameters;
  }

  List<ReportResultRow> _buildRows({
    required List<StoreScope> allowedStores,
    required String roleLabel,
    required ReportId reportId,
  }) {
    final roleMultiplier = switch (roleLabel) {
      'Gerente regional' => 1.12,
      'Gerente de loja' => 0.93,
      'Gestor de loja' => 0.9,
      _ => 1.0,
    };
    final sellers = <String>['Amanda', 'Bruno', 'Carla', 'Diego'];
    final rows = <ReportResultRow>[];

    for (var storeIndex = 0; storeIndex < allowedStores.length; storeIndex++) {
      final store = allowedStores[storeIndex];
      final storeMultiplier = switch (store.id) {
        '08' => 1.08,
        '14' => 0.97,
        _ => 1.0,
      };

      for (var sellerIndex = 0; sellerIndex < sellers.length; sellerIndex++) {
        final seller = sellers[sellerIndex];
        final revenue =
            (15800 + (storeIndex * 1850) + (sellerIndex * 1325)) *
            storeMultiplier *
            roleMultiplier;
        final orders =
            (44 + (storeIndex * 6) + (sellerIndex * 5)) * roleMultiplier;

        rows.add(
          ReportResultRow(
            seller: seller,
            store: store.name,
            revenue: reportId.value == 'margin_audit'
                ? revenue * 0.88
                : revenue,
            orders: orders.round(),
          ),
        );
      }
    }

    return rows;
  }

  String _formatDecimal(num value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}
