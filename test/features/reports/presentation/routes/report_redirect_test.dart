import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/reports/presentation/routes/report_redirect.dart';
import 'package:colmeia/features/user_context/domain/entities/report_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_scope.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redirectWithReportAccessGuard', () {
    test('should keep reports route when permission is granted', () {
      final userContextController = CurrentUserContextController.seeded();

      check(
        redirectWithReportAccessGuard(
          userContextController: userContextController,
          matchedRoute: AppRoute.reports,
        ),
      ).isNull();
    });

    test('should ignore non-report routes', () {
      final userContextController = CurrentUserContextController.seeded();

      check(
        redirectWithReportAccessGuard(
          userContextController: userContextController,
          matchedRoute: AppRoute.dashboard,
        ),
      ).isNull();
    });

    test('should redirect reports route when permission is missing', () {
      final userContextController = CurrentUserContextController(
        userScope: const UserScope(
          userId: 'restricted-user',
          name: 'Camila Nunes',
          roleLabel: 'Coordenadora',
          allowedStores: <StoreScope>[
            StoreScope(id: '03', name: 'Loja Centro'),
          ],
          permissions: <UserPermission>{
            UserPermission.viewDashboard,
          },
        ),
        activeStoreId: '03',
      );

      check(
        redirectWithReportAccessGuard(
          userContextController: userContextController,
          matchedRoute: AppRoute.reports,
        ),
      ).equals(AppRoute.dashboard.path);
    });

    test('should allow report detail when report grant exists', () {
      final userContextController = CurrentUserContextController(
        userScope: const UserScope(
          userId: 'allowed-user',
          name: 'Camila Nunes',
          roleLabel: 'Coordenadora',
          allowedStores: <StoreScope>[
            StoreScope(id: '03', name: 'Loja Centro'),
          ],
          permissions: <UserPermission>{
            UserPermission.viewReports,
          },
          reportGrants: <ReportAccessGrant>[
            ReportAccessGrant(reportId: 'sales_overview'),
          ],
        ),
        activeStoreId: '03',
      );

      check(
        redirectWithReportAccessGuard(
          userContextController: userContextController,
          matchedRoute: AppRoute.reportDetail,
          reportId: 'sales_overview',
        ),
      ).isNull();
    });
  });
}
