import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';

class CurrentUserScope {
  const CurrentUserScope({
    required this.profile,
    required this.access,
  });

  final UserProfile profile;
  final UserAccessScope access;

  String get userId => profile.id;
  String get name => profile.name;
  String get roleLabel => profile.roleLabel;
  String get corporateEmail => profile.corporateEmail;
  String get phone => profile.phone;
  String get firstName => profile.firstName;
  String get lastName => profile.lastName;
  String? get thumbnailUrl => profile.thumbnailUrl;
  List<StoreScope> get allowedStores => access.allowedStores;
  Set<UserPermission> get permissions => access.permissions;
  List<DashboardAccessGrant> get dashboardGrants => access.dashboardGrants;

  bool canAccessStore(String storeId) {
    return access.canAccessStore(storeId);
  }

  bool hasAnyDashboardAccess() {
    return access.hasAnyDashboardAccess();
  }

  bool canAccessDashboard(String dashboardId) {
    return access.canAccessDashboard(dashboardId);
  }

  Set<String> allowedDashboardFilterKeys(String dashboardId) {
    return access.allowedDashboardFilterKeys(dashboardId);
  }
}
