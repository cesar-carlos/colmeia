import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:dio/dio.dart';

class DashboardRemoteDataSource {
  Future<DashboardOverviewModel> fetchOverview({
    required String userId,
    required StoreId storeId,
  }) {
    throw UnimplementedError();
  }
}

class ApiDashboardRemoteDataSource implements DashboardRemoteDataSource {
  ApiDashboardRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<DashboardOverviewModel> fetchOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/dashboards/overview',
      queryParameters: <String, Object?>{
        'userId': userId,
        'storeId': storeId.value,
      },
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Dashboard overview response is null');
    }

    return DashboardOverviewModel.fromJson(responseBody);
  }
}

class FakeDashboardRemoteDataSource implements DashboardRemoteDataSource {
  FakeDashboardRemoteDataSource(this._fakeBackendStore);

  static const String _mainDashboardId = 'dashboard_main';

  final FakeIdentityBackendStore _fakeBackendStore;

  @override
  Future<DashboardOverviewModel> fetchOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw const FormatException('Fake dashboard user not found');
    }

    final selectedStore = user.allowedStores
        .where((store) => store.id == storeId.value)
        .firstOrNull;
    if (selectedStore == null) {
      throw StateError('Requested dashboard store is outside user scope');
    }
    final dashboardGrant = user.dashboardGrants
        .where((grant) => grant.dashboardId == _mainDashboardId)
        .firstOrNull;
    if (dashboardGrant == null) {
      throw StateError('Requested dashboard is not available for this user');
    }

    final storeMultiplier = switch (storeId.value) {
      '08' => 1.08,
      '14' => 0.96,
      _ => 1.0,
    };
    final roleMultiplier = switch (user.roleLabel) {
      'Gerente regional' => 1.12,
      'Gerente de loja' => 0.94,
      'Gestor de loja' => 0.92,
      'Analista operacional' => 0.86,
      _ => 1.0,
    };
    final scopeMultiplier = 1 + (user.allowedStores.length - 1) * 0.03;
    final compositeMultiplier =
        storeMultiplier * roleMultiplier * scopeMultiplier;

    return DashboardOverviewModel(
      summaryMetrics: <DashboardSummaryMetric>[
        DashboardSummaryMetric(
          title: 'Faturamento do dia',
          value: _formatCompactCurrency(128400 * compositeMultiplier),
          deltaLabel: dashboardGrant.allowedFilterKeys.contains('referenceDate')
              ? _deltaLabelForStore(storeId.value)
              : 'Leitura consolidada do periodo',
          icon: DashboardSummaryMetricIcon.trendingUp,
        ),
        DashboardSummaryMetric(
          title: 'Ticket medio',
          value: _formatCurrency(246.3 * compositeMultiplier),
          deltaLabel: _ticketDeltaLabelForRole(user.roleLabel),
          icon: DashboardSummaryMetricIcon.receiptLong,
        ),
        DashboardSummaryMetric(
          title: 'Pedidos em andamento',
          value: (118 * compositeMultiplier).round().toString(),
          deltaLabel: '${selectedStore.name} em foco',
          icon: DashboardSummaryMetricIcon.insights,
        ),
      ],
      revenuePoints: <DashboardChartPoint>[
        DashboardChartPoint(
          label: 'Seg',
          value: 92000 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Ter',
          value: 104000 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Qua',
          value: 98700 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Qui',
          value: 112400 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Sex',
          value: 128400 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Sab',
          value: 136800 * compositeMultiplier,
        ),
      ],
      sellerPerformancePoints: <DashboardChartPoint>[
        DashboardChartPoint(
          label: 'Amanda',
          value: 32400 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Bruno',
          value: 28100 * compositeMultiplier,
        ),
        DashboardChartPoint(
          label: 'Carla',
          value: 26750 * compositeMultiplier,
        ),
      ],
      operationalHighlights: <DashboardDetailHighlight>[
        DashboardDetailHighlight(
          title: 'Ruptura controlada',
          subtitle: 'Itens criticos abaixo do limite nas ultimas 24h.',
          emphasis: switch (storeId.value) {
            '08' => '3 SKUs sob monitoramento',
            '14' => '1 SKU sob monitoramento',
            _ => '2 SKUs sob monitoramento',
          },
        ),
        DashboardDetailHighlight(
          title: 'Checkout',
          subtitle: 'Tempo medio de atendimento percebido pela operacao.',
          emphasis: switch (user.roleLabel) {
            'Gerente regional' => '4min12s no consolidado',
            'Analista operacional' => '4min48s no consolidado',
            _ => '4min26s no consolidado',
          },
        ),
        DashboardDetailHighlight(
          title: 'Meta semanal',
          subtitle: 'Leitura projetada com base no ritmo atual da loja.',
          emphasis: switch (storeId.value) {
            '08' => '92% da meta prevista',
            '14' => '87% da meta prevista',
            _ => '95% da meta prevista',
          },
        ),
      ],
    );
  }

  String _deltaLabelForStore(String storeId) {
    return switch (storeId) {
      '08' => '+10,4% vs ontem',
      '14' => '+2,8% vs ontem',
      _ => '+8,2% vs ontem',
    };
  }

  String _ticketDeltaLabelForRole(String roleLabel) {
    return switch (roleLabel) {
      'Gerente regional' => '+4,7% na semana',
      'Gerente de loja' => '+2,9% na semana',
      'Gestor de loja' => '+2,4% na semana',
      'Analista operacional' => '+1,6% na semana',
      _ => '+3,1% na semana',
    };
  }

  String _formatCompactCurrency(double value) {
    final compactValue = (value / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return 'R\$ $compactValue mil';
  }

  String _formatCurrency(double value) {
    final fixedValue = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixedValue';
  }
}
