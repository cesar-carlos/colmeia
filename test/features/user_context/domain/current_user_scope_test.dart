import 'package:checks/checks.dart';
import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUserScope', () {
    test('should expose profile fields through compatibility getters', () {
      const scope = CurrentUserScope(
        profile: UserProfile(
          id: 'u1',
          name: 'Camila Oliveira',
          roleLabel: 'Gerente regional',
          corporateEmail: 'camila@example.com',
          phone: '+55 (11) 98765-4321',
        ),
        access: UserAccessScope(
          allowedStores: <StoreScope>[
            StoreScope(id: '03', name: 'Loja Centro'),
          ],
          permissions: <UserPermission>{
            UserPermission.viewDashboard,
          },
        ),
      );

      check(scope.userId).equals('u1');
      check(scope.name).equals('Camila Oliveira');
      check(scope.roleLabel).equals('Gerente regional');
      check(scope.corporateEmail).equals('camila@example.com');
      check(scope.phone).equals('+55 (11) 98765-4321');
    });

    test('should delegate access rules to access scope', () {
      const scope = CurrentUserScope(
        profile: UserProfile(
          id: 'u1',
          name: 'Camila Oliveira',
          roleLabel: 'Gerente regional',
        ),
        access: UserAccessScope(
          allowedStores: <StoreScope>[
            StoreScope(id: '03', name: 'Loja Centro'),
          ],
          permissions: <UserPermission>{
            UserPermission.viewDashboard,
          },
          dashboardGrants: <DashboardAccessGrant>[
            DashboardAccessGrant(
              dashboardId: 'dashboard_main',
              allowedFilterKeys: <String>{'store'},
            ),
          ],
        ),
      );

      check(scope.canAccessStore('03')).isTrue();
      check(scope.canAccessDashboard('dashboard_main')).isTrue();
      check(
        scope.allowedDashboardFilterKeys('dashboard_main'),
      ).deepEquals(<String>{'store'});
    });
  });
}
