import 'package:checks/checks.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_remote_datasource.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/data/repositories/dashboard_repository_impl.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardLocalDataSource extends Mock
    implements DashboardLocalDataSource {}

class _MockDashboardRemoteDataSource extends Mock
    implements DashboardRemoteDataSource {}

void main() {
  late _MockDashboardLocalDataSource local;
  late _MockDashboardRemoteDataSource remote;
  late DashboardRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(StoreId('fallback-store'));
  });

  setUp(() {
    local = _MockDashboardLocalDataSource();
    remote = _MockDashboardRemoteDataSource();
    repository = DashboardRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  test(
    'should expose clearer message when dashboard returns 403 '
    'without cache fallback',
    () async {
      when(
        () => remote.fetchOverview(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/dashboards/overview'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/dashboards/overview'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      when(
        () => local.readOverview(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      ).thenAnswer((_) async => _cachedOverviewModel());

      final result = await repository.loadOverview(
        userId: 'client-1',
        storeId: StoreId('client-account'),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Sua conta nao tem permissao para visualizar este dashboard.',
      );
      verifyNever(
        () => local.readOverview(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      );
    },
  );

  test(
    'should fallback to cache on transient error during default load',
    () async {
      when(
        () => remote.fetchOverview(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/dashboards/overview'),
          type: DioExceptionType.connectionError,
        ),
      );
      when(
        () => local.readOverview(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      ).thenAnswer((_) async => _cachedOverviewModel());

      final result = await repository.loadOverview(
        userId: 'client-1',
        storeId: StoreId('client-account'),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrThrow().summaryMetrics.single.title).equals(
        'Faturamento do dia',
      );
    },
  );

  test('should not fallback to cache during force refresh', () async {
    when(
      () => remote.fetchOverview(
        userId: any(named: 'userId'),
        storeId: any(named: 'storeId'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/dashboards/overview'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.loadOverview(
      userId: 'client-1',
      storeId: StoreId('client-account'),
      policy: DashboardLoadPolicy.forceRefresh,
    );

    check(result.isError()).isTrue();
    verifyNever(
      () => local.readOverview(
        userId: any(named: 'userId'),
        storeId: any(named: 'storeId'),
      ),
    );
  });
}

DashboardOverviewModel _cachedOverviewModel() {
  return const DashboardOverviewModel(
    summaryMetrics: <DashboardSummaryMetric>[
      DashboardSummaryMetric(
        title: 'Faturamento do dia',
        value: r'R$ 128,4 mil',
        deltaLabel: '+8,2% vs ontem',
        icon: DashboardSummaryMetricIcon.trendingUp,
      ),
    ],
    revenuePoints: <DashboardChartPoint>[
      DashboardChartPoint(label: 'Seg', value: 92000),
    ],
    sellerPerformancePoints: <DashboardChartPoint>[
      DashboardChartPoint(label: 'Amanda', value: 32400),
    ],
    operationalHighlights: <DashboardDetailHighlight>[
      DashboardDetailHighlight(
        title: 'Ruptura controlada',
        subtitle: 'Itens criticos abaixo do limite nas ultimas 24h.',
        emphasis: '2 SKUs sob monitoramento',
      ),
    ],
    aiInsight: DashboardAiInsight(
      title: 'Insight de IA',
      body: 'Corpo',
      ctaLabel: 'Aplicar',
    ),
    categoryShares: <DashboardCategoryShare>[
      DashboardCategoryShare(label: 'A', percent: 50),
      DashboardCategoryShare(label: 'B', percent: 50),
    ],
  );
}
