import 'package:checks/checks.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_remote_datasource.dart';
import 'package:colmeia/features/dashboards/data/repositories/dashboard_repository_impl.dart';
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

  test('should expose clearer message when dashboard returns 403', () async {
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
    ).thenAnswer((_) async => null);

    final result = await repository.loadOverview(
      userId: 'client-1',
      storeId: StoreId('client-account'),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()?.displayMessage).equals(
      'Sua conta nao tem permissao para visualizar este dashboard.',
    );
  });
}
