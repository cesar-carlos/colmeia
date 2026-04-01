import 'package:checks/checks.dart';
import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserAccessScope', () {
    test('should allow dashboard access from grants', () {
      const access = UserAccessScope(
        allowedStores: <StoreScope>[
          StoreScope(id: '03', name: 'Loja Centro'),
        ],
        permissions: <UserPermission>{},
        dashboardGrants: <DashboardAccessGrant>[
          DashboardAccessGrant(
            dashboardId: 'dashboard_main',
            allowedFilterKeys: <String>{'store', 'referenceDate'},
          ),
        ],
      );

      check(access.hasAnyDashboardAccess()).isTrue();
      check(access.canAccessDashboard('dashboard_main')).isTrue();
      check(access.canAccessStore('03')).isTrue();
      check(access.allowedDashboardFilterKeys('dashboard_main')).deepEquals(
        <String>{'store', 'referenceDate'},
      );
    });

    test('should fallback to dashboard permission when grants are absent', () {
      const access = UserAccessScope(
        allowedStores: <StoreScope>[],
        permissions: <UserPermission>{
          UserPermission.viewDashboard,
        },
      );

      check(access.hasAnyDashboardAccess()).isTrue();
      check(access.canAccessDashboard('any-dashboard')).isTrue();
      check(access.allowedDashboardFilterKeys('any-dashboard')).isEmpty();
    });
  });
}
