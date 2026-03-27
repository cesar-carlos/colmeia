import 'package:colmeia/app/router/app_route_data.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/presentation/pages/report_detail_page.dart';
import 'package:colmeia/features/reports/presentation/pages/reports_page.dart';
import 'package:go_router/go_router.dart';

final class ReportDetailRouteData implements AppRouteData {
  ReportDetailRouteData({
    required this.reportId,
    this.storeId,
  });

  factory ReportDetailRouteData.fromState(GoRouterState state) {
    final storeIdValue = state.uri.queryParameters[storeIdQueryParameter];

    return ReportDetailRouteData(
      reportId: ReportId(state.pathParameters[reportIdParameter]!),
      storeId: storeIdValue == null ? null : StoreId(storeIdValue),
    );
  }

  static const String reportIdParameter = 'reportId';
  static const String storeIdQueryParameter = 'store';

  final ReportId reportId;
  final StoreId? storeId;

  @override
  AppRoute get route => AppRoute.reportDetail;

  @override
  Map<String, String> get pathParameters => <String, String>{
    reportIdParameter: reportId.value,
  };

  @override
  Map<String, dynamic> get queryParameters => <String, dynamic>{
    if (storeId != null) storeIdQueryParameter: storeId!.value,
  };
}

List<RouteBase> buildReportRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.reportDetail.name,
      path: AppRoute.reportDetail.path,
      builder: (context, state) {
        final routeData = ReportDetailRouteData.fromState(state);

        return ReportDetailPage(
          reportId: routeData.reportId,
          storeId: routeData.storeId,
        );
      },
    ),
    GoRoute(
      name: AppRoute.reports.name,
      path: AppRoute.reports.path,
      builder: (context, state) {
        return const ReportsPage();
      },
    ),
  ];
}
