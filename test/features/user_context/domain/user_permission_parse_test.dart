import 'package:checks/checks.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseUserPermissionName', () {
    test('should resolve known permission names', () {
      check(
        parseUserPermissionName('viewDashboard'),
      ).equals(UserPermission.viewDashboard);
      check(parseUserPermissionName('viewSales')).equals(
        UserPermission.viewSales,
      );
    });

    test('should return null for unknown or legacy names', () {
      check(parseUserPermissionName('viewReports')).isNull();
      check(parseUserPermissionName('unknown.permission')).isNull();
    });
  });

  group('parseUserPermissionNameSet', () {
    test('should keep only known permissions and drop the rest', () {
      final result = parseUserPermissionNameSet(<String>[
        'viewDashboard',
        'viewReports',
        'future.permission',
      ]);
      check(result).deepEquals(<UserPermission>{UserPermission.viewDashboard});
    });
  });
}
