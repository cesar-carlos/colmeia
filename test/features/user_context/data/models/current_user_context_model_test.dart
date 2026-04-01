import 'package:checks/checks.dart';
import 'package:colmeia/features/user_context/data/models/current_user_context_model.dart';
import 'package:colmeia/features/user_context/data/models/user_access_scope_model.dart';
import 'package:colmeia/features/user_context/data/models/user_profile_model.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUserContextModel.fromJson', () {
    test(
      'should parse only known permissions when list mixes valid and unknown',
      () {
        final model = CurrentUserContextModel.fromJson(
          _minimalUserJson(
            permissions: <String>['viewDashboard', 'viewReports', 'unknown'],
          ),
        );
        check(
          model.permissions,
        ).deepEquals(<UserPermission>{UserPermission.viewDashboard});
      },
    );
  });

  group('UserProfileModel.fromJson', () {
    test('should read identity and contact fields', () {
      final model = UserProfileModel.fromJson(
        _minimalUserJson(
          permissions: <String>['viewDashboard'],
          corporateEmail: 'camila@example.com',
          phone: '+55 (11) 98765-4321',
        ),
      );

      check(model.id).equals('u1');
      check(model.name).equals('Test');
      check(model.roleLabel).equals('Role');
      check(model.corporateEmail).equals('camila@example.com');
      check(model.phone).equals('+55 (11) 98765-4321');
    });
  });

  group('UserAccessScopeModel.fromJson', () {
    test('should fallback to dashboard permission when grants exist', () {
      final model = UserAccessScopeModel.fromJson(
        _minimalUserJson(
          allowedDashboardIds: <String>['dashboard_main'],
        ),
      );

      check(model.permissions).deepEquals(
        <UserPermission>{UserPermission.viewDashboard},
      );
      check(model.dashboardGrants).length.equals(1);
      check(model.allowedStores.single.id).equals('1');
    });
  });
}

Map<String, dynamic> _minimalUserJson({
  List<String>? permissions,
  String? corporateEmail,
  String? phone,
  List<String>? allowedDashboardIds,
}) {
  return <String, dynamic>{
    'userId': 'u1',
    'name': 'Test',
    'roleLabel': 'Role',
    'allowedStores': <Map<String, String>>[
      <String, String>{'id': '1', 'name': 'Loja'},
    ],
    'permissions': permissions,
    'corporateEmail': corporateEmail,
    'phone': phone,
    'allowedDashboardIds': allowedDashboardIds,
    'activeStoreId': '1',
  };
}
