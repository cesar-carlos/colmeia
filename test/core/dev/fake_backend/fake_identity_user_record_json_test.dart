import 'package:checks/checks.dart';
import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeIdentityUserRecord.fromJson', () {
    test('should ignore legacy reportGrants keys in stored JSON', () {
      final record = FakeIdentityUserRecord.fromJson(<String, dynamic>{
        'id': 'x',
        'fullName': 'Nome',
        'email': 'a@b.c',
        'password': 'p',
        'employeeId': '',
        'roleLabel': 'R',
        'allowedStores': <Map<String, String>>[
          <String, String>{'id': '1', 'name': 'Loja'},
        ],
        'permissions': <String>['viewDashboard', 'viewReports'],
        'dashboardGrants': <Map<String, Object?>>[
          <String, Object?>{
            'dashboardId': 'dashboard_main',
            'allowedFilterKeys': <String>['store'],
            'allowedActions': <String>[],
          },
        ],
        'reportGrants': <Map<String, Object?>>[
          <String, Object?>{
            'reportId': 'sales_overview',
            'allowedFilterKeys': <String>['store'],
            'allowedActions': <String>[],
          },
        ],
        'activeStoreId': '1',
      });

      check(
        record.permissions,
      ).deepEquals(<UserPermission>{UserPermission.viewDashboard});
      check(record.dashboardGrants).length.equals(1);
      check(record.dashboardGrants.single.dashboardId).equals('dashboard_main');
    });

    test('should round-trip without reportGrants in output', () {
      final original = FakeIdentityUserRecord(
        id: 'id',
        fullName: 'Full',
        email: 'e@e.e',
        password: 'pw',
        employeeId: '',
        roleLabel: 'L',
        allowedStores: <StoreScope>[
          const StoreScope(id: '1', name: 'S'),
        ],
        permissions: <UserPermission>{UserPermission.viewDashboard},
        dashboardGrants: <DashboardAccessGrant>[
          const DashboardAccessGrant(dashboardId: 'd1'),
        ],
        activeStoreId: '1',
      );

      final json = original.toJson();
      check(json.containsKey('reportGrants')).isFalse();

      final back = FakeIdentityUserRecord.fromJson(
        Map<String, dynamic>.from(json),
      );
      check(back.id).equals(original.id);
      check(back.permissions).deepEquals(original.permissions);
    });
  });
}
