import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

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
    if (!_canAccessMainDashboard(user)) {
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

    final marginPct = (24.5 / compositeMultiplier.clamp(0.92, 1.08)).clamp(
      18.5,
      29.0,
    );
    final marginDelta = _marginDeltaLabelForStore(storeId.value);
    final marginIcon = marginDelta.trim().startsWith('-')
        ? DashboardSummaryMetricIcon.trendingDown
        : DashboardSummaryMetricIcon.trendingUp;

    return DashboardOverviewModel(
      summaryMetrics: <DashboardSummaryMetric>[
        DashboardSummaryMetric(
          title: 'Total de vendas',
          value: _formatWholeCurrency(142850 * compositeMultiplier),
          deltaLabel: _salesDeltaPctForStore(storeId.value),
          icon: DashboardSummaryMetricIcon.payments,
        ),
        DashboardSummaryMetric(
          title: 'Ticket médio',
          value: _formatDecimalCurrency(84.20 * compositeMultiplier),
          deltaLabel: _ticketDeltaPctForRole(user.roleLabel),
          icon: DashboardSummaryMetricIcon.receiptLong,
        ),
        DashboardSummaryMetric(
          title: 'Rentabilidade',
          value: '${marginPct.toStringAsFixed(1)}%',
          deltaLabel: marginDelta,
          icon: marginIcon,
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
        DashboardChartPoint(
          label: 'Dom',
          value: 118000 * compositeMultiplier,
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
      aiInsight: const DashboardAiInsight(
        title: 'Insight de IA',
        body:
            'Aumentar equipe no horário de pico (11h–13h) pode reduzir a perda '
            'de conversão em até 15%.',
        ctaLabel: 'Aplicar estratégia',
      ),
      categoryShares: _categorySharesForStore(storeId.value),
    );
  }

  List<DashboardCategoryShare> _categorySharesForStore(String storeId) {
    return switch (storeId) {
      '08' => const <DashboardCategoryShare>[
        DashboardCategoryShare(label: 'Bebidas', percent: 44),
        DashboardCategoryShare(label: 'Lanches', percent: 26),
        DashboardCategoryShare(label: 'Mercearia', percent: 18),
        DashboardCategoryShare(label: 'Outros', percent: 12),
      ],
      '14' => const <DashboardCategoryShare>[
        DashboardCategoryShare(label: 'Bebidas', percent: 38),
        DashboardCategoryShare(label: 'Lanches', percent: 31),
        DashboardCategoryShare(label: 'Mercearia', percent: 19),
        DashboardCategoryShare(label: 'Outros', percent: 12),
      ],
      _ => const <DashboardCategoryShare>[
        DashboardCategoryShare(label: 'Bebidas', percent: 42),
        DashboardCategoryShare(label: 'Lanches', percent: 28),
        DashboardCategoryShare(label: 'Mercearia', percent: 18),
        DashboardCategoryShare(label: 'Outros', percent: 12),
      ],
    };
  }

  String _salesDeltaPctForStore(String storeId) {
    return switch (storeId) {
      '08' => '+12,4%',
      '14' => '+6,1%',
      _ => '+8,9%',
    };
  }

  String _ticketDeltaPctForRole(String roleLabel) {
    return switch (roleLabel) {
      'Gerente regional' => '+3,4%',
      'Gerente de loja' => '+2,4%',
      'Gestor de loja' => '+2,1%',
      'Analista operacional' => '+1,2%',
      _ => '+2,1%',
    };
  }

  String _marginDeltaLabelForStore(String storeId) {
    return switch (storeId) {
      '08' => '-0,8%',
      '14' => '+0,4%',
      _ => '-0,8%',
    };
  }

  String _formatWholeCurrency(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDecimalCurrency(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    ).format(value);
  }

  bool _canAccessMainDashboard(FakeIdentityUserRecord user) {
    if (user.dashboardGrants.isEmpty) {
      return user.permissions.contains(UserPermission.viewDashboard);
    }
    return user.dashboardGrants
        .any((grant) => grant.dashboardId == _mainDashboardId);
  }
}
