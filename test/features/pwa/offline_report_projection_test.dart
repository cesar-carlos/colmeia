import 'package:colmeia/features/pwa/domain/offline_authorization.dart';
import 'package:colmeia/features/pwa/domain/offline_package.dart';
import 'package:colmeia/features/pwa/presentation/offline_report_projection.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26);
  final package = OfflinePackage(
    authorization: OfflineAuthorization(
      userId: 'user',
      agentIds: {'agent'},
      issuedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    ),
    agentId: 'agent',
    savedAt: now,
    periodStart: now.subtract(const Duration(days: 29)),
    periodEnd: now,
    datasets: {
      'salesByBranch': [
        {'nomeFilial': 'Norte A', 'totalVenda': 10},
        {'nomeFilial': 'Sul', 'totalVenda': 50},
        {'nomeFilial': 'Norte B', 'totalVenda': 30},
      ],
      'overview': <String, dynamic>{},
    },
  );
  test('filters and sorts the downloaded rows before paging and exporting', () {
    final result = OfflineReportProjection(
      package,
      'salesByBranch',
      const AppReportQuery(
        searchTerm: 'norte',
        pageSize: 1,
        page: 2,
        sorts: [
          AppReportSortDescriptor(
            columnKey: 'totalVenda',
            direction: AppReportSortDirection.descending,
          ),
        ],
      ),
    );
    expect(result.rows.map((row) => row['totalVenda']), [30, 10]);
    expect(result.pageRows.single['nomeFilial'], 'Norte A');
    expect(result.pageInfo.totalRows, 2);
  });
  test('an empty search keeps the column schema and bounds the page', () {
    final result = OfflineReportProjection(
      package,
      'salesByBranch',
      const AppReportQuery(searchTerm: 'missing', page: 50),
    );
    expect(result.rows, isEmpty);
    expect(result.columns, contains('nomeFilial'));
    expect(result.pageInfo.currentPage, 1);
  });
  test('missing datasets and unsupported filters require a connection', () {
    expect(
      () => OfflineReportProjection(
        package,
        'dailySalesTrend',
        const AppReportQuery(),
      ),
      throwsStateError,
    );
    expect(
      () => OfflineReportProjection(
        package,
        'salesByBranch',
        const AppReportQuery(filters: {'period': 'previous'}),
      ),
      throwsStateError,
    );
  });
}
