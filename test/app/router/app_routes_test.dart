import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/presentation/routes/report_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoute', () {
    test('should resolve nested dashboard route from location', () {
      check(AppRoute.fromLocation('/dashboard/store/03')).equals(
        AppRoute.dashboardStore,
      );
    });

    test('should resolve report detail route from location', () {
      check(AppRoute.fromLocation('/reports/sales_overview')).equals(
        AppRoute.reportDetail,
      );
    });
  });

  group('ReportDetailRouteData', () {
    test('should expose path and query parameters', () {
      final routeData = ReportDetailRouteData(
        reportId: ReportId('sales_overview'),
        storeId: StoreId('03'),
      );

      check(routeData.pathParameters).deepEquals(<String, String>{
        ReportDetailRouteData.reportIdParameter: 'sales_overview',
      });
      check(routeData.queryParameters).deepEquals(<String, dynamic>{
        ReportDetailRouteData.storeIdQueryParameter: '03',
      });
    });
  });
}
